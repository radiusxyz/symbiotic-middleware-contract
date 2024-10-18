// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Utils} from "../utils/Utils.sol";

import {Script} from "forge-std/src/Script.sol";
import {ValidationServiceManager} from "src/ValidationServiceManager.sol";

import {INetworkRegistry} from "@symbiotic-core/src/interfaces/INetworkRegistry.sol";
import {IOperatorRegistry} from "@symbiotic-core/src/interfaces/IOperatorRegistry.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";
import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";

contract RegisterVault is Script, Utils {
    function run() external {
        vm.startBroadcast();

        (,, address operatorAddress) = vm.readCallers();

        string memory output1 = readOutput(validationServiceManagerDeploymentOutput);
        address validationServiceManagerAddress = convertAddress(vm.parseJson(output1, ".addresses.validationServiceManager"));
      
        string memory output2 = readOutput(vaultDeploymentOutput);
        address vaultAddress = convertAddress(vm.parseJson(output2, ".addresses.vault"));

        string memory output3 = readOutput(symbioticCoreDeploymentOutput);
        address operatorVaultOptInServiceAddress = convertAddress(vm.parseJson(output3, ".addresses.operatorVaultOptInService"));

        ValidationServiceManager(validationServiceManagerAddress).registerVault(vaultAddress);
        
        vm.stopBroadcast();
    }
}