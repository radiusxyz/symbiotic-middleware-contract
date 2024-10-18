// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/src/Script.sol";

import {Utils} from "../utils/Utils.sol";

import {IMigratablesFactory} from "@symbiotic-core/src/interfaces/common/IMigratablesFactory.sol";
import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";
import {IVaultConfigurator} from "@symbiotic-core/src/interfaces/IVaultConfigurator.sol";
import {IBaseDelegator} from "@symbiotic-core/src/interfaces/delegator/IBaseDelegator.sol";
import {INetworkRestakeDelegator} from "@symbiotic-core/src/interfaces/delegator/INetworkRestakeDelegator.sol";
import {IFullRestakeDelegator} from "@symbiotic-core/src/interfaces/delegator/IFullRestakeDelegator.sol";
import {IVetoSlasher} from "@symbiotic-core/src/interfaces/slasher/IVetoSlasher.sol";
import {IBaseSlasher} from "@symbiotic-core/src/interfaces/slasher/IBaseSlasher.sol";

contract VaultDeploy is Script, Utils {
    function run() public {
        vm.startBroadcast();
        (,, address owner) = vm.readCallers();

        string memory output1 = readOutput(symbioticCoreDeploymentOutput);
        address vaultConfiguratorAddress = convertAddress(vm.parseJson(output1, ".addresses.vaultConfigurator"));

        string memory output2 = readOutput(collateralDeploymentOutput);
        address defaultCollateralAddress = convertAddress(vm.parseJson(output2, ".addresses.defaultCollateral"));

        address[] memory networkLimitSetRoleHolders = new address[](1);
        networkLimitSetRoleHolders[0] = owner;

        address[] memory operatorNetworkLimitSetRoleHolders = new address[](1);
        operatorNetworkLimitSetRoleHolders[0] = owner;

        address[] memory operatorNetworkSharesSetRoleHolders = new address[](1);
        operatorNetworkSharesSetRoleHolders[0] = owner;

        (address vault, address delegator, address slasher) = IVaultConfigurator(vaultConfiguratorAddress).create(
            IVaultConfigurator.InitParams({
                version: IMigratablesFactory(IVaultConfigurator(vaultConfiguratorAddress).VAULT_FACTORY()).lastVersion(),
                owner: owner,
                vaultParams: abi.encode(
                    IVault.InitParams({
                        collateral: defaultCollateralAddress, /// TODO: tokenAddress
                        burner: address(0xdEaD),
                        epochDuration: epochDuration,

                        depositWhitelist: depositWhitelist,
                        
                        isDepositLimit: depositLimit != 0,
                        depositLimit: depositLimit,

                        defaultAdminRoleHolder: owner,
                        depositWhitelistSetRoleHolder: owner,
                        depositorWhitelistRoleHolder: owner,
                        isDepositLimitSetRoleHolder: owner,
                        depositLimitSetRoleHolder: owner
                    })
                ),
                delegatorIndex: delegatorIndex,
                delegatorParams: delegatorIndex == 0
                    ? abi.encode(
                        INetworkRestakeDelegator.InitParams({
                            baseParams: IBaseDelegator.BaseParams({
                                defaultAdminRoleHolder: owner,
                                hook: address(0),
                                hookSetRoleHolder: owner
                            }),
                            networkLimitSetRoleHolders: networkLimitSetRoleHolders,
                            operatorNetworkSharesSetRoleHolders: operatorNetworkSharesSetRoleHolders
                        })
                    )
                    : abi.encode(
                        IFullRestakeDelegator.InitParams({
                            baseParams: IBaseDelegator.BaseParams({
                                defaultAdminRoleHolder: owner,
                                hook: address(0),
                                hookSetRoleHolder: owner
                            }),
                            networkLimitSetRoleHolders: networkLimitSetRoleHolders,
                            operatorNetworkLimitSetRoleHolders: operatorNetworkLimitSetRoleHolders
                        })
                    ),
                withSlasher: withSlasher,
                slasherIndex: slasherIndex,
                slasherParams: slasherIndex == 0
                    ? new bytes(0)
                    : abi.encode(IVetoSlasher.InitParams({
                      baseParams: IBaseSlasher.BaseParams({isBurnerHook: false}),
                      vetoDuration: vetoDuration, 
                      resolverSetEpochsDelay: 3
                    }))
            })
        );

        vm.serializeAddress(
            deployedContractAddresses,
            "vault",
            vault
        );

        vm.serializeAddress(
            deployedContractAddresses,
            "slasher",
            slasher
        );

        string memory deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "delegator",
            delegator
        );

        string memory finalJson = vm.serializeString(
            parentObject,
            deployedContractAddresses,
            deployedContractAddresses_output
        );

        writeOutput(finalJson, vaultDeploymentOutput);

        vm.stopBroadcast();
    }
}
