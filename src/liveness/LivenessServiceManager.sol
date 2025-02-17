// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interfaces/ILivenessServiceManager.sol";

contract LivenessServiceManager is Ownable, ILivenessServiceManager {
    uint256 public constant BLOCK_MARGIN = 7;

    mapping(string => Cluster) private clusters;
    mapping(address => string[]) private clusterIdsByOwner;
    mapping(address => string[]) private clusterIdsByTxOrderer;

    string[] private allClusterIds;

    mapping(string => mapping(string => Rollup)) public rollups;
    mapping(string => mapping(address => bool)) public isTxOrdererRegistered;
    mapping(string => mapping(string => mapping(address => bool))) public isExecutorRegistered;
    
    constructor() Ownable(msg.sender) {}

    ///////////// Cluster management
    function initializeCluster(string calldata clusterId, uint256 maxTxOrdererNumber) public override {
        Cluster storage cluster = clusters[clusterId];

        if (cluster.owner != address(0)) {
            revert AlreadyInitializedCluster();
        }

        cluster.id = clusterId;
        cluster.owner = msg.sender;
        cluster.maxTxOrdererNumber = maxTxOrdererNumber;
        cluster.currentTxOrdererCount = 0;

        for (uint256 i = 0; i < maxTxOrdererNumber; i++) {
            cluster.txOrderers.push(address(0));
        }

        clusterIdsByOwner[msg.sender].push(clusterId);
        allClusterIds.push(clusterId);

        emit InitializedCluster(clusterId, msg.sender, maxTxOrdererNumber);
    }

    function getAllClusterIds() public view override returns (string[] memory) {
        return allClusterIds;
    }

    function getMaxTxOrdererNumber(string calldata clusterId) public view override returns (uint256) {
        return clusters[clusterId].maxTxOrdererNumber;
    }

    function getClusterIdsByOwner(address owner) public view override returns (string[] memory) {
        return clusterIdsByOwner[owner];
    }

    function getClusterIdsByTxOrderer(address txOrderer) public view override returns (string[] memory) {
        return clusterIdsByTxOrderer[txOrderer];
    }

    ///////////// Rollup management
    function addRollup(string calldata clusterId, NewRollup calldata newRollup) public override {
        Cluster storage cluster = clusters[clusterId];

        if (cluster.owner != msg.sender) {
            revert NotClusterOwner();
        }

        Rollup storage rollup = rollups[clusterId][newRollup.rollupId];

        if (rollup.owner != address(0)) {
            revert AlreadyAddedRollup();
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

    function isRollupAdded(string calldata clusterId, string calldata rollupId) public view override returns (bool) {
        return rollups[clusterId][rollupId].owner != address(0);
    }

    function getRollups(string calldata clusterId) public view override returns (Rollup[] memory) {
        Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert NotInitializedCluster();
        }
        
        uint256 rollupCount = cluster.rollupIds.length;
        Rollup[] memory clusterRollups = new Rollup[](rollupCount);

        for (uint256 i = 0; i < rollupCount; i++) {
            string memory rollupId = cluster.rollupIds[i];
            clusterRollups[i] = rollups[clusterId][rollupId];
        }
        return clusterRollups;
    }

    function getRollup(string calldata clusterId, string calldata rollupId) public view override returns (Rollup memory) {
        Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert NotInitializedCluster();
        }

        Rollup storage rollup = rollups[clusterId][rollupId];

        if (rollup.owner == address(0)) {
            revert NotAddedRollup();
        }
          
        return rollup;
    }

    ///////////// TxOrderer management
    function registerTxOrderer(string calldata clusterId) public override {
        Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert NotInitializedCluster();
        }

        if (isTxOrdererRegistered[clusterId][msg.sender]) {
            revert AlreadyRegisteredTxOrderer();
        }

        if (cluster.currentTxOrdererCount >= cluster.maxTxOrdererNumber) {
            revert ExceededMaxTxOrdererNumber();
        }

        for (uint256 i = 0; i < cluster.txOrderers.length; i++) {
            if (cluster.txOrderers[i] == address(0)) {
                cluster.txOrderers[i] = msg.sender;
                isTxOrdererRegistered[clusterId][msg.sender] = true;
                cluster.currentTxOrdererCount++;
                
                clusterIdsByTxOrderer[msg.sender].push(clusterId);

                emit RegisteredTxOrderer(clusterId, msg.sender, i);
                return;
            }
        }

        revert ExceededMaxTxOrdererNumber();
    }

    function deregisterTxOrderer(string calldata clusterId) public override {
        Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert NotInitializedCluster();
        }

        if (!isTxOrdererRegistered[clusterId][msg.sender]) {
            revert NotRegisteredTxOrderer();
        }

        for (uint256 i = 0; i < cluster.txOrderers.length; i++) {
            if (cluster.txOrderers[i] == msg.sender) {
                cluster.txOrderers[i] = address(0);
                break;
            }
        }

        isTxOrdererRegistered[clusterId][msg.sender] = false;
        cluster.currentTxOrdererCount--;

        string[] storage clusterIds = clusterIdsByTxOrderer[msg.sender];        
        for (uint i = 0; i < clusterIds.length; i++) {
            if (keccak256(bytes(clusterIds[i])) == keccak256(bytes(clusterId))) {
                clusterIds[i] = clusterIds[clusterIds.length - 1];
                clusterIds.pop();
                break;
            }
        }
        emit DeregisteredTxOrderer(clusterId, msg.sender);
    }

    function getTxOrderers(string calldata clusterId) public view override returns (address[] memory) {
        Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert NotInitializedCluster();
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
    function registerRollupExecutor(string calldata clusterId, string calldata rollupId, address executor) public override {
        Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert NotInitializedCluster();
        }

        Rollup storage rollup = rollups[clusterId][rollupId];

        if (rollup.owner == address(0)) {
            revert NotAddedRollup();
        }

        if (rollup.owner != msg.sender) {
            revert NotRollupOwner();
        }

        if (isExecutorRegistered[clusterId][rollupId][executor]) {
            revert AlreadyRegisteredExecutor();
        }

        isExecutorRegistered[clusterId][rollupId][executor] = true;
        rollup.executors.push(executor);

        emit RegisteredRollupExecutor(clusterId, rollupId, executor);
    }

    function getExecutors(string calldata clusterId, string calldata rollupId) public view override returns (address[] memory) {
        Cluster storage cluster = clusters[clusterId];

        if (cluster.owner == address(0)) {
            revert NotInitializedCluster();
        }

        Rollup storage rollup = rollups[clusterId][rollupId];

        if (rollup.owner == address(0)) {
            revert NotAddedRollup();
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

    function isRollupExecutorRegistered(string calldata clusterId, string calldata rollupId, address executor) public view override returns (bool) {
        return isExecutorRegistered[clusterId][rollupId][executor];
    }
}
