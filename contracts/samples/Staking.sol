// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Staking {
    // Define the token being staked
    IERC20 public token;

    // Store the total staked amount and the balance of each staker
    uint256 public totalStaked;
    mapping(address => uint256) public stakedBalances;

    // Store the start and end times for the staking period
    uint256 public startTime;
    uint256 public endTime;

    // Define the staking reward amount and the total reward allocated
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

    // Stake tokens to earn rewards
    function stakeTokens(uint256 amount) external {
        // Ensure that the staking period has started and is not yet over
        require(block.timestamp >= startTime, "Staking period not started");
        require(block.timestamp <= endTime, "Staking period ended");

        // Transfer the specified amount of tokens from the sender to the contract
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Update the staked balance for the sender and the total staked amount
        stakedBalances[msg.sender] += amount;
        totalStaked += amount;
    }

    // Withdraw staked tokens and earned rewards
    function withdrawTokens() external {
        // Calculate the amount of rewards earned by the sender
        uint256 rewardsEarned = calculateRewardsEarned(msg.sender);

        // Transfer the staked tokens and rewards earned to the sender
        require(token.transfer(msg.sender, stakedBalances[msg.sender]), "Transfer failed");
        require(token.transfer(msg.sender, rewardsEarned), "Transfer failed");

        // Update the staked balance for the sender and the total staked amount
        totalStaked -= stakedBalances[msg.sender];
        stakedBalances[msg.sender] = 0;
    }

    // Calculate the amount of rewards earned by a staker
    function calculateRewardsEarned(address staker) public view returns (uint256) {
        // Ensure that the staking period has ended
        require(block.timestamp >= endTime, "Staking period not yet ended");

        // Calculate the percentage of the total staked amount represented by the staker's balance
        uint256 stakePercentage = stakedBalances[staker] * 1e18 / totalStaked;

        // Calculate the amount of rewards earned by the staker based on their stake percentage
        uint256 rewardsEarned = stakePercentage * rewardAmount / 1e18;

        return rewardsEarned;
    }

    // Allocate additional rewards to the staking pool
    function allocateRewards(uint256 amount) external {
        // Transfer the specified amount of tokens from the sender to the contract
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Update the total reward amount and the total rewards allocated
        rewardAmount += amount;
        totalRewardsAllocated += amount;
    }

    // Get the current staking reward amount and the amount of rewards remaining
    function getStakingRewards() external view returns (uint256, uint256) {
    uint256 rewardsRemaining = rewardAmount - totalRewardsAllocated;
    return (rewardAmount, rewardsRemaining);
    }

}