// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityPool {
    // Define the two tokens in the liquidity pool
    IERC20 public tokenA;
    IERC20 public tokenB;

    // Store the balances of each token in the pool
    uint256 public tokenABalance;
    uint256 public tokenBBalance;

    constructor(IERC20 _tokenA, IERC20 _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // Add liquidity to the pool by depositing equal amounts of each token
    function addLiquidity(uint256 amount) external {
        // Transfer the specified amount of each token from the sender to the contract
        require(tokenA.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        require(tokenB.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Update the balances of each token in the pool
        tokenABalance += amount;
        tokenBBalance += amount;
    }

    // Remove liquidity from the pool and receive proportional amounts of each token
    function removeLiquidity(uint256 amount) external {
        // Calculate the proportional amounts of each token to return to the sender
        uint256 tokenAAmount = amount * tokenABalance / (tokenABalance + tokenBBalance);
        uint256 tokenBAmount = amount * tokenBBalance / (tokenABalance + tokenBBalance);

        // Transfer the proportional amounts of each token from the contract to the sender
        require(tokenA.transfer(msg.sender, tokenAAmount), "Transfer failed");
        require(tokenB.transfer(msg.sender, tokenBAmount), "Transfer failed");

        // Update the balances of each token in the pool
        tokenABalance -= tokenAAmount;
        tokenBBalance -= tokenBAmount;
    }

    // Swap tokenA for tokenB
    function swapTokenAForTokenB(uint256 amount) external {
        // Calculate the amount of tokenB to receive based on the current exchange rate
        uint256 amountOut = amount * tokenBBalance / tokenABalance;

        // Transfer the specified amount of tokenA from the sender to the contract
        require(tokenA.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Transfer the calculated amount of tokenB from the contract to the sender
        require(tokenB.transfer(msg.sender, amountOut), "Transfer failed");

        // Update the balances of each token in the pool
        tokenABalance += amount;
        tokenBBalance -= amountOut;
    }

    // Swap tokenB for tokenA
    function swapTokenBForTokenA(uint256 amount) external {
        // Calculate the amount of tokenA to receive based on the current exchange rate
        uint256 amountOut = amount * tokenABalance / tokenBBalance;

        // Transfer the specified amount of tokenB from the sender to the contract
        require(tokenB.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Transfer the calculated amount of tokenA from the contract to the sender
        require(tokenA.transfer(msg.sender, amountOut), "Transfer failed");

        // Update the balances of each token in the pool
        tokenBBalance += amount;
        tokenABalance -= amountOut;
    }

    // Get the current exchange rate between tokenA and tokenB
    function getExchangeRate() external view returns (uint256) {
        return tokenBBalance * 1e18 / tokenABalance;
    }
}
