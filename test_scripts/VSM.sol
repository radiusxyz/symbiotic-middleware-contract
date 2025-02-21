// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {console} from "forge-std/src/console.sol";


import {Time} from "@openzeppelin-contracts/contracts/utils/types/Time.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {EnumerableMap} from "@openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";
import {ECDSAUpgradeable} from "@openzeppelin-contracts-upgradeable/contracts/utils/cryptography/ECDSAUpgradeable.sol";

import {IRegistry} from "@symbiotic-core/src/interfaces/common/IRegistry.sol";
import {IEntity} from "@symbiotic-core/src/interfaces/common/IEntity.sol";
import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";
import {IBaseDelegator} from "@symbiotic-core/src/interfaces/delegator/IBaseDelegator.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";
import {Subnetwork} from "@symbiotic-core/src/contracts/libraries/Subnetwork.sol";
import {ICollateral} from "@symbiotic-collateral/src/interfaces/ICollateral.sol";

import {MapWithTimeData} from "src/libraries/MapWithTimeData.sol";
import {OperatingRegistry} from "./OperatingRegistry.sol";
import {IValidationServiceManager} from "src/IValidationServiceManager.sol";
import {IDefaultOperatorRewards} from "@symbiotic-rewards/src/interfaces/defaultOperatorRewards/IDefaultOperatorRewards.sol";
import {IDefaultStakerRewards} from "@symbiotic-rewards/src/interfaces/defaultStakerRewards/IDefaultStakerRewards.sol";
import {IRewardsCore} from "./rewards/interfaces/IRewardsCore.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {INetworkMiddlewareService} from "@symbiotic-core/src/interfaces/service/INetworkMiddlewareService.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";


contract ValidationServiceManager is Ownable, IValidationServiceManager, OperatingRegistry, ReentrancyGuard {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using MapWithTimeData for EnumerableMap.AddressToUintMap;
    using Subnetwork for address;
    using ECDSAUpgradeable for bytes32;
    using SafeERC20 for IERC20;

    address public immutable NETWORK;

    address public immutable OPERATOR_NET_OPT_IN;
    address public immutable VAULT_REGISTRY;

    uint48 public immutable START_TIME;
    uint48 public immutable EPOCH_DURATION;

    uint256 public subnetworkCount;

    mapping(uint48 => bool) public totalStakeCached; 
    mapping(uint48 => mapping(address => uint256)) public tokenTotalStakeCache;
    mapping(uint48 => mapping(address => mapping(address => uint256))) public operatorStakeInfoCache;
    
    EnumerableMap.AddressToUintMap private tokens;
    EnumerableMap.AddressToUintMap private vaults;
    EnumerableMap.AddressToUintMap private operators;

    address public immutable STAKER_REWARDS_REGISTRY;
    address public immutable OPERATOR_REWARDS_REGISTRY;
    address public immutable REWARDS_MANAGER;

    mapping(address => Vault) public vaultDetails;


    mapping(string => RollupTaskInfo) public rollupTaskInfos;
    mapping(address => uint256) public minimumStakingAmounts;

    mapping(string => mapping(string => mapping(uint256 => DistributionData))) public distributionDataByTask;  // clusterId => rollupId => taskId => data
    mapping(string => mapping(string => TaskHistory)) public taskHistory;  // clusterId => rollupId => history

    uint256 constant MAX_STORED_TASKS = 5;

    modifier updateStakeCache(uint48 epoch) {
        if (!totalStakeCached[epoch]) {
            _calcAndCacheStakes(epoch);
        }
        _;
    }

    // Add this struct to store distribution data
    struct DistributionData {
        address[] vaultAddresses;
        bytes32[] operatorMerkleRoots;
        uint256[] totalStakerReward;
        uint256[] totalOperatorReward;
        uint256 taskId;
        bool exists;
    }

    // Add this struct to track task history
    struct TaskHistory {
        uint256[] taskIds;  // Circular buffer of last 5 task IDs
        uint256 currentIndex;  // Current index in the circular buffer
    }

    constructor(
        address _network,

        address _vaultRegistry,
        address _operatorNetOptIn,

        uint48 _epochDuration, // TODO
        address _staker_rewards_registry,
        address _operator_rewards_registry,
        address _rewards_manager

    ) Ownable(msg.sender) {
        START_TIME = Time.timestamp();

        NETWORK = _network;
        
        VAULT_REGISTRY = _vaultRegistry;
        OPERATOR_NET_OPT_IN = _operatorNetOptIn;

        EPOCH_DURATION = _epochDuration;

        subnetworkCount = 1;
        
        STAKER_REWARDS_REGISTRY = _staker_rewards_registry;
        OPERATOR_REWARDS_REGISTRY = _operator_rewards_registry;

        REWARDS_MANAGER = _rewards_manager;
    }

    ///////////// Epoch management
    function getEpochAtTs(uint48 timestamp) public view returns (uint48 epoch) {
        return (timestamp - START_TIME) / EPOCH_DURATION;
    }

    function getCurrentEpoch() public view returns (uint48 epoch) {
        return getEpochAtTs(Time.timestamp());
    }

    function getEpochStartTs(
        uint48 epoch
    ) public view returns (uint48 timestamp) {
        return START_TIME + epoch * EPOCH_DURATION;
    }

    ///////////// Network management
    function setSubnetworkCount(uint256 _subnetworkCount) external onlyOwner {
        if (subnetworkCount >= _subnetworkCount) {
            revert InvalidSubnetworkCount();
        }

        subnetworkCount = _subnetworkCount;
    }

    function getSubnetwork(uint96 index) external view returns (bytes32) {
        return NETWORK.subnetwork(index);
    }

    ///////////// Operator management
    function registerOperator(address operator, address operating) external onlyOwner {
        if (operators.contains(operator)) {
            revert OperatorAlreadyRegistered();
        }

        if (!IOptInService(OPERATOR_NET_OPT_IN).isOptedIn(operator, NETWORK)) {
            revert OperatorNotOptedIn();
        }

        _initOperatingAddress(operator, operating);

        operators.add(operator);
        operators.enable(operator);

        emit RegisterOperator(operator, operating);
    }

    function pauseOperator(address operator) external onlyOwner {
        operators.disable(operator);
    }

    function unpauseOperator(address operator) external onlyOwner {
        operators.enable(operator);
    }

    function unregisterOperator(address operator) external onlyOwner {
        (, uint48 disabledTime) = operators.getTimes(operator);

        if (disabledTime == 0) {
            revert OperatorGracePeriodNotPassed();
        }

        operators.remove(operator);
        _updateOperatingAddress(operator, address(0));
        
        emit UnregisterOperator(operator);
    }

    function updateOperatingAddress(address operator, address operating) external onlyOwner {
        if (!operators.contains(operator)) {
            revert OperatorNotRegistered();
        }

        _updateOperatingAddress(operator, operating);

        emit UpdateOperatingAddress(operator, operating);
    }

    function getCurrentOperatorInfos() public view returns (OperatorInfo[] memory operatorInfos) {
        return getOperatorInfos(getCurrentEpoch());
    }

    function getOperatorInfos(uint48 epoch) public view returns (OperatorInfo[] memory operatorInfos) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        uint256 operatorCount = operators.length();
        operatorInfos = new OperatorInfo[](operatorCount);
        
        uint256 operatorIndex = 0;

        for (uint256 i; i < operatorCount; ++i) {
            (address operator, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);

            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) continue;

            address operating = getOperatingAddressAt(operator, epochStartTs);

            StakeInfo[] memory tokenStakes = getOperatorAllTokenStakes(operator, epochStartTs);

            operatorInfos[operatorIndex++] = OperatorInfo(operator, operating, tokenStakes);
        }

        assembly ("memory-safe") {
            mstore(operatorInfos, operatorIndex)
        }
    }

    ///////////// Token management
    function registerToken(address token) external onlyOwner {
        if (tokens.contains(token)) {
            revert TokenAlreadyRegistered();
        }

        tokens.add(token);
        tokens.enable(token);

        emit RegisterToken(token);
    }

    function registerTokenTest(address token) external onlyOwner {
        emit RegisterToken(token);
    }

     function respondToTaskTest(
        string calldata clusterId,
        string calldata rollupId,
        uint32 referenceTaskIndex,
        bool response
    ) external {
       
        emit TaskResponded(clusterId, rollupId, referenceTaskIndex, response, msg.sender);
        
    }

    function setMinimumStakingAmount(address token, uint256 amount) external onlyOwner {
        minimumStakingAmounts[token] = amount;

        emit SetMinimumStakeAmount(token, amount);
    }

    function pauseToken(address token) external onlyOwner {
        tokens.disable(token);
    }

    function unpauseToken(address token) external onlyOwner {
        tokens.enable(token);
    }

    function unregisterToken(address token) external onlyOwner {
        (, uint48 disabledTime) = tokens.getTimes(token);

        if (disabledTime == 0) {
            revert TokenGracePeriodNotPassed();
        }

        tokens.remove(token);

        emit UnregisterToken(token);
    }

    function isActiveToken(address token) public view returns (bool) {
        if (!tokens.contains(token)) {
            return false;
        }

        uint48 epoch = getCurrentEpoch();
        uint48 epochStartTs = getEpochStartTs(epoch);
        
        (uint48 enabledTime, uint48 disabledTime) = tokens.getTimes(token);

        return _wasActiveAt(enabledTime, disabledTime, epochStartTs);
    }

    function getCurrentTokens() public view returns (address[] memory) {
        return getTokens(getCurrentEpoch());
    }

    function getTokens(uint48 epoch) public view returns (address[] memory) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        uint256 tokenCount = tokens.length();
        address[] memory tokenAddresses = new address[](tokenCount);
        
        uint256 tokenIndex = 0;

        for (uint256 i; i < tokenCount; ++i) {
            (address token, uint48 enabledTime, uint48 disabledTime) = tokens.atWithTimes(i);

            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) continue;

            tokenAddresses[tokenIndex++] = token;
        }

        return tokenAddresses;
    }

    function getTokenAddress(address collateralOrToken) public view returns (address) {
        try ICollateral(collateralOrToken).asset() returns (address asset) {
            return asset;
        } catch {
            return collateralOrToken;
        }
    }

    function getVaultToken(address vault) public view returns (address) {
        return getTokenAddress(IVault(vault).collateral());
    }

    ///////////// Vault management
    function registerVault(address vault, address stakerRewards, address operatorRewards) external onlyOwner {
        if (vaults.contains(vault)) {
            revert VaultAlreadyRegistered();
        }

        if (!IRegistry(VAULT_REGISTRY).isEntity(vault)) {
            revert VaultNotRegisteredInSymbiotic();
        }

        if (!IRegistry(STAKER_REWARDS_REGISTRY).isEntity(stakerRewards)) {
            revert VaultNotRegisteredInSymbiotic();
        }

        if (!IRegistry(OPERATOR_REWARDS_REGISTRY).isEntity(operatorRewards)) {
            revert VaultNotRegisteredInSymbiotic();
        }

        address token = getTokenAddress(IVault(vault).collateral());
        if (!tokens.contains(token)) {
            revert TokenNotWhitelisted();
        }

        vaults.add(vault);
        vaults.enable(vault);

        vaultDetails[vault] = Vault({
            tokenAddress: token,
            stakerRewards: stakerRewards,
            operatorRewards: operatorRewards
        });

        emit RegisterVault(vault, stakerRewards, operatorRewards);
    }

    function pauseVault(address vault) external onlyOwner {
        vaults.disable(vault);
    }

    function unpauseVault(address vault) external onlyOwner {
        vaults.enable(vault);
    }

    function unregisterVault(address vault) external onlyOwner {
        (, uint48 disabledTime) = vaults.getTimes(vault);

        if (disabledTime == 0) {
            revert VaultGracePeriodNotPassed();
        }

        vaults.remove(vault);
        delete vaultDetails[vault];

        emit UnregisterVault(vault);
    }

    function isActiveVault(address vault) public view returns (bool) {
        if (!vaults.contains(vault)) {
            return false;
        }

        uint48 epoch = getCurrentEpoch();
        uint48 epochStartTs = getEpochStartTs(epoch);

        (uint48 enabledTime, uint48 disabledTime) = vaults.getTimes(vault);

        return _wasActiveAt(enabledTime, disabledTime, epochStartTs);
    }

    function getCurrentVaults() public view returns (address[] memory) {
        return getVaults(getCurrentEpoch());
    }

    function getVaults(uint48 epoch) public view returns (address[] memory) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        uint256 vaultCount = vaults.length();
        address[] memory vaultAddresses = new address[](vaultCount);
        
        uint256 vaultIndex = 0;

        for (uint256 i; i < vaultCount; ++i) {
            (address vault, uint48 enabledTime, uint48 disabledTime) = vaults.atWithTimes(i);

            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) continue;

            vaultAddresses[vaultIndex++] = vault;
        }

        return vaultAddresses;
    }

    ///////////// Stake management
    function getCurrentTokenTotalStake(address token) public view returns (uint256 stakeAmount) {
        return getTokenTotalStake(token, getCurrentEpoch());
    }

    function getTokenTotalStake(address token, uint48 epoch) public view returns (uint256 totalStakeAmount) {
      if (totalStakeCached[epoch]) {
          return tokenTotalStakeCache[epoch][token];
      }
      
      uint48 epochStartTs = getEpochStartTs(epoch);
      uint256 operatorCount = operators.length();

      for (uint256 i; i < operatorCount; ++i) {
          (address operator, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);


          if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) continue;

          totalStakeAmount += getOperatorTokenStake(operator, token, epoch);
      }
      return totalStakeAmount;
    }

    function getCurrentAllTokenTotalStakes() public view returns (StakeInfo[] memory tokenStakes) {
        return getAllTokenTotalStakes(getCurrentEpoch());
    }

    function getAllTokenTotalStakes(uint48 epoch) public view returns (StakeInfo[] memory tokenStakes) {
      if (totalStakeCached[epoch]) {
          uint256 tokenCount = tokens.length();
          tokenStakes = new StakeInfo[](tokenCount);
          for (uint256 i; i < tokenCount; ++i) {
              (address token,,) = tokens.atWithTimes(i);
              uint256 tokenTotalStakeAmount = tokenTotalStakeCache[epoch][token];

              tokenStakes[i] = StakeInfo(token, tokenTotalStakeAmount);
          }
          
          return tokenStakes;
      }

      uint48 epochStartTs = getEpochStartTs(epoch);
      uint256 tokenCount = tokens.length();
      uint256 operatorCount = operators.length();

      tokenStakes = new StakeInfo[](tokenCount);
      for (uint256 i; i < tokenCount; ++i) {
          (address token,,) = tokens.atWithTimes(i);

          tokenStakes[i] = StakeInfo(token, 0);
      }
      
      for (uint256 i; i < operatorCount; ++i) {
        (address operator, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);

        if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) continue;

        for (uint256 j; j < tokenCount; ++j) {
          (address token, uint48 enabledTime, uint48 disabledTime) = tokens.atWithTimes(j);

          if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) continue;

          tokenStakes[j].stakeAmount += getOperatorTokenStake(operator, token, epoch);
        }
      }

      return tokenStakes;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////// 

    function getCurrentOperatorTokenStake(address operator, address token) public view returns (uint256 stakeAmount) {
        return getOperatorTokenStake(operator, token, getCurrentEpoch());
    }

    function getOperatorTokenStake(address operator, address token, uint48 epoch) public view returns (uint256 stakeAmount) {
        if (totalStakeCached[epoch]) {
            return operatorStakeInfoCache[epoch][token][operator];
        }

        uint48 epochStartTs = getEpochStartTs(epoch);
        uint256 vaultCount = vaults.length();

        for (uint256 i; i < vaultCount; ++i) {
            (address vault, uint48 enabledTime, uint48 disabledTime) = vaults.atWithTimes(i);
            
            address checkToken = getTokenAddress(IVault(vault).collateral());

            if (checkToken != token) {
                continue;
            }

            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            for (uint96 j = 0; j < subnetworkCount; ++j) {
                stakeAmount += IBaseDelegator(IVault(vault).delegator()).stakeAt(
                    NETWORK.subnetwork(j), operator, epochStartTs, new bytes(0)
                );
            }
        }

        return stakeAmount;
    }

    function getCurrentOperatorAllTokenStakes(address operator) public view returns (StakeInfo[] memory tokenStakes) {
        return getOperatorAllTokenStakes(operator, getCurrentEpoch());
    }

    function getOperatorAllTokenStakes(address operator, uint48 epoch) public view returns (StakeInfo[] memory tokenStakes) {
        if (totalStakeCached[epoch]) {
          uint256 tokenCount = tokens.length();
          tokenStakes = new StakeInfo[](tokenCount);
          for (uint256 i; i < tokenCount; ++i) {
              (address token,,) = tokens.atWithTimes(i);
              uint256 tokenStakeAmount = operatorStakeInfoCache[epoch][token][operator];

              tokenStakes[i] = StakeInfo(token, tokenStakeAmount);
          }
          
          return tokenStakes;
      }

        uint48 epochStartTs = getEpochStartTs(epoch);
        uint256 tokenCount = tokens.length();

        tokenStakes = new StakeInfo[](tokenCount);
        
        uint256 tokenIndex = 0;

        for (uint256 i; i < tokenCount; ++i) {
            (address token, uint48 enabledTime, uint48 disabledTime) = tokens.atWithTimes(i);

            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            uint256 tokenStake = getOperatorTokenStake(operator, token, epochStartTs);
            tokenStakes[tokenIndex++] = StakeInfo(token, tokenStake);
        }

        assembly ("memory-safe") {
            mstore(tokenStakes, tokenIndex)
        }
    }

    function _calcAndCacheStakes(uint48 epoch) internal {
        uint48 epochStartTs = getEpochStartTs(epoch);
        _validateEpoch(epochStartTs);

        uint256 operatorCount = operators.length();
        uint256 tokenCount = tokens.length();

        // Update operator token stakes
        for (uint256 i; i < operatorCount; ++i) {
            (address operator, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);

            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }
            
            for (uint256 j; j < tokenCount; ++j) {
                (address token, , ) = tokens.atWithTimes(j);

                operatorStakeInfoCache[epoch][token][operator] = getOperatorTokenStake(operator, token, epochStartTs);
            }
        }

        // Update total token stakes
        for (uint256 i; i < tokenCount; ++i) {
            (address token, uint48 enabledTime, uint48 disabledTime) = tokens.atWithTimes(i);

            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            tokenTotalStakeCache[epoch][token] = getTokenTotalStake(token, epoch);
        }

        totalStakeCached[epoch] = true;
    }

    ///////////// Task management
   function createNewTask(
    string calldata clusterId,
    string calldata rollupId,
    uint256 blockNumber,
    bytes32 blockCommitment,
    address[] calldata vaultAddresses,
    bytes32[] calldata operatorMerkleRoots,
    uint256[] calldata totalStakerReward, 
    uint256[] calldata totalOperatorReward
) external {
    
    // Check operator status
    require(checkIncludingOperatingAddress(msg.sender), "Operator not registered");

    console.log("================== createNewTask START ==================");
        console.log("Caller address:", msg.sender);
        console.log("Input Parameters:");
        console.log("  clusterId:", clusterId);
        console.log("  rollupId:", rollupId);
        console.log("  blockNumber:", blockNumber);
        console.log("Array lengths:");
        console.log("  vaultAddresses:", vaultAddresses.length);
        console.log("  merkleRoots:", operatorMerkleRoots.length);
        console.log("  stakerAmounts:", totalStakerReward.length);
        console.log("  operatorAmounts:", totalOperatorReward.length);


    // Create task
    console.log("\nCreating new task...");
    Task memory newTask;
    newTask.clusterId = clusterId;
    newTask.rollupId = rollupId;
    newTask.blockNumber = blockNumber;
    newTask.blockCommitment = blockCommitment;

    uint256 latestTaskNumber = rollupTaskInfos[rollupId].latestTaskNumber;
    console.log("Current latest task number:", latestTaskNumber);

    rollupTaskInfos[rollupId].latestTaskNumber += 1;
    console.log("New task number:", rollupTaskInfos[rollupId].latestTaskNumber);

    rollupTaskInfos[rollupId].blockCommitments[latestTaskNumber] = blockCommitment;
    
    bytes32 taskHash = keccak256(abi.encode(newTask));
    rollupTaskInfos[rollupId].taskHash[latestTaskNumber] = taskHash;

    emit NewTaskCreated(
        clusterId, 
        rollupId, 
        latestTaskNumber,
        blockCommitment
    );
    console.log("Emitted NewTaskCreated event");


    // Store distribution data if provided
    if (vaultAddresses.length > 0) {
        // Get or initialize task history
        TaskHistory storage history = taskHistory[clusterId][rollupId];
        if (history.taskIds.length == 0) {
            history.taskIds = new uint256[](MAX_STORED_TASKS);
        }

        // Clean up old task data if it exists
        if (history.taskIds.length == MAX_STORED_TASKS) {
            uint256 oldTaskId = history.taskIds[history.currentIndex];
            if (oldTaskId != 0) {
                delete distributionDataByTask[clusterId][rollupId][oldTaskId];
            }
        }

        // Store new task data
        DistributionData storage data = distributionDataByTask[clusterId][rollupId][latestTaskNumber];
        data.vaultAddresses = vaultAddresses;
        data.operatorMerkleRoots = operatorMerkleRoots;
        data.totalStakerReward = totalStakerReward;
        data.totalOperatorReward = totalOperatorReward;
        data.taskId = latestTaskNumber;
        data.exists = true;

        // Update task history
        history.taskIds[history.currentIndex] = latestTaskNumber;
        history.currentIndex = (history.currentIndex + 1) % MAX_STORED_TASKS;
    }

    emit NewTaskCreated(
        clusterId, 
        rollupId, 
        latestTaskNumber,
        blockCommitment
    );

    console.log("================== createNewTask END ==================");
}

function handleTaskDistribution(
    string calldata clusterId,
    string calldata rollupId,
    uint256 taskId
) external {
    console.log("\nProcessing distributions...");

    DistributionData storage data = distributionDataByTask[clusterId][rollupId][taskId];
    require(data.exists, "No distribution data found for task");

    console.log("Fetching distribution info from rewards manager...");
        (
            bool isEligible,
            uint256 availableAmount,
            address rewardToken,
            uint256 timeUntilNextDistribution,
            uint256 operatorAmount,
            uint256 stakerAmount
        ) = IRewardsCore(REWARDS_MANAGER).getDistributionInfo(
                clusterId,
                rollupId
        );

        console.log("Distribution info:");
        console.log("  isEligible:", isEligible);
        console.log("  availableAmount:", availableAmount);
        console.log("  rewardToken:", rewardToken);
        console.log("  timeUntilNextDistribution:", timeUntilNextDistribution);
        console.log("  operatorAmount:", operatorAmount);
        console.log("  stakerAmount:", stakerAmount);

        require(isEligible && availableAmount > 0, "Not eligible for distribution");

        uint256 approvedAmount = IRewardsCore(REWARDS_MANAGER)
            .approveRewardDistribution(NETWORK, clusterId, rollupId);

        console.log("Approved amount:", approvedAmount);


    IERC20(rewardToken).safeTransferFrom(
        REWARDS_MANAGER,
        address(this),
        availableAmount
    );

    uint48 oneSecondAgo = uint48(block.timestamp - 5);

    // Process each vault's distributions
    for (uint256 i = 0; i < data.vaultAddresses.length; i++) {

        console.log("\nProcessing vault distributions...");

        Vault memory vaultInfo = vaultDetails[data.vaultAddresses[i]];

        console.log("Vault info:");
        console.log("  tokenAddress:", vaultInfo.tokenAddress);
        console.log("  stakerRewards:", vaultInfo.stakerRewards);
        console.log("  operatorRewards:", vaultInfo.operatorRewards);
        
        if (vaultInfo.stakerRewards != address(0)) {

            console.log("Distributing staker rewards for vault...");
            console.log("  Amount:", data.totalStakerReward[i]);

            _safeTokenApprove(rewardToken, vaultInfo.stakerRewards, data.totalStakerReward[i]);

            IDefaultStakerRewards(vaultInfo.stakerRewards).distributeRewards(
                NETWORK,
                rewardToken,
                data.totalStakerReward[i],
                abi.encode(
                    oneSecondAgo,
                    10000,
                    new bytes(0),
                    new bytes(0)
                )
            );

            console.log("Staker rewards distributed successfully");

        }

        if (vaultInfo.operatorRewards != address(0)) {
             console.log("Distributing operator rewards for vault...");
            console.log("  Amount:", data.totalOperatorReward[i]);

            _safeTokenApprove(rewardToken, vaultInfo.operatorRewards, data.totalOperatorReward[i]);

            IDefaultOperatorRewards(vaultInfo.operatorRewards).distributeRewards(
                NETWORK,
                rewardToken,
                data.totalOperatorReward[i],
                data.operatorMerkleRoots[i]
            );
            console.log("Operator rewards distributed successfully");

        }
    }

    // Task has been processed, clean up its data
    delete distributionDataByTask[clusterId][rollupId][taskId];
}
 
    // function createNewTask(
    //     string calldata clusterId,
    //     string calldata rollupId,
    //     uint256 blockNumber,
    //     bytes32 blockCommitment,
    //     address[] calldata vaultAddresses,
    //     bytes32[] calldata operatorMerkleRoots,
    //     uint256[] calldata totalStakerReward, 
    //     uint256[] calldata totalOperatorReward

    // ) external {
    //     console.log("================== createNewTask START ==================");
    //     console.log("Caller address:", msg.sender);
    //     console.log("Input Parameters:");
    //     console.log("  clusterId:", clusterId);
    //     console.log("  rollupId:", rollupId);
    //     console.log("  blockNumber:", blockNumber);
    //     console.log("Array lengths:");
    //     console.log("  vaultAddresses:", vaultAddresses.length);
    //     console.log("  merkleRoots:", operatorMerkleRoots.length);
    //     console.log("  stakerAmounts:", totalStakerReward.length);
    //     console.log("  operatorAmounts:", totalOperatorReward.length);

    //     // Check operator status
    //     console.log("\nChecking operator status...");
    //     bool isOperatorValid = checkIncludingOperatingAddress(msg.sender);
    //     console.log("Operator validation result:", isOperatorValid);
    //     require(isOperatorValid, "Operator not registered");

    //     // Create task
    //     console.log("\nCreating new task...");
    //     Task memory newTask;
    //     newTask.clusterId = clusterId;
    //     newTask.rollupId = rollupId;
    //     newTask.blockNumber = blockNumber;
    //     newTask.blockCommitment = blockCommitment;

    //     uint256 latestTaskNumber = rollupTaskInfos[rollupId].latestTaskNumber;
    //     console.log("Current latest task number:", latestTaskNumber);

    //     rollupTaskInfos[rollupId].latestTaskNumber += 1;
    //     console.log("New task number:", rollupTaskInfos[rollupId].latestTaskNumber);

    //     rollupTaskInfos[rollupId].blockCommitments[latestTaskNumber] = blockCommitment;
        
    //     bytes32 taskHash = keccak256(abi.encode(newTask));
    //     rollupTaskInfos[rollupId].taskHash[latestTaskNumber] = taskHash;

    //     emit NewTaskCreated(
    //         clusterId, 
    //         rollupId, 
    //         latestTaskNumber,
    //         blockCommitment
    //     );
    //     console.log("Emitted NewTaskCreated event");

    //     // Handle distributions if applicable
    //     if (latestTaskNumber > 0 && operatorMerkleRoots.length > 0) {
    //         console.log("\nProcessing distributions...");
    //         uint48 currentTimestamp = uint48(block.timestamp);
    //         console.log("Current timestamp:", currentTimestamp);
    //         uint48 oneSecondAgo = uint48(block.timestamp - 5);

    //         console.log("Fetching distribution info from rewards manager...");
    //         (
    //             bool isEligible,
    //             uint256 availableAmount,
    //             address rewardToken,
    //             uint256 timeUntilNextDistribution,
    //             uint256 operatorAmount,
    //             uint256 stakerAmount
    //         ) = IRewardsCore(REWARDS_MANAGER).getDistributionInfo(
    //                 clusterId,
    //                 rollupId
    //         );

    //         console.log("Distribution info:");
    //         console.log("  isEligible:", isEligible);
    //         console.log("  availableAmount:", availableAmount);
    //         console.log("  rewardToken:", rewardToken);
    //         console.log("  timeUntilNextDistribution:", timeUntilNextDistribution);
    //         console.log("  operatorAmount:", operatorAmount);
    //         console.log("  stakerAmount:", stakerAmount);



    //         uint256 approvedAmount = IRewardsCore(REWARDS_MANAGER)
    //         .approveRewardDistribution(NETWORK, clusterId, rollupId);
    //         console.log("Approved amount:", approvedAmount);


    //         console.log("Transferring rewards from manager...");
    //         IERC20(rewardToken).safeTransferFrom(
    //             REWARDS_MANAGER,
    //             address(this),
    //             availableAmount
    //         );
            
    //         // Process vault distributions
    //         console.log("\nProcessing vault distributions...");
    //         for (uint256 i = 0; i < vaultAddresses.length; i++) {
    //             console.log("\nProcessing vault", i + 1, "of", vaultAddresses.length);
    //             console.log("Vault address:", vaultAddresses[i]);
                
    //             Vault memory vaultInfo = vaultDetails[vaultAddresses[i]];
    //             console.log("Vault info:");
    //             console.log("  tokenAddress:", vaultInfo.tokenAddress);
    //             console.log("  stakerRewards:", vaultInfo.stakerRewards);
    //             console.log("  operatorRewards:", vaultInfo.operatorRewards);
                
    //             if (vaultInfo.stakerRewards != address(0)) {
    //                 console.log("Distributing staker rewards for vault...");
    //                 console.log("  Amount:", totalStakerReward[i]);

    //                 _safeTokenApprove(rewardToken, vaultInfo.stakerRewards, totalStakerReward[i]);
    //                 console.log("Approved staker rewards contract to spend:", totalStakerReward[i]);

    //                 IDefaultStakerRewards(vaultInfo.stakerRewards).distributeRewards(
    //                     NETWORK,
    //                     rewardToken,
    //                     totalStakerReward[i],
    //                     abi.encode(
    //                         oneSecondAgo,
    //                         10000,
    //                         new bytes(0),
    //                         new bytes(0)
    //                     )
    //                 );
    //                 console.log("Staker rewards distributed successfully");
                    
                   
    //             } else {
    //                 console.log("Skipping distribution - no staker rewards contract");
    //             }


    //             if (vaultInfo.stakerRewards != address(0)) {
    //                 console.log("Distributing operator rewards for vault...");
    //                 console.log("  Amount:", totalOperatorReward[i]);

    //                 _safeTokenApprove(rewardToken, vaultInfo.operatorRewards, totalOperatorReward[i]);
    //                 console.log("Approved operator rewards contract to spend:", totalOperatorReward[i]);

    //                 IDefaultOperatorRewards(vaultInfo.operatorRewards).distributeRewards(
    //                     NETWORK,
    //                     rewardToken,
    //                     totalOperatorReward[i], 
    //                     operatorMerkleRoots[i]
    //                 );
    //                 console.log("Operator rewards distributed successfully");
                    
                   
    //             } else {
    //                 console.log("Skipping distribution - no operator rewards contract");
    //             }
                
    //         }
    //     } else {
    //         console.log("\nSkipping distributions - conditions not met:");
    //         console.log("  latestTaskNumber:", latestTaskNumber);
    //         console.log("  merkleRoots.length:", operatorMerkleRoots.length);
    //     }

    //     console.log("================== createNewTask END ==================");
    // }



    uint256 public lastEmitTime;
    uint256 public constant EMIT_DELAY = 1; // 1 second

    function respondToTask(
        string calldata clusterId,
        string calldata rollupId,
        uint32 referenceTaskIndex,
        bool response
    ) external {
        require(checkIncludingOperatingAddress(msg.sender) == true, "Operator is not registered");
        require(
            rollupTaskInfos[rollupId].taskResponses[msg.sender][referenceTaskIndex] == false,
            "Operator has already responded to the task"
        );

        rollupTaskInfos[rollupId].taskResponses[msg.sender][referenceTaskIndex] = response;
        rollupTaskInfos[rollupId].taskTotalResponseCount[referenceTaskIndex]++;

        emit TaskResponded(clusterId, rollupId, referenceTaskIndex, response, msg.sender);
        
        if (rollupTaskInfos[rollupId].taskTotalResponseCount[referenceTaskIndex] == 6) {
            emit TaskThresholdMet(clusterId, rollupId, referenceTaskIndex);
        }
    }

    function checkIncludingOperatingAddress(address currentOperating) public view returns (bool) {
        address currentOperator = getOperatorWithOperatingAddress(currentOperating);
        if (!operators.contains(currentOperator)) {
            revert OperatorNotRegistered();
        }

        uint48 epoch = getCurrentEpoch();
        uint48 epochStartTs = getEpochStartTs(epoch);

        if (epochStartTs > Time.timestamp()) {
            revert InvalidEpoch();
        }
        
        (uint48 enabledTime, uint48 disabledTime) = operators.getTimes(currentOperator);
        if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
            revert OperatorNotActive();
        }

        bool hasEnoughStake = false;
        uint256 tokenCount = tokens.length();

        for (uint256 i; i < tokenCount; ++i) {
            (address token, uint48 tokenEnabledTime, uint48 tokenDisabledTime) = tokens.atWithTimes(i);

            if (!_wasActiveAt(tokenEnabledTime, tokenDisabledTime, epochStartTs)) {
                continue;
            }

            uint256 tokenStake = getOperatorTokenStake(currentOperator, token, epochStartTs);
            if (tokenStake >= minimumStakingAmounts[token]) {
                hasEnoughStake = true;
                break;
            }
        }

        return hasEnoughStake;
    }

    function _wasActiveAt(
        uint48 enabledTime,
        uint48 disabledTime,
        uint48 timestamp
    ) private pure returns (bool) {
        return
            enabledTime != 0 &&
            enabledTime <= timestamp &&
            (disabledTime == 0 || disabledTime >= timestamp);
    }

    function _validateEpoch(uint48 epochStartTs) private view {
        if (epochStartTs > Time.timestamp()) {
            revert InvalidEpoch();
        }
    }
 

    /**
     * @notice Safely approves tokens with protection against approval race conditions
     */
    function _safeTokenApprove(
        address token,
        address spender,
        uint256 amount
    ) private {
        // Using forceApprove which safely handles approvals without requiring a reset
        SafeERC20.safeIncreaseAllowance(IERC20(token), spender, amount);
    }
    /**
     * @notice Distributes rewards for a given cluster and rollup
     * @dev Only callable by the network middleware
     */
    // function distributeRewards(
    // string calldata clusterId,
    // string calldata rollupId,
    // address network,
    // bytes32 operatorMerkleRoot,
    // uint48 stakerTimestamp,
    // bytes memory activeSharesHint,
    // bytes memory activeStakeHint,
    // uint256 maxAdminFee
    // ) external nonReentrant {
    //     console.log("Starting distributeRewards for cluster:", clusterId);
    //     console.log("Starting distributeRewards for rollup:", rollupId);

    //     console.log("Network address:", network);
        
    //     // Check if reward pool exists and is eligible for distribution
    //     (
    //         bool isEligible,
    //         uint256 availableAmount,
    //         address rewardToken,
    //         uint256 timeUntilNextDistribution,
    //         uint256 operatorAmount,
    //         uint256 stakerAmount
    //     ) = IRewardsCore(REWARDS_MANAGER).getDistributionInfo(
    //             clusterId,
    //             rollupId
    //         );
        
    //     console.log("Distribution info - Eligible:", isEligible);
    //     console.log("Available amount:", availableAmount);
    //     console.log("Reward token:", rewardToken);
    //     console.log("Time until next distribution:", timeUntilNextDistribution);

    //     require(isEligible, "Not eligible for distribution");
    //     require(availableAmount > 0, "No rewards available");

    //     // Get approval from RewardsCore for exact amount
    //     uint256 approvedAmount = IRewardsCore(REWARDS_MANAGER)
    //         .approveRewardDistribution(network, clusterId, rollupId);
        
    //     console.log("Approved amount:", approvedAmount);
 
    //     console.log("Operator amount (70%):", operatorAmount);
    //     console.log("Staker amount (30%):", stakerAmount);

    //     // Transfer and distribute operator rewards
    //     if (operatorAmount > 0) {
    //         console.log("Processing operator rewards transfer");
    //         IERC20(rewardToken).safeTransferFrom(
    //             REWARDS_MANAGER,
    //             address(this),
    //             operatorAmount
    //         );

    //         _safeTokenApprove(rewardToken, DEFAULT_OPERATOR_REWARDS, operatorAmount);
    //         console.log("Approved operator rewards contract to spend:", operatorAmount);

    //         console.log("rewardToken: ", rewardToken);

    //         console.log("DEFAULT_OPERATOR_REWARDS: ", DEFAULT_OPERATOR_REWARDS);


    //         IDefaultOperatorRewards(DEFAULT_OPERATOR_REWARDS).distributeRewards(
    //             network,
    //             rewardToken,
    //             operatorAmount,
    //             operatorMerkleRoot
    //         );
    //         console.log("Operator rewards distributed successfully");
    //     }

    //     // Transfer and distribute staker rewards
    //     if (stakerAmount > 0) {
    //         console.log("Processing staker rewards transfer");
    //         IERC20(rewardToken).safeTransferFrom(
    //             REWARDS_MANAGER,
    //             address(this),
    //             stakerAmount
    //         );

    //         _safeTokenApprove(rewardToken, DEFAULT_STAKER_REWARDS, stakerAmount);
    //         console.log("Approved staker rewards contract to spend:", stakerAmount);
    //         console.log("stakerTimestamp:", stakerTimestamp);
    //         console.log("maxAdminFee:", maxAdminFee);
    //         console.log("activeSharesHint:", string(activeSharesHint));
    //         console.log("activeStakeHint:", string(activeStakeHint));

    //         IDefaultStakerRewards(DEFAULT_STAKER_REWARDS).distributeRewards(
    //             network,
    //             rewardToken,
    //             stakerAmount,
    //             abi.encode(
    //                 stakerTimestamp,
    //                 maxAdminFee,
    //                 activeSharesHint,
    //                 activeStakeHint
    //             )
    //         );
    //         console.log("Staker rewards distributed successfully");
    //     }

    //     console.log("Rewards distribution completed successfully");
    //     emit RewardsDistributed(
    //         clusterId,
    //         rollupId,
    //         operatorAmount,
    //         stakerAmount,
    //         operatorMerkleRoot
    //     );
    // }

}

      