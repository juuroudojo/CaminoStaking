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

import "hardhat/console.sol";

contract StakingHandler is 
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable 
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant HUB = keccak256("HUB");

    //flag for upgrades availability
    bool public upgradeStatus;

    address public hub;
    uint256 public maxRate;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    event StakingInitialized (
        address token,
        uint256 interest,
        uint256 timelock,
        uint256 stakeTime,
        uint256 stakeMax,
        uint256 totalLocked,
        uint256 claimed
    );

    address[] public stakingTokens;

    struct StakeTokenInfo {
        uint256 interest;
        uint256 maxAmount;
        uint256 startTime;
        uint256 stakeTime;
        uint256 lockTime;
        uint256 minAmount;
        uint256 totalLocked;
        uint256 airDropAmount;
        uint256 airDropTime;
        uint256 endTime;
        bool active;
    }

    struct StakeInfo {
        address token;
        uint256 amount;
        uint256 claimed;
        uint256 timeStaked;
        uint256 timeLock;
        bool airDropEligible;
    }

    mapping(address => StakeTokenInfo) public tokenToInfo;
    mapping(address => mapping(address => StakeInfo)) public userToInfo;

    function initialize(address _hub) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        hub = _hub;
    }

    /**
    * @dev Initialize the staking campaign for a token
    * @param token address of the token to stake
    * @param interest interest rate for the token with 2 decimals (e.g. 10% = 100000)
    * @param timelock timelock period for the token in seconds (e.g. 1 month = 2592000)
    * @param staketime time to stake the token in seconds (e.g. 1 month = 2592000)
    * @param stakemax maximum amount of tokens to stake
    */
    function launchStaking(
        address token, 
        uint256 interest,
        uint256 timelock,
        uint256 staketime,
        uint256 stakemax
        ) external {
        require(staketime >= 2592000 && timelock <= 31536000, "stakeTime not in 1m - 1y range");
        require(timelock <= staketime, "timelock more than stakeTime");
        require(interest >= 50000 && interest <= 3000000, "interest not in 0.05 - 3% range");

        StakeTokenInfo storage tInfo = tokenToInfo[token];
        tInfo.interest = interest;
        tInfo.maxAmount = stakemax;
        tInfo.startTime = block.timestamp;
        tInfo.stakeTime = staketime;
        tInfo.lockTime = timelock;
        tInfo.active = true;
    }

    function stake(address user, address token, uint256 amount) external onlyRole(HUB) {
        StakeTokenInfo storage tInfo = tokenToInfo[token];
        StakeInfo storage st = userToInfo[msg.sender][token];

        require(amount > tInfo.minAmount, "< minAmount");
        require(block.timestamp < tInfo.startTime + tInfo.stakeTime, "Staking period ended");

        tInfo.totalLocked += amount;
        st.amount += amount;
        st.timeStaked = block.timestamp;
        st.timeLock = tInfo.lockTime;
    }

    function withdraw(address user, address token) public onlyRole(HUB) returns(uint256) {
        StakeInfo storage s = userToInfo[user][token];
        StakeTokenInfo storage tInfo = tokenToInfo[token];

        require(s.amount > 0, "Cannot withdraw 0");
        require(block.timestamp > s.timeStaked + s.timeLock, "Stake is locked");

        uint256 reward = updateReward(user, token);
        uint256 amount = s.amount + reward;
        tInfo.totalLocked -= s.amount;
        s.amount = 0;
        s.claimed = amount;
        
        return amount;
    }

    function updateReward(address user, address token) internal returns(uint256) {
        StakeInfo storage stake = userToInfo[user][token];
        StakeTokenInfo memory tInfo = tokenToInfo[token];
        require(block.timestamp > stake.timeStaked + stake.timeLock, "Stake is locked");
        uint256 daysStaked = (block.timestamp - stake.timeStaked) / 86400;
        uint256 reward = stake.amount * tInfo.interest / daysStaked;
        return reward;
    }

    function finaliseStaking(address token) external {
        StakeTokenInfo storage tInfo = tokenToInfo[token];
        require(block.timestamp > tInfo.startTime + tInfo.stakeTime, "Staking period not ended");
        require(tInfo.active, "Staking already finalised");
        tInfo.active = false;
    }

    function isAirDropEligible(address user, address token) public view returns(bool) {
        StakeInfo storage s = userToInfo[user][token];
        StakeTokenInfo memory tInfo = tokenToInfo[token];
        if(!s.airDropEligible && s.amount >= tInfo.airDropAmount && s.timeStaked >= tInfo.airDropTime) {
            return true;
        } else {
            return s.airDropEligible;
        }
    }

    function stakingLive(address token) public view returns(bool) {
        if(tokenToInfo[token].startTime + tokenToInfo[token].stakeTime > block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function coverAirdrop(address token) external view returns(uint256) {
        StakeTokenInfo storage tInfo = tokenToInfo[token];
        uint256 cover = tInfo.totalLocked / tInfo.airDropAmount;
        return cover;
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