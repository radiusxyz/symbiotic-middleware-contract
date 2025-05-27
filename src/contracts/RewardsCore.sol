// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {console} from "forge-std/src/console.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Math} from "@openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IRewardsCore} from "src/interfaces/IRewardsCore.sol";
import {IValidationServiceManager} from "src/interfaces/IValidationServiceManager.sol";
import {INetworkMiddlewareService} from "@symbiotic-core/src/interfaces/service/INetworkMiddlewareService.sol";

/**
 * @title RewardsCore
 * @notice Manages reward pools and approvals for the ValidationServiceManager
 */
contract RewardsCore is IRewardsCore, Ownable, ReentrancyGuard, Pausable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    // Constants
    uint256 private constant MIN_DISTRIBUTION_INTERVAL = 10;
    uint256 private constant MAX_WHITELISTED_DEPOSITORS = 10;
    uint256 private constant POOL_MULTIPLIER = 5;
    uint256 private constant MAX_DISTRIBUTION_INTERVAL = 30 days;
    uint256 private constant MIN_REWARD_AMOUNT = 1e18;
    uint256 private constant MAX_REWARD_AMOUNT = 1000e18;
    uint256 private constant MAX_STRING_LENGTH = 32;
    uint256 private constant MIN_RATIO = 5; // 5% minimum for each staker/operator rewards

    address public immutable NETWORK_MIDDLEWARE_SERVICE;

    mapping(bytes32 => RewardPoolConfig) private rewardPoolConfigs;
    mapping(bytes32 => uint256) public rewardPools;
    mapping(bytes32 => address[]) public whitelistedDepositorList;
    mapping(bytes32 => mapping(address => bool)) public isWhitelistedDepositor;
    mapping(bytes32 => address) public rewardPoolCreator;

    constructor(address _networkMiddlewareService) Ownable(msg.sender) {
        if (_networkMiddlewareService == address(0)) revert InvalidNetworkMiddleware(_networkMiddlewareService);
        NETWORK_MIDDLEWARE_SERVICE = _networkMiddlewareService;
    }

    function _getRewardKey( string calldata clusterId, string calldata rollupId ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(clusterId, rollupId));
    }
    
    modifier onlyPoolCreator(string calldata clusterId, string calldata rollupId) {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        if (rewardPoolCreator[rewardKey] != msg.sender) 
            revert NotAuthorized(msg.sender);
        _;
    }

    function approveRewardDistribution( address network, string calldata clusterId, string calldata rollupId, uint256 approvalAmount ) external nonReentrant whenNotPaused returns (uint256) {

        address middleware = INetworkMiddlewareService(
            NETWORK_MIDDLEWARE_SERVICE
        ).middleware(network);
        if (middleware != msg.sender)
            revert InvalidMiddleware(msg.sender, middleware);

        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        RewardPoolConfig storage config = rewardPoolConfigs[rewardKey];

        if (!config.isActive) revert ConfigNotActive();

        if ( block.timestamp < config.lastDistribution + config.distributionInterval) revert TooEarlyForDistribution();

        uint256 currentPoolBalance = rewardPools[rewardKey];
        if (currentPoolBalance < approvalAmount)
            revert InsufficientPoolBalance(
                currentPoolBalance,
                approvalAmount
            );

        rewardPools[rewardKey] -= approvalAmount;
        config.lastDistribution = block.timestamp;

        IERC20(config.rewardToken).safeIncreaseAllowance(
            msg.sender,
            approvalAmount
        );

        emit RewardDistributionApproved(
            clusterId,
            rollupId,
            approvalAmount,
            block.timestamp
        );

        return approvalAmount;
    }

    function getDistributionInfo( string calldata clusterId, string calldata rollupId ) external view returns ( bool isEligible, uint256 availableAmount, address rewardToken, uint256 timeUntilNextDistribution, uint256 operatorAmount, uint256 stakerAmount )
    {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        RewardPoolConfig storage config = rewardPoolConfigs[rewardKey];

        if (!config.isActive) {
            return (false, 0, address(0), 0, 0, 0);
        }

        uint256 nextDistribution = config.lastDistribution + config.distributionInterval;
        uint256 poolBalance = rewardPools[rewardKey];

        isEligible = block.timestamp >= nextDistribution && poolBalance >= config.amountPerTask;

        timeUntilNextDistribution = block.timestamp >= nextDistribution ? 0 : nextDistribution - block.timestamp;

        operatorAmount = (config.amountPerTask * config.operatorRewardRatio) / 100;
        stakerAmount = (config.amountPerTask * config.stakerRewardRatio) / 100;

        return ( isEligible, config.amountPerTask, config.rewardToken, timeUntilNextDistribution, operatorAmount, stakerAmount );
    }

    function addRewardPoolConfig( string calldata clusterId, string calldata rollupId, address rewardToken, uint256 amountPerTask, uint256 distributionInterval, uint256 operatorRewardRatio, uint256 stakerRewardRatio ) external whenNotPaused {

        if (amountPerTask < MIN_REWARD_AMOUNT)
            revert AmountTooLow(amountPerTask, MIN_REWARD_AMOUNT);
        if (amountPerTask > MAX_REWARD_AMOUNT)
            revert AmountTooHigh(amountPerTask, MAX_REWARD_AMOUNT);
        if (rewardToken == address(0)) revert ZeroAddress();
        if (distributionInterval < MIN_DISTRIBUTION_INTERVAL)
            revert IntervalTooShort( distributionInterval, MIN_DISTRIBUTION_INTERVAL );
        if (distributionInterval > MAX_DISTRIBUTION_INTERVAL)
            revert IntervalTooLong( distributionInterval, MAX_DISTRIBUTION_INTERVAL );
        if (operatorRewardRatio < MIN_RATIO || operatorRewardRatio > 95)
            revert InvalidRatio(operatorRewardRatio, MIN_RATIO, 95);
        if (stakerRewardRatio < MIN_RATIO || stakerRewardRatio > 95)
            revert InvalidRatio(stakerRewardRatio, MIN_RATIO, 95);
        if (operatorRewardRatio + stakerRewardRatio != 100)
            revert RatioSumInvalid(operatorRewardRatio + stakerRewardRatio);

        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        if (rewardPoolConfigs[rewardKey].isActive) {
            revert ConfigExists();
        }

        try IERC20(rewardToken).totalSupply() returns (uint256) {} catch {
            revert InvalidERC20Token(rewardToken);
        }

        rewardPoolConfigs[rewardKey] = RewardPoolConfig({
            rewardToken: rewardToken,
            amountPerTask: amountPerTask,
            distributionInterval: distributionInterval,
            lastDistribution: block.timestamp,
            operatorRewardRatio: operatorRewardRatio,
            stakerRewardRatio: stakerRewardRatio,
            isActive: true
        });

        rewardPoolCreator[rewardKey] = msg.sender;

        whitelistedDepositorList[rewardKey].push(msg.sender);
        isWhitelistedDepositor[rewardKey][msg.sender] = true;

        emit RewardPoolConfigAdded(clusterId, rollupId, rewardToken, distributionInterval);
    }

    function updateRewardPoolConfig(
        string calldata clusterId,
        string calldata rollupId,
        uint256 newDistributionInterval,
        uint256 newAmountPerTask,
        uint256 newOperatorRewardRatio,
        uint256 newStakerRewardRatio
    ) external onlyPoolCreator(clusterId, rollupId) whenNotPaused {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        RewardPoolConfig storage config = rewardPoolConfigs[rewardKey];
        if (!config.isActive) revert ConfigNotActive();
        if (newAmountPerTask == 0) revert InvalidNewAmountPerTask();
        if (newDistributionInterval < MIN_DISTRIBUTION_INTERVAL) 
            revert InvalidNewDistributionInterval(newDistributionInterval, MIN_DISTRIBUTION_INTERVAL);
        if (newOperatorRewardRatio + newStakerRewardRatio != 100) 
            revert InvalidNewRewardRatios(newOperatorRewardRatio, newStakerRewardRatio);

        config.distributionInterval = newDistributionInterval;
        config.amountPerTask = newAmountPerTask;
        config.operatorRewardRatio = newOperatorRewardRatio;
        config.stakerRewardRatio = newStakerRewardRatio;

        emit RewardPoolConfigUpdated( clusterId, rollupId, newDistributionInterval, newAmountPerTask, newOperatorRewardRatio, newStakerRewardRatio );
    }

    function depositRewards( string calldata clusterId, string calldata rollupId, uint256 amount ) external nonReentrant whenNotPaused {

        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        if (!isWhitelistedDepositor[rewardKey][msg.sender])
            revert NotAuthorizedDepositor();

        RewardPoolConfig storage config = rewardPoolConfigs[rewardKey];
        if (!config.isActive) revert ConfigNotActive();

        uint256 minimumRequired = config.amountPerTask * POOL_MULTIPLIER;

        uint256 newBalance = rewardPools[rewardKey] + amount;
        if (newBalance < minimumRequired)
            revert InsufficientPoolBalance(newBalance, minimumRequired);

        IERC20 token = IERC20(config.rewardToken);
        if (token.balanceOf(msg.sender) < amount) revert InsufficientBalance();

        token.safeTransferFrom(msg.sender, address(this), amount);
        rewardPools[rewardKey] = newBalance;

        emit RewardsDeposited( clusterId, rollupId, msg.sender, amount, newBalance );
    }

    function emergencyWithdraw( string calldata clusterId, string calldata rollupId, uint256 amount ) external onlyPoolCreator(clusterId, rollupId) nonReentrant whenNotPaused {

        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        RewardPoolConfig storage config = rewardPoolConfigs[rewardKey];
        if (!config.isActive) revert ConfigNotActive();

        uint256 currentBalance = rewardPools[rewardKey];
        if (amount == 0 || amount > currentBalance)
            revert InvalidAmount(amount, currentBalance);

        uint256 minimumRequired = config.amountPerTask * POOL_MULTIPLIER * 2;
        uint256 maxWithdrawal = currentBalance > minimumRequired ? currentBalance - minimumRequired : 0;
        if (amount > maxWithdrawal)
            revert ExceedsWithdrawalLimit(amount, maxWithdrawal);

        rewardPools[rewardKey] = currentBalance - amount;

        IERC20(config.rewardToken).safeTransfer(msg.sender, amount);

        emit EmergencyWithdrawn(clusterId, rollupId, msg.sender, amount);
    }

    function addWhitelistedDepositor( string calldata clusterId, string calldata rollupId, address newDepositor ) external onlyPoolCreator(clusterId, rollupId) whenNotPaused {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        if (isWhitelistedDepositor[rewardKey][newDepositor]) 
            revert DepositorAlreadyWhitelisted(newDepositor);
        if (newDepositor == address(0)) revert ZeroAddress();
        if (whitelistedDepositorList[rewardKey].length >= MAX_WHITELISTED_DEPOSITORS)
            revert TooManyDepositors(whitelistedDepositorList[rewardKey].length, MAX_WHITELISTED_DEPOSITORS);

        whitelistedDepositorList[rewardKey].push(newDepositor);
        isWhitelistedDepositor[rewardKey][newDepositor] = true;

        emit WhitelistedDepositorAdded(clusterId, rollupId, newDepositor);
    }

    function removeWhitelistedDepositor( string calldata clusterId, string calldata rollupId, address depositorToRemove ) external onlyPoolCreator(clusterId, rollupId) whenNotPaused {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        if (!isWhitelistedDepositor[rewardKey][depositorToRemove]) 
            revert DepositorNotWhitelisted(depositorToRemove);
        if (whitelistedDepositorList[rewardKey].length <= 1) 
            revert CannotRemoveLastDepositor();

        isWhitelistedDepositor[rewardKey][depositorToRemove] = false;

        for (uint i = 0; i < whitelistedDepositorList[rewardKey].length; i++) {
            if (whitelistedDepositorList[rewardKey][i] == depositorToRemove) {
                whitelistedDepositorList[rewardKey][i] = whitelistedDepositorList[rewardKey][
                    whitelistedDepositorList[rewardKey].length - 1
                ];
                whitelistedDepositorList[rewardKey].pop();
                break;
            }
        }

        emit WhitelistedDepositorRemoved(clusterId, rollupId, depositorToRemove);
    }

    function getRewardPoolCreator( string calldata clusterId, string calldata rollupId ) external view returns (address) {
        return rewardPoolCreator[_getRewardKey(clusterId, rollupId)];
    }

    function getRewardPoolConfig( string calldata clusterId, string calldata rollupId ) external view returns (RewardPoolConfig memory) {
        return rewardPoolConfigs[_getRewardKey(clusterId, rollupId)];
    }

    function getWhitelistedDepositors( string calldata clusterId, string calldata rollupId ) external view returns (address[] memory) {
        return whitelistedDepositorList[_getRewardKey(clusterId, rollupId)];
    }

    function getRewardPoolBalance( string calldata clusterId, string calldata rollupId ) external view returns (uint256) {
        return rewardPools[_getRewardKey(clusterId, rollupId)];
    }

    function rewardPoolExists( string calldata clusterId, string calldata rollupId ) external view returns (bool) {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        return rewardPoolConfigs[rewardKey].isActive;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}