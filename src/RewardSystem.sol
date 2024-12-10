// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-contracts/contracts/access/Ownable.sol";
import "./IRewardSystem.sol";
import "./liveness/interfaces/ILivenessRadius.sol";
import "./ValidationServiceManager.sol";

contract RewardSystem is IRewardSystem, Ownable {
    using SafeERC20 for IERC20;

    ValidationServiceManager public immutable validationManager;
    ILivenessRadius public immutable livenessRadius;
    
    mapping(bytes32 => RewardConfig) private rewardConfigs;        
    mapping(bytes32 => RewardSnapshot) private rewardSnapshots;    
    mapping(bytes32 => mapping(address => uint256)) private claimedRewards;
    mapping(bytes32 => uint256) public rewardPools;
    mapping(bytes32 => address[]) public whitelistedDepositorList;
    mapping(bytes32 => mapping(address => bool)) public isWhitelistedDepositor;

    uint256 private constant PRECISION = 1e18;
    uint256 private constant MIN_DISTRIBUTION_INTERVAL = 1 days;
    uint256 private constant MIN_INTERVALS_COVERAGE = 3;

    event WhitelistedDepositorAdded(string clusterId, string rollupId, address depositor);
    event WhitelistedDepositorRemoved(string clusterId, string rollupId, address depositor);
    event EmergencyWithdrawn(string clusterId, string rollupId, address depositor, uint256 amount);

    constructor(address _validationManager, address _livenessRadius) Ownable(msg.sender) {
        require(_validationManager != address(0), "Invalid validation manager");
        require(_livenessRadius != address(0), "Invalid liveness radius");
        validationManager = ValidationServiceManager(_validationManager);
        livenessRadius = ILivenessRadius(_livenessRadius);
    }

    function _getRewardKey(string calldata clusterId, string calldata rollupId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(clusterId, rollupId));
    }

    function addWhitelistedDepositor(
        string calldata clusterId,
        string calldata rollupId,
        address newDepositor
    ) external {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        require(isWhitelistedDepositor[rewardKey][msg.sender], "Not whitelisted depositor");
        require(!isWhitelistedDepositor[rewardKey][newDepositor], "Already whitelisted");
        require(newDepositor != address(0), "Invalid depositor address");

        whitelistedDepositorList[rewardKey].push(newDepositor);
        isWhitelistedDepositor[rewardKey][newDepositor] = true;

        emit WhitelistedDepositorAdded(clusterId, rollupId, newDepositor);
    }

    function removeWhitelistedDepositor(
        string calldata clusterId,
        string calldata rollupId,
        address depositorToRemove
    ) external {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        require(isWhitelistedDepositor[rewardKey][msg.sender], "Not whitelisted depositor");
        require(isWhitelistedDepositor[rewardKey][depositorToRemove], "Not whitelisted");
        require(whitelistedDepositorList[rewardKey].length > 1, "Cannot remove last depositor");

        for (uint i = 0; i < whitelistedDepositorList[rewardKey].length; i++) {
            if (whitelistedDepositorList[rewardKey][i] == depositorToRemove) {
                whitelistedDepositorList[rewardKey][i] = whitelistedDepositorList[rewardKey][whitelistedDepositorList[rewardKey].length - 1];
                whitelistedDepositorList[rewardKey].pop();
                break;
            }
        }

        isWhitelistedDepositor[rewardKey][depositorToRemove] = false;
        emit WhitelistedDepositorRemoved(clusterId, rollupId, depositorToRemove);
    }

    function getWhitelistedDepositors(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (address[] memory) {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        return whitelistedDepositorList[rewardKey];
    }

    function addRewardConfig(
        string calldata clusterId,
        string calldata rollupId,
        address rewardToken,
        uint256 rewardAmount,
        uint256 minStakeRequired,
        uint256 distributionInterval
    ) external override onlyOwner {
        require(rewardToken != address(0), "Invalid reward token");
        require(distributionInterval >= MIN_DISTRIBUTION_INTERVAL, "Interval too short");
        require(livenessRadius.isAddedRollup(clusterId, rollupId), "Rollup not registered");
        require(validationManager.isRegisteredToken(rewardToken), "Token not registered in ValidationManager");

        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        require(!rewardConfigs[rewardKey].isActive, "Reward config exists");

        rewardConfigs[rewardKey] = RewardConfig({
            rewardToken: rewardToken,
            minStakeRequired: minStakeRequired,
            lockupPeriod: 0,
            lastDistribution: block.timestamp,
            distributionInterval: distributionInterval,
            rewardAmount: rewardAmount,
            isActive: true
        });

        whitelistedDepositorList[rewardKey].push(msg.sender);
        isWhitelistedDepositor[rewardKey][msg.sender] = true;

        emit RewardConfigAdded(clusterId, rollupId, rewardToken);
    }

    function distributeRewards(
        string calldata clusterId,
        string calldata rollupId
    ) external override {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        RewardConfig storage config = rewardConfigs[rewardKey];
        require(config.isActive, "No active reward config");
        require(
            block.timestamp >= config.lastDistribution + config.distributionInterval,
            "Too early for distribution"
        );

        uint48 currentEpoch = validationManager.getCurrentEpoch();
        uint256 totalStake = validationManager.getTotalStake(currentEpoch);
        require(totalStake > 0, "No stake to distribute to");

        uint256 poolBalance = rewardPools[rewardKey];
        require(poolBalance > 0, "No rewards to distribute");

        uint256 distributionAmount = config.rewardAmount;
        require(distributionAmount <= poolBalance, "Insufficient pool balance");

        uint256 rewardPerToken = (distributionAmount * PRECISION) / totalStake;

        RewardSnapshot storage currentSnapshot = rewardSnapshots[rewardKey];
        currentSnapshot.totalStake = totalStake;
        currentSnapshot.rewardPerToken = rewardPerToken;
        currentSnapshot.timestamp = block.timestamp;

        config.lastDistribution = block.timestamp;

        emit RewardDistributed(clusterId, rollupId, address(0), distributionAmount);
    }

    function getClaimableRewards(
        address operator,
        string calldata clusterId,
        string calldata rollupId
    ) public view override returns (uint256) {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        RewardConfig storage config = rewardConfigs[rewardKey];
        if (!config.isActive) return 0;

        RewardSnapshot storage snapshot = rewardSnapshots[rewardKey];
        if (snapshot.timestamp == 0) return 0;

        uint48 epoch = validationManager.getEpochAtTs(uint48(snapshot.timestamp));
        uint256 operatorStake = validationManager.getOperatorStake(operator, epoch);
        if (operatorStake == 0) return 0;

        uint256 rewards = (operatorStake * snapshot.rewardPerToken) / PRECISION;
        uint256 claimable = rewards - claimedRewards[rewardKey][operator];
        
        return claimable;
    }

    function claimRewards(
        string calldata clusterId,
        string calldata rollupId
    ) external override {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        RewardConfig storage config = rewardConfigs[rewardKey];
        require(config.isActive, "No active reward config");

        uint256 claimable = getClaimableRewards(msg.sender, clusterId, rollupId);
        require(claimable > 0, "No rewards to claim");

        claimedRewards[rewardKey][msg.sender] += claimable;

        rewardPools[rewardKey] -= claimable;
        IERC20(config.rewardToken).safeTransfer(msg.sender, claimable);

        emit RewardsClaimed(msg.sender, config.rewardToken, claimable);
    }

    function depositRewards(
        string calldata clusterId,
        string calldata rollupId,
        uint256 amount
    ) external {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        RewardConfig storage config = rewardConfigs[rewardKey];
        
        require(isWhitelistedDepositor[rewardKey][msg.sender], "Not authorized depositor");

        if (!config.isActive) {
            emit DepositRejected(clusterId, rollupId, msg.sender, amount, "Reward config not active");
            return;
        }

        uint256 requiredAmount = config.rewardAmount * MIN_INTERVALS_COVERAGE;
        require(
            rewardPools[rewardKey] + amount >= requiredAmount,
            "Insufficient deposit for minimum intervals"
        );

        IERC20 token = IERC20(config.rewardToken);
        require(token.balanceOf(msg.sender) >= amount, "Insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");

        token.safeTransferFrom(msg.sender, address(this), amount);
        rewardPools[rewardKey] += amount;

        emit RewardsDeposited(clusterId, rollupId, msg.sender, amount, rewardPools[rewardKey]);
    }

    function updateRewardConfig(
        string calldata clusterId,
        string calldata rollupId,
        uint256 newRewardAmount,
        uint256 newMinStake
    ) external override onlyOwner {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        require(rewardConfigs[rewardKey].isActive, "Config not found");

        RewardConfig storage config = rewardConfigs[rewardKey];
        config.minStakeRequired = newMinStake;
        config.rewardAmount = newRewardAmount;

        emit RewardConfigUpdated(clusterId, rollupId, config.rewardToken);
    }

    function getRewardConfig(
        string calldata clusterId,
        string calldata rollupId
    ) external view override returns (RewardConfig memory) {
        return rewardConfigs[_getRewardKey(clusterId, rollupId)];
    }

    function getLastRewardSnapshot(
        string calldata clusterId,
        string calldata rollupId
    ) external view override returns (RewardSnapshot memory) {
        return rewardSnapshots[_getRewardKey(clusterId, rollupId)];
    }

    function getRewardConfigDebugInfo(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (
        bool isActive,
        address rewardToken,
        uint256 lastDistribution,
        uint256 distributionInterval,
        uint256 totalStake,
        uint256 rewardPool
    ) {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        RewardConfig storage config = rewardConfigs[rewardKey];
        RewardSnapshot storage snapshot = rewardSnapshots[rewardKey];
        
        return (
            config.isActive,
            config.rewardToken,
            config.lastDistribution,
            config.distributionInterval,
            snapshot.totalStake,
            rewardPools[rewardKey]
        );
    }

    function getRewardPoolBalance(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (uint256) {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        return rewardPools[rewardKey];
    }

    function emergencyWithdrawRollup(
        string calldata clusterId,
        string calldata rollupId,
        uint256 amount
    ) external {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        require(isWhitelistedDepositor[rewardKey][msg.sender], "Not authorized");
        
        RewardConfig storage config = rewardConfigs[rewardKey];
        require(config.isActive, "Reward config not active");
        require(amount <= rewardPools[rewardKey], "Insufficient pool balance");

        uint256 remainingBalance = rewardPools[rewardKey] - amount;
        uint256 requiredAmount = config.rewardAmount * MIN_INTERVALS_COVERAGE;
        require(remainingBalance >= requiredAmount, "Must maintain minimum intervals coverage");

        rewardPools[rewardKey] -= amount;
        IERC20(config.rewardToken).safeTransfer(msg.sender, amount);

        emit EmergencyWithdrawn(clusterId, rollupId, msg.sender, amount);
    }
}