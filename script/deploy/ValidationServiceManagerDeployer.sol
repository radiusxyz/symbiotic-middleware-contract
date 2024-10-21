// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Utils} from "../utils/Utils.sol";

import {Script} from "forge-std/src/Script.sol";
import {ValidationServiceManager} from "src/ValidationServiceManager.sol";

import {INetworkRegistry} from "@symbiotic-core/src/interfaces/INetworkRegistry.sol";
import {IOperatorRegistry} from "@symbiotic-core/src/interfaces/IOperatorRegistry.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";
import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";

contract ValidationServiceManagerDeployer is Script, Utils {
    function run() external {
        vm.startBroadcast();

        (,, address owner) = vm.readCallers();

        string memory output1 = readOutput(symbioticCoreDeploymentOutput);
        address operatorRegistryAddress = convertAddress(vm.parseJson(output1, ".addresses.operatorRegistry"));
        // address networkRegistryAddress = convertAddress(vm.parseJson(output1, ".addresses.networkRegistry"));
        address vaultFactoryAddress = convertAddress(vm.parseJson(output1, ".addresses.vaultFactory"));
        address operatorNetworkOptInServiceAddress = convertAddress(vm.parseJson(output1, ".addresses.operatorNetworkOptInService"));

        string memory output2 = readOutput(vaultDeploymentOutput);
        address vaultAddress = convertAddress(vm.parseJson(output2, ".addresses.vault"));

        address[] memory vaults = new address[](1);
        vaults[0] = vaultAddress;

        address[] memory operators = new address[](1);
        operators[0] = owner;

        ValidationServiceManager validationServiceManager = new ValidationServiceManager(
            owner, 
            network, 
            operatorRegistryAddress, 
            vaultFactoryAddress, 
            operatorNetworkOptInServiceAddress, 

            validationServiceManagerEpochDuration, 
            minSlashingWindow
        );

        string memory deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "validationServiceManager",
            address(validationServiceManager)
        );

        string memory finalJson = vm.serializeString(
            parentObject,
            deployedContractAddresses,
            deployedContractAddresses_output
        );

        writeOutput(finalJson, validationServiceManagerDeploymentOutput);

        vm.stopBroadcast();
    }
}