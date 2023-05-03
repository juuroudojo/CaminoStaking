// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Staking {
    IERC20 public token;

    uint256 public totalStaked;
    mapping(address => uint256) public stakedBalances;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public rewardAmount;
    uint256 public totalRewardsAllocated;

    constructor(
        IERC20 _token,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rewardAmount
    ) {
        token = _token;
        startTime = _startTime;
        endTime = _endTime;
        rewardAmount = _rewardAmount;
    }

    function stakeTokens(uint256 amount) external {
        require(block.timestamp >= startTime, "Staking period not started");
        require(block.timestamp <= endTime, "Staking period ended");

        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        stakedBalances[msg.sender] += amount;
        totalStaked += amount;
    }

    function withdrawTokens() external {
        uint256 rewardsEarned = calculateRewardsEarned(msg.sender);

        require(token.transfer(msg.sender, stakedBalances[msg.sender]), "Transfer failed");
        require(token.transfer(msg.sender, rewardsEarned), "Transfer failed");

        totalStaked -= stakedBalances[msg.sender];
        stakedBalances[msg.sender] = 0;
    }

    function calculateRewardsEarned(address staker) public view returns (uint256) {
        require(block.timestamp >= endTime, "Staking period not yet ended");

        uint256 stakePercentage = stakedBalances[staker] * 1e18 / totalStaked;
        uint256 rewardsEarned = stakePercentage * rewardAmount / 1e18;

        return rewardsEarned;
    }

    function allocateRewards(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        rewardAmount += amount;
        totalRewardsAllocated += amount;
    }

    function getStakingRewards() external view returns (uint256, uint256) {
    uint256 rewardsRemaining = rewardAmount - totalRewardsAllocated;
    return (rewardAmount, rewardsRemaining);
    }

}