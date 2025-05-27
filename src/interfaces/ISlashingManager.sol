// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import {IValidationServiceManager as IVsmTypes} from "./IValidationServiceManager.sol"; // For structs
interface ISlashingManager {
    
    function NETWORK() external view returns (address);
    function INSTANT_SLASHER_TYPE() external view returns (uint64);
    function VETO_SLASHER_TYPE() external view returns (uint64);
    function SLASH_BASIS_POINTS() external view returns (uint256);

    function slashCredits(bytes32 txHash) external view returns (IVsmTypes.SlashCredit memory);
    function slashCreditTxHashes(uint256 index) external view returns (bytes32);

    function verifyOrderCommitmentSignature(
        address signer,
        string memory rollupId,
        uint256 batchNumber,
        bytes32 txHash,
        uint256 txOrder,
        bytes32[] memory preMerklePath,
        bytes memory signature
    ) external pure returns (bool);

    function recoverSigner(bytes memory message, bytes memory signature) external pure returns (address);

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
    ) external;

    function getPreMerklePath(bytes32 txHash) external view returns (bytes32[] memory);
    function getSlashRequestDetails(bytes32 txHash) external view returns (IVsmTypes.SlashRequest memory);

    function validateMerkleProof(
        bytes32 txHash,
        bytes32 merkleRoot,
        bytes32[] calldata postMerklePath
    ) external view returns (bool isValid);

    function updateSlashRequestStatus(bytes32 txHash, IVsmTypes.Status status) external;

    function createSlashCredit(
        bytes32 txHash,
        address vault,
        address requester,
        address tokenAddress,
        uint256 amount,
        uint64 slasherType,
        uint256 slashIndex
    ) external;

    function updateSlashCreditStatus(
        bytes32 txHash,
        IVsmTypes.SlashCreditStatus status
    ) external;

    function getSlashCredit(bytes32 txHash) external view returns (IVsmTypes.SlashCredit memory);
    function getAllSlashCreditTxHashes() external view returns (bytes32[] memory);
}