// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interfaces/ILivenessRadius.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract LivenessRadius is 
    Ownable,
    ILivenessRadius
{
    uint256 public constant BLOCK_MARGIN = 7;

    mapping(string => Cluster) private clusters;
    mapping(address => string[]) private clusterByOwner;
    mapping(address => string[]) private clusterBySequencer;

    string[] private allClusterIds;

    /// @notice Contract constructor logic
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() Ownable(msg.sender) {}

    function initializeCluster(string calldata clusterId, uint256 maxSequencerNumber) public {
        Cluster storage cluster = clusters[clusterId];

        require(
            cluster.owner == address(0),
            "Already initialized cluster"
        );

        cluster.owner = msg.sender;
        cluster.maxSequencerNumber = maxSequencerNumber;
        cluster.currentSequencerCount = 0;

        for (uint256 i = 0; i < maxSequencerNumber; i++) {
            cluster.emptySlots.push(maxSequencerNumber - 1 - i);
            cluster.sequencerAddresses.push(address(0));
        }

        allClusterIds.push(clusterId);
        clusterByOwner[msg.sender].push(clusterId);

        emit InitializeCluster(clusterId, msg.sender, maxSequencerNumber);
    }

    function addRollup(string calldata clusterId, AddRollupInfo calldata rollupInfo) public {
        Cluster storage cluster = clusters[clusterId];

        require(
            cluster.owner == msg.sender,
            "Not cluster owner"
        );

        Rollup storage rollup = cluster.rollups[rollupInfo.rollupId];

        require(
            rollup.owner == address(0),
            "Already added rollup"
        );
        
        cluster.rollupIdList.push(rollupInfo.rollupId);

        rollup.owner = rollupInfo.owner;
        rollup.rollupType = rollupInfo.rollupType;
        rollup.encryptedTransactionType = rollupInfo.encryptedTransactionType;
        rollup.orderCommitmentType = rollupInfo.orderCommitmentType;
        rollup.validationInfo = rollupInfo.validationInfo;
        rollup.isRegisteredExecutor[rollupInfo.owner] = true;
        
        rollup.executorAddresses.push(rollupInfo.executorAddress);

        emit AddRollup(clusterId, rollupInfo.rollupId, rollupInfo.owner);
    }

    function registerRollupExecutor(string calldata clusterId, string calldata rollupId, address executorAddress) public {
        Cluster storage cluster = clusters[clusterId];

        require(
            cluster.owner != address(0),
            "Not initialized cluster"
        );

        Rollup storage rollup = cluster.rollups[rollupId];

        require(
            rollup.owner == msg.sender,
            "Not rollup owner"
        );

        rollup.isRegisteredExecutor[executorAddress] = true;
        rollup.executorAddresses.push(executorAddress);

        emit RegisterRollupExecutor(clusterId, rollupId, executorAddress);
    }

    function registerSequencer(string calldata clusterId) public {
        Cluster storage cluster = clusters[clusterId];

        require(
            cluster.owner != address(0),
            "Proposer set not initialized"
        );
        require(
            !cluster.isRegisteredSequencer[msg.sender],
            "Already registered sequencer"
        );
        require(
            cluster.currentSequencerCount < cluster.maxSequencerNumber,
            "Max sequencer count exceeded"
        );

        uint256 slotIndex = cluster.emptySlots[cluster.emptySlots.length - 1];
        cluster.emptySlots.pop();

        cluster.isRegisteredSequencer[msg.sender] = true;

        cluster.sequencerAddresses[slotIndex] = msg.sender;
        cluster.sequencerIndex[msg.sender] = slotIndex;
        cluster.currentSequencerCount++;

        clusterBySequencer[msg.sender].push(clusterId);

        emit RegisterSequencer(clusterId, msg.sender, slotIndex);
    }

    function deregisterSequencer(string calldata clusterId) public {
        Cluster storage cluster = clusters[clusterId];

        require(
            cluster.owner != address(0),
            "Proposer set not initialized"
        );
        require(
            cluster.isRegisteredSequencer[msg.sender],
            "Not registered sequencer"
        );

        cluster.isRegisteredSequencer[msg.sender] = false;

        uint256 index = cluster.sequencerIndex[msg.sender];
        cluster.sequencerAddresses[index] = address(0);

        delete cluster.sequencerIndex[msg.sender];
        cluster.currentSequencerCount--;
        cluster.emptySlots.push(index);

        // Remove from clusterBySequencer array
        string[] storage sequencerSets = clusterBySequencer[msg.sender];
        for (uint i = 0; i < sequencerSets.length; i++) {
            // if (sequencerSets[i] == clusterId) {
            if (keccak256(bytes(sequencerSets[i])) == keccak256(bytes(clusterId))) {
                sequencerSets[i] = sequencerSets[sequencerSets.length - 1];
                sequencerSets.pop();
                break;
            }
        }

        emit DeregisterSequencer(clusterId, msg.sender);
    }

    function getSequencerList(
        string calldata clusterId
    )
        public
        view
        returns (address[] memory)
    {
        Cluster storage cluster = clusters[clusterId];
        uint256 count = 0;
        address[] memory validSequencers = new address[](cluster.maxSequencerNumber);

        for (uint256 i = 0; i < cluster.maxSequencerNumber; i++) {
            if (cluster.sequencerAddresses[i] != address(0)) {
                validSequencers[count] = cluster.sequencerAddresses[i];
                count++;
            }
        }
        return validSequencers;
    }

    function getExecutorList(
        string calldata clusterId,
        string calldata rollupId
    )
        public
        view
        returns (address[] memory)
    {
        Cluster storage cluster = clusters[clusterId];
        Rollup storage rollup = cluster.rollups[rollupId];

        // Count non-zero addresses first
        uint256 count = 0;
        for (uint256 i = 0; i < rollup.executorAddresses.length; i++) {
            if (rollup.executorAddresses[i] != address(0)) {
                count++;
            }
        }

        // Create a memory array with the correct size
        address[] memory executorAddressList = new address[](count);

        // Populate the memory array with non-zero addresses
        uint256 index = 0;
        for (uint256 i = 0; i < rollup.executorAddresses.length; i++) {
            if (rollup.executorAddresses[i] != address(0)) {
                executorAddressList[index] = rollup.executorAddresses[i];
                index++;
            }
        }

        return executorAddressList;
    }

    function getRollupInfoList(string calldata clusterId) public view returns (RollupInfo[] memory) {
        Cluster storage cluster = clusters[clusterId];

        require(
            cluster.owner != address(0),
            "Not initialized cluster"
        );
        
        RollupInfo[] memory rollupList = new RollupInfo[](cluster.rollupIdList.length);
        for (uint256 i = 0; i < cluster.rollupIdList.length; i++) {
            Rollup storage rollup = cluster.rollups[cluster.rollupIdList[i]];

            rollupList[i] = RollupInfo({
                rollupId: cluster.rollupIdList[i],
                owner: rollup.owner,
                rollupType: rollup.rollupType,
                encryptedTransactionType: rollup.encryptedTransactionType,
                validationInfo: rollup.validationInfo,
                orderCommitmentType: rollup.orderCommitmentType,
                executorAddresses: rollup.executorAddresses
            });

        }
        return rollupList;
    }

    function getRollupInfo(string calldata clusterId, string calldata rollupId) public view returns (RollupInfo memory) {
        Cluster storage cluster = clusters[clusterId];

        require(
            cluster.owner != address(0),
            "Not initialized cluster"
        );

        Rollup storage rollup = cluster.rollups[rollupId];

        require(
            rollup.owner != address(0),
            "Not added rollup"
        );

        RollupInfo memory rollupInfo = RollupInfo({
            rollupId: rollupId,
            owner: rollup.owner,
            rollupType: rollup.rollupType,
            encryptedTransactionType: rollup.encryptedTransactionType,
            validationInfo: rollup.validationInfo,
            orderCommitmentType: rollup.orderCommitmentType,
            executorAddresses: rollup.executorAddresses
        });
          
        return rollupInfo;
    }

    function getMaxSequencerNumber(string calldata clusterId) public view returns (uint256) {
        return clusters[clusterId].maxSequencerNumber;
    }

    function isAddedRollup(
        string calldata clusterId, string calldata rollupId
    ) public view returns (bool) {
        return
            clusters[clusterId].rollups[rollupId].owner != address(0);
    }

    function isRegisteredRollupExecutor(
        string calldata clusterId, string calldata rollupId, address executorAddress
    ) public view returns (bool) {
        return
            clusters[clusterId].rollups[rollupId].isRegisteredExecutor[executorAddress];
    }

    function isRegisteredSequencer(
        string calldata clusterId,
        address sequencerAddress
    ) public view returns (bool) {
        return
            clusters[clusterId].isRegisteredSequencer[sequencerAddress];
    }

    function getClustersByOwner(
        address owner
    ) public view returns (string[] memory) {
        return clusterByOwner[owner];
    }

    function getClustersBySequencer(
        address sequencer
    ) public view returns (string[] memory) {
        return clusterBySequencer[sequencer];
    }

    function getAllClusterIds() public view returns (string[] memory) {
        return allClusterIds;
    }
}
