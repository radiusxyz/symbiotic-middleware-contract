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
    uint256 public constant SLASH_BASIS_POINTS = 5; // 0.005% represented as 5 basis points

    // Using slash credit types from IValidationServiceManager
    // Mapping to store slash credits by txHash (refactored to one credit per txHash)
    mapping(bytes32 => IValidationServiceManager.SlashCredit) public slashCredits;
    
    bytes32[] public slashCreditTxHashes;

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

        for (uint i = 0; i < slashRequest.preMerklePath.length; i++) {
            bytes32 siblingHash = slashRequest.preMerklePath[i];
            if (currentIndex % 2 == 0) {
                currentHash = keccak256(abi.encodePacked(currentHash, siblingHash));
            } else {
                currentHash = keccak256(abi.encodePacked(siblingHash, currentHash));
            }
            currentIndex = currentIndex / 2;
        }

        for (uint i = 0; i < postMerklePath.length; i++) {
            bytes32 siblingHash = postMerklePath[i];
            if (currentIndex % 2 == 0) {
                currentHash = keccak256(abi.encodePacked(currentHash, siblingHash));
            } else {
                currentHash = keccak256(abi.encodePacked(siblingHash, currentHash));
            }
            currentIndex = currentIndex / 2;
        }

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

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature 'v' value");

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function createSlashCredit(
        bytes32 txHash,
        address vault,
        address requester,
        address tokenAddress,
        uint256 amount,
        uint64 slasherType,
        uint256 slashIndex
    ) external onlyOwner {
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
        
        emit IValidationServiceManager.SlashCreditCreated(
            txHash,
            requester,
            tokenAddress,
            amount,
            slasherType,
            slashIndex
        );
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
            // For instant slashers, transfer tokens directly
            try IERC20(credit.tokenAddress).transfer(credit.requester, credit.amount) {
                credit.status = IValidationServiceManager.SlashCreditStatus.Processed;
                emit IValidationServiceManager.SlashCreditProcessed(
                    txHash,
                    0, // Since we no longer have an index, use 0
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
    
   
    function updateVetoSlashCreditStatus(
        bytes32 txHash, 
        bool slashExecuted
    ) external onlyOwner {
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

    function updateSlashCreditStatus(
        bytes32 txHash, 
        IValidationServiceManager.SlashCreditStatus status
    ) external onlyOwner {
        IValidationServiceManager.SlashCredit storage credit = slashCredits[txHash];
        require(credit.requester != address(0), "No slash credit exists for this txHash");
        
        credit.status = status;
        
     
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
    
    function getSlashCredit(bytes32 txHash) external view returns (IValidationServiceManager.SlashCredit memory) {
        return slashCredits[txHash];
    }
    
    function getAllSlashCreditTxHashes() external view returns (bytes32[] memory) {
        return slashCreditTxHashes;
    }
}