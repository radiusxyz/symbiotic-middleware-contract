// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Utils} from "../utils/Utils.sol";

import {Script} from "forge-std/src/Script.sol";
import {LivenessRadius} from "src/liveness/LivenessRadius.sol";

import {INetworkRegistry} from "@symbiotic-core/src/interfaces/INetworkRegistry.sol";
import {IOperatorRegistry} from "@symbiotic-core/src/interfaces/IOperatorRegistry.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";
import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";

contract LivenessRadiusDeployer is Script, Utils {
    function run() external {
        vm.startBroadcast();

        LivenessRadius livenessRadius = new LivenessRadius();

        string memory deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "livenessRadius",
            address(livenessRadius)
        );

        string memory finalJson = vm.serializeString(
            parentObject,
            deployedContractAddresses,
            deployedContractAddresses_output
        );

        writeOutput(finalJson, livenessRadiusDeploymentOutput);

        vm.stopBroadcast();
    }
}