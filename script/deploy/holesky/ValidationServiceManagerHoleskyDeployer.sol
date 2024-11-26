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

        address network = address(0x47f75987c12Ff78eE33641bCA6D26624791442e0);

        address operatorRegistryAddress = address(0x6F75a4ffF97326A00e52662d82EA4FdE86a2C548);
        address vaultFactoryAddress = address(0x407A039D94948484D356eFB765b3c74382A050B4);
        address operatorNetworkOptInServiceAddress = address(0x58973d16FFA900D11fC22e5e2B6840d9f7e13401);

        uint48 validationServiceManagerEpochDuration = 12;
        uint48 minSlashingWindow = validationServiceManagerEpochDuration;

        ValidationServiceManager validationServiceManager = new ValidationServiceManager(
            network, 

            vaultFactoryAddress, 
            operatorNetworkOptInServiceAddress, 

            validationServiceManagerEpochDuration, 
            minSlashingWindow
        );

        console2.log("validationServiceManager: ", address(validationServiceManager));

        vm.stopBroadcast();
    }
}