// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

interface IValidationServiceManager {
    error VaultNotRegisteredInSymbiotic();

    error OperatorNotRegistered();
    error OperatorNotActive();
    error OperatorNotOptedIn();
    error OperatorAlreadyRegistered();
    error TokenAlreadyRegistered();
    error TokenNotWhitelisted();

    error VaultAlreadyRegistered();
    error VaultEpochTooShort();
    error VaultGracePeriodNotPassed();

    error InvalidSubnetworksCnt();
    
    error InvalidEpoch();
    error TooOldEpoch();
    error OperatorGracePeriodNotPassed();
    error TokenGracePeriodNotPassed();

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

    struct TokenStake {
        address token;
        uint256 stake;
    }

    struct OperatorInfo {
        address operatorAddress;
        address operatingAddress;
        TokenStake[] stakes;
        uint256 stake;
    }

    struct RollupTaskInfo {
        uint256 latestTaskNumber;
        
        mapping(uint256 => bytes32) blockCommitments;
        mapping(uint256 => bytes32) allTaskHashes;
        mapping(address => mapping(uint256 => bool)) allTaskResponses;
        mapping(uint256 => uint256) taskTotalResponseCount;

    } 

    event NewTaskCreated(string clusterId, string rollupId, uint256 referenceTaskIndex, uint256 blockNumber, bytes32 blockCommitment, uint256 taskCreatedBlock);
    event TaskResponded(string clusterId, string rollupId, uint256 referenceTaskIndex, bool response, address operatingAddress);
    event TaskThresholdMet(string clusterId, string rollupId, uint256 referenceTaskIndex);

    event RegisterToken(address token);
    event UnregisterToken(address token);

    event RegisterVault(address vault);
    event UnregisterVault(address vault);

    event RegisterOperator(address operator, address operatingAddress);
    event UpdateOperating(address operator, address operatingAddress);
    event UnregisterOperator(address operator);    

    event RewardsDistributed(
        string clusterId,
        string rollupId,
        uint256 operatorAmount,
        uint256 stakerAmount,
        bytes32 operatorMerkleRoot
    );
}