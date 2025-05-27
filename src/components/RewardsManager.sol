// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {IValidationServiceManager as IVsmTypes} from "src/interfaces/IValidationServiceManager.sol";

import {ITaskManager} from "src/interfaces/ITaskManager.sol";
import {IRewardsManager} from "src/interfaces/IRewardsManager.sol";
contract RewardsManager is Ownable {
    mapping(string => mapping(string => mapping(uint256 => IVsmTypes.DistributionData))) public distributionDataByTask;
    
    mapping(string => mapping(string => uint256)) public latestDistributedTaskIndex;
    
    ITaskManager public taskManager;
    constructor() Ownable(msg.sender) {}

    function setTaskManager(address _taskManager) external onlyOwner {
        taskManager = ITaskManager(_taskManager);
    }

    function storeDistributionData( string calldata clusterId, string calldata rollupId, uint256 pendingRewardTaskIndex, IVsmTypes.DistributionParams calldata distributionParams ) external onlyOwner {
        IVsmTypes.DistributionData storage data = distributionDataByTask[clusterId][rollupId][pendingRewardTaskIndex];
        
        if (data.operatorMerkleRoots.length == 0) {
            data.vaultAddresses = distributionParams.vaultAddresses;
            data.operatorMerkleRoots = distributionParams.operatorMerkleRoots;
            data.totalStakerReward = distributionParams.totalStakerReward;
            data.totalOperatorReward = distributionParams.totalOperatorReward;
            data.distributed = false;   
            
            emit IRewardsManager.DistributionDataSaved(clusterId, rollupId, pendingRewardTaskIndex);
        }
    }

    function markDistributionAsCompleted( string calldata clusterId, string calldata rollupId, uint256 taskIndex ) external onlyOwner {
        distributionDataByTask[clusterId][rollupId][taskIndex].distributed = true;
        
        if (taskIndex > latestDistributedTaskIndex[clusterId][rollupId]) {
            latestDistributedTaskIndex[clusterId][rollupId] = taskIndex;
        }
        
        emit IRewardsManager.DistributionCompleted(clusterId, rollupId, taskIndex);
    }

    function getDistributionData( string memory clusterId, string memory rollupId, uint256 referenceTaskId ) public view returns (
        address[] memory vaultAddresses,
        bytes32[] memory operatorMerkleRoots,
        uint256[] memory totalStakerReward,
        uint256[] memory totalOperatorReward,
        bool distributed
    ) {
        IVsmTypes.DistributionData storage data = distributionDataByTask[clusterId][rollupId][referenceTaskId];
        
        return (
            data.vaultAddresses,
            data.operatorMerkleRoots,
            data.totalStakerReward,
            data.totalOperatorReward,
            data.distributed
        );
    }
    
    struct AggregatedDistributionData {
        address[] vaultAddresses;
        bytes32[] operatorMerkleRoots;
        uint256[] totalStakerReward;
        uint256[] totalOperatorReward;
        uint256[] taskIndices;
        uint256 taskCount;
    }

    function processDistributionData(
        string calldata clusterId,
        string calldata rollupId,
        uint256 startingTaskIndex,
        uint256 taskCount
    ) external view returns (AggregatedDistributionData memory, uint256 totalRewardsRequired) {
        require(address(taskManager) != address(0), "TaskManager not set");
        
        uint256[] memory pendingTaskIndices = new uint256[](taskCount - startingTaskIndex);
        uint256 pendingTaskCount = 0;
        uint256 maxPossibleVaultCount = 0;
        
        for (uint256 i = startingTaskIndex; i < taskCount; i++) {
            if (this.hasDistributionData(clusterId, rollupId, i) && 
                !this.isDistributed(clusterId, rollupId, i) &&
                taskManager.isTaskEligibleForRewards(rollupId, i)) {
                
                pendingTaskIndices[pendingTaskCount] = i;
                pendingTaskCount++;
                
                (address[] memory vaults,,,, ) = this.getDistributionData(clusterId, rollupId, i);
                maxPossibleVaultCount += vaults.length;
            }
        }
        
        if (pendingTaskCount == 0) {
            AggregatedDistributionData memory emptyResult;
            emptyResult.vaultAddresses = new address[](0);
            emptyResult.operatorMerkleRoots = new bytes32[](0);
            emptyResult.totalStakerReward = new uint256[](0);
            emptyResult.totalOperatorReward = new uint256[](0);
            emptyResult.taskIndices = new uint256[](0);
            emptyResult.taskCount = 0;
            return (emptyResult, 0);
        }
        
        address[] memory allVaults = new address[](maxPossibleVaultCount);
        uint256 uniqueVaultCount = 0;
        
        AggregatedDistributionData memory result;
        result.taskIndices = new uint256[](pendingTaskCount);
        
        for (uint256 i = 0; i < pendingTaskCount; i++) {
            result.taskIndices[i] = pendingTaskIndices[i];
        }
        result.taskCount = pendingTaskCount;
        
        uint256[] memory tempStakerRewards = new uint256[](maxPossibleVaultCount);
        uint256[] memory tempOperatorRewards = new uint256[](maxPossibleVaultCount);
        bytes32[] memory tempMerkleRoots = new bytes32[](maxPossibleVaultCount);
        
        for (uint256 i = 0; i < pendingTaskCount; i++) {
            uint256 taskIndex = pendingTaskIndices[i];
            (
                address[] memory vaultAddresses,
                bytes32[] memory operatorMerkleRoots,
                uint256[] memory totalStakerReward,
                uint256[] memory totalOperatorReward,
            ) = this.getDistributionData(clusterId, rollupId, taskIndex);
            
            for (uint256 j = 0; j < vaultAddresses.length; j++) {
                address vault = vaultAddresses[j];
                
                uint256 vaultIndex = uniqueVaultCount;
                for (uint256 k = 0; k < uniqueVaultCount; k++) {
                    if (allVaults[k] == vault) {
                        vaultIndex = k;
                        break;
                    }
                }
                
                if (vaultIndex == uniqueVaultCount) {
                    allVaults[uniqueVaultCount] = vault;
                    tempMerkleRoots[uniqueVaultCount] = operatorMerkleRoots[j];
                    uniqueVaultCount++;
                }
                
                tempStakerRewards[vaultIndex] += totalStakerReward[j];
                tempOperatorRewards[vaultIndex] += totalOperatorReward[j];
                
                tempMerkleRoots[vaultIndex] = operatorMerkleRoots[j];
            }
        }
        
        result.vaultAddresses = new address[](uniqueVaultCount);
        result.operatorMerkleRoots = new bytes32[](uniqueVaultCount);
        result.totalStakerReward = new uint256[](uniqueVaultCount);
        result.totalOperatorReward = new uint256[](uniqueVaultCount);
        
        totalRewardsRequired = 0;
        for (uint256 i = 0; i < uniqueVaultCount; i++) {
            result.vaultAddresses[i] = allVaults[i];
            result.operatorMerkleRoots[i] = tempMerkleRoots[i];
            result.totalStakerReward[i] = tempStakerRewards[i];
            result.totalOperatorReward[i] = tempOperatorRewards[i];
            
            totalRewardsRequired += tempStakerRewards[i] + tempOperatorRewards[i];
        }
        
        return (result, totalRewardsRequired);
    }

    function markMultipleDistributionsAsCompleted( string calldata clusterId, string calldata rollupId, uint256[] calldata taskIndices ) external onlyOwner {
        
        for (uint256 i = 0; i < taskIndices.length; i++) {
            uint256 taskIndex = taskIndices[i];
            distributionDataByTask[clusterId][rollupId][taskIndex].distributed = true;
            emit IRewardsManager.RewardsDistributed(clusterId, rollupId, taskIndex);
        }
        
    }

    function hasDistributionData( string calldata clusterId, string calldata rollupId, uint256 taskIndex ) external view returns (bool) {
        return distributionDataByTask[clusterId][rollupId][taskIndex].operatorMerkleRoots.length > 0;
    }

    function isDistributed( string calldata clusterId, string calldata rollupId, uint256 taskIndex ) external view returns (bool) {
        return distributionDataByTask[clusterId][rollupId][taskIndex].distributed;
    }
    
    function getLatestDistributedTaskIndex( string calldata clusterId, string calldata rollupId ) external view returns (uint256) {
        return latestDistributedTaskIndex[clusterId][rollupId];
    }
}