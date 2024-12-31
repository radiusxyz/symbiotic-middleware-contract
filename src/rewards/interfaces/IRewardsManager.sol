// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IRewardsManager {
    // Structs
    struct RewardPoolConfig {
        address rewardToken;
        uint256 amountPerInterval;
        uint256 distributionInterval;
        uint256 lastDistribution;
        uint256 operatorRewardRatio;
        uint256 stakerRewardRatio;
        bool isActive;
    }

    // Distribution Info struct
    struct DistributionInfo {
        bool isEligible;
        uint256 availableAmount;
        address rewardToken;
        uint256 timeUntilNextDistribution;
        uint256 operatorAmount;
        uint256 stakerAmount;
    }

    // Events
     event RewardPoolConfigAdded(
        string  clusterId,
        string  rollupId,
        address rewardToken
    );

    event RewardPoolConfigUpdated(
        string  clusterId,
        string  rollupId,
        uint256 newDistributionInterval,
        uint256 newAmountPerInterval,
        uint256 newOperatorRewardRatio,
        uint256 newStakerRewardRatio
    );

    event RewardsDeposited(
        string  clusterId,
        string  rollupId,
        address depositor,
        uint256 amount,
        uint256 totalPoolBalance
    );

    event RewardDistributionApproved(
        string  clusterId,
        string  rollupId,
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
    error ConfigNotActive();
    error TooEarlyForDistribution();
    error InsufficientBalance();
    error ZeroAddress();
    error InvalidMiddleware(address provided, address expected);
    error OverflowDetected();
    error InsufficientPoolBalance(uint256 current, uint256 required);
    error ExceedsWithdrawalLimit(uint256 amount, uint256 maxAllowed);
    error InvalidAmount(uint256 amount, uint256 balance);
    error NotAuthorizedDepositor();
    error AmountTooLow(uint256 amount, uint256 minAmount);
    error AmountTooHigh(uint256 amount, uint256 maxAmount);
    error IntervalTooShort(uint256 interval, uint256 minInterval);
    error IntervalTooLong(uint256 interval, uint256 maxInterval);
    error InvalidRatio(uint256 ratio, uint256 minRatio, uint256 maxRatio);
    error RatioSumInvalid(uint256 sum);
    error ConfigExists();
    error InvalidERC20Token(address token);
    error StringInvalid(uint256 length, uint256 maxLength);
    error InvalidNewAmountPerInterval();
    error InvalidNewDistributionInterval(uint256 interval, uint256 minInterval);
    error InvalidNewRewardRatios(uint256 operatorRatio, uint256 stakerRatio);
    error DepositorAlreadyWhitelisted(address depositor);
    error DepositorNotWhitelisted(address depositor);
    error TooManyDepositors(uint256 current, uint256 max);
    error CannotRemoveLastDepositor();
    error InvalidNetworkMiddleware(address middleware);


    // Core Functions
    function approveRewardDistribution(
        address network,
        string calldata clusterId,
        string calldata rollupId
    ) external returns (uint256);

    function getDistributionInfo(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (
        bool isEligible,
        uint256 availableAmount,
        address rewardToken,
        uint256 timeUntilNextDistribution,
        uint256 operatorAmount,
        uint256 stakerAmount
    );

    // Pool Management Functions
    function addRewardPoolConfig(
        string calldata clusterId,
        string calldata rollupId,
        address rewardToken,
        uint256 amountPerInterval,
        uint256 distributionInterval,
        uint256 operatorRewardRatio,
        uint256 stakerRewardRatio
    ) external;

    function updateRewardPoolConfig(
        string calldata clusterId,
        string calldata rollupId,
        uint256 newDistributionInterval,
        uint256 newAmountPerInterval,
        uint256 newOperatorRewardRatio,
        uint256 newStakerRewardRatio
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