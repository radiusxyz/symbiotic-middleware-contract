// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

interface IValidationServiceManager {
    error OperatorNotRegistered();
    error OperatorNotActive();
    error OperatorNotOptedIn();
    error OperatorAlreadyRegistered();
    error OperatorGracePeriodNotPassed();
    
    error TokenAlreadyRegistered();
    error TokenNotWhitelisted();
    error TokenGracePeriodNotPassed();

    error VaultNotRegisteredInSymbiotic();
    error VaultAlreadyRegistered();
    error VaultEpochTooShort();
    error VaultGracePeriodNotPassed();

    error InvalidSubnetworkCount();

    error InvalidEpoch();

    struct StakeInfo {
        address token;
        uint256 stakeAmount;
    }

    struct OperatorInfo {
        address operator;
        address operating;
        
        StakeInfo[] stakeInfos;
    }

    struct Task {
        string clusterId;
        string rollupId;
        uint256 blockNumber;
        
        bytes32 blockCommitment;
    }

    struct RollupTaskInfo {
        uint256 latestTaskNumber;
        
        mapping(uint256 => bytes32) blockCommitments;
        mapping(uint256 => bytes32) taskHash; 
        mapping(address => mapping(uint256 => bool)) taskResponses;
        mapping(uint256 => uint256) taskTotalResponseCount;

    } 

    event RegisterToken(address token);
    event SetMinimumStakeAmount(address token, uint256 minimumStakeAmount);
    event UnregisterToken(address token);

    event RegisterVault(address vault);
    event UnregisterVault(address vault);

    event RegisterOperator(address operator, address operatingAddress);
    event UpdateOperatingAddress(address operator, address operatingAddress);
    event UnregisterOperator(address operator);    

    event NewTaskCreated(string clusterId, string rollupId, uint256 referenceTaskIndex, uint256 blockNumber, bytes32 blockCommitment);
    event TaskResponded(string clusterId, string rollupId, uint256 referenceTaskIndex, bool response);

    event RewardsDistributed(string clusterId, string rollupId, uint256 operatorAmount, uint256 stakerAmount, bytes32 operatorMerkleRoot);
    event TaskThresholdMet(string clusterId, string rollupId, uint256 referenceTaskIndex);


}



