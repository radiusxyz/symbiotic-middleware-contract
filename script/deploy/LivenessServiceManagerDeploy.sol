// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Utils} from "../utils/Utils.sol";

import {Script} from "forge-std/src/Script.sol";
import {LivenessServiceManager} from "src/liveness/LivenessServiceManager.sol";

import {INetworkRegistry} from "@symbiotic-core/src/interfaces/INetworkRegistry.sol";
import {IOperatorRegistry} from "@symbiotic-core/src/interfaces/IOperatorRegistry.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";
import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";

contract LivenessServiceManagerDeploy is Script, Utils {
    function run() external {
        vm.startBroadcast();

        LivenessServiceManager livenessServiceManager = new LivenessServiceManager();

        string memory deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "livenessServiceManager",
            address(livenessServiceManager)
        );

        string memory finalJson = vm.serializeString(
            parentObject,
            deployedContractAddresses,
            deployedContractAddresses_output
        );

        writeOutput(finalJson, livenessServiceManagerDeploymentOutput);

        vm.stopBroadcast();
    }
}