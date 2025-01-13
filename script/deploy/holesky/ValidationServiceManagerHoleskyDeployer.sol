// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Utils} from "../../utils/Utils.sol";

import {Script, console2} from "forge-std/src/Script.sol";
import {ValidationServiceManager} from "src/ValidationServiceManager.sol";

import {INetworkRegistry} from "@symbiotic-core/src/interfaces/INetworkRegistry.sol";
import {IOperatorRegistry} from "@symbiotic-core/src/interfaces/IOperatorRegistry.sol";
import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";
import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";

contract ValidationServiceManagerHoleskyDeployer is Script, Utils {
    function run() external {
        vm.startBroadcast();

        (,, address owner) = vm.readCallers();

        // dynamic
        address network = vm.envAddress("NETWORK_ADDRESS");

        // fixed
        address operatorRegistryAddress = vm.envAddress("OPERATOR_REGISTRY_CONTRACT_ADDRESS");
        address vaultRegistry = vm.envAddress("VAULT_FACTORY_CONTRACT_ADDRESS");
        address operatorNetworkOptInServiceAddress = vm.envAddress("OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS");

        uint48 validationServiceManagerEpochDuration = uint48(vm.envUint("VALIDATION_SERVICE_MANAGER_EPOCH_DURATION"));

        ValidationServiceManager validationServiceManager = new ValidationServiceManager(
            network, 

            vaultRegistry, 
            operatorNetworkOptInServiceAddress, 

            validationServiceManagerEpochDuration
        );

        console2.log("VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS=", address(validationServiceManager));

        vm.stopBroadcast();
    }
}