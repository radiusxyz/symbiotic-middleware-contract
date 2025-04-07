// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ILivenessServiceManager {
    error NotInitializedCluster();
    error NotAddedRollup();
    error NotRegisteredTxOrderer();
  
    error AlreadyInitializedCluster();
    error AlreadyAddedRollup();
    error AlreadyRegisteredTxOrderer();
    error AlreadyRegisteredExecutor();

    error NotClusterOwner();
    error NotRollupOwner();

    error ExceededMaxTxOrdererNumber();

    struct ValidationInfo {
        string platform;
        string serviceProvider;
        address validationServiceManager;
    }

    struct Cluster {
        string id;
        address owner;

        uint256 maxTxOrdererNumber;
        uint256 currentTxOrdererCount;
        address[] txOrderers;
        
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
  
    function initializeCluster(string calldata clusterId, uint256 maxTxOrdererNumber) external;
    function getAllClusterIds() external view returns (string[] memory);
    function getMaxTxOrdererNumber(string calldata clusterId) external view returns (uint256);
    function getClusterIdsByOwner(address owner) external view returns (string[] memory);
    function getClusterIdsByTxOrderer(address txOrderer) external view returns (string[] memory);

    function addRollup(string calldata clusterId, NewRollup calldata newRollup) external;
    function isRollupAdded(string calldata clusterId, string calldata rollupId) external view returns (bool);
    function getRollups(string calldata clusterId) external view returns (Rollup[] memory);
    function getRollup(string calldata clusterId, string calldata rollupId) external view returns (Rollup memory);

    function registerTxOrderer(string calldata clusterId) external;
    function deregisterTxOrderer(string calldata clusterId) external;
    function getTxOrderers(string calldata clusterId) external view returns (address[] memory);

    function registerRollupExecutor(string calldata clusterId, string calldata rollupId, address executor) external;
    function getExecutors(string calldata clusterId, string calldata rollupId) external view returns (address[] memory);
    function isRollupExecutorRegistered(string calldata clusterId, string calldata rollupId, address executor) external view returns (bool);
    
    event InitializedCluster(string clusterId, address owner, uint256 maxTxOrdererNumber);
    
    event RegisteredTxOrderer(string clusterId, address txOrderer, uint256 index);
    event DeregisteredTxOrderer(string clusterId, address txOrderer);

    event RegisteredRollupExecutor(string clusterId, string rollupId, address executor);

    event AddedRollup(string clusterId, string rollupId, address rollupOwner);
}
