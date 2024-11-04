// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/src/Script.sol";

import {Utils} from "../../utils/Utils.sol";

import {IMigratablesFactory} from "@symbiotic-core/src/interfaces/common/IMigratablesFactory.sol";
import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";
import {IVaultConfigurator} from "@symbiotic-core/src/interfaces/IVaultConfigurator.sol";
import {IBaseDelegator} from "@symbiotic-core/src/interfaces/delegator/IBaseDelegator.sol";
import {INetworkRestakeDelegator} from "@symbiotic-core/src/interfaces/delegator/INetworkRestakeDelegator.sol";
import {IFullRestakeDelegator} from "@symbiotic-core/src/interfaces/delegator/IFullRestakeDelegator.sol";
import {IOperatorSpecificDelegator} from "@symbiotic-core/src/interfaces/delegator/IOperatorSpecificDelegator.sol";
import {IVetoSlasher} from "@symbiotic-core/src/interfaces/slasher/IVetoSlasher.sol";
import {IBaseSlasher} from "@symbiotic-core/src/interfaces/slasher/IBaseSlasher.sol";
import {ISlasher} from "@symbiotic-core/src/interfaces/slasher/ISlasher.sol";

contract VaultHoleskyDeploy is Script, Utils {
    function run() public {
        vm.startBroadcast();
        (,, address owner) = vm.readCallers();

        address vaultConfiguratorAddress = address(0xD2191FE92987171691d552C219b8caEf186eb9cA);
        address defaultCollateralAddress = address(0x81Dd92EE2119A5Dbed0F6499DFA3ca4a9E50658e);

        address[] memory networkLimitSetRoleHolders = new address[](1);
        networkLimitSetRoleHolders[0] = owner;

        address[] memory operatorNetworkLimitSetRoleHolders = new address[](1);
        operatorNetworkLimitSetRoleHolders[0] = owner;

        address[] memory operatorNetworkSharesSetRoleHolders = new address[](1);
        operatorNetworkSharesSetRoleHolders[0] = owner;

        console2.log("version", IMigratablesFactory(IVaultConfigurator(vaultConfiguratorAddress).VAULT_FACTORY()).lastVersion());

         (address vault, address delegator, address slasher) = IVaultConfigurator(vaultConfiguratorAddress).create(
            IVaultConfigurator.InitParams({
                version: 2,
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

        console2.log("vault: ", address(vault));
        console2.log("slasher: ", address(slasher));
        console2.log("delegator: ", address(delegator));

        vm.stopBroadcast();
    }
}
