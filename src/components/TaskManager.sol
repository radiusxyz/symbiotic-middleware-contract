// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {console} from "forge-std/src/console.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {IValidationServiceManager} from "src/interfaces/IValidationServiceManager.sol";

contract TaskManager is Ownable {
    mapping(string => IValidationServiceManager.RollupTaskInfo) public rollupTaskInfos;
    mapping(string => mapping(uint256 => uint256)) batchNumberToTaskNumber;
    uint256 public lastEmitTime;
    uint256 public constant EMIT_DELAY = 1; // 1 second
    
    

    constructor() Ownable(msg.sender) {}
    
    function createNewTask(
        IValidationServiceManager.Task calldata task,
        IValidationServiceManager.DistributionParams calldata distributionParams,
        address creator
    ) external {
        uint256 latestTaskNumber = rollupTaskInfos[task.rollupId].latestTaskNumber;
        rollupTaskInfos[task.rollupId].latestTaskNumber = latestTaskNumber + 1;
        rollupTaskInfos[task.rollupId].batchCommitment[latestTaskNumber] = task.batchCommitment;
        batchNumberToTaskNumber[task.rollupId][task.batchNumber] = latestTaskNumber;

        bytes32 taskHash = keccak256(abi.encode(task));
        rollupTaskInfos[task.rollupId].taskHash[latestTaskNumber] = taskHash;

        emit IValidationServiceManager.NewTaskCreated(task.clusterId, task.rollupId, latestTaskNumber, task.batchNumber, task.batchCommitment, creator);
    }

    function respondToTask( string calldata clusterId, string calldata rollupId, uint256 referenceTaskIndex, bool response, address operator ) external {
        require(
            rollupTaskInfos[rollupId].taskResponses[operator][referenceTaskIndex] == false,
            "Operator has already responded to the task"
        );

        rollupTaskInfos[rollupId].taskResponses[operator][referenceTaskIndex] = response;
        rollupTaskInfos[rollupId].taskTotalResponseCount[referenceTaskIndex]++;

        emit IValidationServiceManager.TaskResponded(clusterId, rollupId, referenceTaskIndex, response, operator);
                
        // if (rollupTaskInfos[rollupId].taskTotalResponseCount[referenceTaskIndex] == 5) {
        //     require(
        //         block.timestamp >= lastEmitTime + EMIT_DELAY,
        //         "Must wait for delay period"
        //     );
        //     lastEmitTime = block.timestamp;
        //     emit TaskThresholdMet(clusterId, rollupId, referenceTaskIndex);
        // }
    }

    function getTaskHash(string calldata rollupId, uint256 taskIndex) external view returns (bytes32) {
        return rollupTaskInfos[rollupId].taskHash[taskIndex];
    }

    function getTaskResponseCount(string calldata rollupId, uint256 taskIndex) external view returns (uint256) {
        return rollupTaskInfos[rollupId].taskTotalResponseCount[taskIndex];
    }

    function getBatchCommitment(string calldata rollupId, uint256 taskIndex) external view returns (bytes32) {
        return rollupTaskInfos[rollupId].batchCommitment[taskIndex];
    }

    function hasOperatorResponded(string calldata rollupId, uint256 taskIndex, address operator) external view returns (bool) {
        return rollupTaskInfos[rollupId].taskResponses[operator][taskIndex];
    }

    function getTaskIndexFromBatchNumber(string calldata rollupId, uint256 batchNumber) external view returns (uint256) {
        return batchNumberToTaskNumber[rollupId][batchNumber];
    }

    function getLatestTaskNumber(string calldata rollupId) external view returns (uint256) {
        return rollupTaskInfos[rollupId].latestTaskNumber;
    }
    
}