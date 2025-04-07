// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {console} from "forge-std/src/console.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {IValidationServiceManager} from "src/interfaces/IValidationServiceManager.sol";

contract TaskManager is Ownable {
    mapping(string => IValidationServiceManager.RollupTaskInfo) public rollupTaskInfos;
    mapping(string => mapping(uint256 => uint256)) blockNumberToTaskNumber;
    uint256 public lastEmitTime;
    uint256 public constant EMIT_DELAY = 1; // 1 second
    
    event NewTaskCreated(string clusterId, string rollupId, uint256 referenceTaskIndex, uint256 blockNumber, bytes32 blockCommitment);
    event TaskResponded(string clusterId, string rollupId, uint256 referenceTaskIndex, bool response, address responder);
    event TaskThresholdMet(string clusterId, string rollupId, uint256 referenceTaskIndex);

    constructor() Ownable(msg.sender) {}
    
    function createNewTask(
        IValidationServiceManager.Task calldata task,
        IValidationServiceManager.DistributionParams calldata distributionParams,
        function(address) external view returns (bool) checkOperator
    ) external {
        require(checkOperator(msg.sender), "Operator not registered");

        uint256 latestTaskNumber = rollupTaskInfos[task.rollupId].latestTaskNumber;
        rollupTaskInfos[task.rollupId].latestTaskNumber = latestTaskNumber + 1;
        rollupTaskInfos[task.rollupId].blockCommitments[latestTaskNumber] = task.blockCommitment;
        blockNumberToTaskNumber[task.rollupId][task.blockNumber] = latestTaskNumber;

        bytes32 taskHash = keccak256(abi.encode(task));
        rollupTaskInfos[task.rollupId].taskHash[latestTaskNumber] = taskHash;

        emit NewTaskCreated(task.clusterId, task.rollupId, latestTaskNumber, task.blockNumber, task.blockCommitment);
    }

    function respondToTask(
        string calldata clusterId,
        string calldata rollupId,
        uint256 referenceTaskIndex,
        bool response,
        function(address) external view returns (bool) checkOperator
    ) external {
        require(checkOperator(msg.sender), "Operator is not registered");
        require(
            rollupTaskInfos[rollupId].taskResponses[msg.sender][referenceTaskIndex] == false,
            "Operator has already responded to the task"
        );

        rollupTaskInfos[rollupId].taskResponses[msg.sender][referenceTaskIndex] = response;
        rollupTaskInfos[rollupId].taskTotalResponseCount[referenceTaskIndex]++;

        emit TaskResponded(clusterId, rollupId, referenceTaskIndex, response, msg.sender);
                
        if (rollupTaskInfos[rollupId].taskTotalResponseCount[referenceTaskIndex] == 5) {
            require(
                block.timestamp >= lastEmitTime + EMIT_DELAY,
                "Must wait for delay period"
            );
            lastEmitTime = block.timestamp;
            emit TaskThresholdMet(clusterId, rollupId, referenceTaskIndex);
        }
    }

    function getTaskHash(string calldata rollupId, uint256 taskIndex) external view returns (bytes32) {
        return rollupTaskInfos[rollupId].taskHash[taskIndex];
    }

    function getTaskResponseCount(string calldata rollupId, uint256 taskIndex) external view returns (uint256) {
        return rollupTaskInfos[rollupId].taskTotalResponseCount[taskIndex];
    }

    function getBlockCommitment(string calldata rollupId, uint256 taskIndex) external view returns (bytes32) {
        return rollupTaskInfos[rollupId].blockCommitments[taskIndex];
    }

    function hasOperatorResponded(string calldata rollupId, uint256 taskIndex, address operator) external view returns (bool) {
        return rollupTaskInfos[rollupId].taskResponses[operator][taskIndex];
    }

    function getTaskIndexFromBlockNumber(string calldata rollupId, uint256 blockNumber) external view returns (uint256) {
        return blockNumberToTaskNumber[rollupId][blockNumber];
    }

    function getLatestTaskNumber(string calldata rollupId) external view returns (uint256) {
        return rollupTaskInfos[rollupId].latestTaskNumber;
    }
}