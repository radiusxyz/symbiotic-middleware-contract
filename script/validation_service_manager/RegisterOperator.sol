// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Utils} from "../utils/Utils.sol";

import {Script} from "forge-std/src/Script.sol";

import {ValidationServiceManager} from "src/ValidationServiceManager.sol";

import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";
import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";

contract RegisterOperator is Script, Utils {
    function run(address operatorAddress) external {
        vm.startBroadcast();

        (,, address callerAddress) = vm.readCallers();

        string memory output1 = readOutput(validationServiceManagerDeploymentOutput);
        address validationServiceManagerAddress = convertAddress(vm.parseJson(output1, ".addresses.validationServiceManager"));

        string memory output2 = readOutput(symbioticCoreDeploymentOutput);
        address operatorRegistryAddress = convertAddress(vm.parseJson(output2, ".addresses.operatorRegistry"));
        address operatorNetworkOptInServiceAddress = convertAddress(vm.parseJson(output2, ".addresses.operatorNetworkOptInService"));
        address networkRegistryAddress = convertAddress(vm.parseJson(output2, ".addresses.networkRegistry"));

        address networkAddress = ValidationServiceManager(validationServiceManagerAddress).NETWORK();

        ValidationServiceManager(validationServiceManagerAddress).registerOperator(operatorAddress, operatorAddress);
        
        vm.stopBroadcast();
    }
}