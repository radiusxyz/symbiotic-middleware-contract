// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Utils} from "../utils/Utils.sol";

import {Script} from "forge-std/src/Script.sol";
import {ValidationServiceManager} from "src/contracts/ValidationServiceManager.sol";
import {Registry} from "src/components/Registry.sol";
import {RewardsManager} from "src/components/RewardsManager.sol";
import {SlashingManager} from "src/components/SlashingManager.sol";
import {TaskManager} from "src/components/TaskManager.sol";
import {LivenessServiceManager} from "src/components/LivenessServiceManager.sol";

import {INetworkRegistry} from "@symbiotic-core/src/interfaces/INetworkRegistry.sol";
import {IOperatorRegistry} from "@symbiotic-core/src/interfaces/IOperatorRegistry.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";
import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";

contract ValidationServiceManagerDeploy is Script, Utils {
    function run() external {
        vm.startBroadcast();

        string memory symbioticCoreDeploymentOutput = readOutput(symbioticCoreDeploymentOutput);
        address operatorRegistryAddress = convertAddress(vm.parseJson(symbioticCoreDeploymentOutput, ".addresses.operatorRegistry"));
        address vaultRegistry = convertAddress(vm.parseJson(symbioticCoreDeploymentOutput, ".addresses.vaultFactory"));
        address slasherRegistry = convertAddress(vm.parseJson(symbioticCoreDeploymentOutput, ".addresses.slasherFactory"));

        address operatorNetworkOptInServiceAddress = convertAddress(vm.parseJson(symbioticCoreDeploymentOutput, ".addresses.operatorNetworkOptInService"));
        
        string memory operatorRewardOutput = readOutput(operatorRewardDeploymentOutput);
        string memory stakerRewardOutput = readOutput(stakerRewardDeploymentOutput);
        string memory rewardsCoreOutput = readOutput(rewardsCoreDeploymentOutput);

        address stakerRewardRegistry = convertAddress(vm.parseJson(stakerRewardOutput, ".addresses.defaultStakerRewardsFactory"));
        address operatorRewardRegistry = convertAddress(vm.parseJson(operatorRewardOutput, ".addresses.defaultOperatorRewardsFactory"));
        address rewardsCoreAddress = convertAddress( vm.parseJson(rewardsCoreOutput, ".addresses.rewardsCore"));

        Registry registry = new Registry(
            network, 
            vaultRegistry, 
            operatorNetworkOptInServiceAddress, 
            validationServiceManagerEpochDuration, 
            stakerRewardRegistry,
            operatorRewardRegistry,
            slasherRegistry
        );

         RewardsManager rewardsManager = new RewardsManager();
    
        SlashingManager slashingManager = new SlashingManager(network);
        
        TaskManager taskManager = new TaskManager();
        
        LivenessServiceManager livenessServiceManager = new LivenessServiceManager();

       

        ValidationServiceManager validationServiceManager = new ValidationServiceManager(
            network,
            rewardsCoreAddress,
            address(registry),
            address(rewardsManager),
            address(slashingManager),
            address(taskManager),
            address(livenessServiceManager)
        );

        registry.transferOwnership(address(validationServiceManager));
        rewardsManager.transferOwnership(address(validationServiceManager));
        slashingManager.transferOwnership(address(validationServiceManager));
        taskManager.transferOwnership(address(validationServiceManager));
        livenessServiceManager.transferOwnership(address(validationServiceManager));

        // Write deployment output
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