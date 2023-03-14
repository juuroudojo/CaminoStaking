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

import "hardhat/console.sol";

contract SimpleAirdropHandler is 
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

    address public stakingHandler;

    // Event emitted when a user claims an airdrop
    event AirdropClaimed(address indexed user, address indexed token, uint256 amount);

    struct AirdropInfo {
        uint256 totalAmount;
        address collateralToken;
        uint256 amount;
        uint256 startTime;
        uint256 period;
        bytes32 merkleRoot;
        bool moneyback;
    }

    mapping(address => AirdropInfo) public airdropInfo;

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
    }

    /**
    * @dev Launch airdrop
    * @param token address of token
    * @param amount amount of token
    * @param airdropPeriod airdrop period
    * @param merkleRoot merkle root
    * @param moneyback moneyback flag
    */
    function launchAirdrop(address token, uint256 amount, uint256 airdropPeriod, bytes32 merkleRoot, bool moneyback) external {
        AirdropInfo storage info = airdropInfo[token];
        info.amount = amount;
        info.startTime = block.timestamp;
        info.period = airdropPeriod;
        info.collateralToken = token;
        info.merkleRoot = merkleRoot;
        info.moneyback = moneyback;
    }

    /**
    * @dev Claim airdrop
    * @param user user address
    * @param token token address
    */
    function claimAirdrop(address user, address token) external returns(uint256) {
        AirdropInfo storage info = airdropInfo[token];
        require(info.startTime + info.period > block.timestamp, "Airdrop is expired");
        // bytes memory zeroRoot = abi.encodePacked(keccak256("0"));
        // if (info.merkleRoot != zeroRoot) {
        //     // not implemented yet
        //     return 0;
        // } else {
            uint256 amount = info.amount;
            info.totalAmount -= amount;
            return amount;
        // }
    }

    function previewAirDrop(address token) public view returns(uint256) {
        AirdropInfo storage info = airdropInfo[token];
        return info.totalAmount;
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

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setStakingHandler(address _stakingHandler) public onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingHandler = _stakingHandler;
    }
}
