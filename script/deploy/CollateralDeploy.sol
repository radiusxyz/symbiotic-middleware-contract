// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Script} from "forge-std/src/Script.sol";

import {Utils} from "../utils/Utils.sol";
import "../../src/RadiusTestERC20.sol";
import "../../src/stETHTest.sol";
import "../../src/wBTCTest.sol";

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
        stETHTest stETHTestERC20 = new stETHTest(initialSupply);
        wBTCTest wBTCTestERC20 = new wBTCTest(initialSupply);

        vm.serializeAddress(deployedContractAddresses, "radiusTestERC20", address(radiusTestERC20));
        vm.serializeAddress(deployedContractAddresses, "stETHTestERC20", address(stETHTestERC20));
        vm.serializeAddress(deployedContractAddresses, "wBTCTestERC20", address(wBTCTestERC20));

        DefaultCollateralFactory defaultCollateralFactory = new DefaultCollateralFactory();

        vm.serializeAddress(deployedContractAddresses, "defaultCollateralFactory", address(defaultCollateralFactory));

        address defaultCollateral = defaultCollateralFactory.create(address(radiusTestERC20), initialLimit, limitIncreaser);
        address stETHCollateral = defaultCollateralFactory.create(address(stETHTestERC20), initialLimit, limitIncreaser);
        address wBTCCollateral = defaultCollateralFactory.create(address(wBTCTestERC20), initialLimit, limitIncreaser);

        string memory output1 = vm.serializeAddress(deployedContractAddresses, "defaultCollateral", defaultCollateral);
        string memory output2 = vm.serializeAddress(deployedContractAddresses, "stETHCollateral", stETHCollateral);
        string memory deployedContractAddresses_output = vm.serializeAddress(deployedContractAddresses, "wBTCCollateral", wBTCCollateral);

        string memory finalJson = vm.serializeString(
            parentObject,
            deployedContractAddresses,
            deployedContractAddresses_output
        );

        writeOutput(finalJson, collateralDeploymentOutput);
        vm.stopBroadcast();
    }
}