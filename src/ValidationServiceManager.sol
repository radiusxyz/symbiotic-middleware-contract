// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

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
import {IValidationServiceManager} from "src/IValidationServiceManager.sol";
import {OperatingRegistry} from "./OperatingRegistry.sol";

contract ValidationServiceManager is Ownable, IValidationServiceManager, OperatingRegistry {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using MapWithTimeData for EnumerableMap.AddressToUintMap;
    using Subnetwork for address;
    using ECDSAUpgradeable for bytes32;

    address public immutable NETWORK;

    address public immutable OPERATOR_NET_OPT_IN;
    address public immutable VAULT_REGISTRY;

    uint48 public immutable START_TIME;
    uint48 public immutable EPOCH_DURATION;

    uint256 public subnetworksCnt;

    mapping(uint48 => bool) public totalStakeCached; 
    mapping(uint48 => mapping(address => uint256)) public tokenTotalStakeCache;
    mapping(uint48 => mapping(address => mapping(address => uint256))) public operatorStakeInfoCache;
    
    EnumerableMap.AddressToUintMap private tokens;
    EnumerableMap.AddressToUintMap private vaults;
    EnumerableMap.AddressToUintMap private operators;

    mapping(string => RollupTaskInfo) public rollupTaskInfos;
    mapping(address => uint256) public minimumStakingAmounts;


    modifier updateStakeCache(uint48 epoch) {
        if (!totalStakeCached[epoch]) {
            calcAndCacheStakes(epoch);
        }
        _;
    }

    constructor(
        address _network,
        address _vaultRegistry,
        address _operatorNetOptIn,
        uint48 _epochDuration
    ) Ownable(msg.sender) {
        START_TIME = Time.timestamp();
        
        NETWORK = _network;
        
        VAULT_REGISTRY = _vaultRegistry;
        OPERATOR_NET_OPT_IN = _operatorNetOptIn;

        EPOCH_DURATION = _epochDuration;

        subnetworksCnt = 1;
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
    function setSubnetworksCnt(uint256 _subnetworksCnt) external onlyOwner {
        if (subnetworksCnt >= _subnetworksCnt) {
            revert InvalidSubnetworksCnt();
        }

        subnetworksCnt = _subnetworksCnt;
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
    function getCurrentTokenTotalStake(address token) public view returns (uint256 stake) {
        return getTokenTotalStake(token, getCurrentEpoch());
    }

    function getTokenTotalStake(address token, uint48 epoch) public view returns (uint256 totalStake) {
      uint48 epochStartTs = getEpochStartTs(epoch);
      for (uint256 i; i < operators.length(); ++i) {
          (address operator, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);


          if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) continue;

          totalStake += getOperatorTokenStake(operator, token, epoch);
      }
      return totalStake;
    }

    function getCurrentAllTokenTotalStakes() public view returns (StakeInfo[] memory tokenStakes) {
        return getAllTokenTotalStakes(getCurrentEpoch());
    }

    function getAllTokenTotalStakes(uint48 epoch) public view returns (StakeInfo[] memory tokenStakes) {
      uint48 epochStartTs = getEpochStartTs(epoch);

      uint256 tokenIndex = 0;
      
      for (uint256 i; i < tokens.length(); ++i) {
          (address token, uint48 enabledTime, uint48 disabledTime) = tokens.atWithTimes(i);

          if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) continue;

          tokenStakes[tokenIndex++] = StakeInfo(token, 0);
      }
      
      for (uint256 i; i < operators.length(); ++i) {
        (address operator, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);

        if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) continue;

        for (uint256 j; j < tokens.length(); ++j) {
          (address token, uint48 enabledTime, uint48 disabledTime) = tokens.atWithTimes(j);

          if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) continue;

          tokenStakes[j].stake += getOperatorTokenStake(operator, token, epoch);
        }
      }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////// 

    function getCurrentOperatorTokenStake(address operator, address token) public view returns (uint256 stake) {
        return getOperatorTokenStake(operator, token, getCurrentEpoch());
    }

    function getOperatorTokenStake(address operator, address token, uint48 epoch) public view returns (uint256 stake) {
        if (totalStakeCached[epoch]) {
            return operatorStakeInfoCache[epoch][token][operator];
        }

        uint48 epochStartTs = getEpochStartTs(epoch);

        for (uint256 i; i < vaults.length(); ++i) {
            (address vault, uint48 enabledTime, uint48 disabledTime) = vaults.atWithTimes(i);
            
            address checkToken = getTokenAddress(IVault(vault).collateral());
            
            if (checkToken != token) {
                continue;
            }

            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            for (uint96 j = 0; j < subnetworksCnt; ++j) {
                stake += IBaseDelegator(IVault(vault).delegator()).stakeAt(
                    NETWORK.subnetwork(j), operator, epochStartTs, new bytes(0)
                );
            }
        }

        return stake;
    }

    function getCurrentOperatorAllTokenStakes(address operator) public view returns (StakeInfo[] memory tokenStakes) {
        return getOperatorAllTokenStakes(operator, getCurrentEpoch());
    }

    function getOperatorAllTokenStakes(address operator, uint48 epoch) public view returns (StakeInfo[] memory tokenStakes) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        tokenStakes = new StakeInfo[](tokens.length());
        
        uint256 tokenIndex = 0;

        for (uint256 i; i < tokens.length(); ++i) {
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

    function calcAndCacheStakes(uint48 epoch) public {
        uint48 epochStartTs = getEpochStartTs(epoch);
        _validateEpoch(epochStartTs);

        // Update operator token stakes
        for (uint256 i; i < operators.length(); ++i) {
            (address operator, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);

            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }
            
            for (uint256 j; j < tokens.length(); ++j) {
                (address token, , ) = tokens.atWithTimes(j);

                operatorStakeInfoCache[epoch][token][operator] = getOperatorTokenStake(operator, token, epochStartTs);
            }
        }

        // Update total token stakes
        for (uint256 i; i < tokens.length(); ++i) {
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
        bytes32 _blockCommitment
    ) public {
        require(_checkIncludingOperatingAddress() == true, "Operator is not registered");

        Task memory newTask;

        newTask.clusterId = _clusterId;
        newTask.rollupId = _rollupId;
        newTask.blockNumber = _blockNumber;
        newTask.blockCommitment = _blockCommitment;

        uint256 latestTaskNumber = rollupTaskInfos[_rollupId].latestTaskNumber;
        
        rollupTaskInfos[_rollupId].latestTaskNumber += 1;
        rollupTaskInfos[_rollupId].blockCommitments[latestTaskNumber] = _blockCommitment;
        rollupTaskInfos[_rollupId].taskHash[latestTaskNumber] = keccak256(abi.encode(newTask));

        emit NewTaskCreated(_clusterId, _rollupId, latestTaskNumber, _blockNumber, _blockCommitment);
    }

    function respondToTask(
        string calldata clusterId,
        string calldata rollupId,
        uint32 referenceTaskIndex,
        bool response
    ) external {
        require(_checkIncludingOperatingAddress() == true, "Operator is not registered");
        
        require(
            rollupTaskInfos[rollupId].taskResponses[msg.sender][referenceTaskIndex] == false,
            "Operator has already responded to the task"
        );

        rollupTaskInfos[rollupId].taskResponses[msg.sender][referenceTaskIndex] = response;

        emit TaskResponded(clusterId, rollupId, referenceTaskIndex, response);
    }

    function _checkIncludingOperatingAddress() internal returns (bool) {
        address currentOperator = getOperatorWithOperatingAddress(msg.sender);
        if (!operators.contains(currentOperator)) {
            revert OperatorNotRegistered();
        }

        uint48 epoch = getCurrentEpoch();
        uint48 epochStartTs = getEpochStartTs(epoch);

        if (epochStartTs > Time.timestamp()) {
            revert InvalidEpoch();
        }
        
        for (uint256 i; i < operators.length(); ++i) {
            (address operator, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);

            if (operator == currentOperator) {
                if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                    revert OperatorNotActive();
                }

                bool hasEnoughStake = false;

                for (uint256 j; j < tokens.length(); ++j) {
                    (address token, uint48 tokenEnabledTime, uint48 tokenDisabledTime) = tokens.atWithTimes(j);

                    if (!_wasActiveAt(tokenEnabledTime, tokenDisabledTime, epochStartTs)) {
                        continue;
                    }

                    uint256 tokenStake = getOperatorTokenStake(operator, token, epochStartTs);
                    if (tokenStake >= minimumStakingAmounts[token]) {
                        hasEnoughStake = true;
                        break;
                    }
                }

                return hasEnoughStake;
            }          
        }

        return false;
    }

    function _wasActiveAt(uint48 enabledTime, uint48 disabledTime, uint48 timestamp) private pure returns (bool) {
        return enabledTime != 0 && enabledTime <= timestamp && (disabledTime == 0 || disabledTime >= timestamp);
    }

    function _validateEpoch(uint48 epochStartTs) private view {
        if (epochStartTs > Time.timestamp()) {
            revert InvalidEpoch();
        }
    }
}
