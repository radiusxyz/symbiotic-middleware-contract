// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Utils} from "../utils/Utils.sol";
import {Script, console2} from "forge-std/src/Script.sol";

import "../../src/RadiusTestERC20.sol";
import {DefaultCollateral} from "@symbiotic-collateral/src/contracts/defaultCollateral/DefaultCollateral.sol";

import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";
import {IOperatorRegistry} from "@symbiotic-core/src/interfaces/IOperatorRegistry.sol";
import {INetworkRegistry} from "@symbiotic-core/src/interfaces/INetworkRegistry.sol";

contract Register is Script, Utils {
    function run() external {
        vm.startBroadcast();

        (,, address operatorAddress) = vm.readCallers();
        address networkAddress = operatorAddress;

        string memory output = readOutput(vaultDeploymentOutput);
        address vaultAddress = convertAddress(vm.parseJson(output, ".addresses.vault"));

        output = readOutput(symbioticCoreDeploymentOutput);
        address operatorVaultOptInServiceAddress = convertAddress(vm.parseJson(output, ".addresses.operatorVaultOptInService"));
        address networkRegistryAddress = convertAddress(vm.parseJson(output, ".addresses.networkRegistry"));
        address operatorNetworkOptInServiceAddress = convertAddress(vm.parseJson(output, ".addresses.operatorNetworkOptInService"));
        address operatorRegistryAddress = convertAddress(vm.parseJson(output, ".addresses.operatorRegistry"));

        // Network register
        if (INetworkRegistry(networkRegistryAddress).isEntity(networkAddress) == false) {
            INetworkRegistry(networkRegistryAddress).registerNetwork();
        }

        // Operator register
        if (IOperatorRegistry(operatorRegistryAddress).isEntity(operatorAddress) == false) {
            IOperatorRegistry(operatorRegistryAddress).registerOperator();
        }

        // Vault optin
        if (IOptInService(operatorVaultOptInServiceAddress).isOptedIn(operatorAddress, vaultAddress) == false) {
            IOptInService(operatorVaultOptInServiceAddress).optIn(vaultAddress);
        }

        // Network optin
        if (IOptInService(operatorNetworkOptInServiceAddress).isOptedIn(operatorAddress, networkAddress) == false) {
            IOptInService(operatorNetworkOptInServiceAddress).optIn(networkAddress);
        }
        
        vm.stopBroadcast();
    }
}