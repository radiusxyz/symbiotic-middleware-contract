// SPDX-License-Identifier: MIT
//Interface contract for Bundler.sol
pragma solidity ^0.8.24;

interface ILivenessRadius {
    struct Cluster {
        address owner; // Owner is rollup contract address

        mapping(address => bool) isRegisteredSequencer;
        mapping(address => uint256) sequencerIndex; // Maps address to index in the array

        address[] sequencerAddresses;
        uint256 maxSequencerNumber;
        uint256 currentSequencerCount;
        uint256[] emptySlots; // Keeps track of empty slots

        mapping(string => Rollup) rollups;
        string[] rollupIdList;
    }

    struct Rollup {
        address owner;
        string rollupType;
        string encryptedTransactionType;  
        ValidationInfo validationInfo;
        string orderCommitmentType;

        mapping(address => bool) isRegisteredExecutor;
        address[] executorAddresses;
    }

    struct AddRollupInfo {
        string rollupId;
        address owner;
        string rollupType;
        string encryptedTransactionType;
        string orderCommitmentType;
        address executorAddress;
        ValidationInfo validationInfo;
    }

    struct RollupInfo {
        string rollupId;
        address owner;
        string rollupType;
        string encryptedTransactionType;
        string orderCommitmentType;
        address[] executorAddresses;
        ValidationInfo validationInfo;
    }


    struct ValidationInfo {
        string platform;
        string serviceProvider;
        address validationServiceManager;
    }

    function initializeCluster(string calldata clusterId, uint256 maxSequencerNumber) external;
    function addRollup(string calldata clusterId, AddRollupInfo calldata rollupInfo) external;
    function registerRollupExecutor(string calldata clusterId, string calldata rollupId, address rollupExecutorAddress) external;

    function isAddedRollup(string calldata clusterId, string calldata rollupId) external view returns (bool);
    function isRegisteredRollupExecutor(string calldata clusterId, string calldata rollupId, address executorAddress) external view returns (bool);
    function isRegisteredSequencer(string calldata clusterId, address sequencerAddress) external view returns (bool);

    function registerSequencer(string calldata clusterId) external;
    function deregisterSequencer(string calldata clusterId) external;

    function getSequencerList(string calldata clusterId) external view returns (address[] memory);
    function getExecutorList(string calldata clusterId, string calldata rollupId) external view returns (address[] memory);
    function getRollupInfoList(string calldata clusterId) external view returns (RollupInfo[] memory);
    function getRollupInfo(string calldata clusterId, string calldata rollupId) external view returns (RollupInfo memory);
    
    function getMaxSequencerNumber(string calldata clusterId) external view returns (uint256);
    
    function getAllClusterIds() external view returns (string[] memory) ;
    function getClustersByOwner(address owner) external view returns (string[] memory) ;
    function getClustersBySequencer(address sequencer) external view returns (string[] memory);
    
    event InitializeCluster(string clusterId, address owner, uint256 maxSequencerNumber);
    event RegisterSequencer(
        string clusterId,
        address sequencerAddress,
        uint256 index
    );
    event DeregisterSequencer(string clusterId, address sequencerAddress);
    event AddRollup(string clusterId, string rollupId, address rollupOwnerAddress);
    event RegisterRollupExecutor(string clusterId, string rollupId, address executorAddress);
}
