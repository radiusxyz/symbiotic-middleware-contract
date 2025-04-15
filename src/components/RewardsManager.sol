// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {IValidationServiceManager} from "src/interfaces/IValidationServiceManager.sol";

contract RewardsManager is Ownable {
    mapping(string => mapping(string => mapping(uint256 => IValidationServiceManager.DistributionData))) public distributionDataByTask;

    event DistributionDataSaved(string clusterId, string rollupId, uint256 pendingRewardTaskIndex);

    constructor() Ownable(msg.sender) {}

    function storeDistributionData(
        string calldata clusterId,
        string calldata rollupId,
        uint256 pendingRewardTaskIndex,
        IValidationServiceManager.DistributionParams calldata distributionParams
    ) external onlyOwner {
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

    function markDistributionAsCompleted(
        string calldata clusterId,
        string calldata rollupId,
        uint256 taskIndex
    ) external onlyOwner {
        distributionDataByTask[clusterId][rollupId][taskIndex].distributed = true;
    }

    function getDistributionData(
        string memory clusterId,
        string memory rollupId,
        uint256 referenceTaskId
    ) public view returns (
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

    function hasDistributionData(
        string calldata clusterId, 
        string calldata rollupId, 
        uint256 taskIndex
    ) external view returns (bool) {
        return distributionDataByTask[clusterId][rollupId][taskIndex].operatorMerkleRoots.length > 0;
    }

    function isDistributed(
        string calldata clusterId, 
        string calldata rollupId, 
        uint256 taskIndex
    ) external view returns (bool) {
        return distributionDataByTask[clusterId][rollupId][taskIndex].distributed;
    }
}