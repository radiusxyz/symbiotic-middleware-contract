// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import {IValidationServiceManager as IVsmTypes} from "./IValidationServiceManager.sol";  
interface IRewardsManager {
    function prepareNextDistribution(
        string calldata clusterId,
        string calldata rollupId
    ) external returns (
        bool found,
        uint256 taskIndex,
        IVsmTypes.DistributionData memory distributionData
    );

    function storeDistributionData(
        string calldata clusterId,
        string calldata rollupId,
        uint256 rewardedTaskindex,
        IVsmTypes.DistributionParams calldata distributionParams
    ) external;  

    function markDistributionAsCompleted(
        string calldata clusterId,
        string calldata rollupId,
        uint256 taskIndex
    ) external;

    function getDistributionData(
        string memory clusterId,
        string memory rollupId,
        uint256 referenceTaskId
    ) external view returns (
        address[] memory vaultAddresses,
        bytes32[] memory operatorMerkleRoots,
        uint256[] memory totalStakerReward,
        uint256[] memory totalOperatorReward,
        bool distributed
    );

    event DistributionDataSaved(string clusterId, string rollupId, uint256 rewardedTaskindex);
    event DistributionPrepared(string clusterId, string rollupId, uint256 indexed taskIndex);  
    event DistributionCompleted(string clusterId, string rollupId, uint256 indexed taskIndex); 
    event RewardsDistributed(string clusterId, string rollupId, uint256 referenceTaskIndex);

}