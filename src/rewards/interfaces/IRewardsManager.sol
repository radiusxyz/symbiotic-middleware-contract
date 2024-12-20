// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IRewardsManager {
    // Structs
    struct RewardPoolConfig {
        address rewardToken;
        uint256 minPoolBalance;
        uint256 distributionInterval;
        uint256 lastDistribution;
        bool isActive;
    }

    // Distribution Info struct
    struct DistributionInfo {
        bool isEligible;
        uint256 availableAmount;
        address rewardToken;
        uint256 timeUntilNextDistribution;
    }

    // Events
    event RewardPoolConfigAdded(
        string indexed clusterId,
        string indexed rollupId,
        address rewardToken
    );

    event RewardPoolConfigUpdated(
        string indexed clusterId,
        string indexed rollupId,
        uint256 newDistributionInterval,
        uint256 newMinPoolBalance
    );

    event RewardsDeposited(
        string indexed clusterId,
        string indexed rollupId,
        address depositor,
        uint256 amount,
        uint256 totalPoolBalance
    );

    event RewardDistributionApproved(
        string indexed clusterId,
        string indexed rollupId,
        uint256 amount,
        uint256 timestamp
    );

    event WhitelistedDepositorAdded(
        string clusterId,
        string rollupId,
        address depositor
    );

    event WhitelistedDepositorRemoved(
        string clusterId,
        string rollupId,
        address depositor
    );

    event EmergencyWithdrawn(
        string clusterId,
        string rollupId,
        address depositor,
        uint256 amount
    );

    // Errors
    error InvalidRewardToken();
    error InvalidDistributionInterval();
    error RollupNotRegistered();
    error TokenNotRegistered();
    error ConfigAlreadyExists();
    error ConfigNotFound();
    error NotAuthorizedDepositor();
    error ConfigNotActive();
    error InsufficientDeposit();
    error InsufficientBalance();
    error InsufficientAllowance();
    error TooEarlyForDistribution();
    error NoRewardsToDistribute();
    error InvalidMinimumBalance();
    error LastDepositorRemoval();
    error AlreadyWhitelisted();
    error NotWhitelisted();
    error ZeroAddress();
    error InsufficientPoolBalance();
    error InvalidApprovalAmount();

    // Core Functions
    function approveRewardDistribution(
        address network,
        string calldata clusterId,
        string calldata rollupId,
        uint256 amount
    ) external returns (uint256);

    function getDistributionInfo(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (
        bool isEligible,
        uint256 availableAmount,
        address rewardToken,
        uint256 timeUntilNextDistribution
    );

    // Pool Management Functions
    function addRewardPoolConfig(
        string calldata clusterId,
        string calldata rollupId,
        address rewardToken,
        uint256 minPoolBalance,
        uint256 distributionInterval
    ) external;

    function updateRewardPoolConfig(
        string calldata clusterId,
        string calldata rollupId,
        uint256 newDistributionInterval,
        uint256 newMinPoolBalance
    ) external;

    function depositRewards(
        string calldata clusterId,
        string calldata rollupId,
        uint256 amount
    ) external;

    function emergencyWithdraw(
        string calldata clusterId,
        string calldata rollupId,
        uint256 amount
    ) external;

    // Whitelist Management
    function addWhitelistedDepositor(
        string calldata clusterId,
        string calldata rollupId,
        address newDepositor
    ) external;

    function removeWhitelistedDepositor(
        string calldata clusterId,
        string calldata rollupId,
        address depositorToRemove
    ) external;

    // View Functions
    function getRewardPoolConfig(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (RewardPoolConfig memory);

    function getWhitelistedDepositors(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (address[] memory);

    function getRewardPoolBalance(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (uint256);

    function rewardPoolExists(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (bool);

    // Admin Functions
    function pause() external;
    function unpause() external;
}