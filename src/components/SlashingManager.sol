// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {IValidationServiceManager} from "src/interfaces/IValidationServiceManager.sol";

contract SlashingManager is Ownable {

    address public immutable NETWORK;
    mapping(bytes32 => IValidationServiceManager.SlashRequest) public slashRequests;

    constructor(
        address _network
    ) Ownable(msg.sender) {
        NETWORK = _network;
    }



    function storeSlashRequest(
        address operator,
        address requester,
        string calldata rollupId,
        uint256 blockHeight,
        bytes32 txHash,
        uint256 txOrder,
        bytes32[] calldata preMerklePath,
        bytes calldata signature,
        uint256 depositAmount
    ) external onlyOwner {
        // Store the slash request data
        IValidationServiceManager.SlashRequest storage newRequest = slashRequests[txHash];
        newRequest.operator = operator;
        newRequest.requester = requester;
        newRequest.rollupId = rollupId;
        newRequest.blockHeight = blockHeight;
        newRequest.txHash = txHash;
        newRequest.txOrder = txOrder;
        newRequest.signature = signature;
        newRequest.depositAmount = depositAmount;
        newRequest.status = IValidationServiceManager.Status.Pending;
        newRequest.exists = true;

        // Store pre-merkle-path
        for (uint i = 0; i < preMerklePath.length; i++) {
            newRequest.preMerklePath.push(preMerklePath[i]);
        }
    }

    function getPreMerklePath(bytes32 txHash) external view returns (bytes32[] memory) {
        require(slashRequests[txHash].exists, "Slash request does not exist");
        return slashRequests[txHash].preMerklePath;
    }

    function getSlashRequestDetails(bytes32 txHash) external view returns (IValidationServiceManager.SlashRequest memory) {
         return slashRequests[txHash];
    }

    function validateMerkleProof(
        bytes32 txHash,
        bytes32 merkleRoot,
        bytes32[] calldata postMerklePath
    ) external view returns (bool isValid) {
        require(slashRequests[txHash].exists, "Slash request does not exist");
        IValidationServiceManager.SlashRequest storage slashRequest = slashRequests[txHash];
        require(slashRequest.status == IValidationServiceManager.Status.Pending, "Slash request already processed");

        // Retrieve stored data needed for calculation
        bytes32 currentHash = slashRequest.txHash;
        uint256 currentIndex = slashRequest.txOrder;

        // Process Pre-Merkle-Path
        for (uint i = 0; i < slashRequest.preMerklePath.length; i++) {
            bytes32 siblingHash = slashRequest.preMerklePath[i];
            if (currentIndex % 2 == 0) {
                currentHash = keccak256(abi.encodePacked(currentHash, siblingHash));
            } else {
                currentHash = keccak256(abi.encodePacked(siblingHash, currentHash));
            }
            currentIndex = currentIndex / 2;
        }

        // Process Post-Merkle-Path
        for (uint i = 0; i < postMerklePath.length; i++) {
            bytes32 siblingHash = postMerklePath[i];
            if (currentIndex % 2 == 0) {
                currentHash = keccak256(abi.encodePacked(currentHash, siblingHash));
            } else {
                currentHash = keccak256(abi.encodePacked(siblingHash, currentHash));
            }
            currentIndex = currentIndex / 2;
        }

        // Calculate validity
        bytes32 finalHash = currentHash;
        return (finalHash == merkleRoot);
    }

    function updateSlashRequestStatus(bytes32 txHash, IValidationServiceManager.Status status) external onlyOwner {
        require(slashRequests[txHash].exists, "Slash request does not exist");
        slashRequests[txHash].status = status;
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature)
        public
        pure
        returns (address)
    {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract r, s, v from signature
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // Adjust v value (legacy reasons)
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature 'v' value");

        return ecrecover(ethSignedMessageHash, v, r, s);
    }
}