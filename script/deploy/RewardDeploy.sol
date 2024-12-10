// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Utils} from "../utils/Utils.sol";
import {Script} from "forge-std/src/Script.sol";
import {RewardSystem} from "../../src/RewardSystem.sol";
import {ValidationServiceManager} from "../../src/ValidationServiceManager.sol";

contract RewardDeploy is Script, Utils {
    function run() external {
        vm.startBroadcast();

        string memory output1 = readOutput(
            validationServiceManagerDeploymentOutput
        );
        string memory output2 = readOutput(livenessRadiusDeploymentOutput);
        address validationManagerAddress = convertAddress(
            vm.parseJson(output1, ".addresses.validationServiceManager")
        );
        address livenessRadiusAddress = convertAddress(
            vm.parseJson(output2, ".addresses.livenessRadius")
        );

        RewardSystem rewardSystem = new RewardSystem(
            validationManagerAddress,
            livenessRadiusAddress
        );

        string memory deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "rewardSystem",
            address(rewardSystem)
        );

        string memory finalJson = vm.serializeString(
            parentObject,
            deployedContractAddresses,
            deployedContractAddresses_output
        );

        writeOutput(finalJson, rewardSystemDeploymentOutput);

        vm.stopBroadcast();
    }
}
