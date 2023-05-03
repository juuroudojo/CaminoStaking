// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityPool {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public tokenABalance;
    uint256 public tokenBBalance;

    constructor(IERC20 _tokenA, IERC20 _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function addLiquidity(uint256 amount) external {
        require(tokenA.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        require(tokenB.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        tokenABalance += amount;
        tokenBBalance += amount;
    }

    function removeLiquidity(uint256 amount) external {
        uint256 tokenAAmount = amount * tokenABalance / (tokenABalance + tokenBBalance);
        uint256 tokenBAmount = amount * tokenBBalance / (tokenABalance + tokenBBalance);

        require(tokenA.transfer(msg.sender, tokenAAmount), "Transfer failed");
        require(tokenB.transfer(msg.sender, tokenBAmount), "Transfer failed");

        tokenABalance -= tokenAAmount;
        tokenBBalance -= tokenBAmount;
    }

    function swapTokenAForTokenB(uint256 amount) external {
        uint256 amountOut = amount * tokenBBalance / tokenABalance;

        require(tokenA.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        require(tokenB.transfer(msg.sender, amountOut), "Transfer failed");

        tokenABalance += amount;
        tokenBBalance -= amountOut;
    }

    function swapTokenBForTokenA(uint256 amount) external {
        uint256 amountOut = amount * tokenABalance / tokenBBalance;

        require(tokenB.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        require(tokenA.transfer(msg.sender, amountOut), "Transfer failed");

        tokenBBalance += amount;
        tokenABalance -= amountOut;
    }

    function getExchangeRate() external view returns (uint256) {
        return tokenBBalance * 1e18 / tokenABalance;
    }
}
