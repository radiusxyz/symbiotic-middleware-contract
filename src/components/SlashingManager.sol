// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {IValidationServiceManager} from "src/interfaces/IValidationServiceManager.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IBaseSlasher} from "@symbiotic-core/src/interfaces/slasher/IBaseSlasher.sol";
import {ISlasher} from "@symbiotic-core/src/interfaces/slasher/ISlasher.sol";
import {IVetoSlasher} from "@symbiotic-core/src/interfaces/slasher/IVetoSlasher.sol";

contract SlashingManager is Ownable, ReentrancyGuard {

    address public immutable NETWORK;
    mapping(bytes32 => IValidationServiceManager.SlashRequest) public slashRequests;

    uint64 public constant INSTANT_SLASHER_TYPE = 0;
    uint64 public constant VETO_SLASHER_TYPE = 1;
    uint256 public constant SLASH_BASIS_POINTS = 5;  

    mapping(bytes32 => IValidationServiceManager.SlashCredit) public slashCredits;
    
    bytes32[] public slashCreditTxHashes;

    constructor(
        address _network
    ) Ownable(msg.sender) {
        NETWORK = _network;
    }

    function u64LE(uint64 n) internal pure returns (bytes memory) {
        bytes memory result = new bytes(8);
        
        for (uint i = 0; i < 8; i++) {
            result[i] = bytes1(uint8(n & 0xFF));
            n >>= 8;
        }
        
        return result;
    }

    function encodeString(string memory s) internal pure returns (bytes memory) {
        bytes memory strBytes = bytes(s);
        
        return abi.encodePacked(
            u64LE(uint64(strBytes.length)),
            strBytes
        );
    }

    function encodeHashString(bytes32 hash) internal pure returns (bytes memory) {
        string memory hashStr = toHexString(hash);
        return encodeString(hashStr);
    }

    function toHexString(bytes32 value) internal pure returns (string memory) {
        bytes memory result = new bytes(66); // 0x + 64 hex chars
        result[0] = "0";
        result[1] = "x";
        
        bytes16 symbols = "0123456789abcdef";
        for (uint256 i = 0; i < 32; i++) {
            uint8 b = uint8(value[i]);
            result[2 + i * 2] = symbols[b >> 4];
            result[3 + i * 2] = symbols[b & 0xf];
        }
        
        return string(result);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        
        uint256 temp = value;
        uint256 digits;
        
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }

    function concatArrays(bytes32 a, bytes32 b) internal pure returns (bytes memory) {
        return abi.encodePacked(a, b);
    }

    function hashData(bytes memory data) internal pure returns (bytes32) {
        return keccak256(data);
    }

    function encodeOrderCommitmentData(
        string memory rollupId,
        uint256 batchNumber,
        uint256 txOrder,
        bytes32 txHash,
        bytes32[] memory preMerklePath
    ) internal pure returns (bytes memory) {
        bytes memory result;
        
        // Rollup ID (length-prefixed string)
        result = abi.encodePacked(result, encodeString(rollupId));
        
        // Batch number (u64 little-endian)
        result = abi.encodePacked(result, u64LE(uint64(batchNumber)));
        
        // Transaction order (u64 little-endian)
        result = abi.encodePacked(result, u64LE(uint64(txOrder)));
        
        // Transaction hash (length-prefixed string with 0x prefix)
        result = abi.encodePacked(result, encodeHashString(txHash));
        
        // Pre merkle path array length (u64 little-endian)
        result = abi.encodePacked(result, u64LE(uint64(preMerklePath.length)));
        
        // Pre merkle path elements (each as a length-prefixed string)
        for (uint i = 0; i < preMerklePath.length; i++) {
            result = abi.encodePacked(result, encodeHashString(preMerklePath[i]));
        }
        
        return result;
    }

    function verifyOrderCommitmentSignature(
        address signer,
        string memory rollupId,
        uint256 batchNumber,
        bytes32 txHash,
        uint256 txOrder,
        bytes32[] memory preMerklePath,
        bytes memory signature
    ) external view returns (bool) {
        bytes memory message = encodeOrderCommitmentData(
            rollupId,
            batchNumber,
            txOrder,
            txHash,
            preMerklePath
        );

        address recoveredSigner = recoverSigner(message, signature);
        return (recoveredSigner == signer);
    }

    function recoverSigner(bytes memory message, bytes memory signature) public pure returns (address) {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature 'v' value");

        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n",
            toString(message.length),
            message
        ));

        return ecrecover(messageHash, v, r, s);
    }

    function storeSlashRequest(
        address operator,
        address requester,
        string calldata clusterId,
        string calldata rollupId,
        uint256 batchNumber,
        bytes32 txHash,
        uint256 txOrder,
        bytes32[] calldata preMerklePath,
        bytes calldata signature,
        uint256 depositAmount,
        uint256 timestamp
    ) external onlyOwner {
        IValidationServiceManager.SlashRequest storage newRequest = slashRequests[txHash];
        newRequest.operator = operator;
        newRequest.requester = requester;
        newRequest.clusterId = clusterId;

        newRequest.rollupId = rollupId;
        newRequest.batchNumber = batchNumber;
        newRequest.txHash = txHash;
        newRequest.txOrder = txOrder;
        newRequest.signature = signature;
        newRequest.depositAmount = depositAmount;
        newRequest.status = IValidationServiceManager.Status.Pending;
        newRequest.exists = true;
        newRequest.timestamp = timestamp;  

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

    function validateMerkleProof( bytes32 txHash, bytes32 merkleRoot, bytes32[] calldata postMerklePath ) external view returns (bool isValid) {
        require(slashRequests[txHash].exists, "Slash request does not exist");
        IValidationServiceManager.SlashRequest storage slashRequest = slashRequests[txHash];
        require(slashRequest.status == IValidationServiceManager.Status.Pending, "Slash request already processed");

        string memory txHashString = toHexString(txHash);
        bytes32 currentHash = hashData(bytes(txHashString));

        bytes32[] memory reversedPreMerklePath = new bytes32[](slashRequest.preMerklePath.length);
        for (uint arrIndex = 0; arrIndex < slashRequest.preMerklePath.length; arrIndex++) {
            reversedPreMerklePath[arrIndex] = slashRequest.preMerklePath[slashRequest.preMerklePath.length - 1 - arrIndex];
        }
        uint256 index = slashRequest.txOrder;
        uint preMerkleIndex = 0;
        uint postMerkleIndex = 0;

        while (preMerkleIndex < reversedPreMerklePath.length || postMerkleIndex < postMerklePath.length) {
            bytes32 sibling;
            
            if (index % 2 == 0) {
                // If index is even, take from postMerklePath
                if (postMerkleIndex >= postMerklePath.length) {
                    return false;
                }
                sibling = postMerklePath[postMerkleIndex];
                postMerkleIndex++;
            } else {
                // If index is odd, take from preMerklePath
                if (preMerkleIndex >= reversedPreMerklePath.length) {
                    return false; 
                }
                sibling = reversedPreMerklePath[preMerkleIndex];
                preMerkleIndex++;
            }
            
            // Compute the parent hash 
            if (index % 2 == 0) {
                currentHash = hashData(concatArrays(currentHash, sibling));
            } else {
                currentHash = hashData(concatArrays(sibling, currentHash));
            }
            
            // Move up the tree
            index /= 2;
        }
        
        // Final verification
        return currentHash == merkleRoot;
    }

    function updateSlashRequestStatus(bytes32 txHash, IValidationServiceManager.Status status) external onlyOwner {
        require(slashRequests[txHash].exists, "Slash request does not exist");
        slashRequests[txHash].status = status;
    }

    function createSlashCredit( bytes32 txHash, address vault, address requester, address tokenAddress, uint256 amount, uint64 slasherType, uint256 slashIndex ) external onlyOwner {
        require(slashCredits[txHash].requester == address(0), "Slash credit already exists for this txHash");
        
        IValidationServiceManager.SlashCredit memory newCredit = IValidationServiceManager.SlashCredit({
            vault: vault,
            requester: requester,
            tokenAddress: tokenAddress,
            amount: amount,
            slasherType: slasherType,
            slashIndex: slashIndex,
            status: IValidationServiceManager.SlashCreditStatus.Pending,
            timestamp: block.timestamp
        });
        
        slashCredits[txHash] = newCredit;
        slashCreditTxHashes.push(txHash);
        emit IValidationServiceManager.SlashCreditCreated(txHash, requester, tokenAddress, amount, slasherType, slashIndex);
    }
    
    function findLargestStake(IValidationServiceManager.StakeInfo[] memory stakes) 
        external pure returns (address largestToken, uint256 largestAmount) 
    {
        largestToken = address(0);
        largestAmount = 0;
        
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].stakeAmount > largestAmount) {
                largestAmount = stakes[i].stakeAmount;
                largestToken = stakes[i].token;
            }
        }
        
        return (largestToken, largestAmount);
    }
    
    function processSlashCredit(bytes32 txHash) external nonReentrant {
        IValidationServiceManager.SlashCredit storage credit = slashCredits[txHash];
        
        require(credit.requester != address(0), "No slash credit exists for this txHash");
        require(credit.status == IValidationServiceManager.SlashCreditStatus.Pending, "Credit not in pending state");
        
        if (credit.slasherType == INSTANT_SLASHER_TYPE) {
            try IERC20(credit.tokenAddress).transfer(credit.requester, credit.amount) {
                credit.status = IValidationServiceManager.SlashCreditStatus.Processed;
                emit IValidationServiceManager.SlashCreditProcessed(
                    txHash,
                    0,  
                    credit.requester,
                    credit.tokenAddress,
                    credit.amount
                );
            } catch {
                credit.status = IValidationServiceManager.SlashCreditStatus.Failed;
            }
        } else if (credit.slasherType == VETO_SLASHER_TYPE) {
            
            credit.status = IValidationServiceManager.SlashCreditStatus.Failed;  
        }
    }
    
   
    function updateVetoSlashCreditStatus( bytes32 txHash, bool slashExecuted ) external onlyOwner {
        IValidationServiceManager.SlashCredit storage credit = slashCredits[txHash];
        
        require(credit.requester != address(0), "No slash credit exists for this txHash");
        require(credit.slasherType == VETO_SLASHER_TYPE, "Not a veto slash credit");
        require(credit.status != IValidationServiceManager.SlashCreditStatus.Processed, "Credit not is not already processed");
        
        if (slashExecuted) {
            try IERC20(credit.tokenAddress).transfer(credit.requester, credit.amount) {
                credit.status = IValidationServiceManager.SlashCreditStatus.Processed;
                emit IValidationServiceManager.SlashCreditProcessed(
                    txHash,
                    0,  
                    credit.requester,
                    credit.tokenAddress,
                    credit.amount
                );
            } catch {
                credit.status = IValidationServiceManager.SlashCreditStatus.Failed;
            }
        } else {
            credit.status = IValidationServiceManager.SlashCreditStatus.Failed;
        }
    }

    function updateSlashCreditStatus( bytes32 txHash, IValidationServiceManager.SlashCreditStatus status ) external onlyOwner {
        IValidationServiceManager.SlashCredit storage credit = slashCredits[txHash];
        require(credit.requester != address(0), "No slash credit exists for this txHash");
        
        credit.status = status;
    }
    
    function getSlashCredit(bytes32 txHash) external view returns (IValidationServiceManager.SlashCredit memory) {
        return slashCredits[txHash];
    }

    function getPendingSlashCredits() external view returns (bytes32[] memory) {
        uint256 pendingCount = 0;
        
        // First, count the pending credits
        for (uint256 i = 0; i < slashCreditTxHashes.length; i++) {
            bytes32 txHash = slashCreditTxHashes[i];
            if (slashCredits[txHash].status == IValidationServiceManager.SlashCreditStatus.Pending) {
                pendingCount++;
            }
        }
        
        // Then create the result array
        bytes32[] memory pendingTxHashes = new bytes32[](pendingCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 0; i < slashCreditTxHashes.length; i++) {
            bytes32 txHash = slashCreditTxHashes[i];
            if (slashCredits[txHash].status == IValidationServiceManager.SlashCreditStatus.Pending) {
                pendingTxHashes[currentIndex] = txHash;
                currentIndex++;
            }
        }
        
        return pendingTxHashes;
    }
    
    function getAllSlashCreditTxHashes() external view returns (bytes32[] memory) {
        return slashCreditTxHashes;
    }
}