// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IValidationServiceManager as IVsmTypes} from "./IValidationServiceManager.sol";


interface IRegistry {


    // --- Epoch Management ---
    function getEpochAtTs(uint48 timestamp) external view returns (uint48 epoch);
    function getCurrentEpoch() external view returns (uint48 epoch);
    function getEpochStartTs(uint48 epoch) external view returns (uint48 timestamp);

    // --- Network Management ---
    function setSubnetworkCount(uint256 _subnetworkCount) external; // Typically Ownable
    function getSubnetwork(uint96 index) external view returns (bytes32);

    // --- Operator Management ---
    function registerOperator(address operator, address operating) external; // Typically Ownable
    function pauseOperator(address operator) external; // Typically Ownable
    function unpauseOperator(address operator) external; // Typically Ownable
    function unregisterOperator(address operator) external; // Typically Ownable
    function updateOperatingAddress(address operator, address operating) external; // Typically Ownable
    function getCurrentOperatorInfos() external view returns (IVsmTypes.OperatorInfo[] memory);
    function getOperatorInfos(uint48 epoch) external view returns (IVsmTypes.OperatorInfo[] memory);
    function checkIncludingOperatingAddress(address currentOperating) external view returns (bool);

    // --- Token Management ---
    function registerToken(address token) external; // Typically Ownable
    function setMinimumStakingAmount(address token, uint256 amount) external; // Typically Ownable
    function pauseToken(address token) external; // Typically Ownable
    function unpauseToken(address token) external; // Typically Ownable
    function unregisterToken(address token) external; // Typically Ownable
    function isActiveToken(address token) external view returns (bool);
    function getCurrentTokens() external view returns (address[] memory);
    function getTokens(uint48 epoch) external view returns (address[] memory);
    function getTokenAddress(address collateralOrToken) external view returns (address); // Utility

    // --- Vault Management ---
    function registerVault(address vault, address stakerRewards, address operatorRewards, address slasher) external; // Typically Ownable
    function pauseVault(address vault) external; // Typically Ownable
    function unpauseVault(address vault) external; // Typically Ownable
    function unregisterVault(address vault) external; // Typically Ownable
    function isActiveVault(address vault) external view returns (bool);
    function getCurrentVaults() external view returns (address[] memory);
    function getVaults(uint48 epoch) external view returns (address[] memory);
    function getVaultToken(address vault) external view returns (address); // Utility, equivalent to getTokenAddress(IVault(vault).collateral())
    function getVaultDetails(address vault) external view returns (
        address tokenAddress,
        address stakerRewards,
        address operatorRewards,
        address slasher
    );

    // --- Stake Management ---
    function getCurrentTokenTotalStake(address token) external view returns (uint256 stakeAmount);
    function getTokenTotalStake(address token, uint48 epoch) external view returns (uint256 totalStakeAmount);
    function getCurrentAllTokenTotalStakes() external view returns (IVsmTypes.StakeInfo[] memory tokenStakes);
    function getAllTokenTotalStakes(uint48 epoch) external view returns (IVsmTypes.StakeInfo[] memory tokenStakes);
    function getCurrentOperatorTokenStake(address operator, address token) external view returns (uint256 stakeAmount);
    function getOperatorTokenStake(address operator, address token, uint48 epoch) external view returns (uint256 stakeAmount);
    function getCurrentOperatorAllTokenStakes(address operator) external view returns (IVsmTypes.StakeInfo[] memory tokenStakes);
    function getOperatorAllTokenStakes(address operator, uint48 epoch) external view returns (IVsmTypes.StakeInfo[] memory tokenStakes);
    function calcAndCacheStakes(uint48 epoch) external; // Permissioned call

}