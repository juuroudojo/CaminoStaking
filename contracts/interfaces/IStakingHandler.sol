// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IStakingHandler {
    function initialize(address _hub) external;
    function launchStaking(
        address token, 
        uint256 interest,
        uint256 timelock,
        uint256 staketime,
        uint256 stakemax
    ) external;
    function stake(address user, address token, uint256 amount) external;
    function withdraw(address user, address token) external returns (uint256);
    function exit(address user, address token) external;
    function claimReward(address user, address token) external returns (uint256);
    function stakingLive(address token) external view returns (bool);
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
    function coverAirdrop(address token) external view returns (uint256);
    function recoverETH() external;
    function isAirDropEligible(address user, address token) external view returns (bool);
    function setHub(address _hub) external;
    function setInterest(address token, uint256 newInterest) external;
    function finaliseStaking(address token) external;
    function pause() external;
    function unpause() external;
    function setUpgradeStatus(bool _status) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
}
