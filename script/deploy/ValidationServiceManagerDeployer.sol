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

        string memory symbioticCoreDeploymentOutput = readOutput(symbioticCoreDeploymentOutput);
        address operatorRegistryAddress = convertAddress(vm.parseJson(symbioticCoreDeploymentOutput, ".addresses.operatorRegistry"));
        address vaultFactoryAddress = convertAddress(vm.parseJson(symbioticCoreDeploymentOutput, ".addresses.vaultFactory"));
        address operatorNetworkOptInServiceAddress = convertAddress(vm.parseJson(symbioticCoreDeploymentOutput, ".addresses.operatorNetworkOptInService"));

         string memory operatorRewardOutput = readOutput(
            operatorRewardDeploymentOutput
        );
        string memory stakerRewardOutput = readOutput(
            stakerRewardDeploymentOutput
        );

         string memory rewardManagerOutput = readOutput(
            rewardsManagerDeploymentOutput
        );

        address stakerRewardAddress = convertAddress(
            vm.parseJson(stakerRewardOutput, ".addresses.stakerReward")
        );
        address operatorRewardAddress = convertAddress(
            vm.parseJson(operatorRewardOutput, ".addresses.operatorReward")
        );

         address rewardManagerAddress = convertAddress(
            vm.parseJson(rewardManagerOutput, ".addresses.rewardsManager")
        );

        ValidationServiceManager validationServiceManager = new ValidationServiceManager(
            network, 
            vaultFactoryAddress, 
            operatorNetworkOptInServiceAddress, 
            validationServiceManagerEpochDuration, 
            minSlashingWindow,
            stakerRewardAddress,
            operatorRewardAddress,
            rewardManagerAddress
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