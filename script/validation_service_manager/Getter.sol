// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Utils} from "../utils/Utils.sol";

import {Script, console2} from "forge-std/src/Script.sol";

import {ValidationServiceManager} from "src/ValidationServiceManager.sol";
import {IValidationServiceManager} from "src/IValidationServiceManager.sol";

import {INetworkRegistry} from "@symbiotic-core/src/interfaces/INetworkRegistry.sol";
import {IOperatorRegistry} from "@symbiotic-core/src/interfaces/IOperatorRegistry.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";
import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";

contract Getter is Script, Utils {
    function getRollupTaskInfo(string memory rollupId) external {
        vm.startBroadcast();

        (,, address callerAddress) = vm.readCallers();

        string memory output1 = readOutput(validationServiceManagerDeploymentOutput);
        address validationServiceManagerAddress = convertAddress(vm.parseJson(output1, ".addresses.validationServiceManager"));
        
        vm.stopBroadcast();
    }
}