// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IRewardSystem {
     struct RewardConfig {
        address rewardToken;
        uint256 minStakeRequired;
        uint256 lockupPeriod;
        uint256 lastDistribution;
        uint256 distributionInterval;
        uint256 rewardAmount;
        bool isActive;
    }

    struct RewardSnapshot {
        uint256 totalStake;      
        uint256 rewardPerToken;  
        uint256 timestamp;       
    }

    event RewardConfigAdded(string indexed clusterId, string indexed rollupId, address rewardToken);
    event RewardDistributed(string indexed clusterId, string indexed rollupId, address indexed operator, uint256 amount);
    event RewardsClaimed(address indexed operator, address indexed token, uint256 amount);
    event RewardConfigUpdated(string indexed clusterId, string indexed rollupId, address rewardToken);

     event RewardsDeposited(
        string indexed clusterId,
        string indexed rollupId,
        address depositor,
        uint256 amount,
        uint256 totalPoolBalance
    );

    event DepositRejected(
        string indexed clusterId,
        string indexed rollupId,
        address depositor,
        uint256 amount,
        string reason
    );

    function addRewardConfig(
        string calldata clusterId,
        string calldata rollupId,
        address rewardToken,
        uint256 rewardRate,
        uint256 minStakeRequired,
        uint256 distributionInterval
    ) external;

    function updateRewardConfig(
        string calldata clusterId,
        string calldata rollupId,
        uint256 newRewardRate,
        uint256 newMinStake
    ) external;

    function distributeRewards(string calldata clusterId, string calldata rollupId) external;
    function claimRewards(string calldata clusterId, string calldata rollupId) external;
    function getClaimableRewards(
        address operator,
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (uint256);

    function getRewardConfig(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (RewardConfig memory);
    
    function getLastRewardSnapshot(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (RewardSnapshot memory);
}