// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {IValidationServiceManager as IVsmTypes} from "src/interfaces/IValidationServiceManager.sol";

interface ITaskManager {
    enum TaskStatus { Voting, QuorumPassed, QuorumFailed }

    event TaskQuorumPassed(string indexed rollupId, uint256 indexed taskIndex, uint256 trueVotes, uint256 eligibleOperators);
    event TaskQuorumFailed(string indexed rollupId, uint256 indexed taskIndex, uint256 trueVotes, uint256 eligibleOperators);

    function taskStatus(string calldata rollupId, uint256 taskIndex) external view returns (TaskStatus);
    function taskEpoch(string calldata rollupId, uint256 taskIndex) external view returns (uint48);
    function eligibleOperatorCount(string calldata rollupId, uint256 taskIndex) external view returns (uint256);
    function registry() external view returns (address);

    function createNewTask(
        IVsmTypes.Task calldata task,
        address creator
    ) external;

    function respondToTask(
        string calldata clusterId,
        string calldata rollupId,
        uint256 referenceTaskIndex,
        bool response,
        address operator
    ) external;

    function finalizeTaskQuorum(string calldata rollupId, uint256 taskIndex) external;

    function getTaskQuorumStatus(string calldata rollupId, uint256 taskIndex) external view returns (
        TaskStatus status,
        uint256 trueVotes,
        uint256 eligibleOperators,
        uint256 requiredQuorum
    );

    function isTaskEligibleForRewards(string calldata rollupId, uint256 taskIndex) external view returns (bool);
    function getTaskHash(string calldata rollupId, uint256 taskIndex) external view returns (bytes32);
    function getTaskResponseCount(string calldata rollupId, uint256 taskIndex) external view returns (uint256);
    function getBatchCommitment(string calldata rollupId, uint256 taskIndex) external view returns (bytes32);
    function hasOperatorResponded(string calldata rollupId, uint256 taskIndex, address operator) external view returns (bool);
    function getTaskIndexFromBatchNumber(string calldata rollupId, uint256 batchNumber) external view returns (uint256);
    function getLatestTaskNumber(string calldata rollupId) external view returns (uint256);
    function setRegistry(address _registry) external;
}


