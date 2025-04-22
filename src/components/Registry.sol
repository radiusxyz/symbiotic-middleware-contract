// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Time} from "@openzeppelin-contracts/contracts/utils/types/Time.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {EnumerableMap} from "@openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";
import {Checkpoints} from "@openzeppelin-contracts/contracts/utils/structs/Checkpoints.sol";
import {IRegistry} from "@symbiotic-core/src/interfaces/common/IRegistry.sol";
import {IEntity} from "@symbiotic-core/src/interfaces/common/IEntity.sol";
import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";
import {IBaseDelegator} from "@symbiotic-core/src/interfaces/delegator/IBaseDelegator.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";
import {Subnetwork} from "@symbiotic-core/src/contracts/libraries/Subnetwork.sol";
import {ICollateral} from "@symbiotic-collateral/src/interfaces/ICollateral.sol";

import {MapWithTimeData} from "src/libraries/MapWithTimeData.sol";
import {IValidationServiceManager} from "src/interfaces/IValidationServiceManager.sol";

contract Registry is Ownable {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using MapWithTimeData for EnumerableMap.AddressToUintMap;
    using Checkpoints for Checkpoints.Trace208;
    using Subnetwork for address;

    address public immutable NETWORK;
    address public immutable OPERATOR_NET_OPT_IN;
    address public immutable VAULT_REGISTRY;
    address public immutable STAKER_REWARDS_REGISTRY;
    address public immutable OPERATOR_REWARDS_REGISTRY;
    address public immutable SLASHER_REGISTRY;

    uint48 public immutable START_TIME;
    uint48 public immutable EPOCH_DURATION;
    uint256 public subnetworkCount;

    mapping(uint48 => bool) public totalStakeCached; 
    mapping(uint48 => mapping(address => uint256)) public tokenTotalStakeCache;
    mapping(uint48 => mapping(address => mapping(address => uint256))) public operatorStakeInfoCache;
    
    EnumerableMap.AddressToUintMap private tokens;
    EnumerableMap.AddressToUintMap private vaults;
    EnumerableMap.AddressToUintMap private operators;

    mapping(address => IValidationServiceManager.Vault) public vaultDetails;
    mapping(address => uint256) public minimumStakingAmounts;
    mapping(address => uint256) public slashAmounts;


    // TxOrderer Registry state variables integrated directly into Registry
    mapping(address => Checkpoints.Trace208) private operatorToIndex;
    mapping(address => address) private txOrdererToOperator;
    mapping(uint208 => address) private indexToTxOrderer;
    uint208 private totalTxOrdererCount;
    uint208 internal constant EMPTY_TXORDERER_ADDRESS_INDEX = 0;

    error DuplicateTxOrdererAddress();

    event RegisterToken(address token);
    event SetMinimumStakeAmount(address token, uint256 minimumStakeAmount);
    event SetSlashAmount(address token, uint256 amount);

    event UnregisterToken(address token);

    event RegisterVault(address vault, address stakerRewards, address operatorRewards);
    event UnregisterVault(address vault);

    event RegisterOperator(address operator, address txOrdererAddress);
    event UpdateTxOrdererAddress(address operator, address txOrdererAddress);
    event UnregisterOperator(address operator);    


    constructor(
        address _network,
        address _vaultRegistry,
        address _operatorNetOptIn,
        uint48 _epochDuration,
        address _staker_rewards_registry,
        address _operator_rewards_registry,
        address _slasher_registry
    ) Ownable(msg.sender) {
        START_TIME = Time.timestamp();
        NETWORK = _network;
        VAULT_REGISTRY = _vaultRegistry;
        OPERATOR_NET_OPT_IN = _operatorNetOptIn;
        EPOCH_DURATION = _epochDuration;
        subnetworkCount = 1;
        STAKER_REWARDS_REGISTRY = _staker_rewards_registry;
        OPERATOR_REWARDS_REGISTRY = _operator_rewards_registry;
        SLASHER_REGISTRY = _slasher_registry;
    }

    ///////////// Epoch management
    function getEpochAtTs(uint48 timestamp) public view returns (uint48 epoch) {
        return (timestamp - START_TIME) / EPOCH_DURATION;
    }

    function getCurrentEpoch() public view returns (uint48 epoch) {
        return getEpochAtTs(Time.timestamp());
    }

    function getEpochStartTs(uint48 epoch) public view returns (uint48 timestamp) {
        return START_TIME + epoch * EPOCH_DURATION;
    }

    ///////////// Network management
    function setSubnetworkCount(uint256 _subnetworkCount) external onlyOwner {
        if (subnetworkCount >= _subnetworkCount) {
            revert IValidationServiceManager.InvalidSubnetworkCount();
        }
        subnetworkCount = _subnetworkCount;
    }

    function getSubnetwork(uint96 index) public view returns (bytes32) {
        return NETWORK.subnetwork(index);
    }
    
    function getVaultDetails(address vault) public view returns (
        address tokenAddress,
        address stakerRewards,
        address operatorRewards,
        address slasher
    ) {
        IValidationServiceManager.Vault memory vaultInfo = vaultDetails[vault];
        return (
            vaultInfo.tokenAddress,
            vaultInfo.stakerRewards,
            vaultInfo.operatorRewards,
            vaultInfo.slasher
        );
    }

    ///////////// TxOrderer Registry Functions Integrated
    function getOperatorWithTxOrdererAddress(address txOrderer) public view returns (address) {
        return txOrdererToOperator[txOrderer];
    }

    function getCurrentTxOrdererAddress(address operator) public view returns (address) {
        uint208 txOrdererIndex = operatorToIndex[operator].latest();

        if (txOrdererIndex == EMPTY_TXORDERER_ADDRESS_INDEX) {
            return address(0);
        }

        return indexToTxOrderer[txOrdererIndex];
    }

    function getTxOrdererAddressAt(address operator, uint48 timestamp) public view returns (address) {
        uint208 txOrdererIndex = operatorToIndex[operator].upperLookup(timestamp);

        if (txOrdererIndex == EMPTY_TXORDERER_ADDRESS_INDEX) {
            return address(0);
        }

        return indexToTxOrderer[txOrdererIndex];
    }

    function _initTxOrdererAddress(address operator, address txOrderer) internal {
        if (txOrdererToOperator[txOrderer] != address(0)) {
            revert DuplicateTxOrdererAddress();
        }

        uint208 newIndex = ++totalTxOrdererCount;
        indexToTxOrderer[newIndex] = txOrderer;
        operatorToIndex[operator].push(Time.timestamp(), newIndex);
        txOrdererToOperator[txOrderer] = operator;
    }

    function _updateTxOrdererAddress(address operator, address newTxOrderer) internal {
        if (txOrdererToOperator[newTxOrderer] != address(0)) {
            revert DuplicateTxOrdererAddress();
        }

        address currentTxOrderer = getCurrentTxOrdererAddress(operator);
        uint208 txOrdererIndex = operatorToIndex[operator].latest();

        indexToTxOrderer[txOrdererIndex] = newTxOrderer;
        
        txOrdererToOperator[newTxOrderer] = operator;

        delete txOrdererToOperator[currentTxOrderer];
    }

    ///////////// Operator management
    function registerOperator(address operator, address txOrderer) external onlyOwner {
        if (operators.contains(operator)) {
            revert IValidationServiceManager.OperatorAlreadyRegistered();
        }

        if (!IOptInService(OPERATOR_NET_OPT_IN).isOptedIn(operator, NETWORK)) {
            revert IValidationServiceManager.OperatorNotOptedIn();
        }

        // Initialize both the operator registry and txOrderer registry
        _initTxOrdererAddress(operator, txOrderer);

        operators.add(operator);
        operators.enable(operator);

        emit RegisterOperator(operator, txOrderer);
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
            revert IValidationServiceManager.OperatorGracePeriodNotPassed();
        }

        operators.remove(operator);
        
        // Update the txOrderer address mapping to clear it
        address txOrderer = getCurrentTxOrdererAddress(operator);
        if (txOrderer != address(0)) {
            delete txOrdererToOperator[txOrderer];
        }
        
        emit UnregisterOperator(operator);
    }

    function updateTxOrdererAddress(address operator, address txOrderer) external onlyOwner {
        if (!operators.contains(operator)) {
            revert IValidationServiceManager.OperatorNotRegistered();
        }

        _updateTxOrdererAddress(operator, txOrderer);

        emit UpdateTxOrdererAddress(operator, txOrderer);
    }

    function getCurrentOperatorInfos() public view returns (IValidationServiceManager.OperatorInfo[] memory operatorInfos) {
        return getOperatorInfos(getCurrentEpoch());
    }

    function getOperatorInfos(uint48 epoch) public view returns (IValidationServiceManager.OperatorInfo[] memory operatorInfos) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        uint256 operatorCount = operators.length();
        operatorInfos = new IValidationServiceManager.OperatorInfo[](operatorCount);
        
        uint256 operatorIndex = 0;

        for (uint256 i; i < operatorCount; ++i) {
            (address operator, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);

            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) continue;

            address txOrderer = getTxOrdererAddressAt(operator, epochStartTs);

            IValidationServiceManager.StakeInfo[] memory tokenStakes = getOperatorAllTokenStakes(operator, epochStartTs);

            operatorInfos[operatorIndex++] = IValidationServiceManager.OperatorInfo(operator, txOrderer, tokenStakes);
        }

        assembly ("memory-safe") {
            mstore(operatorInfos, operatorIndex)
        }
    }

    ///////////// Token management
    function registerToken(address token) external onlyOwner {
        if (tokens.contains(token)) {
            revert IValidationServiceManager.TokenAlreadyRegistered();
        }

        tokens.add(token);
        tokens.enable(token);

        emit RegisterToken(token);
    }

    function setMinimumStakingAmount(address token, uint256 amount) external onlyOwner {
        minimumStakingAmounts[token] = amount;
        emit SetMinimumStakeAmount(token, amount);
    }

    function setSlashAmount(address token, uint256 amount) external onlyOwner {
        slashAmounts[token] = amount;
        emit SetSlashAmount(token, amount); 
    }

    function getSlashAmount(address token) public view returns (uint256) {
        return slashAmounts[token];
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
            revert IValidationServiceManager.TokenGracePeriodNotPassed();
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

    function getVaultCollateral(address vault) public view returns (address) {
        return IVault(vault).collateral();
    }

    function getVaultToken(address vault) public view returns (address) {
        return getTokenAddress(IVault(vault).collateral());
    }

    ///////////// Vault management
    function registerVault(address vault, address stakerRewards, address operatorRewards, address slasher) external onlyOwner {
        if (vaults.contains(vault)) {
            revert IValidationServiceManager.VaultAlreadyRegistered();
        }

        if (!IRegistry(VAULT_REGISTRY).isEntity(vault)) {
            revert IValidationServiceManager.VaultNotRegisteredInSymbiotic();
        }

        if (!IRegistry(STAKER_REWARDS_REGISTRY).isEntity(stakerRewards)) {
            revert IValidationServiceManager.StakerRewardNotRegistered();
        }

        if (!IRegistry(OPERATOR_REWARDS_REGISTRY).isEntity(operatorRewards)) {
            revert IValidationServiceManager.OperatorRewardNotRegistered();
        }
        if (!IRegistry(SLASHER_REGISTRY).isEntity(slasher)) {
            revert IValidationServiceManager.VaultSlasherNotRegistered();
        }

        address token = getTokenAddress(IVault(vault).collateral());
        if (!tokens.contains(token)) {
            revert IValidationServiceManager.TokenNotWhitelisted();
        }

        vaults.add(vault);
        vaults.enable(vault);

        vaultDetails[vault] = IValidationServiceManager.Vault({
            tokenAddress: token,
            stakerRewards: stakerRewards,
            operatorRewards: operatorRewards,
            slasher: slasher
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
            revert IValidationServiceManager.VaultGracePeriodNotPassed();
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

    function getCurrentAllTokenTotalStakes() public view returns (IValidationServiceManager.StakeInfo[] memory tokenStakes) {
        return getAllTokenTotalStakes(getCurrentEpoch());
    }

    function getAllTokenTotalStakes(uint48 epoch) public view returns (IValidationServiceManager.StakeInfo[] memory tokenStakes) {
      if (totalStakeCached[epoch]) {
          uint256 tokenCount = tokens.length();
          tokenStakes = new IValidationServiceManager.StakeInfo[](tokenCount);
          for (uint256 i; i < tokenCount; ++i) {
              (address token,,) = tokens.atWithTimes(i);
              uint256 tokenTotalStakeAmount = tokenTotalStakeCache[epoch][token];

              tokenStakes[i] = IValidationServiceManager.StakeInfo(token, tokenTotalStakeAmount);
          }
          
          return tokenStakes;
      }

      uint48 epochStartTs = getEpochStartTs(epoch);
      uint256 tokenCount = tokens.length();
      uint256 operatorCount = operators.length();

      tokenStakes = new IValidationServiceManager.StakeInfo[](tokenCount);
      for (uint256 i; i < tokenCount; ++i) {
          (address token,,) = tokens.atWithTimes(i);

          tokenStakes[i] = IValidationServiceManager.StakeInfo(token, 0);
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
            
            // Bail early if vault isn't active
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }
            
            address checkToken = getTokenAddress(IVault(vault).collateral());
            // Bail early if token doesn't match
            if (checkToken != token) {
                continue;
            }

            // Pull this out to a helper function to reduce stack depth
            stakeAmount += _getOperatorVaultStake(vault, operator, epochStartTs);
        }

        return stakeAmount;
    }

    function _getOperatorVaultStake( address vault, address operator, uint48 timestamp ) internal view returns (uint256 totalStake) {
        for (uint96 j = 0; j < subnetworkCount; ++j) {
            totalStake += IBaseDelegator(IVault(vault).delegator()).stakeAt(
                NETWORK.subnetwork(j), operator, timestamp, new bytes(0)
            );
        }
        return totalStake;
    }

    function getCurrentOperatorAllTokenStakes(address operator) public view returns (IValidationServiceManager.StakeInfo[] memory tokenStakes) {
        return getOperatorAllTokenStakes(operator, getCurrentEpoch());
    }

    function getOperatorAllTokenStakes(address operator, uint48 epoch) public view returns (IValidationServiceManager.StakeInfo[] memory tokenStakes) {
        if (totalStakeCached[epoch]) {
          uint256 tokenCount = tokens.length();
          tokenStakes = new IValidationServiceManager.StakeInfo[](tokenCount);
          for (uint256 i; i < tokenCount; ++i) {
              (address token,,) = tokens.atWithTimes(i);
              uint256 tokenStakeAmount = operatorStakeInfoCache[epoch][token][operator];

              tokenStakes[i] = IValidationServiceManager.StakeInfo(token, tokenStakeAmount);
          }
          
          return tokenStakes;
      }

        uint48 epochStartTs = getEpochStartTs(epoch);
        uint256 tokenCount = tokens.length();

        tokenStakes = new IValidationServiceManager.StakeInfo[](tokenCount);
        
        uint256 tokenIndex = 0;

        for (uint256 i; i < tokenCount; ++i) {
            (address token, uint48 enabledTime, uint48 disabledTime) = tokens.atWithTimes(i);

            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            uint256 tokenStake = getOperatorTokenStake(operator, token, epochStartTs);
            tokenStakes[tokenIndex++] = IValidationServiceManager.StakeInfo(token, tokenStake);
        }

        assembly ("memory-safe") {
            mstore(tokenStakes, tokenIndex)
        }
    }

    function calcAndCacheStakes(uint48 epoch) external {
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

    function checkIncludingTxOrdererAddress(address currentTxOrderer) public view returns (bool) {
        address currentOperator = getOperatorWithTxOrdererAddress(currentTxOrderer);
        if (currentOperator == address(0) || !operators.contains(currentOperator)) {
            revert IValidationServiceManager.OperatorNotRegistered();
        }

        uint48 epoch = getCurrentEpoch();
        uint48 epochStartTs = getEpochStartTs(epoch);

        if (epochStartTs > Time.timestamp()) {
            revert IValidationServiceManager.InvalidEpoch();
        }
        
        (uint48 enabledTime, uint48 disabledTime) = operators.getTimes(currentOperator);
        if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
            revert IValidationServiceManager.OperatorNotActive();
        }

        bool hasEnoughStake = false;
        uint256 tokenCount = tokens.length();

        for (uint256 i; i < tokenCount && !hasEnoughStake; ++i) {
            (address token, uint48 tokenEnabledTime, uint48 tokenDisabledTime) = tokens.atWithTimes(i);

            if (!_wasActiveAt(tokenEnabledTime, tokenDisabledTime, epochStartTs)) {
                continue;
            }

            uint256 minimumStake = minimumStakingAmounts[token];
            if (minimumStake == 0) {
                // If no minimum stake is set, any token is considered valid
                hasEnoughStake = true;
                break;
            }

            uint256 tokenStake = getOperatorTokenStake(currentOperator, token, epochStartTs);
            if (tokenStake >= minimumStake) {
                hasEnoughStake = true;
                break;
            }
        }

        return hasEnoughStake;
    }

    function _wasActiveAt( uint48 enabledTime, uint48 disabledTime, uint48 timestamp ) internal pure returns (bool) {
        return
            enabledTime != 0 &&
            enabledTime <= timestamp &&
            (disabledTime == 0 || disabledTime >= timestamp);
    }

    function _validateEpoch(uint48 epochStartTs) internal view {
        if (epochStartTs > Time.timestamp()) {
            revert IValidationServiceManager.InvalidEpoch();
        }
    }
}