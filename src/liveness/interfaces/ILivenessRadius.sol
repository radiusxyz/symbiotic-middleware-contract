// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ILivenessRadius {
    error NotInitializedCluster();
    error NotAddedRollup();
    error NotRegisteredSequencer();
  
    error AlreadyInitializedCluster();
    error AlreadyAddedRollup();
    error AlreadyRegisteredSequencer();
    error AlreadyRegisteredExecutor();

    error NotClusterOwner();
    error NotRollupOwner();

    error ExceededMaxSequencerNumber();

    struct ValidationInfo {
        string platform;
        string serviceProvider;
        address validationServiceManager;
    }

    struct Cluster {
        string id;
        address owner;

        uint256 maxSequencerNumber;
        uint256 currentSequencerCount;
        address[] sequencers;
        
        string[] rollupIds;
        
    }

    struct Rollup {
        string id;
        address owner;
        string rollupType;
        string encryptedTransactionType;
        string orderCommitmentType;
        
        address[] executors;
        ValidationInfo validationInfo;
    }

    struct NewRollup {
        string rollupId;
        address owner;
        string rollupType;
        string encryptedTransactionType;
        string orderCommitmentType;

        address executor;

        ValidationInfo validationInfo;
    }
  
    function initializeCluster(string calldata clusterId, uint256 maxSequencerNumber) external;
    function getAllClusterIds() external view returns (string[] memory);
    function getMaxSequencerNumber(string calldata clusterId) external view returns (uint256);
    function getClusterIdsByOwner(address owner) external view returns (string[] memory);
    function getClusterIdsBySequencer(address sequencer) external view returns (string[] memory);

    function addRollup(string calldata clusterId, NewRollup calldata newRollup) external;
    function isRollupAdded(string calldata clusterId, string calldata rollupId) external view returns (bool);
    function getRollups(string calldata clusterId) external view returns (Rollup[] memory);
    function getRollup(string calldata clusterId, string calldata rollupId) external view returns (Rollup memory);

    function registerSequencer(string calldata clusterId) external;
    function deregisterSequencer(string calldata clusterId) external;
    function getSequencers(string calldata clusterId) external view returns (address[] memory);

    function registerRollupExecutor(string calldata clusterId, string calldata rollupId, address executor) external;
    function getExecutors(string calldata clusterId, string calldata rollupId) external view returns (address[] memory);
    function isRollupExecutorRegistered(string calldata clusterId, string calldata rollupId, address executor) external view returns (bool);
    
    event InitializedCluster(string clusterId, address owner, uint256 maxSequencerNumber);
    
    event RegisteredSequencer(string clusterId, address sequencer, uint256 index);
    event DeregisteredSequencer(string clusterId, address sequencer);

    event RegisteredRollupExecutor(string clusterId, string rollupId, address executor);

    event AddedRollup(string clusterId, string rollupId, address rollupOwner);
}
