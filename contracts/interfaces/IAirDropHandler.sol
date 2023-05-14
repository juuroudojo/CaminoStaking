// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IAirDropHandler {
    function launchAirdrop(address token, uint256 amount, uint256 _totalAmount, uint256 airdropPeriod, bytes memory merkleRoot, bool moneyback) external;
    function launchAirdropBatch(address[] calldata tokens, uint256[] calldata amounts) external;
    function claimAirdrop(address user, address token) external returns (uint256);
    function previewAirDrop(address token) external view returns(uint256 amount);
}