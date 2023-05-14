// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IStakingHandler} from "./../interfaces/IStakingHandler.sol";
import {IAirDropHandler} from "./../interfaces/IAirDropHandler.sol";

import "hardhat/console.sol";

contract Hub is 
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable 
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    //flag for upgrades availability
    bool public upgradeStatus;

    address public airdropHandler;
    address public stakingHandler;
    address public multisig;

    mapping(address => address) public tokenToColToken;

    event StakingIntialized(
        address token,
        uint256 amount,
        uint256 APR
    );

    event Staked(
        address user,
        address token,
        uint256 amount
    );

    event Unstaked(
        address user, 
        address token,
        uint256 amount
    );

    event AirdropInitialized(
        address token, 
        uint256 amount
    );

    event AirdropClaimed(
        address user,
        address token,
        uint256 amount
    );

    address[] public stakedTokens;

    /**
    * @dev constructor for the upgradeable contract
    */
    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
    }
    
    /**
    * @dev stakes a token
    * @param token address of the token to be staked
    * @param amount amount of the token to be staked
    */
    function stake(address token, uint256 amount) external  {
        require(IStakingHandler(stakingHandler).stakingLive(token), "Staking is not live");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        // All the info in handlers is stored in 18 decimals, thus needs to be converted
        uint256 decDif = 18 - IERC20Metadata(token).decimals() ;
        uint256 adjustedAmount = amount * 10 ** decDif;
        IStakingHandler(stakingHandler).stake(msg.sender, token, adjustedAmount);

        emit Staked(msg.sender, token, amount);
    }

    /**
    * @dev Unstakes a token performing all the checks when calculating the amount to be withdrawn in StakingHandler
    * @param token address of the token to be unstaked
    */
    function unstake (address token) external  {
        uint256 amount = IStakingHandler(stakingHandler).withdraw(msg.sender, token);
        console.log(amount);
        uint256 decDif = 18 - IERC20Metadata(token).decimals();
        amount = amount / 10 ** decDif;
        console.log(amount);
        IERC20Upgradeable(token).safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, token, amount);
    }

    /**
    *@dev Launches staking for a token
    *@param token address of the token to be staked
    *@param dailyInterest interest rate per day with 6 decimals (e.g. 10% = 10000000)
    */
    function launchStaking(address token, uint256 dailyInterest, uint256 timelock, uint256 stakeTime, uint256 maxAmount) external {
        // Calculating the max amount to cover the interest, after the staking is over the user, who initiated the staking can claim the unused tokens
        uint256 daysToStake = stakeTime / 86400;
        uint256 interest = dailyInterest * daysToStake;
        // uint256 bb = daysToStake * dailyInterest;
        uint256 maxCover = maxAmount * interest / 100;

        IERC20(token).transferFrom(msg.sender, address(this), maxCover);
        // All the info in handlers is stored in 18 decimals, thus needs to be converted
        uint256 decDiff = 18 - IERC20Metadata(token).decimals();
        IStakingHandler(stakingHandler).launchStaking(token, dailyInterest, timelock, stakeTime, maxCover * 10 ** decDiff);

        emit StakingIntialized(token, maxAmount, dailyInterest* 31536000);
    }

    /**
    * @dev Launches airdrop for a token
    * @param token address of the token to be airdropped
    * @param amount amount of tokens to be airdropped
    * @param airdropPeriod period of time the airdrop is active for
    * @param moneyBack flag to indicate if the unused tokens should be returned to the initiator or distributed among the participants
    */
    function launchAirdrop(address token, uint256 amount, uint256 airdropPeriod, bool moneyBack) external {
        // Checks if there are finalised stakings to enable aidrops
        require(stakedTokens.length > 0, "Airdrop is not available");

        // Checks if the amount covers the max possible airdrop, if moneyBack is on - rest can 
        // be claimed by the initiator after the airdrop is completed
        // require(IStakingHandler(stakingHandler).coverAirdrop(token) <= amount, "amount doesn't cover max possible");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        address colToken = stakedTokens[stakedTokens.length - 1];
        tokenToColToken[token] = colToken;
        
        stakedTokens.pop();
        uint256 decDiff = 18 - IERC20Metadata(token).decimals();
        bytes memory zeroRoot = abi.encodePacked(keccak256("0x0"));
        IAirDropHandler(airdropHandler).launchAirdrop(token, amount * 10 ** decDiff, amount * 10 ** decDiff * 20, airdropPeriod, zeroRoot, moneyBack);

        emit AirdropInitialized(token, amount);
    }

    /**
    * @dev Override for the function above which allows to enforce whitelisting of addresses for aidrops
    * @param token address of the token to be airdropped
    * @param amount amount of tokens to be airdropped
    * @param airdropPeriod period of time the airdrop is active for
    * @param moneyBack flag to indicate if the airdrop is a money back airdrop
    * @param merkleRoot encoded Merkle Root of the whitelisted addresses for the airdrop
    */
    function launchAirdrop(
        address token, 
        uint256 amount, 
        uint256 airdropPeriod, 
        bool moneyBack, 
        bytes memory merkleRoot
        ) public whenNotPaused {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 decDiff = 18 - IERC20Metadata(token).decimals();
        IAirDropHandler(airdropHandler).launchAirdrop(token, amount * 10 ** decDiff, amount * 10 ** decDiff * 20, airdropPeriod, merkleRoot, moneyBack);
        
        emit AirdropInitialized(token, amount);
    }

    /**
    * @dev Claims airdrop for a token
    * @param token address of the token to be airdropped
    */
    function claimAirdrop(address token) public whenNotPaused {
        require(IStakingHandler(stakingHandler).isAirDropEligible(msg.sender, tokenToColToken[token]), "User is not eligible for airdrop");

        uint256 amount = IAirDropHandler(airdropHandler).claimAirdrop(msg.sender, token);
        // All the info in handlers is stored in 18 decimals, thus needs to be converted
        uint256 decDiff = 18 - IERC20Metadata(token).decimals();
        IERC20Upgradeable(token).safeTransfer(msg.sender, amount / 10 ** decDiff);

        emit AirdropClaimed(msg.sender, token, amount);
    }

    function previewAirDrop(address token) public view returns(uint256) {
        return IAirDropHandler(airdropHandler).previewAirDrop(token);
    }

    function finaliseStaking(address token) public {
        IStakingHandler(stakingHandler).finaliseStaking(token);
        stakedTokens.push(token);
    }

    function setStakingHandler(address _stakingHandler) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingHandler = _stakingHandler;
    }

    function setAirdropHandler(address _airDropHandler) external onlyRole(DEFAULT_ADMIN_ROLE) {
        airdropHandler = _airDropHandler;
    }

    function setMultiSig(address _multisig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        multisig = _multisig;
    }

    function changeUpgradeStatus(
        bool _status
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeStatus = _status;
    }

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(UPGRADER_ROLE) {
        require(upgradeStatus, "StakingHandler: Upgrade not allowed");
        upgradeStatus = false;
    }
}