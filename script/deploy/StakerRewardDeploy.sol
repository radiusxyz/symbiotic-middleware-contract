// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Script} from "forge-std/src/Script.sol";
import {Utils} from "../utils/Utils.sol";

import {INetworkRegistry} from "@symbiotic-core/src/interfaces/INetworkRegistry.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";

import {IDefaultStakerRewards} from "@symbiotic-rewards/src/interfaces/defaultStakerRewards/IDefaultStakerRewards.sol";
import {DefaultStakerRewards} from "@symbiotic-rewards/src/contracts/defaultStakerRewards/DefaultStakerRewards.sol";
import {DefaultStakerRewardsFactory} from "@symbiotic-rewards/src/contracts/defaultStakerRewards/DefaultStakerRewardsFactory.sol";

contract StakerRewardDeploy is Script, Utils {
    function run() external {
        vm.startBroadcast();
        
        string memory output1 = readOutput(symbioticCoreDeploymentOutput);
        address networkRegistryAddress = convertAddress(vm.parseJson(output1, ".addresses.networkRegistry"));
        address vaultFactoryAddress = convertAddress(vm.parseJson(output1, ".addresses.vaultFactory"));
        address networkMiddlewareServiceAddress = convertAddress(vm.parseJson(output1, ".addresses.networkMiddlewareService"));

        string memory output2 = readOutput(vaultDeploymentOutput);
        address vaultAddress = convertAddress(vm.parseJson(output2, ".addresses.vault"));

        DefaultStakerRewards stakerRewardsImplementation =
            new DefaultStakerRewards(vaultFactoryAddress, networkMiddlewareServiceAddress);
        
        DefaultStakerRewardsFactory defaultStakerRewardsFactory = new DefaultStakerRewardsFactory(address(stakerRewardsImplementation));

        vm.serializeAddress(
            deployedContractAddresses,
            "defaultStakerRewardsFactory",
            address(defaultStakerRewardsFactory)
        );

        address stakerReward = defaultStakerRewardsFactory.create(
            IDefaultStakerRewards.InitParams({
                vault: vaultAddress,
                adminFee: adminFee,
                defaultAdminRoleHolder: defaultAdminRoleHolder,
                adminFeeClaimRoleHolder: adminFeeClaimRoleHolder,
                adminFeeSetRoleHolder: adminFeeSetRoleHolder
            })
        );

        string memory deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "stakerReward",
            stakerReward
        );

        string memory finalJson = vm.serializeString(
            parentObject,
            deployedContractAddresses,
            deployedContractAddresses_output
        );

        writeOutput(finalJson, stakerRewardDeploymentOutput);

        vm.stopBroadcast();
    }
}
