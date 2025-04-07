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

    struct Vault {
        address tokenAddress;
        address stakerRewards;
        address operatorRewards;
        address slasher;
    }

    struct DistributionParams {
        uint256 rewardedTaskindex;
        address[] vaultAddresses;
        bytes32[] operatorMerkleRoots;
        uint256[] totalStakerReward;
        uint256[] totalOperatorReward;
    }

    // struct TaskParams {
    //     string clusterId;
    //     string rollupId;
    //     uint256 blockNumber;
    //     bytes32 blockCommitment;
    // }

    struct TransactionData {
        bytes32 txHash;        // Hash of the transaction
        uint256 txIndex;       // Index/order of the transaction in the original set
        bytes32[] preMerklePath; // Pre-Merkle-Path (variable length)
        bool exists;           // Flag to check if the data exists
    }

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



   enum Status {
        Pending,
        Processed
    }

struct SlashRequest {
        address operator;      
        address requester;    
        string rollupId;
        uint256 blockHeight;
        bytes32 txHash;
        uint256 txOrder;
        bytes32[] preMerklePath; 
        bytes signature;      
        uint256 depositAmount; 
        Status status;         
        bool exists;            
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
        
        mapping(uint256 => bytes32) blockCommitments;
        mapping(uint256 => bytes32) taskHash; 
        mapping(address => mapping(uint256 => bool)) taskResponses;
        mapping(uint256 => uint256) taskTotalResponseCount;

    } 

    event RegisterToken(address token);
    event SetMinimumStakeAmount(address token, uint256 minimumStakeAmount);
    event UnregisterToken(address token);

    event RegisterVault(address vault, address stakerRewards, address operatorRewards);
    event UnregisterVault(address vault);

    event RegisterOperator(address operator, address operatingAddress);
    event UpdateOperatingAddress(address operator, address operatingAddress);
    event UnregisterOperator(address operator);    

    event NewTaskCreated(string clusterId, string rollupId, uint256 referenceTaskIndex, uint256 blockNumber, bytes32 blockCommitment);

    event TaskResponded(string clusterId, string rollupId, uint256 referenceTaskIndex, bool response, address responder);

    event RewardsDistributed(string clusterId, string rollupId, uint256 referenceTaskIndex);

    event TaskThresholdMet(string clusterId, string rollupId, uint256 referenceTaskIndex);
    event DistributionDataSaved(string clusterId, string rollupId, uint256 rewardedTaskindex);
    
    // Event for successful direct slash
    event OperatorSlashed(address indexed vault, address indexed operator, uint256 amount, bool isVeto);

    // Event for veto slash request
    event OperatorSlashRequested(address indexed vault, address indexed operator, uint256 amount, uint256 slashIndex);
    event SlashRequestSubmitted(uint256 indexed requestId, address indexed submitter, uint256 blockNumber, bytes32 txHash);
    event SlashResponseSubmitted(uint256 indexed requestId, address indexed responder, bool isValid);
    event SlashRequestResolved(uint256 indexed requestId, bool wasValid);


    event SlashRequested(
        bytes32 indexed txHash,
        address indexed operator,
        address indexed requester,
        string rollupId,
        uint256 blockHeight
    );

    event SlashResponded(
        bytes32 indexed txHash,
        address indexed operator,
        address indexed requester,
        bool isValid,
        Status newStatus
    );



}



