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

    error StakerRewardNotRegistered();
    error OperatorRewardNotRegistered();
    error VaultSlasherNotRegistered();

    error InvalidSubnetworkCount();

    error InvalidEpoch();

    error SlashingWindowTooShort();
    error TooBigSlashAmount();
    error UnknownSlasherType();

    error StakerRewardsNotRegistered();
    error OperatorRewardsNotRegistered();

    error InvalidValidationServiceManager(); 
    error RollupNotRegistered(); 
    error ExecutorNotRegisteredForRollup();  
    error NoPendingDistributions(); 
    error DistributionAlreadyProcessed();
    error InvalidTransactionHash();
    error SlashRequestAlreadyExists();
    error IncorrectSlashDepositAmount();
    error InvalidSignature();
    error SlashRequestNotFound();
    error SlashRequestAlreadyProcessed();
    error InvalidSlashResponder();
    error EthTransferFailed();
    error EthRefundFailed();
    error OperatorSlashingFailed();
    error TokenTransferFailed();
    error SlashCreditAlreadyProcessed();
    error SlashCreditNotFound();
    error InvalidSlashPeriod();

    struct Vault {
        address tokenAddress;
        address stakerRewards;
        address operatorRewards;
        address slasher;
    }

    struct DistributionParams {
        uint256 pendingRewardTaskIndex;
        address[] vaultAddresses;
        bytes32[] operatorMerkleRoots;
        uint256[] totalStakerReward;
        uint256[] totalOperatorReward;
    }

    struct TransactionData {
        bytes32 txHash;         
        uint256 txIndex;       
        bytes32[] preMerklePath; 
        bool exists;          
    }

    struct StakeInfo {
        address token;
        uint256 stakeAmount;
    }

    struct OperatorInfo {
        address operator;
        address txOrderer;
        
        StakeInfo[] stakeInfos;
    }

    struct Task {
        string clusterId;
        string rollupId;
        uint256 batchNumber;
        bytes32 batchCommitment;
    }



   enum Status {
        Pending,
        Processed
    }

    struct SlashRequest {
        address operator;
        address requester;
        string clusterId;
        string rollupId;
        uint256 batchNumber;
        bytes32 txHash;
        uint256 txOrder;
        bytes32[] preMerklePath;
        bytes signature;
        uint256 depositAmount;
        Status status;
        bool exists;
        uint256 timestamp; 
    }
    struct SlashResponse {
        address responder;
        bool isValid; // Result of the Merkle proof verification
    }

    struct DistributionData {
        address[] vaultAddresses;
        bytes32[] operatorMerkleRoots;
        uint256[] totalStakerReward;
        uint256[] totalOperatorReward;
        bool distributed;  // Added this field
    }

    struct RollupTaskInfo {
        uint256 latestTaskNumber;
        
        mapping(uint256 => bytes32) batchCommitment;
        mapping(uint256 => bytes32) taskHash; 
        mapping(address => mapping(uint256 => bool)) taskResponses;
        mapping(uint256 => uint256) taskTotalResponseCount;

    } 

    event RegisterToken(address token);
    event SetMinimumStakeAmount(address token, uint256 minimumStakeAmount);
    event UnregisterToken(address token);

    event RegisterVault(address vault, address stakerRewards, address operatorRewards);
    event UnregisterVault(address vault);

    event RegisterOperator(address operator, address txOrderer);
    event UpdateTxOrdererAddress(address operator, address txOrderer);
    event UnregisterOperator(address operator);    

    event NewTaskCreated(string clusterId, string rollupId, uint256 referenceTaskIndex, uint256 batchNumber, bytes32 batchCommitment, address creator);

    event TaskResponded(string clusterId, string rollupId, uint256 referenceTaskIndex, bool response, address responder);

    event RewardsDistributed(string clusterId, string rollupId, uint256 referenceTaskIndex);

    event TaskThresholdMet(string clusterId, string rollupId, uint256 referenceTaskIndex);
    event DistributionDataSaved(string clusterId, string rollupId, uint256 rewardedTaskindex);
    
    event OperatorSlashed(address indexed vault, address indexed operator, uint256 amount, bool isVeto);

    event SlashRequestSubmitted(uint256 indexed requestId, address indexed submitter, uint256 batchNumber, bytes32 txHash);
    event SlashResponseSubmitted(uint256 indexed requestId, address indexed responder, bool isValid);
    event SlashRequestResolved(uint256 indexed requestId, bool wasValid);


    event SlashRequested(
        bytes32 indexed txHash,
        address indexed operator,
        string clusterId,
        string rollupId,
        uint256 batchNumber,   
        uint256 txOrder,
        address indexed requester
    );

    event SlashResponded(
        bytes32 indexed txHash,
        address indexed operator,
        address indexed requester,
        bool isValid,
        Status newStatus
    );


    enum SlashCreditStatus {
            Pending,
            Processed,
            Failed
    }

    struct SlashCredit {
        address vault;
        address requester;         
        address tokenAddress;      
        uint256 amount;            
        uint64 slasherType;       
        uint256 slashIndex;        
        SlashCreditStatus status;  
        uint256 timestamp;         
    }

    event SlashCreditCreated(
        bytes32 indexed txHash,
        address indexed requester,
        address indexed tokenAddress,
        uint256 amount,
        uint64 slasherType,
        uint256 slashIndex
    );
    
    event SlashCreditProcessed(
        bytes32 indexed txHash,
        uint256 indexed creditIndex,
        address indexed requester,
        address tokenAddress,
        uint256 amount
    );



}



