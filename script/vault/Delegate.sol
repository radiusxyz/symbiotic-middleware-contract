// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Utils} from "../utils/Utils.sol";

import {Script, console2} from "forge-std/src/Script.sol";

import "../../src/RadiusTestERC20.sol";
import {DefaultCollateral} from "@symbiotic-collateral/src/contracts/defaultCollateral/DefaultCollateral.sol";
import {IVault} from "@symbiotic-core/src/interfaces/vault/IVault.sol";
import {INetworkRestakeDelegator} from "@symbiotic-core/src/interfaces/delegator/INetworkRestakeDelegator.sol";

import {IOptInService} from "@symbiotic-core/src/interfaces/service/IOptInService.sol";

contract Delegate is Script, Utils {
    function run() external {
        vm.startBroadcast();

        (,, address operatorAddress) = vm.readCallers();

        string memory output1 = readOutput(vaultDeploymentOutput);
        address vaultAddress = convertAddress(vm.parseJson(output1, ".addresses.vault"));
        
        address delegatorAddress = IVault(vaultAddress).delegator();
        
        uint96 identifier = 0;
        bytes32 subnetwork = 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266000000000000000000000000;

        INetworkRestakeDelegator(delegatorAddress).setMaxNetworkLimit(identifier, 100);
        INetworkRestakeDelegator(delegatorAddress).setNetworkLimit(subnetwork, 20);
        INetworkRestakeDelegator(delegatorAddress).setOperatorNetworkShares(subnetwork, operatorAddress, 10);
  
        vm.stopBroadcast();
    }
}