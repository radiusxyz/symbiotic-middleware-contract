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
import {IBaseSlasher} from "@symbiotic-core/src/interfaces/slasher/IBaseSlasher.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";
import {IEntity} from "@symbiotic-core/src/interfaces/common/IEntity.sol";
import {ISlasher} from "@symbiotic-core/src/interfaces/slasher/ISlasher.sol";
import {IVetoSlasher} from "@symbiotic-core/src/interfaces/slasher/IVetoSlasher.sol";
import {Subnetwork} from "@symbiotic-core/src/contracts/libraries/Subnetwork.sol";

import {ICollateral} from "@symbiotic-collateral/src/interfaces/ICollateral.sol";

import {MapWithTimeData} from "src/libraries/MapWithTimeData.sol";
import {IValidationServiceManager} from "src/IValidationServiceManager.sol";

import {OperatingAddressRegistry} from "./OperatingAddressRegistry.sol";

import {IDefaultOperatorRewards} from "@symbiotic-rewards/src/interfaces/defaultOperatorRewards/IDefaultOperatorRewards.sol";
import {IDefaultStakerRewards} from "@symbiotic-rewards/src/interfaces/defaultStakerRewards/IDefaultStakerRewards.sol";
import {IRewardsCore} from "./rewards/interfaces/IRewardsCore.sol";

import {ReentrancyGuard} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

import {INetworkMiddlewareService} from "@symbiotic-core/src/interfaces/service/INetworkMiddlewareService.sol";

import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract ValidationServiceManager is
    Ownable,
    IValidationServiceManager,
    OperatingAddressRegistry,
    ReentrancyGuard
{
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using MapWithTimeData for EnumerableMap.AddressToUintMap;
    using Subnetwork for address;
    using ECDSAUpgradeable for bytes32;
    using SafeERC20 for IERC20;

    address public immutable NETWORK;
    address public immutable OPERATOR_NET_OPT_IN;
    address public immutable VAULT_FACTORY;

    uint48 public immutable EPOCH_DURATION;
    uint48 public immutable SLASHING_WINDOW;
    uint48 public immutable START_TIME;

    uint48 private constant INSTANT_SLASHER_TYPE = 0;
    uint48 private constant VETO_SLASHER_TYPE = 1;

    uint256 public subnetworksCnt;

    mapping(uint48 => bool) public totalStakeCached; // Check if total stake for the epoch is already calculated
    mapping(uint48 => uint256) public totalStakeCache; // Total stake for the epoch
    mapping(uint48 => mapping(address => uint256)) public tokenTotalStakeCache; // Total stake for the epoch for each token

    mapping(uint48 => mapping(address => uint256)) public operatorStakeCache;
    mapping(uint48 => mapping(address => mapping(address => uint256)))
        public operatorTokenStakeCache;

    EnumerableMap.AddressToUintMap private operators;
    EnumerableMap.AddressToUintMap private vaults;
    EnumerableMap.AddressToUintMap private tokens;

    address public immutable DEFAULT_OPERATOR_REWARDS;
    address public immutable DEFAULT_STAKER_REWARDS;
    address public immutable REWARDS_MANAGER;

    mapping(string => RollupTaskInfo) public rollupTaskInfos;

    modifier updateStakeCache(uint48 epoch) {
        if (!totalStakeCached[epoch]) {
            calcAndCacheStakes(epoch);
        }
        _;
    }

    constructor(
        address _network,
        address _vaultFactory,
        address _operatorNetOptIn,
        uint48 _epochDuration,
        uint48 _slashingWindow,
        address _default_staker_rewards,
        address _default_operator_rewards,
        address _rewards_manager
    ) Ownable(msg.sender) {
        if (_slashingWindow < _epochDuration) {
            revert SlashingWindowTooShort();
        }

        START_TIME = Time.timestamp();

        NETWORK = _network;

        VAULT_FACTORY = _vaultFactory;
        OPERATOR_NET_OPT_IN = _operatorNetOptIn;

        EPOCH_DURATION = _epochDuration;
        SLASHING_WINDOW = _slashingWindow;

        subnetworksCnt = 1;
        DEFAULT_STAKER_REWARDS = _default_staker_rewards;
        DEFAULT_OPERATOR_REWARDS = _default_operator_rewards;

        REWARDS_MANAGER = _rewards_manager;
    }

    ///////////// Epoch management
    function getCurrentEpoch() public view returns (uint48 epoch) {
        return getEpochAtTs(Time.timestamp());
    }

    function getEpochStartTs(
        uint48 epoch
    ) public view returns (uint48 timestamp) {
        return START_TIME + epoch * EPOCH_DURATION;
    }

    function getEpochAtTs(uint48 timestamp) public view returns (uint48 epoch) {
        return (timestamp - START_TIME) / EPOCH_DURATION;
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
    function registerOperator(
        address operator,
        address operatingAddress
    ) external onlyOwner {
        if (operators.contains(operator)) {
            revert OperatorAlreadyRegistered();
        }

        if (!IOptInService(OPERATOR_NET_OPT_IN).isOptedIn(operator, NETWORK)) {
            revert OperatorNotOptedIn();
        }

        _updateOperatingAddress(operator, operatingAddress);

        operators.add(operator);
        operators.enable(operator);

        emit RegisterOperator(operator, operatingAddress);
    }

    function pauseOperator(address operator) external onlyOwner {
        operators.disable(operator);
    }

    function unpauseOperator(address operator) external onlyOwner {
        operators.enable(operator);
    }

    function unregisterOperator(address operator) external onlyOwner {
        (, uint48 disabledTime) = operators.getTimes(operator);

        if (
            disabledTime == 0 ||
            disabledTime + SLASHING_WINDOW > Time.timestamp()
        ) {
            revert OperatorGracePeriodNotPassed();
        }

        operators.remove(operator);

        emit UnregisterOperator(operator);
    }

    function updateOperatingAddress(
        address operator,
        address operatingAddress
    ) external {
        if (!operators.contains(operator)) {
            revert OperatorNotRegistered();
        }

        require(operator == msg.sender, "Not authorized");

        _updateOperatingAddress(operator, operatingAddress);

        emit UpdateOperating(operator, operatingAddress);
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

    function pauseToken(address token) external onlyOwner {
        tokens.disable(token);
    }

    function unpauseToken(address token) external onlyOwner {
        tokens.enable(token);
    }

    function unregisterToken(address token) external onlyOwner {
        (, uint48 disabledTime) = tokens.getTimes(token);

        if (
            disabledTime == 0 ||
            disabledTime + SLASHING_WINDOW > Time.timestamp()
        ) {
            revert TokenGracePeriodNotPassed();
        }

        tokens.remove(token);

        emit UnregisterToken(token);
    }

    // Check if Token is Registered [Whitelisted]
    function isRegisteredToken(address token) public view returns (bool) {
        return tokens.contains(token);
    }

    function getTokenAddress(
        address collateralOrToken
    ) public view returns (address) {
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

        if (!IRegistry(VAULT_FACTORY).isEntity(vault)) {
            revert VaultNotRegisteredInSymbiotic();
        }

        address token = getTokenAddress(IVault(vault).collateral());
        if (!tokens.contains(token)) {
            revert TokenNotWhitelisted();
        }

        uint48 vaultEpoch = IVault(vault).epochDuration();
        address slasher = IVault(vault).slasher();

        if (
            slasher != address(0) &&
            IEntity(slasher).TYPE() == VETO_SLASHER_TYPE
        ) {
            vaultEpoch -= IVetoSlasher(slasher).vetoDuration();
        }

        if (vaultEpoch < SLASHING_WINDOW) {
            revert VaultEpochTooShort();
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

        if (
            disabledTime == 0 ||
            disabledTime + SLASHING_WINDOW > Time.timestamp()
        ) {
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

        uint256 vaultsCnt = vaults.length();
        address[] memory vaultAddresses = new address[](vaultsCnt);

        uint256 vaultIdx = 0;

        for (uint256 i; i < vaultsCnt; ++i) {
            (address vault, uint48 enabledTime, uint48 disabledTime) = vaults
                .atWithTimes(i);

            // just skip vault if it was added after the target epoch or paused
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            vaultAddresses[vaultIdx++] = vault;
        }

        return vaultAddresses;
    }

    ///////////// Stake management
    function getCurrentTokenTotalStake(
        address token
    ) public view returns (uint256) {
        return getTokenTotalStake(token, getCurrentEpoch());
    }

    function getTokenTotalStake(
        address token,
        uint48 epoch
    ) public view returns (uint256) {
        if (totalStakeCached[epoch]) {
            return tokenTotalStakeCache[epoch][token];
        }
        return _calcTokenTotalStake(token, epoch);
    }

    function getCurrentTotalStake() public view returns (uint256) {
        return getTotalStake(getCurrentEpoch());
    }

    function getTotalStake(uint48 epoch) public view returns (uint256) {
        if (totalStakeCached[epoch]) {
            return totalStakeCache[epoch];
        }
        return _calcTotalStake(epoch);
    }

    function getCurrentOperatorStake(
        address operator
    ) public view returns (uint256) {
        return getOperatorStake(operator, getCurrentEpoch());
    }

    function getOperatorStake(
        address operator,
        uint48 epoch
    ) public view returns (uint256 stake) {
        if (totalStakeCached[epoch]) {
            return operatorStakeCache[epoch][operator];
        }

        uint48 epochStartTs = getEpochStartTs(epoch);

        for (uint256 i; i < vaults.length(); ++i) {
            (address vault, uint48 enabledTime, uint48 disabledTime) = vaults
                .atWithTimes(i);

            // just skip the vault if it was enabled after the target epoch or not enabled
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            // TODO: apply the token value
            address token = getTokenAddress(IVault(vault).collateral());

            for (uint96 j = 0; j < subnetworksCnt; ++j) {
                // address public immutable NETWORK;
                stake += IBaseDelegator(IVault(vault).delegator()).stakeAt(
                    NETWORK.subnetwork(j),
                    operator,
                    epochStartTs,
                    new bytes(0)
                );
            }
        }

        return stake;
    }

    function getCurrentOperatorEachTokenStake(
        address operator
    ) public view returns (TokenStake[] memory) {
        return getOperatorEachTokenStake(operator, getCurrentEpoch());
    }

    function getOperatorEachTokenStake(
        address operator,
        uint48 epoch
    ) public view returns (TokenStake[] memory tokenStakes) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        tokenStakes = new TokenStake[](tokens.length());

        uint256 tokenIdx = 0;

        for (uint256 i; i < tokens.length(); ++i) {
            (address token, uint48 enabledTime, uint48 disabledTime) = tokens
                .atWithTimes(i);

            // just skip token if it was added after the target epoch or paused
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            uint256 tokenStake = getOperatorTokenStake(
                operator,
                token,
                epochStartTs
            );
            tokenStakes[tokenIdx++] = TokenStake(token, tokenStake);
        }

        assembly ("memory-safe") {
            mstore(tokenStakes, tokenIdx)
        }
    }

    function getCurrentOperatorTokenStake(
        address operator,
        address token
    ) public view returns (uint256) {
        return getOperatorTokenStake(operator, token, getCurrentEpoch());
    }

    function getOperatorTokenStake(
        address operator,
        address token,
        uint48 epoch
    ) public view returns (uint256 stake) {
        if (totalStakeCached[epoch]) {
            return operatorTokenStakeCache[epoch][token][operator];
        }

        uint48 epochStartTs = getEpochStartTs(epoch);

        for (uint256 i; i < vaults.length(); ++i) {
            (address vault, uint48 enabledTime, uint48 disabledTime) = vaults
                .atWithTimes(i);

            address checkToken = getTokenAddress(IVault(vault).collateral());

            if (checkToken != token) {
                continue;
            }

            // just skip the vault if it was enabled after the target epoch or not enabled
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            for (uint96 j = 0; j < subnetworksCnt; ++j) {
                stake += IBaseDelegator(IVault(vault).delegator()).stakeAt(
                    NETWORK.subnetwork(j),
                    operator,
                    epochStartTs,
                    new bytes(0)
                );
            }
        }

        return stake;
    }

    function getCurrentOperatorInfos()
        public
        view
        returns (OperatorInfo[] memory operatorInfos)
    {
        return getOperatorInfos(getCurrentEpoch());
    }

    function getOperatorInfos(
        uint48 epoch
    ) public view returns (OperatorInfo[] memory operatorInfos) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        operatorInfos = new OperatorInfo[](operators.length());

        uint256 operatorIdx = 0;

        for (uint256 i; i < operators.length(); ++i) {
            (
                address operator,
                uint48 enabledTime,
                uint48 disabledTime
            ) = operators.atWithTimes(i);

            // just skip operator if it was added after the target epoch or paused
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            address operatingAddress = getOperatorOperatingAddressAt(
                operator,
                epochStartTs
            );
            TokenStake[] memory tokenStakes = getOperatorEachTokenStake(
                operator,
                epochStartTs
            );
            uint256 operatorStake = getOperatorStake(operator, epochStartTs);

            operatorInfos[operatorIdx++] = OperatorInfo(
                operator,
                operatingAddress,
                tokenStakes,
                operatorStake
            );
        }

        assembly ("memory-safe") {
            mstore(operatorInfos, operatorIdx)
        }
    }

    ///////////// Task management
     function createNewTask(
        string calldata _clusterId,
        string calldata _rollupId,
        uint256 _blockNumber,
        bytes32 _blockCommitment,
        bytes32 _taskMerkleRoot
    ) public {
        // require(
        //     _checkIncludingOperatingAddress() == true,
        //     "Operator is not registered"
        // );

        console.log("Create New Task:");
        console.log("_clusterId:", _clusterId);
        console.log("_rollupId:", _rollupId);
 
        Task memory newTask;
        newTask.clusterId = _clusterId;
        newTask.rollupId = _rollupId;
        newTask.blockNumber = _blockNumber;
        newTask.blockCommitment = _blockCommitment;
        newTask.taskCreatedBlock = uint256(block.number);

        uint256 latestTaskNumber = rollupTaskInfos[_rollupId].latestTaskNumber;

        rollupTaskInfos[_rollupId].latestTaskNumber += 1;
        rollupTaskInfos[_rollupId].blockCommitments[
            latestTaskNumber
        ] = _blockCommitment;
        rollupTaskInfos[_rollupId].allTaskHashes[latestTaskNumber] = keccak256(
            abi.encode(newTask)
        );


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

        emit NewTaskCreated(
            _clusterId,
            _rollupId,
            latestTaskNumber,
            _blockNumber,
            _blockCommitment,
            newTask.taskCreatedBlock
        );
    }

    uint256 public lastEmitTime;
    uint256 public constant EMIT_DELAY = 1; // 1 second

    function respondToTask(
        string calldata clusterId,
        string calldata rollupId,
        uint32 referenceTaskIndex,
        bool response
    ) external {
        // require(
        //     _checkIncludingOperatingAddress() == true,
        //     "Operator is not registered"
        // );

        require(
            rollupTaskInfos[rollupId].allTaskResponses[msg.sender][
                referenceTaskIndex
            ] == false,
            "Operator has already responded to the task"
        );

        rollupTaskInfos[rollupId].allTaskResponses[msg.sender][
            referenceTaskIndex
        ] = response;

        emit TaskResponded(clusterId, rollupId, referenceTaskIndex, response, msg.sender);
        rollupTaskInfos[rollupId].taskTotalResponseCount[referenceTaskIndex]++;

        if (rollupTaskInfos[rollupId].taskTotalResponseCount[referenceTaskIndex] == 2) {
            emit TaskThresholdMet(clusterId, rollupId, referenceTaskIndex);
        }
    }

    // TODO: check
    function verify(
        string calldata rollupId,
        uint64 blockNumber, // for getting merkle root
        uint256 order, // order
        bytes32[] memory proof, // merkle path
        bytes32 leaf // transaction_hash
    ) public view returns (bool) {
        bytes32 root = rollupTaskInfos[rollupId].blockCommitments[
            rollupTaskInfos[rollupId].latestTaskNumber
        ];

        // The merkle root is not stored. It means that the block is not finalized
        if (root == bytes32(0)) {
            return false;
        }

        // If the partial proof is valid, proceed with the verification
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (order % 2 == 0) {
                // Current node is a left child
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Current node is a right child
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }

            // Move to the parent node order
            order = order / 2;
        }

        return computedHash == root;
    }

    function calcAndCacheStakes(
        uint48 epoch
    ) public returns (uint256 totalStake) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        // for epoch older than SLASHING_WINDOW total stake can be invalidated (use cache)
        _validateEpoch(epochStartTs);

        for (uint256 i; i < operators.length(); ++i) {
            (
                address operator,
                uint48 enabledTime,
                uint48 disabledTime
            ) = operators.atWithTimes(i);

            // just skip operator if it was added after the target epoch or paused
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            uint256 operatorStake = getOperatorStake(operator, epoch);
            operatorStakeCache[epoch][operator] = operatorStake;

            totalStake += operatorStake;

            for (uint256 j; j < tokens.length(); ++j) {
                (address token, , ) = tokens.atWithTimes(j);

                operatorTokenStakeCache[epoch][token][
                    operator
                ] = getOperatorTokenStake(operator, token, epochStartTs);
            }
        }

        for (uint256 i; i < tokens.length(); ++i) {
            (address token, uint48 enabledTime, uint48 disabledTime) = tokens
                .atWithTimes(i);

            // just skip token if it was added after the target epoch or paused
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            tokenTotalStakeCache[epoch][token] = _calcTokenTotalStake(
                token,
                epoch
            );
        }

        totalStakeCached[epoch] = true;
        totalStakeCache[epoch] = totalStake;
    }

    function _checkIncludingOperatingAddress() internal returns (bool) {
        if (!operators.contains(msg.sender)) {
            revert OperatorNotRegistered();
        }

        uint48 epoch = getCurrentEpoch();
        uint48 epochStartTs = getEpochStartTs(epoch);

        if (epochStartTs > Time.timestamp()) {
            revert InvalidEpoch();
        }

        for (uint256 i; i < operators.length(); ++i) {
            (
                address operator,
                uint48 enabledTime,
                uint48 disabledTime
            ) = operators.atWithTimes(i);

            if (operator == msg.sender) {
                // just skip operator if it was added after the target epoch or paused
                if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                    revert OperatorNotActive();
                }
                break;
            }
        }
    }

    function _calcTotalStake(
        uint48 epoch
    ) private view returns (uint256 totalStake) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        // for epoch older than SLASHING_WINDOW total stake can be invalidated (use cache)
        _validateEpoch(epochStartTs);

        for (uint256 i; i < operators.length(); ++i) {
            (
                address operator,
                uint48 enabledTime,
                uint48 disabledTime
            ) = operators.atWithTimes(i);

            // just skip operator if it was added after the target epoch or paused
            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            uint256 operatorStake = getOperatorStake(operator, epochStartTs);
            totalStake += operatorStake;
        }
    }

    function _calcTokenTotalStake(
        address token,
        uint48 epoch
    ) private view returns (uint256 tokenTotalStake) {
        uint48 epochStartTs = getEpochStartTs(epoch);

        _validateEpoch(epochStartTs);

        for (uint256 i; i < operators.length(); ++i) {
            (
                address operator,
                uint48 enabledTime,
                uint48 disabledTime
            ) = operators.atWithTimes(i);

            if (!_wasActiveAt(enabledTime, disabledTime, epochStartTs)) {
                continue;
            }

            uint256 operatorTokenStake = getOperatorTokenStake(
                operator,
                token,
                epochStartTs
            );
            tokenTotalStake += operatorTokenStake;
        }
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
        if (epochStartTs < Time.timestamp() - SLASHING_WINDOW) {
            revert TooOldEpoch();
        }

        if (epochStartTs > Time.timestamp()) {
            revert InvalidEpoch();
        }
    }

    // TODO:
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
            ISlasher(slasher).slash(
                subnetwork,
                operator,
                amount,
                timestamp,
                new bytes(0)
            );
        } else if (slasherType == VETO_SLASHER_TYPE) {
            IVetoSlasher(slasher).requestSlash(
                subnetwork,
                operator,
                amount,
                timestamp,
                new bytes(0)
            );
        } else {
            revert UnknownSlasherType();
        }
    }

    // TODO:
    function slash(
        uint48 epoch,
        address operator,
        uint256 amount
    ) public onlyOwner updateStakeCache(epoch) {
        // TODO
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
