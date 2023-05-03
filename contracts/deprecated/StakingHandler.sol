// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.9;

// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// import "hardhat/console.sol";

// contract StakingHandler is 
//     Initializable,
//     PausableUpgradeable,
//     AccessControlUpgradeable,
//     UUPSUpgradeable 
// {
//     using AddressUpgradeable for address;
//     using SafeERC20Upgradeable for IERC20Upgradeable;
//     using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

//     bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
//     bytes32 public constant HUB = keccak256("HUB");

//     //flag for upgrades availability
//     bool public upgradeStatus;

//     address public hub;
//     uint256 public maxRate;

//     mapping(address => uint256) public userRewardPerTokenPaid;
//     mapping(address => uint256) public rewards;
//     mapping(address => uint256) private _balances;

//     event StakingInitialized (
//         address token,
//         uint256 interest,
//         uint256 timelock,
//         uint256 stakeTime,
//         uint256 stakeMax,
//         uint256 totalLocked
//     );

//     address[] public stakingTokens;

//     struct StakeTokenInfo {
//         uint256 interest;
//         uint256 maxAmount;
//         uint256 startTime;
//         uint256 stakeTime;
//         uint256 lockTime;
//         bool active;
//     }

//     struct StakeInfo {
//         address token;
//         uint256 amount;
//         uint256 timeStaked;
//         uint256 timeLock;
//     }

//     mapping(address => StakeTokenInfo) public tokenToInfo;
//     mapping(address => mapping(address => StakeInfo)) public userToInfo;

//     modifier updateReward(address user, address token) {
//         _updateReward(user, token);
//         _;
//     }

//     function initialize(address _hub) public initializer {
//         __Pausable_init();
//         __AccessControl_init();
//         __UUPSUpgradeable_init();

//         _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
//         _setupRole(UPGRADER_ROLE, msg.sender);

//         hub = _hub;
//     }

//     /**
//     * @dev Initialize the staking campaign for a token
//     * @param token address of the token to stake
//     * @param interest interest rate for the token with 2 decimals (e.g. 10% = 1000)
//     * @param timelock timelock period for the token in seconds (e.g. 1 month = 2592000)
//     * @param staketime time to stake the token in seconds (e.g. 1 month = 2592000)
//     * @param stakemax maximum amount of tokens to stake
//     */
//     function launchStaking(
//         address token, 
//         uint256 interest,
//         uint256 timelock,
//         uint256 staketime,
//         uint256 stakemax
//         ) external {
//         require(staketime >= 2592000 && timelock <= 31536000, "stakeTime not in 1m - 1y range");
//         require(timelock <= staketime, "timelock more than stakeTime");
//         require(interest >= 50000 && interest <= 3000000, "interest not in 0.05 - 3% range");

//         StakeTokenInfo storage tInfo = tokenToInfo[token];
//         tInfo.interest = interest;
//         tInfo.maxAmount = stakemax;
//         tInfo.startTime = block.timestamp;
//         tInfo.stakeTime = staketime;
//         tInfo.lockTime = timelock;
//         tInfo.active = true;
//     }

//     /**
//     * @dev Stake tokens
//     * @param user address of the user to stake
//     * @param token address of the token to stake
//     * @param amount amount of tokens to stake
//     */
//     function stake (address user, address token, uint256 amount) external onlyRole(HUB) {
//         StakeInfo storage sInfo = userToInfo[user][token];
//         StakeTokenInfo storage tInfo = tokenToInfo[token];

//         require(tInfo.maxAmount > 0, "StakingHandler: Staking not initialized");

//         sInfo.amount = amount;
//         sInfo.timeLock = block.timestamp + tInfo.stakeTime;
//     }

//     /**
//     * @notice Unstakes the full amount and claims the reward
//     * @dev Unstake tokens
//     * @param token address of the token to unstake
//     */
//     function unstake (address token) external {
//         StakeInfo storage uInfo = userToInfo[msg.sender][token];

//         require(uInfo.amount > 0, "StakingHandler: No stake found");
//         require(uInfo.timeLock < block.timestamp, "StakingHandler: Stake locked");

//         uint256 reward = _updateReward(msg.sender, token);
//         IERC20(token).transferFrom(hub, msg.sender, reward);
//         uInfo.amount = 0;
//     }

//     function claimReward(address token) external updateReward(msg.sender, token){
//         StakeInfo storage uInfo = userToInfo[msg.sender][token];

//         require(uInfo.amount > 0, "StakingHandler: No stake found");
//         require(uInfo.timeLock < block.timestamp, "StakingHandler: Stake locked");

//         uint256 reward = _updateReward(msg.sender, token);
//         IERC20(token).transferFrom(hub, msg.sender, reward);
//     }

//     function calcCurrLockMultiplier(address account, uint256 stake_idx) public view returns (uint256 midpoint_lock_multiplier) {
//         // Get the stake
//         LockedStake memory thisStake = lockedStakes[account][stake_idx];

//         // Handles corner case where user never claims for a new stake
//         // Don't want the multiplier going above the max
//         uint256 accrue_start_time;
//         if (lastRewardClaimTime[account] < thisStake.start_timestamp) {
//             accrue_start_time = thisStake.start_timestamp;
//         }
//         else {
//             accrue_start_time = lastRewardClaimTime[account];
//         }
        
//         // If the lock is expired
//         if (thisStake.ending_timestamp <= block.timestamp) {
//             // If the lock expired in the time since the last claim, the weight needs to be proportionately averaged this time
//             if (lastRewardClaimTime[account] < thisStake.ending_timestamp){
//                 uint256 time_before_expiry = thisStake.ending_timestamp - accrue_start_time;
//                 uint256 time_after_expiry = block.timestamp - thisStake.ending_timestamp;

//                 // Average the pre-expiry lock multiplier
//                 uint256 pre_expiry_avg_multiplier = lockMultiplier(time_before_expiry / 2);

//                 // Get the weighted-average lock_multiplier
//                 // uint256 numerator = (pre_expiry_avg_multiplier * time_before_expiry) + (MULTIPLIER_PRECISION * time_after_expiry);
//                 uint256 numerator = (pre_expiry_avg_multiplier * time_before_expiry) + (0 * time_after_expiry);
//                 midpoint_lock_multiplier = numerator / (time_before_expiry + time_after_expiry);
//             }
//             else {
//                 // Otherwise, it needs to just be 1x
//                 // midpoint_lock_multiplier = MULTIPLIER_PRECISION;

//                 // Otherwise, it needs to just be 0x
//                 midpoint_lock_multiplier = 0;
//             }
//         }
//         // If the lock is not expired
//         else {
//             // Decay the lock multiplier based on the time left
//             uint256 avg_time_left;
//             {
//                 uint256 time_left_p1 = thisStake.ending_timestamp - accrue_start_time;
//                 uint256 time_left_p2 = thisStake.ending_timestamp - block.timestamp;
//                 avg_time_left = (time_left_p1 + time_left_p2) / 2;
//             }
//             midpoint_lock_multiplier = lockMultiplier(avg_time_left);
//         }

//         // Sanity check: make sure it never goes above the initial multiplier
//         if (midpoint_lock_multiplier > thisStake.lock_multiplier) midpoint_lock_multiplier = thisStake.lock_multiplier;
//     }

//     // Calculate the combined weight for an account
//     function calcCurCombinedWeight(address account) public override view
//         returns (
//             uint256 old_combined_weight,
//             uint256 new_vefxs_multiplier,
//             uint256 new_combined_weight
//         )
//     {
//         // Get the old combined weight
//         old_combined_weight = _combined_weights[account];

//         // Get the veFXS multipliers
//         // For the calculations, use the midpoint (analogous to midpoint Riemann sum)
//         new_vefxs_multiplier = veFXSMultiplier(account);

//         uint256 midpoint_vefxs_multiplier;
//         if (
//             (_locked_liquidity[account] == 0 && _combined_weights[account] == 0) || 
//             (new_vefxs_multiplier > _vefxsMultiplierStored[account])
//         ) {
//             // This is only called for the first stake to make sure the veFXS multiplier is not cut in half
//             // Also used if the user increased their position
//             midpoint_vefxs_multiplier = new_vefxs_multiplier;
//         }
//         else {
//             // Handles natural decay with a non-increased veFXS position
//             midpoint_vefxs_multiplier = (new_vefxs_multiplier + _vefxsMultiplierStored[account]) / 2;
//         }

//         // Loop through the locked stakes, first by getting the liquidity * lock_multiplier portion
//         new_combined_weight = 0;
//         for (uint256 i = 0; i < lockedStakes[account].length; i++) {
//             LockedStake memory thisStake = lockedStakes[account][i];

//             // Calculate the midpoint lock multiplier
//             uint256 midpoint_lock_multiplier = calcCurrLockMultiplier(account, i);

//             // Calculate the combined boost
//             uint256 liquidity = thisStake.liquidity;
//             uint256 combined_boosted_amount = liquidity + ((liquidity * (midpoint_lock_multiplier + midpoint_vefxs_multiplier)) / MULTIPLIER_PRECISION);
//             new_combined_weight += combined_boosted_amount;
//         }
//     }

//     function exit() external {
//         withdraw(_balances[msg.sender]);
//         getReward();
//     }

//     function stakingLive (address token) external view returns (bool) {
//         StakeTokenInfo storage tInfo = tokenToInfo[token];
//         return tInfo.stakeTime > 0;
//     }

//     function getReward() public nonReentrant updateReward(msg.sender) {
//         uint256 reward = rewards[msg.sender];
//         if (reward > 0) {
//             rewards[msg.sender] = 0;
//             rewardsToken.safeTransfer(msg.sender, reward);
//             emit RewardPaid(msg.sender, reward);
//         }
//     }

//     function _updateReward(address user, address token) public view returns (uint256) {
//         StakeInfo storage uInfo = userToInfo[user][token];
//         StakeTokenInfo storage tInfo = tokenToInfo[token];

//         if (uInfo.amount == 0) {
//             return 0;
//         }

//         uint256 daysStaked = (block.timestamp - uInfo.timeStaked) / 86400;
//         uint256 reward = uInfo.amount + (uInfo.amount * tInfo.interest * daysStaked / 10000 / 365);
//         return reward;
//     }

//     function updateRewardAndBalance(address account, bool sync_too) public {
//         // Need to retro-adjust some things if the period hasn't been renewed, then start a new one
//         if (sync_too){
//             sync();
//         }
        
//         if (account != address(0)) {
//             // To keep the math correct, the user's combined weight must be recomputed to account for their
//             // ever-changing veFXS balance.
//             (   
//                 uint256 old_combined_weight,
//                 uint256 new_vefxs_multiplier,
//                 uint256 new_combined_weight
//             ) = calcCurCombinedWeight(account);

//             // Calculate the earnings first
//             _syncEarned(account);

//             // Update the user's stored veFXS multipliers
//             _vefxsMultiplierStored[account] = new_vefxs_multiplier;

//             // Update the user's and the global combined weights
//             if (new_combined_weight >= old_combined_weight) {
//                 uint256 weight_diff = new_combined_weight - old_combined_weight;
//                 _total_combined_weight = _total_combined_weight + weight_diff;
//                 _combined_weights[account] = old_combined_weight + weight_diff;
//             } else {
//                 uint256 weight_diff = old_combined_weight - new_combined_weight;
//                 _total_combined_weight = _total_combined_weight - weight_diff;
//                 _combined_weights[account] = old_combined_weight - weight_diff;
//             }

//         }
//     }

//     function _syncEarned(address account) internal {
//         if (account != address(0)) {
//             // Calculate the earnings
//             uint256[] memory earned_arr = earned(account);

//             // Update the rewards array
//             for (uint256 i = 0; i < earned_arr.length; i++){ 
//                 rewards[account][i] = earned_arr[i];
//             }

//             // Update the rewards paid array
//             for (uint256 i = 0; i < earned_arr.length; i++){ 
//                 userRewardsPerTokenPaid[account][i] = rewardsPerTokenStored[i];
//             }
//         }
//     }

//     function changeUpgradeStatus(
//         bool _status
//     ) external onlyRole(DEFAULT_ADMIN_ROLE) {
//         upgradeStatus = _status;
//     }

//     function _authorizeUpgrade(
//         address
//     ) internal override onlyRole(UPGRADER_ROLE) {
//         require(upgradeStatus, "StakingHandler: Upgrade not allowed");
//         upgradeStatus = false;
//     }
// }