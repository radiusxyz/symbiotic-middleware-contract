// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {console} from "forge-std/src/console.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Math} from "@openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IRewardsManager} from "./interfaces/IRewardsManager.sol";
import {IValidationServiceManager} from "../IValidationServiceManager.sol";
import {INetworkMiddlewareService} from "@symbiotic-core/src/interfaces/service/INetworkMiddlewareService.sol";


/**
 * @title RewardsManager
 * @notice Manages reward pools and approvals for the ValidationServiceManager
 */
contract RewardsManager is IRewardsManager, Ownable, ReentrancyGuard, Pausable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    // Constants
    uint256 private constant MIN_DISTRIBUTION_INTERVAL = 10;
    uint256 private constant MAX_WHITELISTED_DEPOSITORS = 10;

    // Immutable state variables
    address public immutable NETWORK_MIDDLEWARE_SERVICE;

    // State variables
    mapping(bytes32 => RewardPoolConfig) private rewardPoolConfigs;
    mapping(bytes32 => uint256) public rewardPools;
    mapping(bytes32 => address[]) public whitelistedDepositorList;
    mapping(bytes32 => mapping(address => bool)) public isWhitelistedDepositor;

    constructor(
        address _networkMiddlewareService
    ) Ownable(msg.sender) {
        require(_networkMiddlewareService != address(0), "Invalid network middleware service address");

        NETWORK_MIDDLEWARE_SERVICE = _networkMiddlewareService;
    }

    function _getRewardKey(string calldata clusterId, string calldata rollupId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(clusterId, rollupId));
    }

    function approveRewardDistribution(
    address network,
    string calldata clusterId,
    string calldata rollupId,
    uint256 amount
) external nonReentrant whenNotPaused returns (uint256) {
    console.log("approveRewardDistribution called with:");
    console.log("network:", network);
    console.log("clusterId:", clusterId);
    console.log("rollupId:", rollupId);
    console.log("amount:", amount);
    console.log("msg.sender:", msg.sender);

    address middleware = INetworkMiddlewareService(NETWORK_MIDDLEWARE_SERVICE).middleware(network);
    console.log("Expected middleware:", middleware);
        console.log("NETWORK_MIDDLEWARE_SERVICE:", NETWORK_MIDDLEWARE_SERVICE);

    
    require(middleware == msg.sender, "Not Network Middleware");
    console.log("Middleware check passed");

    bytes32 rewardKey = _getRewardKey(clusterId, rollupId);

    RewardPoolConfig storage config = rewardPoolConfigs[rewardKey];
    console.log("Config active status:", config.isActive);
    console.log("Config lastDistribution:", config.lastDistribution);
    console.log("Config distributionInterval:", config.distributionInterval);
    console.log("Config minPoolBalance:", config.minPoolBalance);
    
    require(config.isActive, "Config not active");
    console.log("Active check passed");
    
    console.log("Current timestamp:", block.timestamp);
    console.log("Next allowed distribution:", config.lastDistribution + config.distributionInterval);
    require(block.timestamp >= config.lastDistribution + config.distributionInterval, "Too early");
    console.log("Time check passed");

    uint256 currentPoolBalance = rewardPools[rewardKey];
    console.log("Current pool balance:", currentPoolBalance);
    require(currentPoolBalance >= config.minPoolBalance, "Insufficient pool balance");
    console.log("Balance check passed");
    
    uint256 availableAmount = Math.min(amount, currentPoolBalance);
    console.log("Calculated available amount:", availableAmount);
    require(availableAmount > 0, "No rewards available");
    console.log("Amount check passed");

    // Update state
    rewardPools[rewardKey] -= availableAmount;
    config.lastDistribution = block.timestamp;
    console.log("State updated");
    console.log("New pool balance:", rewardPools[rewardKey]);
    console.log("New lastDistribution:", config.lastDistribution);

    // Approve exact amount
    address rewardToken = config.rewardToken;
    console.log("Reward token address:", rewardToken);
    console.log("Approving amount:", availableAmount);
    IERC20(rewardToken).approve(msg.sender, availableAmount);
    console.log("Approval complete");

    emit RewardDistributionApproved(clusterId, rollupId, availableAmount, block.timestamp);
    console.log("Event emitted");
    
    return availableAmount;
}

    function getDistributionInfo(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (
        bool isEligible,
        uint256 availableAmount,
        address rewardToken,
        uint256 timeUntilNextDistribution
    ) {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        RewardPoolConfig storage config = rewardPoolConfigs[rewardKey];
        
        if (!config.isActive) {
            return (false, 0, address(0), 0);
        }

        uint256 nextDistribution = config.lastDistribution + config.distributionInterval;
        uint256 poolBalance = rewardPools[rewardKey];

        isEligible = block.timestamp >= nextDistribution && 
                     poolBalance >= config.minPoolBalance;
                     
        timeUntilNextDistribution = block.timestamp >= nextDistribution ? 
                                   0 : nextDistribution - block.timestamp;

        return (
            isEligible,
            poolBalance,
            config.rewardToken,
            timeUntilNextDistribution
        );
    }

    function addRewardPoolConfig(
        string calldata clusterId,
        string calldata rollupId,
        address rewardToken,
        uint256 minPoolBalance,
        uint256 distributionInterval
    ) external whenNotPaused {
        require(minPoolBalance > 0, "Invalid minimum balance");
        require(rewardToken != address(0), "Invalid reward token");
        require(distributionInterval >= MIN_DISTRIBUTION_INTERVAL, "Interval too short");

        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        if(rewardPoolConfigs[rewardKey].isActive) {
            revert("Config exists");
        }

        try IERC20(rewardToken).totalSupply() returns (uint256) {
        } catch {
            revert("Invalid ERC20 token");
        }

        rewardPoolConfigs[rewardKey] = RewardPoolConfig({
            rewardToken: rewardToken,
            minPoolBalance: minPoolBalance,
            distributionInterval: distributionInterval,
            lastDistribution: block.timestamp,
            isActive: true
        });

        whitelistedDepositorList[rewardKey].push(msg.sender);
        isWhitelistedDepositor[rewardKey][msg.sender] = true;

        emit RewardPoolConfigAdded(clusterId, rollupId, rewardToken);
    }

    function updateRewardPoolConfig(
        string calldata clusterId,
        string calldata rollupId,
        uint256 newDistributionInterval,
        uint256 newMinPoolBalance
    ) external  whenNotPaused {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        RewardPoolConfig storage config = rewardPoolConfigs[rewardKey];
        require(config.isActive, "Config not active");
        require(newMinPoolBalance > 0, "Invalid minimum balance");
        require(newDistributionInterval >= MIN_DISTRIBUTION_INTERVAL, "Invalid interval");

        config.distributionInterval = newDistributionInterval;
        config.minPoolBalance = newMinPoolBalance;

        emit RewardPoolConfigUpdated(
            clusterId, 
            rollupId,
            newDistributionInterval,
            newMinPoolBalance
        );
    }

    function depositRewards(
        string calldata clusterId,
        string calldata rollupId,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        require(isWhitelistedDepositor[rewardKey][msg.sender], "Not authorized");
        
        RewardPoolConfig storage config = rewardPoolConfigs[rewardKey];
        require(config.isActive, "Config not active");
        require(rewardPools[rewardKey] + amount >= config.minPoolBalance, "Insufficient deposit");

        IERC20 token = IERC20(config.rewardToken);
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        token.safeTransferFrom(msg.sender, address(this), amount);
        rewardPools[rewardKey] += amount;

        emit RewardsDeposited(clusterId, rollupId, msg.sender, amount, rewardPools[rewardKey]);
    }

    function emergencyWithdraw(
        string calldata clusterId,
        string calldata rollupId,
        uint256 amount
    ) external onlyOwner nonReentrant whenNotPaused {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        RewardPoolConfig storage config = rewardPoolConfigs[rewardKey];
        require(config.isActive, "Config not active");
        require(amount > 0 && amount <= rewardPools[rewardKey], "Invalid amount");

        uint256 remainingBalance = rewardPools[rewardKey] - amount;
        require(remainingBalance >= config.minPoolBalance, "Below min balance");

        rewardPools[rewardKey] = remainingBalance;
        
        IERC20(config.rewardToken).safeTransfer(msg.sender, amount);

        emit EmergencyWithdrawn(clusterId, rollupId, msg.sender, amount);
    }

    function addWhitelistedDepositor(
        string calldata clusterId,
        string calldata rollupId,
        address newDepositor
    ) external onlyOwner whenNotPaused {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        require(!isWhitelistedDepositor[rewardKey][newDepositor], "Already whitelisted");
        require(newDepositor != address(0), "Invalid address");
        require(whitelistedDepositorList[rewardKey].length < MAX_WHITELISTED_DEPOSITORS, "Too many depositors");

        whitelistedDepositorList[rewardKey].push(newDepositor);
        isWhitelistedDepositor[rewardKey][newDepositor] = true;

        emit WhitelistedDepositorAdded(clusterId, rollupId, newDepositor);
    }

    function removeWhitelistedDepositor(
        string calldata clusterId,
        string calldata rollupId,
        address depositorToRemove
    ) external onlyOwner whenNotPaused {
        bytes32 rewardKey = _getRewardKey(clusterId, rollupId);
        require(isWhitelistedDepositor[rewardKey][depositorToRemove], "Not whitelisted");
        require(whitelistedDepositorList[rewardKey].length > 1, "Cannot remove last depositor");

        isWhitelistedDepositor[rewardKey][depositorToRemove] = false;

        // Remove from array efficiently
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

    function getRewardPoolConfig(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (RewardPoolConfig memory) {
        return rewardPoolConfigs[_getRewardKey(clusterId, rollupId)];
    }

    function getWhitelistedDepositors(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (address[] memory) {
        return whitelistedDepositorList[_getRewardKey(clusterId, rollupId)];
    }

    function getRewardPoolBalance(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (uint256) {
        return rewardPools[_getRewardKey(clusterId, rollupId)];
    }

    function rewardPoolExists(
        string calldata clusterId,
        string calldata rollupId
    ) external view returns (bool) {
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