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

    // STRUCTS
    struct Task {
        string clusterId;
        string rollupId;

        uint256 blockNumber;
        bytes32 blockCommitment;

        uint256 taskCreatedBlock;
    }

    struct ValidatorData {
        address operatingAddress;
        uint256 stake;
    }

    struct RollupTaskInfo {
        uint256 latestTaskNumber;
        
        mapping(uint256 => bytes32) blockCommitments;
        mapping(uint256 => bytes32) allTaskHashes;
        mapping(address => mapping(uint256 => bool)) allTaskResponses;
    } 

    event NewTaskCreated(string clusterId, string rollupId, uint256 referenceTaskIndex, uint256 blockNumber, bytes32 blockCommitment, uint256 taskCreatedBlock);
    event TaskResponded(string clusterId, string rollupId, uint256 referenceTaskIndex, bool response);
}