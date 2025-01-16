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

    address public immutable DEFAULT_OPERATOR_REWARDS;
    address public immutable DEFAULT_STAKER_REWARDS;
    address public immutable REWARDS_MANAGER;

    mapping(string => RollupTaskInfo) public rollupTaskInfos;
    mapping(address => uint256) public minimumStakingAmounts;

    modifier updateStakeCache(uint48 epoch) {
        if (!totalStakeCached[epoch]) {
            _calcAndCacheStakes(epoch);
        }
        _;
    }

    constructor(
        address _network,

        address _vaultRegistry,
        address _operatorNetOptIn,

        uint48 _epochDuration, // TODO
        address _default_staker_rewards,
        address _default_operator_rewards,
        address _rewards_manager

    ) Ownable(msg.sender) {
        START_TIME = Time.timestamp();

        NETWORK = _network;
        
        VAULT_REGISTRY = _vaultRegistry;
        OPERATOR_NET_OPT_IN = _operatorNetOptIn;

        EPOCH_DURATION = _epochDuration;

        subnetworkCount = 1;
        
         DEFAULT_STAKER_REWARDS = _default_staker_rewards;
        DEFAULT_OPERATOR_REWARDS = _default_operator_rewards;

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

    ///////////// Vault management
    function registerVault(address vault) external onlyOwner {
        if (vaults.contains(vault)) {
            revert VaultAlreadyRegistered();
        }

        if (!IRegistry(VAULT_REGISTRY).isEntity(vault)) {
            revert VaultNotRegisteredInSymbiotic();
        }

        address token = getTokenAddress(IVault(vault).collateral());
        if (!tokens.contains(token)) {
            revert TokenNotWhitelisted();
        }

        vaults.add(vault);
        vaults.enable(vault);

        emit RegisterVault(vault);
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
        string calldata _clusterId,
        string calldata _rollupId,
        uint256 _blockNumber,
        bytes32 _blockCommitment,
        bytes32 _taskMerkleRoot

    ) public updateStakeCache(getCurrentEpoch()) {
        require(checkIncludingOperatingAddress(msg.sender) == true, "Operator is not registered");

        console.log("Create New Task:");
        console.log("_clusterId:", _clusterId);
        console.log("_rollupId:", _rollupId);
 
        Task memory newTask;

        newTask.clusterId = _clusterId;
        newTask.rollupId = _rollupId;
        newTask.blockNumber = _blockNumber;
        newTask.blockCommitment = _blockCommitment;

        uint256 latestTaskNumber = rollupTaskInfos[_rollupId].latestTaskNumber;
        
        rollupTaskInfos[_rollupId].latestTaskNumber += 1;
        rollupTaskInfos[_rollupId].blockCommitments[latestTaskNumber] = _blockCommitment;
        rollupTaskInfos[_rollupId].taskHash[latestTaskNumber] = keccak256(abi.encode(newTask));

        console.log("latestTaskNumber:", latestTaskNumber);
                  console.log("Sender:", msg.sender);

        // If not first task and merkle root is present, distribute rewards
        uint48 oneSecondAgo = uint48(block.timestamp - 5);

        if (latestTaskNumber > 0 && _taskMerkleRoot != bytes32(0)) {
            this.distributeRewards(
                _clusterId,
                _rollupId,
                NETWORK,
                _taskMerkleRoot,
                oneSecondAgo,
               new bytes(0),  // empty bytes for activeSharesHint
                new bytes(0),  // empty bytes for activeStakeHint
                10000
            );
        }

        emit NewTaskCreated(_clusterId, _rollupId, latestTaskNumber, _blockNumber, _blockCommitment);
    }

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
        emit TaskResponded(clusterId, rollupId, referenceTaskIndex, response, msg.sender);
        if (rollupTaskInfos[rollupId].taskTotalResponseCount[referenceTaskIndex] == 2) {
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
    function distributeRewards(
    string calldata clusterId,
    string calldata rollupId,
    address network,
    bytes32 operatorMerkleRoot,
    uint48 stakerTimestamp,
    bytes memory activeSharesHint,
    bytes memory activeStakeHint,
    uint256 maxAdminFee
    ) external nonReentrant {
        console.log("Starting distributeRewards for cluster:", clusterId);
        console.log("Starting distributeRewards for rollup:", rollupId);

        console.log("Network address:", network);
        
        // Check if reward pool exists and is eligible for distribution
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
        
        console.log("Distribution info - Eligible:", isEligible);
        console.log("Available amount:", availableAmount);
        console.log("Reward token:", rewardToken);
        console.log("Time until next distribution:", timeUntilNextDistribution);

        require(isEligible, "Not eligible for distribution");
        require(availableAmount > 0, "No rewards available");

        // Get approval from RewardsCore for exact amount
        uint256 approvedAmount = IRewardsCore(REWARDS_MANAGER)
            .approveRewardDistribution(network, clusterId, rollupId);
        
        console.log("Approved amount:", approvedAmount);
 
        console.log("Operator amount (70%):", operatorAmount);
        console.log("Staker amount (30%):", stakerAmount);

        // Transfer and distribute operator rewards
        if (operatorAmount > 0) {
            console.log("Processing operator rewards transfer");
            IERC20(rewardToken).safeTransferFrom(
                REWARDS_MANAGER,
                address(this),
                operatorAmount
            );

            _safeTokenApprove(rewardToken, DEFAULT_OPERATOR_REWARDS, operatorAmount);
            console.log("Approved operator rewards contract to spend:", operatorAmount);

            console.log("rewardToken: ", rewardToken);

            console.log("DEFAULT_OPERATOR_REWARDS: ", DEFAULT_OPERATOR_REWARDS);


            IDefaultOperatorRewards(DEFAULT_OPERATOR_REWARDS).distributeRewards(
                network,
                rewardToken,
                operatorAmount,
                operatorMerkleRoot
            );
            console.log("Operator rewards distributed successfully");
        }

        // Transfer and distribute staker rewards
        if (stakerAmount > 0) {
            console.log("Processing staker rewards transfer");
            IERC20(rewardToken).safeTransferFrom(
                REWARDS_MANAGER,
                address(this),
                stakerAmount
            );

            _safeTokenApprove(rewardToken, DEFAULT_STAKER_REWARDS, stakerAmount);
            console.log("Approved staker rewards contract to spend:", stakerAmount);
            console.log("stakerTimestamp:", stakerTimestamp);
            console.log("maxAdminFee:", maxAdminFee);
            console.log("activeSharesHint:", string(activeSharesHint));
            console.log("activeStakeHint:", string(activeStakeHint));

            IDefaultStakerRewards(DEFAULT_STAKER_REWARDS).distributeRewards(
                network,
                rewardToken,
                stakerAmount,
                abi.encode(
                    stakerTimestamp,
                    maxAdminFee,
                    activeSharesHint,
                    activeStakeHint
                )
            );
            console.log("Staker rewards distributed successfully");
        }

        console.log("Rewards distribution completed successfully");
        emit RewardsDistributed(
            clusterId,
            rollupId,
            operatorAmount,
            stakerAmount,
            operatorMerkleRoot
        );
    }
}
