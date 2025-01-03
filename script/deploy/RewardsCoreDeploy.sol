// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Utils} from "../utils/Utils.sol";
import {Script} from "forge-std/src/Script.sol";
import {RewardsCore} from "../../src/rewards/RewardsCore.sol";
import {ValidationServiceManager} from "../../src/ValidationServiceManager.sol";

contract RewardsCoreDeploy is Script, Utils {
    function run() external {
        vm.startBroadcast();

        string memory symbioticCoreDeploymentOutput = readOutput(symbioticCoreDeploymentOutput);

        address networkMiddlewareServiceAddress = convertAddress(vm.parseJson(symbioticCoreDeploymentOutput, ".addresses.networkMiddlewareService"));

        RewardsCore rewardsCore = new RewardsCore(
            networkMiddlewareServiceAddress
        );

        string memory deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "rewardsCore",
            address(rewardsCore)
        );

        string memory finalJson = vm.serializeString(
            parentObject,
            deployedContractAddresses,
            deployedContractAddresses_output
        );

        writeOutput(finalJson, rewardsCoreDeploymentOutput);

        vm.stopBroadcast();
    }
}
