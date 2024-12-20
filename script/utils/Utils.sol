// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.25;

import "forge-std/src/Script.sol";
import "forge-std/src/StdJson.sol";

contract Utils is Script {
    string public parentObject = "parent object";
    string public deployedContractAddresses = "addresses";

    string public symbioticCoreDeploymentOutput = "symbiotic_core_deployment_output";
    string public collateralDeploymentOutput = "collateral_deployment_output";
    string public vaultDeploymentOutput = "vault_deployment_output";
    string public operatorRewardDeploymentOutput = "operator_reward_deployment_output";
    string public stakerRewardDeploymentOutput = "staker_reward_deployment_output";
    string public validationServiceManagerDeploymentOutput = "validation_service_manager_deployment_output";
    string public livenessRadiusDeploymentOutput = "liveness_radius_deployment_output";

    string constant rewardsManagerDeploymentOutput = "rewards_manager_deployment_output";

    // Related to CollateralDeploy
    uint256 public initialSupply = 1000000000000000000000000000;
    uint256 public initialLimit = 1000000000000000000000000000;

    // Related to VaultDeploy
    bool public depositWhitelist = false;
    uint64 public delegatorIndex = 0; // 0: INetworkRestakeDelegator / 1: IFullRestakeDelegator
    uint64 public slasherIndex = 0; // 0: Instance? / 1: IVetoSlasher
    uint48 public vetoDuration = 100;
    bool public withSlasher = false;
    uint256 public depositLimit = 100000000000;
    uint48 public epochDuration = 100;

    // Rlated to StakerRewardDeploy
    uint256 public adminFee = 0;
    address public defaultAdminRoleHolder = address(0x0000000000000000000000000000000000000000);
    address public adminFeeClaimRoleHolder = address(0x0000000000000000000000000000000000000000);
    address public adminFeeSetRoleHolder = address(0x0000000000000000000000000000000000000000);

    // Related to middlewareDeploy
    address public network = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    uint48 public validationServiceManagerEpochDuration = 12;
    uint48 public minSlashingWindow = validationServiceManagerEpochDuration; // we dont use this

    function convertAddress(bytes memory input) public pure returns (address) {
        return abi.decode(input, (address));
    }

    function readOutput(
        string memory outputFileName
    ) public view returns (string memory) {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/latest-state/"
        );
        string memory chainDir = string.concat(vm.toString(block.chainid), "/");
        string memory file = string.concat(outputFileName, ".json");
        return vm.readFile(string.concat(inputDir, chainDir, file));
    }

    function writeOutput(
        string memory outputJson,
        string memory outputFileName
    ) public {
        string memory outputDir = string.concat(
            vm.projectRoot(),
            "/latest-state/"
        );
        string memory chainDir = string.concat(outputDir, vm.toString(block.chainid), "/");
        string memory outputFilePath = string.concat(
            chainDir,
            outputFileName,
            ".json"
        );
        vm.writeJson(outputJson, outputFilePath);
    }
}
