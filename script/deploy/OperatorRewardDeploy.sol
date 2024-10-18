// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/src/Script.sol";
import {Utils} from "../utils/Utils.sol";

import {IDefaultOperatorRewardsFactory} from
    "@symbiotic-rewards/src/interfaces/defaultOperatorRewards/IDefaultOperatorRewardsFactory.sol";
import {DefaultOperatorRewards} from "@symbiotic-rewards/src/contracts/defaultOperatorRewards/DefaultOperatorRewards.sol";
import {DefaultOperatorRewardsFactory} from
    "@symbiotic-rewards/src/contracts/defaultOperatorRewards/DefaultOperatorRewardsFactory.sol";

contract OperatorRewardDeploy is Script, Utils {
    function run() external {
        vm.startBroadcast();
      
        string memory output = readOutput(symbioticCoreDeploymentOutput);
        
        address networkMiddlewareServiceAddress = convertAddress(vm.parseJson(output, ".addresses.networkMiddlewareService"));

        DefaultOperatorRewards operatorRewardsImplementation = new DefaultOperatorRewards(networkMiddlewareServiceAddress);
        
        DefaultOperatorRewardsFactory defaultOperatorRewardsFactory = new DefaultOperatorRewardsFactory(address(operatorRewardsImplementation));
      
        vm.serializeAddress(
            deployedContractAddresses,
            "defaultOperatorRewardsFactory",
            address(defaultOperatorRewardsFactory)
        );

        address operatorReward = defaultOperatorRewardsFactory.create();

        string memory deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "operatorReward",
            operatorReward
        );

        string memory finalJson = vm.serializeString(
            parentObject,
            deployedContractAddresses,
            deployedContractAddresses_output
        );

        writeOutput(finalJson, operatorRewardDeploymentOutput);

        vm.stopBroadcast();
    }
}
