// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

interface IValidationServiceManager {
    error NotOperator();
    error NotVault();

    error OperatorNotActive();
    error OperatorNotOptedIn();
    error OperatorNotRegistred();
    error OperarorGracePeriodNotPassed();
    error OperatorAlreadyRegistred();

    error VaultAlreadyRegistred();
    error VaultEpochTooShort();
    error VaultGracePeriodNotPassed();

    error InvalidSubnetworksCnt();

    error TooOldEpoch();
    error InvalidEpoch();

    error SlashingWindowTooShort();
    error TooBigSlashAmount();
    error UnknownSlasherType();

    struct ValidatorData {
        address operator;
        uint256 stake;
    }

    // STRUCTS
    struct Task {
        string clusterId;
        string rollupId;

        uint64 blockNumber;
        bytes blockCommitment;

        uint32 taskCreatedBlock;
    }

    struct RollupTaskInfo {
        uint32 latestTaskNumber;
        
        mapping(uint32 => bytes32) allTaskHashes;
        mapping(address => mapping(uint32 => bytes)) allTaskResponses;
    } 

    event NewTaskCreated(uint32 indexed taskIndex, Task task, bytes commitment, uint64 blockNumber, string rollupId, string clusterId, uint32 taskCreatedBlock);
    event TaskResponded(uint32 indexed taskIndex, bytes commitment, uint64 blockNumber, string rollupId, string clusterId, uint32 taskCreatedBlock, address operator);
}