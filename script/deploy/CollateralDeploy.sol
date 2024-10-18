// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Script} from "forge-std/src/Script.sol";

import {Utils} from "../utils/Utils.sol";
import "../../src/RadiusTestERC20.sol";

import "forge-std/src/Test.sol";
import "forge-std/src/Script.sol";
import "forge-std/src/StdJson.sol";
import "forge-std/src/console.sol";

import {DefaultCollateralFactory} from "@symbiotic-collateral/src/contracts/defaultCollateral/DefaultCollateralFactory.sol";
import {DefaultCollateral} from "@symbiotic-collateral/src/contracts/defaultCollateral/DefaultCollateral.sol";

contract CollateralDeploy is Script, Utils {
    function run() public {
        vm.startBroadcast();

        (,, address deployer) = vm.readCallers();
        
        address limitIncreaser = address(deployer);

        RadiusTestERC20 radiusTestERC20 = new RadiusTestERC20(initialSupply);

        vm.serializeAddress(
            deployedContractAddresses,
            "radiusTestERC20",
            address(radiusTestERC20)
        );

        DefaultCollateralFactory defaultCollateralFactory = new DefaultCollateralFactory();

        vm.serializeAddress(
            deployedContractAddresses,
            "defaultCollateralFactory",
            address(defaultCollateralFactory)
        );

        address defaultCollateral = defaultCollateralFactory.create(address(radiusTestERC20), initialLimit, limitIncreaser);

        string memory deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "defaultCollateral",
            defaultCollateral
        );

        string memory finalJson = vm.serializeString(
            parentObject,
            deployedContractAddresses,
            deployedContractAddresses_output
        );

        writeOutput(finalJson, collateralDeploymentOutput);
        vm.stopBroadcast();
    }
}