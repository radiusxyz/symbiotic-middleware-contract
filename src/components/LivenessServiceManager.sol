// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import "src/interfaces/ILivenessServiceManager.sol";

contract LivenessServiceManager is Ownable {
    uint256 public constant BLOCK_MARGIN = 7;

    mapping(string => ILivenessServiceManager.Cluster) private clusters;
    mapping(address => string[]) private clusterIdsByOwner;
    mapping(address => string[]) private clusterIdsByTxOrderer;

    string[] private allClusterIds;

    mapping(string => mapping(string => ILivenessServiceManager.Rollup)) public rollups;
    mapping(string => mapping(address => bool)) public isTxOrdererRegistered;
    mapping(string => mapping(string => mapping(address => bool))) public isExecutorRegistered;
    
    // Events from ILivenessServiceManager
    event InitializedCluster(string clusterId, address owner, uint256 maxTxOrdererNumber);
    event RegisteredTxOrderer(string clusterId, address txOrderer, uint256 index);
    event DeregisteredTxOrderer(string clusterId, address txOrderer);
    event RegisteredRollupExecutor(string clusterId, string rollupId, address executor);
    event AddedRollup(string clusterId, string rollupId, address rollupOwner);

    constructor() Ownable(msg.sender) {}

    ///////////// Cluster management
    function initializeCluster(string calldata clusterId, uint256 maxTxOrdererNumber, address sender) external onlyOwner {
        ILivenessServiceManager.Cluster storage cluster = clusters[clusterId];

        if (cluster.owner != address(0)) {
            revert ILivenessServiceManager.AlreadyInitializedCluster();
        }

        cluster.id = clusterId;
        cluster.owner = sender;
        cluster.maxTxOrdererNumber = maxTxOrdererNumber;
        cluster.currentTxOrdererCount = 0;

        for (uint256 i = 0; i < maxTxOrdererNumber; i++) {
            cluster.txOrderers.push(address(0));
        }

        clusterIdsByOwner[sender].push(clusterId);
        allClusterIds.push(clusterId);

        emit InitializedCluster(clusterId, sender, maxTxOrdererNumber);
    }

    function getAllClusterIds() public view returns (string[] memory) {
        return allClusterIds;
    }

    function getMaxTxOrdererNumber(string calldata clusterId) public view returns (uint256) {
        return clusters[clusterId].maxTxOrdererNumber;
    }

    function getClusterIdsByOwner(address owner) public view returns (string[] memory) {
        return clusterIdsByOwner[owner];
    }

    function getClusterIdsByTxOrderer(address txOrderer) public view returns (string[] memory) {
        return clusterIdsByTxOrderer[txOrderer];
    }

    ///////////// Rollup management
    function addRollup(
        string calldata clusterId, 
        ILivenessServiceManager.NewRollup calldata newRollup, 
        address sender
    ) external onlyOwner {
        ILivenessServiceManager.Cluster storage cluster = clusters[clusterId];

        if (cluster.owner != sender) {
            revert ILivenessServiceManager.NotClusterOwner();
        }

        ILivenessServiceManager.Rollup storage rollup = rollups[clusterId][newRollup.rollupId];

        if (rollup.owner != address(0)) {
            revert ILivenessServiceManager.AlreadyAddedRollup();
        }
        
        cluster.rollupIds.push(newRollup.rollupId);

        rollup.id = newRollup.rollupId;
        rollup.owner = newRollup.owner;
        rollup.rollupType = newRollup.rollupType;
        rollup.encryptedTransactionType = newRollup.encryptedTransactionType;
        rollup.orderCommitmentType = newRollup.orderCommitmentType;
        
        rollup.executors.push(newRollup.executor);
        
        isExecutorRegistered[clusterId][newRollup.rollupId][newRollup.executor] = true;
        
        rollup.validationInfo = newRollup.validationInfo;

        emit AddedRollup(clusterId, newRollup.rollupId, newRollup.owner);
    }

    function isRollupAdded(string calldata clusterId, string calldata rollupId) public view returns (bool) {
        return rollups[clusterId][rollupId].owner != address(0);
    }

    function getRollups(string calldata clusterId) public view returns (ILivenessServiceManager.Rollup[] memory) {
        ILivenessServiceManager.Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert ILivenessServiceManager.NotInitializedCluster();
        }
        
        uint256 rollupCount = cluster.rollupIds.length;
        ILivenessServiceManager.Rollup[] memory clusterRollups = new ILivenessServiceManager.Rollup[](rollupCount);

        for (uint256 i = 0; i < rollupCount; i++) {
            string memory rollupId = cluster.rollupIds[i];
            clusterRollups[i] = rollups[clusterId][rollupId];
        }
        return clusterRollups;
    }

    function getRollup(string calldata clusterId, string calldata rollupId) public view returns (ILivenessServiceManager.Rollup memory) {
        ILivenessServiceManager.Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert ILivenessServiceManager.NotInitializedCluster();
        }

        ILivenessServiceManager.Rollup storage rollup = rollups[clusterId][rollupId];

        if (rollup.owner == address(0)) {
            revert ILivenessServiceManager.NotAddedRollup();
        }
          
        return rollup;
    }

    ///////////// TxOrderer management
    function registerTxOrderer(string calldata clusterId, address sender) external onlyOwner {
        ILivenessServiceManager.Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert ILivenessServiceManager.NotInitializedCluster();
        }

        if (isTxOrdererRegistered[clusterId][sender]) {
            revert ILivenessServiceManager.AlreadyRegisteredTxOrderer();
        }

        if (cluster.currentTxOrdererCount >= cluster.maxTxOrdererNumber) {
            revert ILivenessServiceManager.ExceededMaxTxOrdererNumber();
        }

        for (uint256 i = 0; i < cluster.txOrderers.length; i++) {
            if (cluster.txOrderers[i] == address(0)) {
                cluster.txOrderers[i] = sender;
                isTxOrdererRegistered[clusterId][sender] = true;
                cluster.currentTxOrdererCount++;
                
                clusterIdsByTxOrderer[sender].push(clusterId);

                emit RegisteredTxOrderer(clusterId, sender, i);
                return;
            }
        }

        revert ILivenessServiceManager.ExceededMaxTxOrdererNumber();
    }

    function deregisterTxOrderer(string calldata clusterId, address sender) external onlyOwner {
        ILivenessServiceManager.Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert ILivenessServiceManager.NotInitializedCluster();
        }

        if (!isTxOrdererRegistered[clusterId][sender]) {
            revert ILivenessServiceManager.NotRegisteredTxOrderer();
        }

        for (uint256 i = 0; i < cluster.txOrderers.length; i++) {
            if (cluster.txOrderers[i] == sender) {
                cluster.txOrderers[i] = address(0);
                break;
            }
        }

        isTxOrdererRegistered[clusterId][sender] = false;
        cluster.currentTxOrdererCount--;

        string[] storage clusterIds = clusterIdsByTxOrderer[sender];        
        for (uint i = 0; i < clusterIds.length; i++) {
            if (keccak256(bytes(clusterIds[i])) == keccak256(bytes(clusterId))) {
                clusterIds[i] = clusterIds[clusterIds.length - 1];
                clusterIds.pop();
                break;
            }
        }
        emit DeregisteredTxOrderer(clusterId, sender);
    }

    function getTxOrderers(string calldata clusterId) public view returns (address[] memory) {
        ILivenessServiceManager.Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert ILivenessServiceManager.NotInitializedCluster();
        }

        uint256 txOrdererIndex = 0;
        address[] memory txOrderers = new address[](cluster.currentTxOrdererCount);
        for (uint256 i = 0; i < cluster.txOrderers.length; i++) {
            if (cluster.txOrderers[i] != address(0)) {
                txOrderers[txOrdererIndex++] = cluster.txOrderers[i];
            }
        }
        return txOrderers;
    }

    ///////////// Executor management
    function registerRollupExecutor(
        string calldata clusterId, 
        string calldata rollupId, 
        address executor, 
        address sender
    ) external onlyOwner {
        ILivenessServiceManager.Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert ILivenessServiceManager.NotInitializedCluster();
        }

        ILivenessServiceManager.Rollup storage rollup = rollups[clusterId][rollupId];

        if (rollup.owner == address(0)) {
            revert ILivenessServiceManager.NotAddedRollup();
        }

        if (rollup.owner != sender) {
            revert ILivenessServiceManager.NotRollupOwner();
        }

        if (isExecutorRegistered[clusterId][rollupId][executor]) {
            revert ILivenessServiceManager.AlreadyRegisteredExecutor();
        }

        isExecutorRegistered[clusterId][rollupId][executor] = true;
        rollup.executors.push(executor);

        emit RegisteredRollupExecutor(clusterId, rollupId, executor);
    }

    function getExecutors(string calldata clusterId, string calldata rollupId) public view returns (address[] memory) {
        ILivenessServiceManager.Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert ILivenessServiceManager.NotInitializedCluster();
        }

        ILivenessServiceManager.Rollup storage rollup = rollups[clusterId][rollupId];

        if (rollup.owner == address(0)) {
            revert ILivenessServiceManager.NotAddedRollup();
        }

        uint256 count = 0;
        for (uint256 i = 0; i < rollup.executors.length; i++) {
            if (rollup.executors[i] != address(0)) {
                count++;
            }
        }

        address[] memory executors = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < rollup.executors.length; i++) {
            if (rollup.executors[i] != address(0)) {
                executors[index] = rollup.executors[i];
                index++;
            }
        }

        return executors;
    }

    function isRollupExecutorRegistered(string calldata clusterId, string calldata rollupId, address executor) public view returns (bool) {
        return isExecutorRegistered[clusterId][rollupId][executor];
    }

}