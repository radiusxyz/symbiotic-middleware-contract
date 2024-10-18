// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/src/Script.sol";

import {Utils} from "../utils/Utils.sol";
import "../../src/RadiusTestERC20.sol";

import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";

import {DefaultCollateral} from "@symbiotic-collateral/src/contracts/defaultCollateral/DefaultCollateral.sol";

contract Deposit is Script, Utils {
    function run(uint256 depositAmount) external {
        vm.startBroadcast();

        (,, address operatorAddress) = vm.readCallers();

        string memory output1 = readOutput(collateralDeploymentOutput);
        address radiusTestERC20Address = convertAddress(vm.parseJson(output1, ".addresses.radiusTestERC20"));
        address defaultCollateralAddress = convertAddress(vm.parseJson(output1, ".addresses.defaultCollateral"));

        string memory output2 = readOutput(vaultDeploymentOutput);
        address vaultAddress = convertAddress(vm.parseJson(output2, ".addresses.vault"));

        string memory output3 = readOutput(symbioticCoreDeploymentOutput);
        address operatorVaultOptInServiceAddress = convertAddress(vm.parseJson(output3, ".addresses.operatorVaultOptInService"));
        address networkRegistryAddress = convertAddress(vm.parseJson(output3, ".addresses.networkRegistry"));
        
        // ERC20 -> defaultCollateralAddress
        RadiusTestERC20(radiusTestERC20Address).approve(defaultCollateralAddress, depositAmount);
        uint256 depositedAmount1 = DefaultCollateral(defaultCollateralAddress).deposit(operatorAddress, depositAmount);

        console2.log("depositedAmount1: ", depositedAmount1);

        // defaultCollateral -> vault
        DefaultCollateral(defaultCollateralAddress).approve(vaultAddress, depositAmount);
        (uint256 depositedAmount, uint256 mintedShares) = IVault(vaultAddress).deposit(operatorAddress, depositAmount);
        
        console2.log("depositedAmount: ", depositedAmount);
        console2.log("mintedShares: ", mintedShares);
  
        vm.stopBroadcast();
    }
}