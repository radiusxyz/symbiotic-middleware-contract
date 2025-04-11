// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {console} from "forge-std/src/console.sol";
import {Time} from "@openzeppelin-contracts/contracts/utils/types/Time.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IValidationServiceManager} from "src/interfaces/IValidationServiceManager.sol";
import {Registry} from "src/components/Registry.sol";
import {RewardsManager} from "src/components/RewardsManager.sol";
import {SlashingManager} from "src/components/SlashingManager.sol";
import {TaskManager} from "src/components/TaskManager.sol";
import {LivenessServiceManager} from "src/components/LivenessServiceManager.sol";
import {IRewardsCore} from "src/interfaces/IRewardsCore.sol";
import {IDefaultOperatorRewards} from "@symbiotic-rewards/src/interfaces/defaultOperatorRewards/IDefaultOperatorRewards.sol";
import {IDefaultStakerRewards} from "@symbiotic-rewards/src/interfaces/defaultStakerRewards/IDefaultStakerRewards.sol";
import {IBaseSlasher} from "@symbiotic-core/src/interfaces/slasher/IBaseSlasher.sol";
import {ISlasher} from "@symbiotic-core/src/interfaces/slasher/ISlasher.sol";
import {IVetoSlasher} from "@symbiotic-core/src/interfaces/slasher/IVetoSlasher.sol";
import {ILivenessServiceManager} from "src/interfaces/ILivenessServiceManager.sol";

contract ValidationServiceManager is Ownable, IValidationServiceManager, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    Registry public registry;
    RewardsManager public rewardsManager;
    SlashingManager public slashingManager;
    TaskManager public taskManager;
    LivenessServiceManager public livenessServiceManager;

    address public immutable NETWORK;
    address public immutable REWARDS_CORE_ADDRESS;
    uint256 public constant SLASH_DEPOSIT_AMOUNT = 0.05 ether;
    uint64 private constant INSTANT_SLASHER_TYPE = 0;
    uint64 private constant VETO_SLASHER_TYPE = 1;

    mapping(bytes32 => SlashCredit[]) public slashCredits;

    constructor(
        address _network,
        address _rewards_core_address,
        address _registry,
        address _rewardsManager,
        address _slashingManager,
        address _taskManager,
        address _livenessServiceManager
    ) Ownable(msg.sender) {
        NETWORK = _network;
        REWARDS_CORE_ADDRESS = _rewards_core_address;
        
        registry = Registry(_registry);
        rewardsManager = RewardsManager(_rewardsManager);
        slashingManager = SlashingManager(_slashingManager);
        taskManager = TaskManager(_taskManager);
        livenessServiceManager = LivenessServiceManager(_livenessServiceManager);
    }

    // Registry Methods
    function getEpochAtTs(uint48 timestamp) public view returns (uint48 epoch) {
        return registry.getEpochAtTs(timestamp);
    }

    function getCurrentEpoch() public view returns (uint48 epoch) {
        return registry.getCurrentEpoch();
    }

    function getEpochStartTs(uint48 epoch) public view returns (uint48 timestamp) {
        return registry.getEpochStartTs(epoch);
    }

    function setSubnetworkCount(uint256 _subnetworkCount) external onlyOwner {
        registry.setSubnetworkCount(_subnetworkCount);
    }

    function getSubnetwork(uint96 index) external view returns (bytes32) {
        return registry.getSubnetwork(index);
    }

    function registerOperator(address operator, address operating) external onlyOwner {
        registry.registerOperator(operator, operating);
    }

    function pauseOperator(address operator) external onlyOwner {
        registry.pauseOperator(operator);
    }

    function unpauseOperator(address operator) external onlyOwner {
        registry.unpauseOperator(operator);
    }

    function unregisterOperator(address operator) external onlyOwner {
        registry.unregisterOperator(operator);
    }

    function updateOperatingAddress(address operator, address operating) external onlyOwner {
        registry.updateOperatingAddress(operator, operating);
    }

    function getCurrentOperatorInfos() public view returns (OperatorInfo[] memory) {
        return registry.getCurrentOperatorInfos();
    }

    function getOperatorInfos(uint48 epoch) public view returns (OperatorInfo[] memory) {
        return registry.getOperatorInfos(epoch);
    }

    function registerToken(address token) external onlyOwner {
        registry.registerToken(token);
    }

    function setMinimumStakingAmount(address token, uint256 amount) external onlyOwner {
        registry.setMinimumStakingAmount(token, amount);
    }

    function pauseToken(address token) external onlyOwner {
        registry.pauseToken(token);
    }

    function unpauseToken(address token) external onlyOwner {
        registry.unpauseToken(token);
    }

    function unregisterToken(address token) external onlyOwner {
        registry.unregisterToken(token);
    }

    function isActiveToken(address token) public view returns (bool) {
        return registry.isActiveToken(token);
    }

    function getCurrentTokens() public view returns (address[] memory) {
        return registry.getCurrentTokens();
    }

    function getTokens(uint48 epoch) public view returns (address[] memory) {
        return registry.getTokens(epoch);
    }

    function getTokenAddress(address collateralOrToken) public view returns (address) {
        return registry.getTokenAddress(collateralOrToken);
    }

    function getVaultToken(address vault) public view returns (address) {
        return registry.getVaultToken(vault);
    }

    function registerVault(address vault, address stakerRewards, address operatorRewards, address slasher) external onlyOwner {
        registry.registerVault(vault, stakerRewards, operatorRewards, slasher);
    }

    function pauseVault(address vault) external onlyOwner {
        registry.pauseVault(vault);
    }

    function unpauseVault(address vault) external onlyOwner {
        registry.unpauseVault(vault);
    }

    function unregisterVault(address vault) external onlyOwner {
        registry.unregisterVault(vault);
    }

    function isActiveVault(address vault) public view returns (bool) {
        return registry.isActiveVault(vault);
    }

    function getCurrentVaults() public view returns (address[] memory) {
        return registry.getCurrentVaults();
    }

    function getVaults(uint48 epoch) public view returns (address[] memory) {
        return registry.getVaults(epoch);
    }

    function getCurrentTokenTotalStake(address token) public view returns (uint256) {
        return registry.getCurrentTokenTotalStake(token);
    }

    function getTokenTotalStake(address token, uint48 epoch) public view returns (uint256) {
        return registry.getTokenTotalStake(token, epoch);
    }

    function getCurrentAllTokenTotalStakes() public view returns (StakeInfo[] memory) {
        return registry.getCurrentAllTokenTotalStakes();
    }

    function getAllTokenTotalStakes(uint48 epoch) public view returns (StakeInfo[] memory) {
        return registry.getAllTokenTotalStakes(epoch);
    }

    function getCurrentOperatorTokenStake(address operator, address token) public view returns (uint256) {
        return registry.getCurrentOperatorTokenStake(operator, token);
    }

    function getOperatorTokenStake(address operator, address token, uint48 epoch) public view returns (uint256) {
        return registry.getOperatorTokenStake(operator, token, epoch);
    }

    function getCurrentOperatorAllTokenStakes(address operator) public view returns (StakeInfo[] memory) {
        return registry.getCurrentOperatorAllTokenStakes(operator);
    }

    function getOperatorAllTokenStakes(address operator, uint48 epoch) public view returns (StakeInfo[] memory) {
        return registry.getOperatorAllTokenStakes(operator, epoch);
    }

    function calcAndCacheStakes(uint48 epoch) external {
        registry.calcAndCacheStakes(epoch);
    }

    // Liveness Manager Methods
    function initializeCluster(string calldata clusterId, uint256 maxTxOrdererNumber) external {
        livenessServiceManager.initializeCluster(clusterId, maxTxOrdererNumber, msg.sender);
    }

    function getAllClusterIds() external view returns (string[] memory) {
        return livenessServiceManager.getAllClusterIds();
    }

    function getMaxTxOrdererNumber(string calldata clusterId) external view returns (uint256) {
        return livenessServiceManager.getMaxTxOrdererNumber(clusterId);
    }

    function getClusterIdsByOwner(address owner) external view returns (string[] memory) {
        return livenessServiceManager.getClusterIdsByOwner(owner);
    }

    function getClusterIdsByTxOrderer(address txOrderer) external view returns (string[] memory) {
        return livenessServiceManager.getClusterIdsByTxOrderer(txOrderer);
    }

    function addRollup(string calldata clusterId, ILivenessServiceManager.NewRollup calldata newRollup) external {
        // Add validation to ensure that validation service manager's address is correct
        require(newRollup.validationInfo.validationServiceManager == address(this), 
                "Invalid VSM");
        
        livenessServiceManager.addRollup(clusterId, newRollup, msg.sender);
    }

    function isRollupAdded(string calldata clusterId, string calldata rollupId) external view returns (bool) {
        return livenessServiceManager.isRollupAdded(clusterId, rollupId);
    }

    function getRollups(string calldata clusterId) external view returns (ILivenessServiceManager.Rollup[] memory) {
        return livenessServiceManager.getRollups(clusterId);
    }

    function getRollup(string calldata clusterId, string calldata rollupId) external view returns (ILivenessServiceManager.Rollup memory) {
        return livenessServiceManager.getRollup(clusterId, rollupId);
    }

    function registerTxOrderer(string calldata clusterId) external {
        livenessServiceManager.registerTxOrderer(clusterId, msg.sender);
    }

    function deregisterTxOrderer(string calldata clusterId) external {
        livenessServiceManager.deregisterTxOrderer(clusterId, msg.sender);
    }

    function getTxOrderers(string calldata clusterId) external view returns (address[] memory) {
        return livenessServiceManager.getTxOrderers(clusterId);
    }

    function registerRollupExecutor(string calldata clusterId, string calldata rollupId, address executor) external {
        livenessServiceManager.registerRollupExecutor(clusterId, rollupId, executor, msg.sender);
    }

    function getExecutors(string calldata clusterId, string calldata rollupId) external view returns (address[] memory) {
        return livenessServiceManager.getExecutors(clusterId, rollupId);
    }

    function isRollupExecutorRegistered(string calldata clusterId, string calldata rollupId, address executor) external view returns (bool) {
        return livenessServiceManager.isRollupExecutorRegistered(clusterId, rollupId, executor);
    }

    // Task Manager Methods
    function createNewTask(
        Task calldata task,
        DistributionParams calldata distributionParams
    ) external {
        if (!registry.checkIncludingOperatingAddress(msg.sender)) {
            revert OperatorNotRegistered();
        }
        if (!livenessServiceManager.isRollupAdded(task.clusterId, task.rollupId)) {
            revert RollupNotRegistered();
        }
        
        uint256 latestTaskNumber = taskManager.getLatestTaskNumber(task.rollupId);
        taskManager.createNewTask(task, distributionParams);
        
        if (latestTaskNumber > 0 && distributionParams.operatorMerkleRoots.length > 0) {
            rewardsManager.storeDistributionData(task.clusterId, task.rollupId, distributionParams.rewardedTaskindex, distributionParams);
        }
    }

    function respondToTask(
        string calldata clusterId,
        string calldata rollupId,
        uint256 referenceTaskIndex,
        bool response
    ) external {
        if (!registry.checkIncludingOperatingAddress(msg.sender)) {
            revert OperatorNotRegistered();
        }
         if (!livenessServiceManager.isRollupExecutorRegistered(clusterId, rollupId, msg.sender)) {
            revert ExecutorNotRegisteredForRollup();
        }
        
        taskManager.respondToTask(clusterId, rollupId, referenceTaskIndex, response);
    }

    // Distribution Methods
    function executeDistributions(
        string calldata clusterId,
        string calldata rollupId
    ) external nonReentrant {
        (
            bool isEligible,
            uint256 availableAmount,
            address rewardToken,
            uint256 timeUntilNextDistribution,
            uint256 operatorAmount,
            uint256 stakerAmount
        ) = IRewardsCore(REWARDS_CORE_ADDRESS).getDistributionInfo(clusterId, rollupId);

        if (!isEligible) {
            revert IRewardsCore.TooEarlyForDistribution();
        }

        uint256 taskCount = taskManager.getLatestTaskNumber(rollupId) + 1;
        uint256 distributedCount = 0;
        
        // First check if any distributions are pending
        bool hasPendingDistributions = false;
        for (uint256 i = 0; i < taskCount && !hasPendingDistributions; i++) {
            bool hasData = rewardsManager.hasDistributionData(clusterId, rollupId, i);
            bool isDistributed = rewardsManager.isDistributed(clusterId, rollupId, i);
            uint256 responseCount = taskManager.getTaskResponseCount(rollupId, i);
            
            if (hasData && !isDistributed && responseCount >= 5) {
                hasPendingDistributions = true;
            }
        }
        if (!hasPendingDistributions) {
            revert NoPendingDistributions();
        }
        
        for (uint256 i = 0; i < taskCount; i++) {
            bool hasData = rewardsManager.hasDistributionData(clusterId, rollupId, i);
            bool isDistributed = rewardsManager.isDistributed(clusterId, rollupId, i);
            uint256 responseCount = taskManager.getTaskResponseCount(rollupId, i);
            
            if (!hasData || isDistributed || responseCount < 5) {
                continue;
            }
            
            _processDistribution(clusterId, rollupId, i, rewardToken);
            emit RewardsDistributed(clusterId, rollupId, i);
            rewardsManager.markDistributionAsCompleted(clusterId, rollupId, i);
            distributedCount++;
        }
    }

    function _processDistribution(
        string calldata clusterId,
        string calldata rollupId,
        uint256 taskIndex,
        address rewardToken
    ) internal {
        (
            address[] memory vaultAddresses,
            bytes32[] memory operatorMerkleRoots,
            uint256[] memory totalStakerReward,
            uint256[] memory totalOperatorReward,
            bool distributed
        ) = rewardsManager.getDistributionData(clusterId, rollupId, taskIndex);
        
         if (distributed) {
            revert DistributionAlreadyProcessed();
        }
        
        uint48 oneSecondAgo = uint48(block.timestamp - 5);
        uint256 vaultCount = vaultAddresses.length;
        uint256 totalRewardsRequired = 0;
        
        for (uint256 i = 0; i < vaultCount; i++) {
            uint256 vaultTotalReward = totalStakerReward[i] + totalOperatorReward[i];
            totalRewardsRequired += vaultTotalReward;
        }

        uint256 approvedAmount = IRewardsCore(REWARDS_CORE_ADDRESS)
            .approveRewardDistribution(NETWORK, clusterId, rollupId, totalRewardsRequired);

        IERC20(rewardToken).safeTransferFrom(
            REWARDS_CORE_ADDRESS,
            address(this),
            approvedAmount
        );

        for (uint256 i = 0; i < vaultCount; i++) {
            _distributeToVault(
                rewardToken,
                vaultAddresses[i],
                operatorMerkleRoots[i],
                totalStakerReward[i],
                totalOperatorReward[i],
                oneSecondAgo
            );
        }
    }

    function _distributeToVault(
        address rewardToken,
        address vaultAddress,
        bytes32 operatorMerkleRoot,
        uint256 stakerReward,
        uint256 operatorReward,
        uint48 oneSecondAgo
    ) internal {
        // Get vault details directly
        address tokenAddress = registry.getVaultToken(vaultAddress);
        address stakerRewards;
        address operatorRewards;
        address slasher;
        
        // Access the vault details struct from registry
        (tokenAddress, stakerRewards, operatorRewards, slasher) = registry.getVaultDetails(vaultAddress);

        if (stakerRewards != address(0)) {
            _safeTokenApprove(rewardToken, stakerRewards, stakerReward);
            IDefaultStakerRewards(stakerRewards).distributeRewards(
                NETWORK,
                rewardToken,
                stakerReward,
                abi.encode(oneSecondAgo, 10000, new bytes(0), new bytes(0))
            );
        }

        if (operatorRewards != address(0)) {
            _safeTokenApprove(rewardToken, operatorRewards, operatorReward);
            IDefaultOperatorRewards(operatorRewards).distributeRewards(
                NETWORK,
                rewardToken,
                operatorReward,
                operatorMerkleRoot
            );
        }
    }

    function _safeTokenApprove(
        address token,
        address spender,
        uint256 amount
    ) private {
        SafeERC20.safeIncreaseAllowance(IERC20(token), spender, amount);
    }

    function getDistributionData(
        string memory clusterId,
        string memory rollupId,
        uint256 referenceTaskId
    ) public view returns (
        address[] memory vaultAddresses,
        bytes32[] memory operatorMerkleRoots,
        uint256[] memory totalStakerReward,
        uint256[] memory totalOperatorReward
    ) {
        (vaultAddresses, operatorMerkleRoots, totalStakerReward, totalOperatorReward, ) = 
            rewardsManager.getDistributionData(clusterId, rollupId, referenceTaskId);
    }

    function getSlashRequestDetails(bytes32 txHash) external view returns (SlashRequest memory) {
        return slashingManager.getSlashRequestDetails(txHash);
    }
    function getSlashCreditDetails(bytes32 txHash) external view returns (SlashCredit memory) {
        return slashingManager.getSlashCredit(txHash);
    }

    
    function requestSlash(
        address operator,
        string calldata rollupId,
        uint256 blockHeight,
        bytes32 txHash,
        uint256 txOrder,
        bytes32[] calldata preMerklePath,
        bytes calldata signature   
    ) external payable {  

        if (txHash == bytes32(0)) {
            revert InvalidTransactionHash();
        }
        
        SlashRequest memory existingRequest = slashingManager.getSlashRequestDetails(txHash);
        if (existingRequest.exists) {
            revert SlashRequestAlreadyExists();
        }
        
         if (msg.value != SLASH_DEPOSIT_AMOUNT) {
            revert IncorrectSlashDepositAmount();
        }

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                rollupId,
                blockHeight,
                txHash,
                txOrder,
                preMerklePath
            )
        );
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        address recoveredAddress = slashingManager.recoverSigner(ethSignedMessageHash, signature);
        if (recoveredAddress != operator) {
            revert InvalidSignature();
        }

        slashingManager.storeSlashRequest(
            operator,
            msg.sender,
            rollupId,
            blockHeight,
            txHash,
            txOrder,
            preMerklePath,
            signature,
            msg.value
        );

        emit SlashRequested(txHash, operator, msg.sender, rollupId, blockHeight);
    }

    function respondToSlash(
        bytes32 txHash,
        bytes32[] calldata postMerklePath
    ) external nonReentrant {
        SlashRequest memory slashRequest = slashingManager.getSlashRequestDetails(txHash);
         if (!slashRequest.exists) {
            revert SlashRequestNotFound();
        }

        if (slashRequest.status != Status.Pending) {
            revert SlashRequestAlreadyProcessed();
        }
        
        if (msg.sender != slashRequest.operator) {
            revert InvalidSlashResponder();
        }

        uint256 taskIndex = taskManager.getTaskIndexFromBlockNumber(slashRequest.rollupId, slashRequest.blockHeight);
        bytes32 merkleRoot = taskManager.getBlockCommitment(slashRequest.rollupId, taskIndex);

        bool isValid = slashingManager.validateMerkleProof(txHash, merkleRoot, postMerklePath);
        
        slashingManager.updateSlashRequestStatus(txHash, Status.Processed);

        if (isValid) {
            (bool success, ) = payable(slashRequest.operator).call{value: slashRequest.depositAmount}("");
            if (!success) revert EthTransferFailed();
        } else {
            (bool successRefund, ) = payable(slashRequest.requester).call{value: slashRequest.depositAmount}("");
            if (!successRefund) revert EthRefundFailed();
            
            bool slashingSucceeded = _handleInvalidSlashResponse(txHash, slashRequest);
            if (!slashingSucceeded) revert OperatorSlashingFailed();
        }

        emit SlashResponded(txHash, slashRequest.operator, slashRequest.requester, isValid, Status.Processed);
    }
    
    function _handleInvalidSlashResponse(bytes32 txHash, SlashRequest memory slashRequest) internal returns (bool) {
        StakeInfo[] memory operatorStakes = registry.getCurrentOperatorAllTokenStakes(slashRequest.operator);
        
        (address largestStakeToken, uint256 largestStakeAmount) = slashingManager.findLargestStake(operatorStakes);
        
        if (largestStakeToken == address(0) || largestStakeAmount == 0) {
            return false;
        }
        
        uint256 slashAmount = (largestStakeAmount * slashingManager.SLASH_BASIS_POINTS()) / 10000;

        if (slashAmount == 0) {
            return false;
        }
        
        return _executeOperatorSlash(txHash, slashRequest, largestStakeToken, 10);
    }
    
    function _executeOperatorSlash(
    bytes32 txHash, 
    SlashRequest memory slashRequest, 
    address tokenAddress, 
    uint256 slashAmount
) internal returns (bool) {
    address[] memory vaults = registry.getCurrentVaults();
    address vaultForToken = address(0);
    address slasherAddress = address(0);
    uint64 slasherType = 0;  
    
    for (uint256 i = 0; i < vaults.length; i++) {
        (address tokenFromVault, , , address slasher) = registry.getVaultDetails(vaults[i]);
        if (tokenFromVault == tokenAddress) {
            vaultForToken = vaults[i];
            slasherAddress = slasher;
            slasherType = IBaseSlasher(slasher).TYPE();
            break;
        }
    }
    
    if (vaultForToken == address(0)) {
        return false;
    }
    
    uint48 captureTimestamp = uint48(block.timestamp - 5); 
    bytes32 subnetwork = registry.getSubnetwork(0);
    
    return _executeSlash(
        txHash, 
        vaultForToken, 
        slashRequest, 
        tokenAddress, 
        slashAmount, 
        slasherAddress, 
        subnetwork, 
        captureTimestamp, 
        slasherType
    );
}

function _executeSlash(
    bytes32 txHash,
    address vaultForToken,
    SlashRequest memory slashRequest,
    address tokenAddress,
    uint256 slashAmount,
    address slasherAddress,
    bytes32 subnetwork,
    uint48 captureTimestamp,
    uint64 slasherType
) internal returns (bool) {
    if (slasherType == 0) {
        // Instant slash
        try ISlasher(slasherAddress).slash(
            subnetwork,
            slashRequest.operator,
            slashAmount,
            captureTimestamp,
            new bytes(0)
        ) returns (uint256 slashedAmount) {
            slashingManager.createSlashCredit(
                txHash,
                vaultForToken,
                slashRequest.requester,
                tokenAddress,
                slashedAmount,
                0, // slasherType
                0  // slashIndex for instant slash is always 0
            );
            return true;
        } catch {
            return false;
        }
    } else if (slasherType == 1) {
        // Veto slash
        try IVetoSlasher(slasherAddress).requestSlash(
            subnetwork,
            slashRequest.operator,
            slashAmount,
            captureTimestamp,
            new bytes(0)
        ) returns (uint256 slashIndex) {
            slashingManager.createSlashCredit(
                txHash,
                vaultForToken,
                slashRequest.requester,
                tokenAddress,
                slashAmount,
                1, // slasherType
                slashIndex
            );
            return true;
        } catch {
            return false;
        }
    }
    
    return false;
}

    // function processSlashCredit(bytes32 txHash) external nonReentrant {
    //     SlashCredit memory credit = slashingManager.getSlashCredit(txHash);
    //     require(credit.requester != address(0), "No slash credit exists for this txHash");

    //     address collateralToken = registry.getVaultToken(credit.vault);

    //     try IERC20(collateralToken).transfer(credit.requester, credit.amount) {
    //             credit.status = IValidationServiceManager.SlashCreditStatus.Processed;
    //     } catch {
    //             credit.status = IValidationServiceManager.SlashCreditStatus.Failed;
    //         }
    //     // if (credit.slasherType == 0) { // INSTANT_SLASHER_TYPE
    //     //     slashingManager.processSlashCredit(txHash);
    //     // } else if (credit.slasherType == 1) { // VETO_SLASHER_TYPE
    //     //     address[] memory vaults = registry.getCurrentVaults();
    //     //     address slasherAddress = address(0);
            
    //     //     for (uint256 i = 0; i < vaults.length && slasherAddress == address(0); i++) {
    //     //         (address tokenAddress, , , address slasher) = registry.getVaultDetails(vaults[i]);
    //     //         if (tokenAddress == credit.tokenAddress) {
    //     //             slasherAddress = slasher;
    //     //         }
    //     //     }
            
    //     //     if (slasherAddress == address(0)) {
    //     //         slashingManager.updateVetoSlashCreditStatus(txHash, false);
    //     //         return;
    //     //     }
            
    //     //     try IVetoSlasher(slasherAddress).slashRequests(credit.slashIndex) returns (
    //     //         bytes32 subnetwork,
    //     //         address operator,
    //     //         uint256 amount,
    //     //         uint48 captureTimestamp,
    //     //         uint48 vetoDeadline,
    //     //         bool completed
    //     //     ) {
    //     //         // Check if veto period has passed and slash is completed
    //     //         if (completed && block.timestamp > vetoDeadline) {
    //     //             // This is a simplification - in a real implementation you'd need to check
    //     //             // if the slash was actually executed and not vetoed
    //     //             slashingManager.updateVetoSlashCreditStatus(txHash, true);
    //     //         } else {
    //     //             slashingManager.updateVetoSlashCreditStatus(txHash, false);
    //     //         }
    //     //     } catch {
    //     //         // Error accessing veto slasher, mark as failed
    //     //         slashingManager.updateVetoSlashCreditStatus(txHash, false);
    //     //     }
    //     // }
    // }

    function processSlashCredit(bytes32 txHash) external nonReentrant {
        SlashCredit memory credit = slashingManager.getSlashCredit(txHash);
        // require(credit.requester != address(0), "No slash credit exists for this txHash");
        // require(credit.status == IValidationServiceManager.SlashCreditStatus.Pending, "Credit already processed");

        address collateralToken = registry.getVaultCollateral(credit.vault);
        console.log("collateralToken", collateralToken);
        bool success = IERC20(collateralToken).transfer(credit.requester, credit.amount);
        // require(success, "Token transfer failed");
        
        // Update the status in storage, not just in memory
        slashingManager.updateSlashCreditStatus(txHash, IValidationServiceManager.SlashCreditStatus.Processed);
        
    }
    

   

    // Allow contract to receive ETH
    receive() external payable {}
    fallback() external payable {}
}