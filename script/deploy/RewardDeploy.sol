// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Utils} from "../utils/Utils.sol";
import {Script} from "forge-std/src/Script.sol";
import {RewardsManager} from "../../src/rewards/RewardsManager.sol";
import {ValidationServiceManager} from "../../src/ValidationServiceManager.sol";

contract RewardDeploy is Script, Utils {
    function run() external {
        vm.startBroadcast();

        // string memory livenessRadiusOutput = readOutput(
        //     livenessRadiusDeploymentOutput
        // );
        // string memory operatorRewardOutput = readOutput(
        //     operatorRewardDeploymentOutput
        // );
        // string memory stakerRewardOutput = readOutput(
        //     stakerRewardDeploymentOutput
        // );

        string memory symbioticCoreDeploymentOutput = readOutput(symbioticCoreDeploymentOutput);

        address networkMiddlewareServiceAddress = convertAddress(vm.parseJson(symbioticCoreDeploymentOutput, ".addresses.networkMiddlewareService"));


    
        // address livenessRadiusAddress = convertAddress(
        //     vm.parseJson(livenessRadiusOutput, ".addresses.livenessRadius")
        // );

        // address stakerRewardAddress = convertAddress(
        //     vm.parseJson(stakerRewardOutput, ".addresses.stakerReward")
        // );
        // address operatorRewardAddress = convertAddress(
        //     vm.parseJson(operatorRewardOutput, ".addresses.operatorReward")
        // );

        RewardsManager rewardsManager = new RewardsManager(
            networkMiddlewareServiceAddress
        );

        string memory deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "rewardsManager",
            address(rewardsManager)
        );

        string memory finalJson = vm.serializeString(
            parentObject,
            deployedContractAddresses,
            deployedContractAddresses_output
        );

        writeOutput(finalJson, rewardsManagerDeploymentOutput);

        vm.stopBroadcast();
    }
}
