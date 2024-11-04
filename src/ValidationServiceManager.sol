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
import {IBaseSlasher} from "@symbiotic-core/src/interfaces/slasher/IBaseSlasher.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";
import {IEntity} from "@symbiotic-core/src/interfaces/common/IEntity.sol";
import {ISlasher} from "@symbiotic-core/src/interfaces/slasher/ISlasher.sol";
import {IVetoSlasher} from "@symbiotic-core/src/interfaces/slasher/IVetoSlasher.sol";
import {Subnetwork} from "@symbiotic-core/src/contracts/libraries/Subnetwork.sol";

import {MapWithTimeData} from "src/libraries/MapWithTimeData.sol";
import {IValidationServiceManager} from "src/IValidationServiceManager.sol";

import {OperatingAddressRegistry} from "./OperatingAddressRegistry.sol";

contract ValidationServiceManager is Ownable, IValidationServiceManager, OperatingAddressRegistry {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using MapWithTimeData for EnumerableMap.AddressToUintMap;
    using Subnetwork for address;
    using ECDSAUpgradeable for bytes32;

    address public immutable NETWORK;
    address public immutable OPERATOR_REGISTRY;
    address public immutable OPERATOR_NET_OPTIN;
    address public immutable VAULT_REGISTRY;

    uint48 public immutable EPOCH_DURATION;
    uint48 public immutable SLASHING_WINDOW;
    uint48 public immutable START_TIME;
    uint48 private constant INSTANT_SLASHER_TYPE = 0;
    uint48 private constant VETO_SLASHER_TYPE = 1;

    uint256 public subnetworksCnt;

    mapping(uint48 => uint256) public totalStakeCache;
    mapping(uint48 => bool) public totalStakeCached;
    mapping(uint48 => mapping(address => uint256)) public operatorStakeCache;
    
    EnumerableMap.AddressToUintMap private operators;
    EnumerableMap.AddressToUintMap private vaults;

    mapping(string => RollupTaskInfo) public rollupTaskInfos;

    modifier updateStakeCache(uint48 epoch) {
        if (!totalStakeCached[epoch]) {
            calcAndCacheStakes(epoch);
        }
        _;
    }

    constructor(
        address _owner,
        address _network,
        
        address _operatorRegistry,
        address _vaultRegistry,

        address _operatorNetOptin,
        
        uint48 _epochDuration,
        uint48 _slashingWindow
    ) Ownable(_owner) {
        if (_slashingWindow < _epochDuration) {
            revert SlashingWindowTooShort();
        }

        START_TIME = Time.timestamp();
        
        EPOCH_DURATION = _epochDuration;
        SLASHING_WINDOW = _slashingWindow;

        NETWORK = _network;

        OPERATOR_REGISTRY = _operatorRegistry;
        VAULT_REGISTRY = _vaultRegistry;
        OPERATOR_NET_OPTIN = _operatorNetOptin;

        subnetworksCnt = 1;
    }

    function getEpochStartTs(uint48 epoch) public view returns (uint48 timestamp) {
        return START_TIME + epoch * EPOCH_DURATION;
    }

    function getEpochAtTs(uint48 timestamp) public view returns (uint48 epoch) {
        return (timestamp - START_TIME) / EPOCH_DURATION;
    }

    function getCurrentEpoch() public view returns (uint48 epoch) {
        return getEpochAtTs(Time.timestamp());
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
    function registerOperator(address operator, address operatingAddress) external onlyOwner {
        if (operators.contains(operator)) {
            revert OperatorAlreadyRegistred();
        }

        if (!IRegistry(OPERATOR_REGISTRY).isEntity(operator)) {
            revert NotOperator();
        }

        if (!IOptInService(OPERATOR_NET_OPTIN).isOptedIn(operator, NETWORK)) {
            revert OperatorNotOptedIn();
        }

        updateOperatingAddress(operator, operatingAddress);

        operators.add(operator);
        operators.enable(operator);
    }

    function updateOperatorOperatingAddress(address operator, address operatingAddress) external onlyOwner {
        if (!operators.contains(operator)) {
            revert OperatorNotRegistred();
        }

        updateOperatingAddress(operator, operatingAddress);
    }

    function pauseOperator(address operator) external onlyOwner {
        operators.disable(operator);
    }

    function unpauseOperator(address operator) external onlyOwner {
        operators.enable(operator);
    }

    function unregisterOperator(address operator) external onlyOwner {
        (, uint48 disabledTime) = operators.getTimes(operator);

        if (disabledTime == 0 || disabledTime + SLASHING_WINDOW > Time.timestamp()) {
            revert OperarorGracePeriodNotPassed();
        }

        operators.remove(operator);
    }

    ///////////// Vault management
    function registerVault(address vault) external onlyOwner {
        if (vaults.contains(vault)) {
            revert VaultAlreadyRegistred();
        }

        if (!IRegistry(VAULT_REGISTRY).isEntity(vault)) {
            revert NotVault();
        }

        uint48 vaultEpoch = IVault(vault).epochDuration();
        address slasher = IVault(vault).slasher();

        if (slasher != address(0) && IEntity(slasher).TYPE() == VETO_SLASHER_TYPE) {
            vaultEpoch -= IVetoSlasher(slasher).vetoDuration();
        }

        if (vaultEpoch < SLASHING_WINDOW) {
            revert VaultEpochTooShort();
        }

        vaults.add(vault);
        vaults.enable(vault);
    }

    function pauseVault(address vault) external onlyOwner {
        vaults.disable(vault);
    }

    function unpauseVault(address vault) external onlyOwner {
        vaults.enable(vault);
    }

    function unregisterVault(address vault) external onlyOwner {
        (, uint48 disabledTime) = vaults.getTimes(vault);

        if (disabledTime == 0 || disabledTime + SLASHING_WINDOW > Time.timestamp()) {
            revert VaultGracePeriodNotPassed();
        }

        vaults.remove(vault);
    }

    function isActiveVault(uint256 index) public view returns (bool) {
        uint48 epoch = getCurrentEpoch();
        uint48 epochStartTs = getEpochStartTs(epoch);
        
        (, uint48 enabledTime, uint48 disabledTime) = vaults.atWithTimes(index);

        return _wasActiveAt(enabledTime, disabledTime, epochStartTs);
    }

    function getOperatorStake(address operator, uint48 epoch) public view returns (uint256 stake) {
        if (totalStakeCached[epoch]) {
            return operatorStakeCache[epoch][operator];
        }

        uint48 epochStartTs = getEpochStartTs(epoch);

        for (uint256 i; i < vaults.length(); ++i) {
            (address vault, uint48 enabledTime, uint48 disabledTime) = vaults.atWithTimes(i);

            // just skip the vault if it was enabled after the target epoch or not enabled
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            for (uint96 j = 0; j < subnetworksCnt; ++j) {
                // address public immutable NETWORK;
                stake += IBaseDelegator(IVault(vault).delegator()).stakeAt(
                    NETWORK.subnetwork(j), operator, epochStartTs, new bytes(0)
                );
            }
        }

        return stake;
    }

    function getTotalStake(uint48 epoch) public view returns (uint256) {
        if (totalStakeCached[epoch]) {
            return totalStakeCache[epoch];
        }
        return _calcTotalStake(epoch);
    }
    
    function getValidatorSet(uint48 epoch) public view returns (ValidatorData[] memory validatorsData) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        validatorsData = new ValidatorData[](operators.length());
        uint256 valIdx = 0;

        for (uint256 i; i < operators.length(); ++i) {
            (address operator, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);

            // just skip operator if it was added after the target epoch or paused
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            address operatingAddress = getOperatorOperatingAddressAt(operator, epochStartTs);
            if (operatingAddress == address(0)) {
                continue;
            }

            uint256 stake = getOperatorStake(operator, epochStartTs);

            validatorsData[valIdx++] = ValidatorData(operatingAddress, stake);
        }

        assembly ("memory-safe") {
            mstore(validatorsData, valIdx)
        }
    }

    ///////////// Task management
    function createNewTask(
        string calldata _clusterId,
        string calldata _rollupId,
        uint256 _blockNumber,
        bytes32 _blockCommitment // merkle root / block_commitment
    ) public updateStakeCache(getCurrentEpoch()) {
        require(_checkIncludingOperatingAddress() == true, "Operator is not registered");

        Task memory newTask;
        newTask.clusterId = _clusterId;
        newTask.rollupId = _rollupId;
        newTask.blockNumber = _blockNumber;
        newTask.blockCommitment = _blockCommitment;
        newTask.taskCreatedBlock = uint256(block.number);

        uint256 latestTaskNumber = rollupTaskInfos[_rollupId].latestTaskNumber;
        
        rollupTaskInfos[_rollupId].latestTaskNumber += 1;
        rollupTaskInfos[_rollupId].blockCommitments[latestTaskNumber] = _blockCommitment;
        rollupTaskInfos[_rollupId].allTaskHashes[latestTaskNumber] = keccak256(abi.encode(newTask));

        emit NewTaskCreated(_clusterId, _rollupId, latestTaskNumber, _blockNumber, _blockCommitment, newTask.taskCreatedBlock);
    }

    function _checkIncludingOperatingAddress() internal returns (bool) {
        return true;
        // TODO:  check
        // if (!operators.contains(msg.sender)) {
        //     revert OperatorNotRegistred();
        // }

        // uint48 epoch = getCurrentEpoch();
        // uint48 epochStartTs = getEpochStartTs(epoch);

        // // for epoch older than SLASHING_WINDOW total stake can be invalidated (use cache)
        // if (epochStartTs < Time.timestamp() - SLASHING_WINDOW) {
        //     revert TooOldEpoch();
        // }

        // if (epochStartTs > Time.timestamp()) {
        //     revert InvalidEpoch();
        // }
        
        // for (uint256 i; i < operators.length(); ++i) {
        //     (address operator, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);

        //     if (operator == msg.sender) {
        //         // just skip operator if it was added after the target epoch or paused
        //         if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
        //             revert OperatorNotActive();
        //         }
        //         break;
        //     }          
        // }
    }

    function respondToTask(
        string calldata clusterId,
        string calldata rollupId,
        uint32 referenceTaskIndex,
        bool response
    ) external {
        require(_checkIncludingOperatingAddress() == true, "Operator is not registered");
        
        // some logical checks
        require(
            rollupTaskInfos[rollupId].allTaskResponses[msg.sender][referenceTaskIndex] == false,
            "Operator has already responded to the task"
        );

        // updating the storage with task responses
        rollupTaskInfos[rollupId].allTaskResponses[msg.sender][referenceTaskIndex] = response;

        // TODO: We should give reward (Here) / Over Threshold

        // emitting event
        emit TaskResponded(clusterId, rollupId, referenceTaskIndex, response);
    }

    ///////////// Called by user or v
    function verify(
        string calldata rollupId,
        uint64 blockNumber, // for getting merkle root
        uint256 order, // order

        bytes32[] memory proof, // merkle path
        bytes32[] memory partialProof, // for checking no blank transaction
        bytes32 leaf // transaction_hash
    ) public view returns (bool) {
        bytes32 root = rollupTaskInfos[rollupId].blockCommitments[rollupTaskInfos[rollupId].latestTaskNumber];

        // The merkle root is not stored. It means that the block is not finalized
        if (root == bytes32(0)) {
            return false;
        }

        // Check if the partial proof matches the first consecutive elements of the proof
        // This is done to ensure, that the sequencer did not insert transactions 
        // into blank spaces he left initially
        if (partialProof.length > proof.length) {
            return false;
        }

        for (uint256 i = 0; i < partialProof.length; i++) {
            if (partialProof[i] != proof[i]) {
                return false;
            }
        }

        // If the partial proof is valid, proceed with the verification
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (order % 2 == 0) {
                // Current node is a left child
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Current node is a right child
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }

            // Move to the parent node order
            order = order / 2;
        }

        return computedHash == root;
    }

    function slash(uint48 epoch, address operator, uint256 amount) public onlyOwner updateStakeCache(epoch) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        if (epochStartTs < Time.timestamp() - SLASHING_WINDOW) {
            revert TooOldEpoch();
        }

        uint256 totalOperatorStake = getOperatorStake(operator, epoch);

        if (totalOperatorStake < amount) {
            revert TooBigSlashAmount();
        }

        for (uint256 i; i < vaults.length(); ++i) {
            (address vault, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);

            // just skip the vault if it was enabled after the target epoch or not enabled
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            for (uint96 j = 0; j < subnetworksCnt; ++j) {
                bytes32 subnetwork = NETWORK.subnetwork(j);
                uint256 vaultStake =
                    IBaseDelegator(IVault(vault).delegator()).stakeAt(subnetwork, operator, epochStartTs, new bytes(0));

                _slashVault(epochStartTs, vault, subnetwork, operator, amount * vaultStake / totalOperatorStake);
            }
        }
    }

    function calcAndCacheStakes(uint48 epoch) public returns (uint256 totalStake) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        // for epoch older than SLASHING_WINDOW total stake can be invalidated (use cache)
        if (epochStartTs < Time.timestamp() - SLASHING_WINDOW) {
            revert TooOldEpoch();
        }

        if (epochStartTs > Time.timestamp()) {
            revert InvalidEpoch();
        }

        for (uint256 i; i < operators.length(); ++i) {
            (address operator, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);

            // just skip operator if it was added after the target epoch or paused
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            uint256 operatorStake = getOperatorStake(operator, epoch);
            operatorStakeCache[epoch][operator] = operatorStake;

            totalStake += operatorStake;
        }

        totalStakeCached[epoch] = true;
        totalStakeCache[epoch] = totalStake;
    }

    function _calcTotalStake(uint48 epoch) private view returns (uint256 totalStake) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        // for epoch older than SLASHING_WINDOW total stake can be invalidated (use cache)
        if (epochStartTs < Time.timestamp() - SLASHING_WINDOW) {
            revert TooOldEpoch();
        }

        if (epochStartTs > Time.timestamp()) {
            revert InvalidEpoch();
        }

        for (uint256 i; i < operators.length(); ++i) {
            (address operator, uint48 enabledTime, uint48 disabledTime) = operators.atWithTimes(i);

            // just skip operator if it was added after the target epoch or paused
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            uint256 operatorStake = getOperatorStake(operator, epochStartTs);
            totalStake += operatorStake;
        }
    }

    function _wasActiveAt(uint48 enabledTime, uint48 disabledTime, uint48 timestamp) private pure returns (bool) {
        return enabledTime != 0 && enabledTime <= timestamp && (disabledTime == 0 || disabledTime >= timestamp);
    }

    function _slashVault(
        uint48 timestamp,
        address vault,
        bytes32 subnetwork,
        address operator,
        uint256 amount
    ) private {
        address slasher = IVault(vault).slasher();
        uint256 slasherType = IEntity(slasher).TYPE();

        if (slasherType == INSTANT_SLASHER_TYPE) {
            ISlasher(slasher).slash(subnetwork, operator, amount, timestamp, new bytes(0));
        } else if (slasherType == VETO_SLASHER_TYPE) {
            IVetoSlasher(slasher).requestSlash(subnetwork, operator, amount, timestamp, new bytes(0));
        } else {
            revert UnknownSlasherType();
        }
    }
}
