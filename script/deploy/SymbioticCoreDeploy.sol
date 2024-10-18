// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/src/Script.sol";

import {Utils} from "../utils/Utils.sol";
import "../../src/RadiusTestERC20.sol";

import "forge-std/src/Test.sol";
import "forge-std/src/Script.sol";
import "forge-std/src/StdJson.sol";
import "forge-std/src/console.sol";

import {DefaultCollateralFactory} from "@symbiotic-collateral/src/contracts/defaultCollateral/DefaultCollateralFactory.sol";

import {VaultFactory} from "@symbiotic-core/src/contracts/VaultFactory.sol";
import {DelegatorFactory} from "@symbiotic-core/src/contracts/DelegatorFactory.sol";
import {SlasherFactory} from "@symbiotic-core/src/contracts/SlasherFactory.sol";
import {NetworkRegistry} from "@symbiotic-core/src/contracts/NetworkRegistry.sol";
import {OperatorRegistry} from "@symbiotic-core/src/contracts/OperatorRegistry.sol";
import {MetadataService} from "@symbiotic-core/src/contracts/service/MetadataService.sol";
import {NetworkMiddlewareService} from "@symbiotic-core/src/contracts/service/NetworkMiddlewareService.sol";
import {OptInService} from "@symbiotic-core/src/contracts/service/OptInService.sol";
import {Vault} from "@symbiotic-core/src/contracts/vault/Vault.sol";
import {NetworkRestakeDelegator} from "@symbiotic-core/src/contracts/delegator/NetworkRestakeDelegator.sol";
import {FullRestakeDelegator} from "@symbiotic-core/src/contracts/delegator/FullRestakeDelegator.sol";
import {Slasher} from "@symbiotic-core/src/contracts/slasher/Slasher.sol";
import {VetoSlasher} from "@symbiotic-core/src/contracts/slasher/VetoSlasher.sol";
import {VaultConfigurator} from "@symbiotic-core/src/contracts/VaultConfigurator.sol";

contract SymbioticCoreDeploy is Script, Utils {
    function run() public {
        vm.startBroadcast();

        (,, address deployer) = vm.readCallers();

        VaultFactory vaultFactory = new VaultFactory(deployer);
        vm.serializeAddress(
            deployedContractAddresses,
            "vaultFactory",
            address(vaultFactory)
        );

        DelegatorFactory delegatorFactory = new DelegatorFactory(deployer);
        vm.serializeAddress(
            deployedContractAddresses,
            "delegatorFactory",
            address(delegatorFactory)
        );

        SlasherFactory slasherFactory = new SlasherFactory(deployer);
        vm.serializeAddress(
            deployedContractAddresses,
            "slasherFactory",
            address(slasherFactory)
        );

        NetworkRegistry networkRegistry = new NetworkRegistry();
        vm.serializeAddress(
            deployedContractAddresses,
            "networkRegistry",
            address(networkRegistry)
        );

        OperatorRegistry operatorRegistry = new OperatorRegistry();
        vm.serializeAddress(
            deployedContractAddresses,
            "operatorRegistry",
            address(operatorRegistry)
        );

        MetadataService operatorMetadataService = new MetadataService(address(operatorRegistry));
        vm.serializeAddress(
            deployedContractAddresses,
            "operatorMetadataService",
            address(operatorMetadataService)
        );

        MetadataService networkMetadataService = new MetadataService(address(networkRegistry));
        vm.serializeAddress(
            deployedContractAddresses,
            "networkMetadataService",
            address(networkMetadataService)
        );

        NetworkMiddlewareService networkMiddlewareService = new NetworkMiddlewareService(address(networkRegistry));
        vm.serializeAddress(
            deployedContractAddresses,
            "networkMiddlewareService",
            address(networkMiddlewareService)
        );

        OptInService operatorVaultOptInService = new OptInService(address(operatorRegistry), address(vaultFactory), "operator-vault");
        vm.serializeAddress(
            deployedContractAddresses,
            "operatorVaultOptInService",
            address(operatorVaultOptInService)
        );

        OptInService operatorNetworkOptInService = new OptInService(address(operatorRegistry), address(networkRegistry), "operator-network");
        vm.serializeAddress(
            deployedContractAddresses,
            "operatorNetworkOptInService",
            address(operatorNetworkOptInService)
        );

        address vaultImpl =
            address(new Vault(address(delegatorFactory), address(slasherFactory), address(vaultFactory)));
        vaultFactory.whitelist(vaultImpl);

        address networkRestakeDelegatorImpl = address(
            new NetworkRestakeDelegator(
                address(networkRegistry),
                address(vaultFactory),
                address(operatorVaultOptInService),
                address(operatorNetworkOptInService),
                address(delegatorFactory),
                delegatorFactory.totalTypes()
            )
        );
        delegatorFactory.whitelist(networkRestakeDelegatorImpl);

        address fullRestakeDelegatorImpl = address(
            new FullRestakeDelegator(
                address(networkRegistry),
                address(vaultFactory),
                address(operatorVaultOptInService),
                address(operatorNetworkOptInService),
                address(delegatorFactory),
                delegatorFactory.totalTypes()
            )
        );
        delegatorFactory.whitelist(fullRestakeDelegatorImpl);

        address slasherImpl = address(
            new Slasher(
                address(vaultFactory),
                address(networkMiddlewareService),
                address(slasherFactory),
                slasherFactory.totalTypes()
            )
        );
        slasherFactory.whitelist(slasherImpl);

        address vetoSlasherImpl = address(
            new VetoSlasher(
                address(vaultFactory),
                address(networkMiddlewareService),
                address(networkRegistry),
                address(slasherFactory),
                slasherFactory.totalTypes()
            )
        );
        slasherFactory.whitelist(vetoSlasherImpl);

        VaultConfigurator vaultConfigurator =
            new VaultConfigurator(address(vaultFactory), address(delegatorFactory), address(slasherFactory));
        string memory deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "vaultConfigurator",
            address(vaultConfigurator)
        );

        string memory finalJson = vm.serializeString(
            parentObject,
            deployedContractAddresses,
            deployedContractAddresses_output
        );

        writeOutput(finalJson, symbioticCoreDeploymentOutput);
        vm.stopBroadcast();
    }
}