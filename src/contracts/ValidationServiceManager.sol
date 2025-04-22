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
import {IDefaultOperatorRewards} from
    "@symbiotic-rewards/src/interfaces/defaultOperatorRewards/IDefaultOperatorRewards.sol";
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
    uint64 private constant INSTANT_SLASHER_TYPE = 0;
    uint64 private constant VETO_SLASHER_TYPE = 1;
    
    uint256 public SLASH_AMOUNT;
    uint256 public SLASH_PERIOD; 
    uint256 public constant SLASH_DEPOSIT_AMOUNT = 0.05 ether;

    
    mapping(bytes32 => SlashCredit[]) public slashCredits;
    
    event SlashAmountUpdated(uint256 amount);
    event SlashPeriodUpdated(uint256 period);

    modifier updateStakeCache(uint48 epoch) {
        registry.calcAndCacheStakes(epoch);
        _;
    }

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
    
    function setSlashAmount(address token, uint256 amount) external onlyOwner {
        registry.setSlashAmount(token, amount);
    }

    function setSlashPeriod(uint256 period) external onlyOwner {
        SLASH_PERIOD = period;
        emit SlashPeriodUpdated(period);
    }

    // Registry Methods
    function getEpochAtTs(
        uint48 timestamp
    ) public view returns (uint48 epoch) {
        return registry.getEpochAtTs(timestamp);
    }

    function getCurrentEpoch() public view returns (uint48 epoch) {
        return registry.getCurrentEpoch();
    }

    function getEpochStartTs(
        uint48 epoch
    ) public view returns (uint48 timestamp) {
        return registry.getEpochStartTs(epoch);
    }

    function setSubnetworkCount(
        uint256 _subnetworkCount
    ) external onlyOwner {
        registry.setSubnetworkCount(_subnetworkCount);
    }

    function registerOperator(address operator, address txOrderer) external onlyOwner {
        registry.registerOperator(operator, txOrderer);
    }

    function pauseOperator(
        address operator
    ) external onlyOwner {
        registry.pauseOperator(operator);
    }

    function unpauseOperator(
        address operator
    ) external onlyOwner {
        registry.unpauseOperator(operator);
    }

    function unregisterOperator(
        address operator
    ) external onlyOwner {
        registry.unregisterOperator(operator);
    }

    function updateTxOrdererAddress(address operator, address txOrderer) external onlyOwner {
        registry.updateTxOrdererAddress(operator, txOrderer);
    }

    function registerToken(
        address token
    ) external onlyOwner {
        registry.registerToken(token);
    }

    function setMinimumStakingAmount(address token, uint256 amount) external onlyOwner {
        registry.setMinimumStakingAmount(token, amount);
    }

    function pauseToken(
        address token
    ) external onlyOwner {
        registry.pauseToken(token);
    }

    function unpauseToken(
        address token
    ) external onlyOwner {
        registry.unpauseToken(token);
    }

    function unregisterToken(
        address token
    ) external onlyOwner {
        registry.unregisterToken(token);
    }

    function registerVault( address vault, address stakerRewards, address operatorRewards, address slasher ) external onlyOwner {
        registry.registerVault(vault, stakerRewards, operatorRewards, slasher);
    }

    function pauseVault( address vault ) external onlyOwner {
        registry.pauseVault(vault);
    }

    function unpauseVault( address vault ) external onlyOwner {
        registry.unpauseVault(vault);
    }

    function unregisterVault( address vault ) external onlyOwner {
        registry.unregisterVault(vault);
    }

    function calcAndCacheStakes( uint48 epoch ) external {
        registry.calcAndCacheStakes(epoch);
    }

    // Liveness Manager Methods
    function initializeCluster(string calldata clusterId, uint256 maxTxOrdererNumber) external {
        livenessServiceManager.initializeCluster(clusterId, maxTxOrdererNumber, msg.sender);
    }

    function addRollup(string calldata clusterId, ILivenessServiceManager.NewRollup calldata newRollup) external {
        require(newRollup.validationInfo.validationServiceManager == address(this), "Invalid VSM");

        livenessServiceManager.addRollup(clusterId, newRollup, msg.sender);
    }

    function getBlockMargin() external view returns (uint256) {
        return livenessServiceManager.BLOCK_MARGIN();
    }

    function getRollups( string calldata clusterId ) external view returns (ILivenessServiceManager.Rollup[] memory) {
        return livenessServiceManager.getRollups(clusterId);
    }

    function getRollup( string calldata clusterId, string calldata rollupId ) external view returns (ILivenessServiceManager.Rollup memory) {
        return livenessServiceManager.getRollup(clusterId, rollupId);
    }

    function registerTxOrderer( string calldata clusterId ) external {
        if (!registry.checkIncludingTxOrdererAddress(msg.sender)) {
            revert OperatorNotRegistered();
        }
        livenessServiceManager.registerTxOrderer(clusterId, msg.sender);
    }

    function deregisterTxOrderer( string calldata clusterId ) external {
        livenessServiceManager.deregisterTxOrderer(clusterId, msg.sender);
    }

    function registerRollupExecutor(string calldata clusterId, string calldata rollupId, address executor) external {
        livenessServiceManager.registerRollupExecutor(clusterId, rollupId, executor, msg.sender);
    }

    function createNewTask(Task calldata task, DistributionParams calldata distributionParams) external     updateStakeCache(getCurrentEpoch())
    {
        if (!registry.checkIncludingTxOrdererAddress(msg.sender)) {
            revert OperatorNotRegistered();
        }
        if (!livenessServiceManager.isRollupAdded(task.clusterId, task.rollupId)) {
            revert RollupNotRegistered();
        }

        uint256 latestTaskNumber = taskManager.getLatestTaskNumber(task.rollupId);
        taskManager.createNewTask(task, distributionParams, msg.sender);

        if (latestTaskNumber > 0 && distributionParams.operatorMerkleRoots.length > 0) {
            rewardsManager.storeDistributionData(
                task.clusterId, task.rollupId, distributionParams.pendingRewardTaskIndex, distributionParams
            );
        }
    }
    
    function respondToTask( string calldata clusterId, string calldata rollupId, uint256 referenceTaskIndex, bool response ) external {
        if (!registry.checkIncludingTxOrdererAddress(msg.sender)) {
            revert OperatorNotRegistered();
        }

        taskManager.respondToTask(clusterId, rollupId, referenceTaskIndex, response, msg.sender);
    }

    function executeDistributions(string calldata clusterId, string calldata rollupId) external nonReentrant {
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

        uint256 startingTaskIndex = rewardsManager.getLatestDistributedTaskIndex(clusterId, rollupId);
        uint256 taskCount = taskManager.getLatestTaskNumber(rollupId) + 1;
        
        (
            RewardsManager.AggregatedDistributionData memory aggregatedData,
            uint256 totalRewardsRequired
        ) = rewardsManager.processDistributionData(
            clusterId, 
            rollupId, 
            startingTaskIndex, 
            taskCount,
            taskManager.getTaskResponseCount  
        );
        
        if (aggregatedData.taskCount == 0) {
            revert NoPendingDistributions();
        }
        
        uint256 approvedAmount = IRewardsCore(REWARDS_CORE_ADDRESS).approveRewardDistribution(
            NETWORK, clusterId, rollupId, totalRewardsRequired
        );

        IERC20(rewardToken).safeTransferFrom(REWARDS_CORE_ADDRESS, address(this), approvedAmount);
        
        uint48 oneSecondAgo = uint48(block.timestamp - 5);
        
        for (uint256 i = 0; i < aggregatedData.vaultAddresses.length; i++) {
            _distributeToVault( rewardToken, aggregatedData.vaultAddresses[i], aggregatedData.operatorMerkleRoots[i], aggregatedData.totalStakerReward[i], aggregatedData.totalOperatorReward[i], oneSecondAgo );
        }
        
        rewardsManager.markMultipleDistributionsAsCompleted(clusterId, rollupId, aggregatedData.taskIndices);
        
        emit RewardsDistributed(clusterId, rollupId, aggregatedData.taskIndices[aggregatedData.taskIndices.length - 1]);
    }

    function _distributeToVault( address rewardToken, address vaultAddress, bytes32 operatorMerkleRoot, uint256 stakerReward, uint256 operatorReward, uint48 oneSecondAgo ) internal {
        address tokenAddress = registry.getVaultToken(vaultAddress);
        address stakerRewards;
        address operatorRewards;
        address slasher;

        (tokenAddress, stakerRewards, operatorRewards, slasher) = registry.getVaultDetails(vaultAddress);

        if (stakerRewards != address(0)) {
            _safeTokenApprove(rewardToken, stakerRewards, stakerReward);
            IDefaultStakerRewards(stakerRewards).distributeRewards(
                NETWORK, rewardToken, stakerReward, abi.encode(oneSecondAgo, 10000, new bytes(0), new bytes(0))
            );
        }

        if (operatorRewards != address(0)) {
            _safeTokenApprove(rewardToken, operatorRewards, operatorReward);
            IDefaultOperatorRewards(operatorRewards).distributeRewards(
                NETWORK, rewardToken, operatorReward, operatorMerkleRoot
            );
        }
    }

    function _safeTokenApprove(address token, address spender, uint256 amount) private {
        SafeERC20.safeIncreaseAllowance(IERC20(token), spender, amount);
    }

    function _safeTransferEth(address payable _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert EthTransferFailed(); 
        }
    }

    function getDistributionData( string memory clusterId, string memory rollupId, uint256 referenceTaskId ) public view returns (
        address[] memory vaultAddresses, bytes32[] memory operatorMerkleRoots, uint256[] memory totalStakerReward, uint256[] memory totalOperatorReward, bool distributed
    )

    {
        (vaultAddresses, operatorMerkleRoots, totalStakerReward, totalOperatorReward, distributed) = rewardsManager.getDistributionData(clusterId, rollupId, referenceTaskId);
    }

    function getSlashRequestDetails( bytes32 txHash ) external view returns (SlashRequest memory) {
        return slashingManager.getSlashRequestDetails(txHash);
    }

    function getSlashCreditDetails( bytes32 txHash ) external view returns (SlashCredit memory) {
        return slashingManager.getSlashCredit(txHash);
    }

    function requestSlash( address operator, string calldata clusterId, string calldata rollupId, uint256 batchNumber, bytes32 txHash, uint256 txOrder, bytes32[] calldata preMerklePath, bytes calldata signature ) external payable {
        if (txHash == bytes32(0)) {
            revert InvalidTransactionHash();
        }

        if (msg.value != SLASH_DEPOSIT_AMOUNT) {
            revert IncorrectSlashDepositAmount();
        }

        if (!livenessServiceManager.isRollupAdded(clusterId, rollupId)) {
            revert RollupNotRegistered();
        }

        if (!registry.checkIncludingTxOrdererAddress(operator)) {
            revert OperatorNotRegistered();
        }

        SlashRequest memory existingRequest = slashingManager.getSlashRequestDetails(txHash);
        if (existingRequest.txHash != bytes32(0)) {
            revert SlashRequestAlreadyExists();
        }

        bool isValid = slashingManager.verifyOrderCommitmentSignature( operator, rollupId, batchNumber, txHash, txOrder, preMerklePath, signature );

        if (!isValid) {
            revert InvalidSignature();
        }

        slashingManager.storeSlashRequest( operator, msg.sender, clusterId, rollupId, batchNumber, txHash, txOrder, preMerklePath, signature, msg.value, block.timestamp );

        emit SlashRequested(txHash, operator, clusterId, rollupId, batchNumber, txOrder, msg.sender);
    }

    function respondToSlash(bytes32 txHash, bytes32[] calldata postMerklePath) external nonReentrant {
       
        SlashRequest memory slashRequest = slashingManager.getSlashRequestDetails(txHash);

       
        if (slashRequest.txHash == bytes32(0)) {
            console.log("Slash request not found for txHash");
            revert SlashRequestNotFound();
        }

        if (slashRequest.status != Status.Pending) {
            console.log("Slash request already processed");
            revert SlashRequestAlreadyProcessed();
        }

        if (msg.sender != slashRequest.operator) {
            console.log("Invalid responder for slash request. Expected %s", msg.sender);
            revert InvalidSlashResponder();
        }

        bool inResponsePeriod = (block.timestamp <= slashRequest.timestamp + SLASH_PERIOD);
        console.log("inResponsePeriod for txHash: %s", inResponsePeriod);

        if (!inResponsePeriod) {
            console.log("Response period expired for txHash ");
            slashingManager.updateSlashRequestStatus(txHash, Status.Processed);
            _processInvalidOrExpiredSlash(txHash, slashRequest);
            emit SlashResponded(txHash, slashRequest.operator, slashRequest.requester, false, Status.Processed);
            return;  
        }

        uint256 taskIndex = taskManager.getTaskIndexFromBatchNumber(slashRequest.rollupId, slashRequest.batchNumber);
        bytes32 merkleRoot = taskManager.getBatchCommitment(slashRequest.rollupId, taskIndex);
        bool isValid = slashingManager.validateMerkleProof(txHash, merkleRoot, postMerklePath);
        console.log("Merkle proof validation result for txHash: %s", isValid);

        slashingManager.updateSlashRequestStatus(txHash, Status.Processed);

        if (isValid) {
            // Valid proof: Operator post merkle valid. Slash requester's deposit -> operator.
            console.log("Valid response for txHash. Refunding operator.");
            _safeTransferEth(payable(slashRequest.operator), slashRequest.depositAmount);
        } else {
            // Invalid proof: Operator post merkle invalid. Refund requester, slash operator.
            console.log("Invalid response for txHash. Refunding requester and slashing operator.");
            _processInvalidOrExpiredSlash(txHash, slashRequest);
        }

        emit SlashResponded(txHash, slashRequest.operator, slashRequest.requester, isValid, Status.Processed);
    }

    function _handleInvalidSlashResponse(bytes32 txHash, SlashRequest memory slashRequest) internal returns (bool) {
        StakeInfo[] memory operatorStakes = registry.getCurrentOperatorAllTokenStakes(slashRequest.operator);

        if (operatorStakes.length == 0) {
            console.log("Operator has no stakes to slash for txHash.");
            return false;  
        }
        console.log("Found %d staked tokens for operator %s for txHash", operatorStakes.length, slashRequest.operator);

        bool anySlashSucceeded = false;
        uint48 captureTimestamp = uint48(block.timestamp - 5);  
        bytes32 subnetwork = registry.getSubnetwork(0);  

        address[] memory allVaults = registry.getCurrentVaults();  

        for (uint256 i = 0; i < operatorStakes.length; i++) {
            address tokenAddress = operatorStakes[i].token;
            uint256 stakeAmount = operatorStakes[i].stakeAmount;  

            if (stakeAmount == 0) {  
                continue;
            }
            console.log("Processing token %s for operator %s ", tokenAddress, slashRequest.operator);

            for (uint256 j = 0; j < allVaults.length; j++) {
                address currentVaultAddress = allVaults[j];
                (address tokenFromVault, , , address slasher) = registry.getVaultDetails(currentVaultAddress);

                if (tokenFromVault == tokenAddress && slasher != address(0)) {
                    console.log("Found matching vault %s for token %s", currentVaultAddress, tokenAddress);
                    uint256 slashAmount = registry.getSlashAmount(tokenAddress);  
                    uint64 slasherType = IBaseSlasher(slasher).TYPE();  

                    console.log("Attempting slash ");
                    console.log("Vault", currentVaultAddress);
                    console.log("tokenAddress", tokenAddress);
                    console.log("slashAmount", slashAmount);
                    console.log("slasherType", slasherType);

                    bool slashSuccess = _executeSlash(
                        txHash, currentVaultAddress, slashRequest, tokenAddress,
                        slashAmount, slasher, subnetwork, captureTimestamp, slasherType
                    );

                    if (slashSuccess) {
                        anySlashSucceeded = true;
                    } else {
                        console.log("Slash attempt failed for Vault %s, Token %s", currentVaultAddress, tokenAddress);
                    }
                   
                    break;  
                }
            }
        }

        if (!anySlashSucceeded) {
            console.log("No slash attempts were successful for operator %s", slashRequest.operator);
        }

        return anySlashSucceeded;  
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
        if (slasherType == INSTANT_SLASHER_TYPE) {  
            try ISlasher(slasherAddress).slash(
                subnetwork, slashRequest.operator, slashAmount, captureTimestamp, new bytes(0)  
            ) returns (uint256 slashedAmount) {
                slashingManager.createSlashCredit(
                    txHash, vaultForToken, slashRequest.requester, tokenAddress,
                    slashedAmount,  
                    INSTANT_SLASHER_TYPE, 
                    0   
                );
                console.log("Instant Slash successful: Vault=%s, Operator=%s, Amount=%d", vaultForToken, slashRequest.operator, slashedAmount);
                return true;
            } catch Error(string memory reason) {
                console.log("Instant Slasher Slash Failed: Vault=%s, Reason=%s", vaultForToken, reason);
                return false;
            } catch {
                console.log("Instant Slasher Slash Failed with unknown error: Vault=%s", vaultForToken);
                return false;
            }
        } else if (slasherType == VETO_SLASHER_TYPE) {  
            try IVetoSlasher(slasherAddress).requestSlash(
                subnetwork, slashRequest.operator, slashAmount, captureTimestamp, new bytes(0)  
            ) returns (uint256 slashIndex) {
                slashingManager.createSlashCredit(
                    txHash, vaultForToken, slashRequest.requester, tokenAddress,
                    slashAmount,  
                    VETO_SLASHER_TYPE,
                    slashIndex  
                );
                console.log("Veto Slash Request successful ");
                console.log("Vault", vaultForToken);
                console.log("slashRequest.operator", slashRequest.operator);
                console.log("slashAmount", slashAmount);
                console.log("slashIndex", slashIndex);
                return true;
            } catch Error(string memory reason) {
                console.log("Veto Slasher Request Failed: Vault=%s, Reason=%s", vaultForToken, reason);
                return false;
            } catch {
                console.log("Veto Slasher Request Failed with unknown error: Vault=%s", vaultForToken);
                return false;
            }
        } else {
            
            console.log("Unknown slasher type %d for slasher %s", slasherType, slasherAddress);
            return false;
        }
    }


    function processSlashRequest(bytes32 txHash) external nonReentrant {
        SlashRequest memory slashRequest = slashingManager.getSlashRequestDetails(txHash);

        if (slashRequest.txHash == bytes32(0)) {
            revert SlashRequestNotFound();
        }

        if (slashRequest.status != Status.Pending) {
            revert SlashRequestAlreadyProcessed();
        }

      
        bool responsePeriodExpired = (block.timestamp > slashRequest.timestamp + SLASH_PERIOD);

        if (!responsePeriodExpired) {
            revert("Slash response period has not expired yet.");  
        }

        console.log("Processing expired slash request txHash");

        slashingManager.updateSlashRequestStatus(txHash, Status.Processed);

        _processInvalidOrExpiredSlash(txHash, slashRequest);

        emit SlashResponded(txHash, slashRequest.operator, slashRequest.requester, false, Status.Processed);
    }

    function processSlashCredit(bytes32 txHash) external nonReentrant {
        IValidationServiceManager.SlashCredit memory credit = slashingManager.getSlashCredit(txHash);

        if (credit.requester == address(0)) {
            revert IValidationServiceManager.SlashCreditNotFound();
        }

        if (credit.status != IValidationServiceManager.SlashCreditStatus.Pending) {
            revert IValidationServiceManager.SlashCreditAlreadyProcessed();
        }

        address collateralTokenAddress = registry.getVaultCollateral(credit.vault);
        if (collateralTokenAddress == address(0)) {
            revert IValidationServiceManager.TokenNotWhitelisted(); 
        }
        console.log("Processing credit for txHash");

        console.log("Vault", credit.vault);
        console.log("collateralTokenAddress", collateralTokenAddress);
        console.log("credit.requester", credit.requester);
        console.log("credit.amount", credit.amount);

       
        if (credit.amount > 0) {
            IERC20(collateralTokenAddress).safeTransfer(credit.requester, credit.amount);
            console.log("Token transfer successful");
        } else {
             console.log("Credit amount is 0 for txHash, skipping transfer.");
        }
        
        slashingManager.updateSlashCreditStatus(txHash, IValidationServiceManager.SlashCreditStatus.Processed);
        console.log("Updated credit status to Processed for txHash");
    }

    function _processInvalidOrExpiredSlash(bytes32 _txHash, SlashRequest memory _slashRequest) internal {
        _safeTransferEth(payable(_slashRequest.requester), _slashRequest.depositAmount);
        console.log("Refunded requester for txHash");
        bool slashingSucceeded = _handleInvalidSlashResponse(_txHash, _slashRequest);
        if (!slashingSucceeded) {
            revert OperatorSlashingFailed();
        }
        console.log("Slashed operator for txHash");
        console.log("Vault", _slashRequest.operator);
                
    }

    receive() external payable {}
    fallback() external payable {}
}