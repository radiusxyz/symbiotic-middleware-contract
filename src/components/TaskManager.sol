// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {console} from "forge-std/src/console.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {IValidationServiceManager as IVsmTypes} from "src/interfaces/IValidationServiceManager.sol";

import {IRegistry} from "src/interfaces/IRegistry.sol";

import {ITaskManager} from "src/interfaces/ITaskManager.sol";
contract TaskManager is Ownable {
    enum TaskStatus { Voting, QuorumPassed, QuorumFailed }
    
    mapping(string => IVsmTypes.RollupTaskInfo) public rollupTaskInfos;
    mapping(string => mapping(uint256 => uint256)) batchNumberToTaskNumber;
    
    mapping(string => mapping(uint256 => TaskStatus)) public taskStatus;
    mapping(string => mapping(uint256 => uint48)) public taskEpoch;
    mapping(string => mapping(uint256 => uint256)) public eligibleOperatorCount;
    
    address public registry;


    constructor(address _registry) Ownable(msg.sender) {
        registry = _registry;
    }
    
    function createNewTask(
        IVsmTypes.Task calldata task,
        address creator
    ) external onlyOwner {
        string memory rollupId = task.rollupId;
        uint256 currentLatestTaskNumber = rollupTaskInfos[rollupId].latestTaskNumber;
        
        if (currentLatestTaskNumber > 0) {
            uint256 previousTaskIndex = currentLatestTaskNumber - 1;
            _checkAndFinalizeQuorum(rollupId, previousTaskIndex);
        }
        
        uint256 newTaskIndex = currentLatestTaskNumber;
        rollupTaskInfos[rollupId].latestTaskNumber = newTaskIndex + 1;
        rollupTaskInfos[rollupId].batchCommitment[newTaskIndex] = task.batchCommitment;
        batchNumberToTaskNumber[rollupId][task.batchNumber] = newTaskIndex;

        bytes32 taskHash = keccak256(abi.encode(task));
        rollupTaskInfos[rollupId].taskHash[newTaskIndex] = taskHash;
        
        taskStatus[rollupId][newTaskIndex] = TaskStatus.Voting;
        taskEpoch[rollupId][newTaskIndex] = IRegistry(registry).getCurrentEpoch();
        
        IVsmTypes.OperatorInfo[] memory operators = IRegistry(registry).getOperatorInfos(taskEpoch[rollupId][newTaskIndex]);
        eligibleOperatorCount[rollupId][newTaskIndex] = operators.length;

        emit IVsmTypes.NewTaskCreated(
            task.clusterId, 
            rollupId, 
            newTaskIndex, 
            task.batchNumber, 
            task.batchCommitment, 
            creator
        );
    }

    function respondToTask( string calldata clusterId, string calldata rollupId, uint256 referenceTaskIndex, bool response, address operator ) external onlyOwner {
        require(taskStatus[rollupId][referenceTaskIndex] == TaskStatus.Voting, "Task is not in voting phase");
        
        require(
            rollupTaskInfos[rollupId].taskResponses[operator][referenceTaskIndex] == false,
            "Operator has already responded to the task"
        );

        rollupTaskInfos[rollupId].taskResponses[operator][referenceTaskIndex] = response;
        rollupTaskInfos[rollupId].taskTotalResponseCount[referenceTaskIndex]++;

        emit IVsmTypes.TaskResponded(clusterId, rollupId, referenceTaskIndex, response, operator);
    }
    
    function _checkAndFinalizeQuorum(string memory rollupId, uint256 taskIndex) internal {
        if (taskStatus[rollupId][taskIndex] != TaskStatus.Voting) {
            return;
        }
        
        uint256 eligibleOperators = eligibleOperatorCount[rollupId][taskIndex];
        uint256 requiredQuorum = (eligibleOperators * 2) / 3;  
        
        if ((eligibleOperators * 2) % 3 != 0) {
            requiredQuorum += 1;
        }
        
        uint256 trueVotes = _countTrueVotes(rollupId, taskIndex, taskEpoch[rollupId][taskIndex]);
        
        if (trueVotes >= requiredQuorum) {
            taskStatus[rollupId][taskIndex] = TaskStatus.QuorumPassed;
            emit ITaskManager.TaskQuorumPassed(rollupId, taskIndex, trueVotes, eligibleOperators);
        } else {
            taskStatus[rollupId][taskIndex] = TaskStatus.QuorumFailed;
            emit ITaskManager.TaskQuorumFailed(rollupId, taskIndex, trueVotes, eligibleOperators);
        }
    }
    
    function _countTrueVotes(string memory rollupId, uint256 taskIndex, uint48 taskEpochTime) internal view returns (uint256 trueVotes) {
        IVsmTypes.OperatorInfo[] memory operators = IRegistry(registry).getOperatorInfos(taskEpochTime);
        
        for (uint256 i = 0; i < operators.length; i++) {
            address operator = operators[i].operator;
            if (rollupTaskInfos[rollupId].taskResponses[operator][taskIndex] == true) {
                trueVotes++;
            }
        }
        
        return trueVotes;
    }
    
    function finalizeTaskQuorum(string calldata rollupId, uint256 taskIndex) external {
        require(taskStatus[rollupId][taskIndex] == TaskStatus.Voting, "Task is not in voting phase");
        _checkAndFinalizeQuorum(rollupId, taskIndex);
    }
    
   
    function getTaskQuorumStatus(string calldata rollupId, uint256 taskIndex) external view returns (
        TaskStatus status, uint256 trueVotes, uint256 eligibleOperators, uint256 requiredQuorum 
    ) {
        status = taskStatus[rollupId][taskIndex];
        eligibleOperators = eligibleOperatorCount[rollupId][taskIndex];
        
        requiredQuorum = (eligibleOperators * 2) / 3;
        if ((eligibleOperators * 2) % 3 != 0) {
            requiredQuorum += 1;
        }
        
        trueVotes = _countTrueVotes(rollupId, taskIndex, taskEpoch[rollupId][taskIndex]);
    }
    
    function isTaskEligibleForRewards(string calldata rollupId, uint256 taskIndex) external view returns (bool) {
        return taskStatus[rollupId][taskIndex] == TaskStatus.QuorumPassed;
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
    
    function setRegistry(address _registry) external onlyOwner {
        registry = _registry;
    }
}