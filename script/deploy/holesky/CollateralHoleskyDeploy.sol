// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/src/Script.sol";

import {Utils} from "../../utils/Utils.sol";
import "../../../src/RadiusTestERC20.sol";

import "forge-std/src/Test.sol";
import "forge-std/src/Script.sol";
import "forge-std/src/StdJson.sol";
import "forge-std/src/console.sol";

import {DefaultCollateralFactory} from "@symbiotic-collateral/src/contracts/defaultCollateral/DefaultCollateralFactory.sol";
import {DefaultCollateral} from "@symbiotic-collateral/src/contracts/defaultCollateral/DefaultCollateral.sol";

contract CollateralHoleskyDeploy is Script, Utils {
    function run() public {
        vm.startBroadcast();

        (,, address deployer) = vm.readCallers();
        
        address limitIncreaser = address(deployer);

        uint256 initialSupply = vm.envUint("INITIAL_SUPPLY");

        RadiusTestERC20 radiusTestERC20 = new RadiusTestERC20(initialSupply);
        console2.log("TEST_TOKEN_CONTRACT_ADDRESS=", address(radiusTestERC20));

        DefaultCollateralFactory defaultCollateralFactory = new DefaultCollateralFactory();
        console2.log("DEFAULT_COLLATERAL_FACTORY=", address(defaultCollateralFactory));

        address defaultCollateral = defaultCollateralFactory.create(address(radiusTestERC20), initialLimit, limitIncreaser);
        console2.log("DEFAULT_COLLATERAL=", address(defaultCollateral));

        vm.stopBroadcast();
    }
}