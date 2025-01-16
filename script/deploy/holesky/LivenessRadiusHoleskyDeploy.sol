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
import {LivenessRadius} from "src/liveness/LivenessRadius.sol";

contract LivenessRadiusHoleskyDeploy is Script, Utils {
    function run() public {
        vm.startBroadcast();

        LivenessRadius livenessRadius = new LivenessRadius();

        console2.log("livenessRadius: ", address(livenessRadius));

        vm.stopBroadcast();
    }
}
