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

    // Constants
    uint64 public constant INSTANT_SLASHER_TYPE = 0;
    uint64 public constant VETO_SLASHER_TYPE = 1;
    uint256 public constant SLASH_BASIS_POINTS = 5; // 0.005% represented as 5 basis points

    // Using slash credit types from IValidationServiceManager
    // Mapping to store slash credits by txHash
    mapping(bytes32 => IValidationServiceManager.SlashCredit[]) public slashCredits;

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

    // New function to create a slash credit record
    function createSlashCredit(
        bytes32 txHash,
        address requester,
        address tokenAddress,
        uint256 amount,
        uint64 slasherType,
        uint256 slashIndex
    ) external onlyOwner {
        IValidationServiceManager.SlashCredit memory newCredit = IValidationServiceManager.SlashCredit({
            requester: requester,
            tokenAddress: tokenAddress,
            amount: amount,
            slasherType: slasherType,
            slashIndex: slashIndex,
            status: IValidationServiceManager.SlashCreditStatus.Pending,
            timestamp: block.timestamp
        });
        
        slashCredits[txHash].push(newCredit);
        
        emit IValidationServiceManager.SlashCreditCreated(
            txHash,
            requester,
            tokenAddress,
            amount,
            slasherType,
            slashIndex
        );
    }
    
    // Helper function to find the token with the largest stake
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
    
    // Function to process a single slash credit
    function processSlashCredit(bytes32 txHash, uint256 creditIndex) external nonReentrant {
        require(creditIndex < slashCredits[txHash].length, "Invalid credit index");
        IValidationServiceManager.SlashCredit storage credit = slashCredits[txHash][creditIndex];
        
        // Skip already processed credits
        if (credit.status != IValidationServiceManager.SlashCreditStatus.Pending) {
            return;
        }
        
        if (credit.slasherType == INSTANT_SLASHER_TYPE) {
            // For instant slashers, transfer tokens directly
            try IERC20(credit.tokenAddress).transfer(credit.requester, credit.amount) {
                credit.status = IValidationServiceManager.SlashCreditStatus.Processed;
                emit IValidationServiceManager.SlashCreditProcessed(
                    txHash,
                    creditIndex,
                    credit.requester,
                    credit.tokenAddress,
                    credit.amount
                );
            } catch {
                credit.status = IValidationServiceManager.SlashCreditStatus.Failed;
            }
        } else if (credit.slasherType == VETO_SLASHER_TYPE) {
            // For veto slashers, we can only verify completion through the external call
            // This needs to be implemented by the caller with access to veto slasher
            credit.status = IValidationServiceManager.SlashCreditStatus.Failed; // Default to failed until processed by caller
        }
    }
    
    // Function to update a veto slash credit status after external verification
    function updateVetoSlashCreditStatus(
        bytes32 txHash, 
        uint256 creditIndex, 
        bool slashExecuted
    ) external onlyOwner {
        require(creditIndex < slashCredits[txHash].length, "Invalid credit index");
        IValidationServiceManager.SlashCredit storage credit = slashCredits[txHash][creditIndex];
        
        require(credit.slasherType == VETO_SLASHER_TYPE, "Not a veto slash credit");
        require(credit.status == IValidationServiceManager.SlashCreditStatus.Pending, "Credit not in pending state");
        
        if (slashExecuted) {
            try IERC20(credit.tokenAddress).transfer(credit.requester, credit.amount) {
                credit.status = IValidationServiceManager.SlashCreditStatus.Processed;
                emit IValidationServiceManager.SlashCreditProcessed(
                    txHash,
                    creditIndex,
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
    
    // Function to process multiple slash credits in batch
    function processSlashCreditsBatch(bytes32 txHash, uint256[] calldata creditIndices) external nonReentrant {
        for (uint256 i = 0; i < creditIndices.length; i++) {
            if (creditIndices[i] < slashCredits[txHash].length) {
                IValidationServiceManager.SlashCredit storage credit = slashCredits[txHash][creditIndices[i]];
                
                // Skip already processed credits
                if (credit.status != IValidationServiceManager.SlashCreditStatus.Pending) {
                    continue;
                }
                
                if (credit.slasherType == INSTANT_SLASHER_TYPE) {
                    try IERC20(credit.tokenAddress).transfer(credit.requester, credit.amount) {
                        credit.status = IValidationServiceManager.SlashCreditStatus.Processed;
                        emit IValidationServiceManager.SlashCreditProcessed(
                            txHash,
                            creditIndices[i],
                            credit.requester,
                            credit.tokenAddress,
                            credit.amount
                        );
                    } catch {
                        credit.status = IValidationServiceManager.SlashCreditStatus.Failed;
                    }
                }
                // Skip veto slasher type credits as they need external verification
            }
        }
    }
    
    // Function to get all pending slash credits for a txHash
    function getPendingSlashCredits(bytes32 txHash) external view returns (uint256[] memory) {
        uint256 pendingCount = 0;
        
        // First, count the pending credits
        for (uint256 i = 0; i < slashCredits[txHash].length; i++) {
            if (slashCredits[txHash][i].status == IValidationServiceManager.SlashCreditStatus.Pending) {
                pendingCount++;
            }
        }
        
        // Then create the result array
        uint256[] memory pendingIndices = new uint256[](pendingCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 0; i < slashCredits[txHash].length; i++) {
            if (slashCredits[txHash][i].status == IValidationServiceManager.SlashCreditStatus.Pending) {
                pendingIndices[currentIndex] = i;
                currentIndex++;
            }
        }
        
        return pendingIndices;
    }
    
    // Function to get all slash credits for a txHash
    function getSlashCredits(bytes32 txHash) external view returns (IValidationServiceManager.SlashCredit[] memory) {
        return slashCredits[txHash];
    }
}