// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {IValidationServiceManager} from "src/interfaces/IValidationServiceManager.sol";

contract RewardsManager is Ownable {
    mapping(string => mapping(string => mapping(uint256 => IValidationServiceManager.DistributionData))) public distributionDataByTask;
    
    // Track the latest distributed task index per rollup
    mapping(string => mapping(string => uint256)) public latestDistributedTaskIndex;

    event DistributionDataSaved(string clusterId, string rollupId, uint256 pendingRewardTaskIndex);
    event DistributionCompleted(string clusterId, string rollupId, uint256 taskIndex);
    event AggregateDistributionProcessed(string clusterId, string rollupId, uint256 fromTaskIndex, uint256 toTaskIndex);

    constructor() Ownable(msg.sender) {}

    function storeDistributionData( string calldata clusterId, string calldata rollupId, uint256 pendingRewardTaskIndex, IValidationServiceManager.DistributionParams calldata distributionParams ) external onlyOwner {
        IValidationServiceManager.DistributionData storage data = distributionDataByTask[clusterId][rollupId][pendingRewardTaskIndex];
        
        if (data.operatorMerkleRoots.length == 0) {
            data.vaultAddresses = distributionParams.vaultAddresses;
            data.operatorMerkleRoots = distributionParams.operatorMerkleRoots;
            data.totalStakerReward = distributionParams.totalStakerReward;
            data.totalOperatorReward = distributionParams.totalOperatorReward;
            data.distributed = false;   
            
            emit DistributionDataSaved(clusterId, rollupId, pendingRewardTaskIndex);
        }
    }

    function markDistributionAsCompleted( string calldata clusterId, string calldata rollupId, uint256 taskIndex ) external onlyOwner {
        distributionDataByTask[clusterId][rollupId][taskIndex].distributed = true;
        
        if (taskIndex > latestDistributedTaskIndex[clusterId][rollupId]) {
            latestDistributedTaskIndex[clusterId][rollupId] = taskIndex;
        }
        
        emit DistributionCompleted(clusterId, rollupId, taskIndex);
    }

    function getDistributionData( string memory clusterId, string memory rollupId, uint256 referenceTaskId ) public view returns (
        address[] memory vaultAddresses,
        bytes32[] memory operatorMerkleRoots,
        uint256[] memory totalStakerReward,
        uint256[] memory totalOperatorReward,
        bool distributed
    ) {
        IValidationServiceManager.DistributionData storage data = distributionDataByTask[clusterId][rollupId][referenceTaskId];
        
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
        uint256 taskCount,
        function(string memory, uint256) external view returns (uint256) responseCountFunc
    ) external view returns (AggregatedDistributionData memory, uint256 totalRewardsRequired) {
        uint256[] memory pendingTaskIndices = new uint256[](taskCount - startingTaskIndex);
        uint256 pendingTaskCount = 0;
        
        for (uint256 i = startingTaskIndex; i < taskCount; i++) {
            bool hasData = this.hasDistributionData(clusterId, rollupId, i);
            bool isDistributed = this.isDistributed(clusterId, rollupId, i);
            uint256 responseCount = responseCountFunc(rollupId, i);
            
            if (hasData && !isDistributed) {
                pendingTaskIndices[pendingTaskCount] = i;
                pendingTaskCount++;
            }
        }
        
        uint256 maxPossibleVaultCount = 0;
        for (uint256 i = 0; i < pendingTaskCount; i++) {
            uint256 taskIndex = pendingTaskIndices[i];
            (address[] memory vaults,,,, ) = this.getDistributionData(clusterId, rollupId, taskIndex);
            maxPossibleVaultCount += vaults.length;
        }
        
        address[] memory allVaults = new address[](maxPossibleVaultCount);
        bool[] memory isUnique = new bool[](maxPossibleVaultCount);
        uint256 uniqueVaultCount = 0;
        
        for (uint256 i = 0; i < pendingTaskCount; i++) {
            uint256 taskIndex = pendingTaskIndices[i];
            (address[] memory vaults,,,, ) = this.getDistributionData(clusterId, rollupId, taskIndex);
            
            for (uint256 j = 0; j < vaults.length; j++) {
                bool found = false;
                for (uint256 k = 0; k < uniqueVaultCount; k++) {
                    if (allVaults[k] == vaults[j]) {
                        found = true;
                        break;
                    }
                }
                
                if (!found) {
                    allVaults[uniqueVaultCount] = vaults[j];
                    isUnique[uniqueVaultCount] = true;
                    uniqueVaultCount++;
                }
            }
        }
        
        AggregatedDistributionData memory result;
        result.vaultAddresses = new address[](uniqueVaultCount);
        result.operatorMerkleRoots = new bytes32[](uniqueVaultCount);
        result.totalStakerReward = new uint256[](uniqueVaultCount);
        result.totalOperatorReward = new uint256[](uniqueVaultCount);
        
        for (uint256 i = 0; i < uniqueVaultCount; i++) {
            result.vaultAddresses[i] = allVaults[i];
        }
        
        result.taskIndices = new uint256[](pendingTaskCount);
        for (uint256 i = 0; i < pendingTaskCount; i++) {
            result.taskIndices[i] = pendingTaskIndices[i];
        }
        result.taskCount = pendingTaskCount;
        
        for (uint256 i = 0; i < pendingTaskCount; i++) {
            uint256 taskIndex = pendingTaskIndices[i];
            (
                address[] memory vaultAddresses,
                bytes32[] memory operatorMerkleRoots,
                uint256[] memory totalStakerReward,
                uint256[] memory totalOperatorReward,
            ) = this.getDistributionData(clusterId, rollupId, taskIndex);
            
            for (uint256 j = 0; j < vaultAddresses.length; j++) {
                for (uint256 k = 0; k < uniqueVaultCount; k++) {
                    if (result.vaultAddresses[k] == vaultAddresses[j]) {
                        result.totalStakerReward[k] += totalStakerReward[j];
                        result.totalOperatorReward[k] += totalOperatorReward[j];
                        
                        result.operatorMerkleRoots[k] = operatorMerkleRoots[j];
                        break;
                    }
                }
            }
        }
        
        totalRewardsRequired = 0;
        for (uint256 i = 0; i < uniqueVaultCount; i++) {
            totalRewardsRequired += result.totalStakerReward[i] + result.totalOperatorReward[i];
        }
        
        return (result, totalRewardsRequired);
    }

    function markMultipleDistributionsAsCompleted( string calldata clusterId, string calldata rollupId, uint256[] calldata taskIndices ) external onlyOwner {
        uint256 maxIndex = 0;
        
        for (uint256 i = 0; i < taskIndices.length; i++) {
            uint256 taskIndex = taskIndices[i];
            distributionDataByTask[clusterId][rollupId][taskIndex].distributed = true;
            
            if (taskIndex > maxIndex) {
                maxIndex = taskIndex;
            }
        }
        
        if (maxIndex > latestDistributedTaskIndex[clusterId][rollupId]) {
            latestDistributedTaskIndex[clusterId][rollupId] = maxIndex;
        }
        
        emit AggregateDistributionProcessed(clusterId, rollupId, taskIndices[0], taskIndices[taskIndices.length-1]);
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