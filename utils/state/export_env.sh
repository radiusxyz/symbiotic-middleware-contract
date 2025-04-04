#!/bin/bash
PROJECT_ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
LATEST_STATE_PATH="$PROJECT_ROOT_PATH/latest-state"

source $SCRIPT_PATH/../env.sh
STATE_DIR="$LATEST_STATE_PATH/$CHAIN_ID"

# Function to extract values from JSON files using jq
extract_json_addresses() {
    jq -r '.addresses' "$1"
}

# Read all deployment files
SYMBIOTIC_CORE_FILE=$(extract_json_addresses "$STATE_DIR/symbiotic_core_deployment_output.json")

REWARDS_CORE_FILE=$(extract_json_addresses "$STATE_DIR/rewards_core_deployment_output.json")
OPERATOR_REWARDS_FILE=$(extract_json_addresses "$STATE_DIR/operator_reward_deployment_output.json")
STAKER_REWARDS_FILE=$(extract_json_addresses "$STATE_DIR/staker_reward_deployment_output.json")

COLLATERAL_FILE=$(extract_json_addresses "$STATE_DIR/collateral_deployment_output.json")
VAULT_FILE=$(extract_json_addresses "$STATE_DIR/vault_deployment_output.json")

LIVENESS_SERVICE_MANAGER_FILE=$(extract_json_addresses "$STATE_DIR/liveness_service_manager_deployment_output.json")
VALIDATION_MANAGER_FILE=$(extract_json_addresses "$STATE_DIR/validation_service_manager_deployment_output.json")

echo -e "\n# RPC info"
echo "export LIVENESS_RPC_URL=\"$(echo $LIVENESS_RPC_URL)\""
echo "export LIVENESS_WS_URL=\"$(echo $LIVENESS_WS_URL)\""
echo "export VALIDATION_RPC_URL=\"$(echo $VALIDATION_RPC_URL)\""
echo "export VALIDATION_WS_URL=\"$(echo $VALIDATION_WS_URL)\""

echo -e "\n# Account info"
echo "export SYMBIOTIC_CORE_DEPLOYER_PRIVATE_KEY=\"$(echo $SYMBIOTIC_CORE_DEPLOYER_PRIVATE_KEY)\""
echo "export SYMBIOTIC_CORE_DEPLOYER_ADDRESS=\"$(echo $SYMBIOTIC_CORE_DEPLOYER_ADDRESS)\""
echo ""
echo "export RADIUS_PRIVATE_KEY=\"$(echo $RADIUS_PRIVATE_KEY)\""
echo "export RADIUS_ADDRESS=\"$(echo $RADIUS_ADDRESS)\""
echo ""
echo "export NETWORK_PRIVATE_KEY=\"$(echo $NETWORK_PRIVATE_KEY)\""
echo "export NETWORK_ADDRESS=\"$(echo $NETWORK_ADDRESS)\""
echo ""
echo "export RADIUS_TOKEN_CONTRACT_OWNER_PRIVATE_KEY=\"$(echo $VAULT_OWNER_PRIVATE_KEY)\""
echo "export RADIUS_TOKEN_CONTRACT_OWNER_ADDRESS=\"$(echo $VAULT_OWNER_ADDRESS)\""
echo ""
echo "export STETH_TOKEN_CONTRACT_OWNER_PRIVATE_KEY=\"$(echo $VAULT_OWNER_PRIVATE_KEY)\""
echo "export STETH_TOKEN_CONTRACT_OWNER_ADDRESS=\"$(echo $VAULT_OWNER_ADDRESS)\""
echo "export STETH_COLLATERAL_CONTRACT_OWNER_PRIVATE_KEY=\"$(echo $VAULT_OWNER_PRIVATE_KEY)\""
echo "export STETH_COLLATERAL_CONTRACT_OWNER_ADDRESS=\"$(echo $VAULT_OWNER_ADDRESS)\""
echo "export STETH_DELEGATOR_CONTRACT_OWNER_PRIVATE_KEY=\"$(echo $VAULT_OWNER_PRIVATE_KEY)\""
echo "export STETH_DELEGATOR__CONTRACT_OWNER_ADDRESS=\"$(echo $VAULT_OWNER_ADDRESS)\""
echo "export STETH_SLASHER_CONTRACT_OWNER_PRIVATE_KEY=\"$(echo $VAULT_OWNER_PRIVATE_KEY)\""
echo "export STETH_SLASHER__CONTRACT_OWNER_ADDRESS=\"$(echo $VAULT_OWNER_ADDRESS)\""
echo "export STETH_VAULT_CONTRACT_OWNER_PRIVATE_KEY=\"$(echo $VAULT_OWNER_PRIVATE_KEY)\""
echo "export STETH_VAULT__CONTRACT_OWNER_ADDRESS=\"$(echo $VAULT_OWNER_ADDRESS)\""
echo ""
echo "export WBTC_TOKEN_CONTRACT_OWNER_PRIVATE_KEY=\"$(echo $VAULT_OWNER_PRIVATE_KEY)\""
echo "export WBTC_TOKEN_CONTRACT_OWNER_ADDRESS=\"$(echo $VAULT_OWNER_ADDRESS)\""
echo "export WBTC_COLLATERAL_CONTRACT_OWNER_PRIVATE_KEY=\"$(echo $VAULT_OWNER_PRIVATE_KEY)\""
echo "export WBTC_COLLATERAL_CONTRACT_OWNER_ADDRESS=\"$(echo $VAULT_OWNER_ADDRESS)\""
echo "export WBTC_DELEGATOR_CONTRACT_OWNER_PRIVATE_KEY=\"$(echo $VAULT_OWNER_PRIVATE_KEY)\""
echo "export WBTC_DELEGATOR__CONTRACT_OWNER_ADDRESS=\"$(echo $VAULT_OWNER_ADDRESS)\""
echo "export WBTC_SLASHER_CONTRACT_OWNER_PRIVATE_KEY=\"$(echo $VAULT_OWNER_PRIVATE_KEY)\""
echo "export WBTC_SLASHER__CONTRACT_OWNER_ADDRESS=\"$(echo $VAULT_OWNER_ADDRESS)\""
echo "export WBTC_VAULT_CONTRACT_OWNER_PRIVATE_KEY=\"$(echo $VAULT_OWNER_PRIVATE_KEY)\""
echo "export WBTC_VAULT__CONTRACT_OWNER_ADDRESS=\"$(echo $VAULT_OWNER_ADDRESS)\""


echo -e "\n# Symbiotic core deployment"
echo "export DELEGATOR_FACTORY_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE_FILE | jq -r '.delegatorFactory')\""
echo "export NETWORK_METADATA_SERVICE_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE_FILE | jq -r '.networkMetadataService')\""
echo "export NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE_FILE | jq -r '.networkMiddlewareService')\""
echo "export NETWORK_REGISTRY_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE_FILE | jq -r '.networkRegistry')\""
echo "export OPERATOR_METADATA_SERVICE_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE_FILE | jq -r '.operatorMetadataService')\""
echo "export OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE_FILE | jq -r '.operatorNetworkOptInService')\""
echo "export OPERATOR_REGISTRY_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE_FILE | jq -r '.operatorRegistry')\""
echo "export OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE_FILE | jq -r '.operatorVaultOptInService')\""
echo "export SLASHER_FACTORY_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE_FILE | jq -r '.slasherFactory')\""
echo "export VAULT_CONFIGURATOR_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE_FILE | jq -r '.vaultConfigurator')\""
echo "export VAULT_FACTORY_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE_FILE | jq -r '.vaultFactory')\""

echo -e "\n# Operator reward deployment"
echo "export DEFAULT_OPERATOR_REWARD_CONTRACT_ADDRESS=\"$(echo $OPERATOR_REWARDS_FILE | jq -r '.defaultOperatorReward')\""
echo "export DEFAULT_OPERATOR_REWARDS_FACTORY_CONTRACT_ADDRESS=\"$(echo $OPERATOR_REWARDS_FILE | jq -r '.defaultOperatorRewardsFactory')\""
echo "export STETH_OPERATOR_REWARD_CONTRACT_ADDRESS=\"$(echo $OPERATOR_REWARDS_FILE | jq -r '.stETHOperatorReward')\""
echo "export WBTC_OPERATOR_REWARD_CONTRACT_ADDRESS=\"$(echo $OPERATOR_REWARDS_FILE | jq -r '.wBTCOperatorReward')\""

echo -e "\n# Staker reward deployment"
echo "export DEFAULT_STAKER_REWARD_CONTRACT_ADDRESS=\"$(echo $STAKER_REWARDS_FILE | jq -r '.defaultStakerReward')\""
echo "export DEFAULT_STAKER_REWARDS_FACTORY_CONTRACT_ADDRESS=\"$(echo $STAKER_REWARDS_FILE | jq -r '.defaultStakerRewardsFactory')\""
echo "export STETH_STAKER_REWARD_CONTRACT_ADDRESS=\"$(echo $STAKER_REWARDS_FILE | jq -r '.stETHStakerReward')\""
echo "export WBTC_STAKER_REWARD_CONTRACT_ADDRESS=\"$(echo $STAKER_REWARDS_FILE | jq -r '.wBTCStakerReward')\""

echo -e "\n# Reward core deployment"
echo "export REWARDS_CORE_CONTRACT_ADDRESS=\"$(echo $REWARDS_CORE_FILE | jq -r '.rewardsCore')\""

echo -e "\n# Collateral deployment"
echo "export DEFAULT_COLLATERAL_CONTRACT_ADDRESS=\"$(echo $COLLATERAL_FILE | jq -r '.defaultCollateral')\""
echo "export DEFAULT_COLLATERAL_FACTORY_CONTRACT_ADDRESS=\"$(echo $COLLATERAL_FILE | jq -r '.defaultCollateralFactory')\""
echo "export STETH_COLLATERAL_CONTRACT_ADDRESS=\"$(echo $COLLATERAL_FILE | jq -r '.stETHCollateral')\""
echo "export WBTC_COLLATERAL_CONTRACT_ADDRESS=\"$(echo $COLLATERAL_FILE | jq -r '.wBTCCollateral')\""
echo "export RADIUS_TOKEN_CONTRACT_ADDRESS=\"$(echo $COLLATERAL_FILE | jq -r '.radiusTestERC20')\""
echo "export STETH_TOKEN_CONTRACT_ADDRESS=\"$(echo $COLLATERAL_FILE | jq -r '.stETHTestERC20')\""
echo "export WBTC_TOKEN_CONTRACT_ADDRESS=\"$(echo $COLLATERAL_FILE | jq -r '.wBTCTestERC20')\""

echo -e "\n# Vault deployment"
echo "export DEFAULT_DELEGATOR_CONTRACT_ADDRESS=\"$(echo $VAULT_FILE | jq -r '.defaultDelegator')\""
echo "export DEFAULT_SLASHER_CONTRACT_ADDRESS=\"$(echo $VAULT_FILE | jq -r '.defaultSlasher')\""
echo "export DEFAULT_VAULT_CONTRACT_ADDRESS=\"$(echo $VAULT_FILE | jq -r '.defaultVault')\""
echo "export STETH_DELEGATOR_CONTRACT_ADDRESS=\"$(echo $VAULT_FILE | jq -r '.stETHDelegator')\""
echo "export STETH_SLASHER_CONTRACT_ADDRESS=\"$(echo $VAULT_FILE | jq -r '.stETHSlasher')\""
echo "export STETH_VAULT_CONTRACT_ADDRESS=\"$(echo $VAULT_FILE | jq -r '.stETHVault')\""
echo "export WBTC_DELEGATOR_CONTRACT_ADDRESS=\"$(echo $VAULT_FILE | jq -r '.wBTCDelegator')\""
echo "export WBTC_SLASHER_CONTRACT_ADDRESS=\"$(echo $VAULT_FILE | jq -r '.wBTCSlasher')\""
echo "export WBTC_VAULT_CONTRACT_ADDRESS=\"$(echo $VAULT_FILE | jq -r '.wBTCVault')\""

echo -e "\n# Liveness deployment"
echo "export LIVENESS_SERVICE_MANAGER_CONTRACT_ADDRESS=\"$(echo $LIVENESS_SERVICE_MANAGER_FILE | jq -r '.livenessServiceManager')\""

echo -e "\n# Validation deployment"
echo "export VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS=\"$(echo $VALIDATION_MANAGER_FILE | jq -r '.validationServiceManager')\""