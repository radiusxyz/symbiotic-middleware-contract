// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/src/Script.sol";
import {Utils} from "../utils/Utils.sol";

import {BurnerRouter} from "lib/symbioticfi/burners/src/contracts/router/BurnerRouter.sol";
import {IBurnerRouter} from "lib/symbioticfi/burners/src/interfaces/router/IBurnerRouter.sol";
import {BurnerRouterFactory} from "lib/symbioticfi/burners/src/contracts/router/BurnerRouterFactory.sol";
import {IBurnerRouterFactory} from "lib/symbioticfi/burners/src/interfaces/router/IBurnerRouterFactory.sol";


contract BurnerRouterDeploy is Script, Utils {

    function run() public {
        vm.startBroadcast();
        (,, address owner) = vm.readCallers();

        string memory output1 = readOutput(collateralDeploymentOutput);
        address defaultCollateralAddress = convertAddress(vm.parseJson(output1, ".addresses.defaultCollateral"));
        address stETHCollateralAddress = convertAddress(vm.parseJson(output1, ".addresses.stETHCollateral"));
        address wBTCCollateralAddress = convertAddress(vm.parseJson(output1, ".addresses.wBTCCollateral"));

        // First, deploy the BurnerRouter implementation
        BurnerRouter burnerRouterImplementation = new BurnerRouter();
        
        // Deploy the factory with the implementation address
        BurnerRouterFactory burnerRouterFactory = new BurnerRouterFactory(
            address(burnerRouterImplementation)
        );
        
        // Serialize factory address
        vm.serializeAddress(
            deployedContractAddresses,
            "burnerRouterFactory",
            address(burnerRouterFactory)
        );

        IBurnerRouter.NetworkReceiver[] memory networkReceivers = new IBurnerRouter.NetworkReceiver[](1);
        networkReceivers[0] = IBurnerRouter.NetworkReceiver({
            network: network, // Use your network address variable
            receiver: network // Same address as network
        });
        IBurnerRouter.OperatorNetworkReceiver[] memory emptyOperatorNetworkReceivers = new IBurnerRouter.OperatorNetworkReceiver[](0);
        
        address defaultBurnerRouter = burnerRouterFactory.create(
            IBurnerRouter.InitParams({
                collateral: defaultCollateralAddress,
                owner: owner,
                delay: 10,
                globalReceiver: owner,
                networkReceivers: networkReceivers,
                operatorNetworkReceivers: emptyOperatorNetworkReceivers
            })
        );
        
        string memory deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "defaultBurnerRouter",
            defaultBurnerRouter
        );
        
        // For stETH
        address stETHBurnerRouter = burnerRouterFactory.create(
            IBurnerRouter.InitParams({
                collateral: stETHCollateralAddress,
                owner: owner,
                delay: 10,
                globalReceiver: owner,
                networkReceivers: networkReceivers,
                operatorNetworkReceivers: emptyOperatorNetworkReceivers
            })
        );
        deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "stETHBurnerRouter",
            stETHBurnerRouter
        );
        
        // For wBTC
        address wBTCBurnerRouter = burnerRouterFactory.create(
            IBurnerRouter.InitParams({
                collateral: wBTCCollateralAddress,
                owner: owner,
                delay: 10,
                globalReceiver: owner,
                networkReceivers: networkReceivers,
                operatorNetworkReceivers: emptyOperatorNetworkReceivers
            })
        );
        deployedContractAddresses_output = vm.serializeAddress(
            deployedContractAddresses,
            "wBTCBurnerRouter",
            wBTCBurnerRouter
        );

        string memory finalJson = vm.serializeString(
            parentObject,
            deployedContractAddresses,
            deployedContractAddresses_output
        );

        writeOutput(finalJson, burnerRouterDeploymentOutput);
        vm.stopBroadcast();
    }
}