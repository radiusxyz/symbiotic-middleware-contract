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
SYMBIOTIC_CORE=$(extract_json_addresses "$STATE_DIR/symbiotic_core_deployment_output.json")
VALIDATION_MANAGER=$(extract_json_addresses "$STATE_DIR/validation_service_manager_deployment_output.json")
VAULT=$(extract_json_addresses "$STATE_DIR/vault_deployment_output.json")
COLLATERAL=$(extract_json_addresses "$STATE_DIR/collateral_deployment_output.json")
LIVENESS_SERVICE_MANAGER=$(extract_json_addresses "$STATE_DIR/liveness_service_manager_deployment_output.json")
REWARDS_CORE=$(extract_json_addresses "$STATE_DIR/rewards_core_deployment_output.json")
OPERATOR_REWARDS=$(extract_json_addresses "$STATE_DIR/operator_reward_deployment_output.json")
STAKER_REWARDS=$(extract_json_addresses "$STATE_DIR/staker_reward_deployment_output.json")

SUBNETWORK="${NETWORK_ADDRESS}000000000000000000000000"

# Base Configurations
echo -e "\n# Base Configurations"
echo "export CHAIN_ID=\"$CHAIN_ID\""

echo "export LIVENESS_RPC_URL=\"$LIVENESS_RPC_URL\""
echo "export LIVENESS_WS_URL=\"$LIVENESS_WS_URL\""

echo "export VALIDATION_RPC_URL=\"$VALIDATION_RPC_URL\""
echo "export VALIDATION_WS_URL=\"$VALIDATION_WS_URL\""

echo "export SYMBIOTIC_CORE_CONTRACT_OWNER_PRIVATE_KEY=\"$SYMBIOTIC_CORE_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export SYMBIOTIC_CORE_CONTRACT_OWNER_ADDRESS=\"$SYMBIOTIC_CORE_CONTRACT_OWNER_ADDRESS\""
echo ""

echo "export TOKEN_CONTRACT_OWNER_PRIVATE_KEY=\"$TOKEN_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export TOKEN_CONTRACT_OWNER_ADDRESS=\"$TOKEN_CONTRACT_OWNER_ADDRESS\""
echo ""

echo "export BURNER_CONTRACT_OWNER_PRIVATE_KEY=\"$BURNER_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export BURNER_CONTRACT_OWNER_ADDRESS=\"$BURNER_CONTRACT_OWNER_ADDRESS\""
echo ""

echo "export VAULT_CONTRACT_OWNER_PRIVATE_KEY=\"$VAULT_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export VAULT_CONTRACT_OWNER_ADDRESS=\"$VAULT_CONTRACT_OWNER_ADDRESS\""
echo ""

echo "export OPERATOR_REWARD_CONTRACT_OWNER_PRIVATE_KEY=\"$OPERATOR_REWARD_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export OPERATOR_REWARD_CONTRACT_OWNER_ADDRESS=\"$OPERATOR_REWARD_CONTRACT_OWNER_ADDRESS\""
echo ""

echo "export STAKER_REWARD_CONTRACT_OWNER_PRIVATE_KEY=\"$STAKER_REWARD_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export STAKER_REWARD_CONTRACT_OWNER_ADDRESS=\"$STAKER_REWARD_CONTRACT_OWNER_ADDRESS\""
echo ""

echo "export LIVENESS_SERVICE_MANAGER_CONTRACT_OWNER_PRIVATE_KEY=\"$LIVENESS_SERVICE_MANAGER_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export LIVENESS_SERVICE_MANAGER_CONTRACT_OWNER_ADDRESS=\"$LIVENESS_SERVICE_MANAGER_CONTRACT_OWNER_ADDRESS\""
echo ""

echo "export REWARD_CORE_CONTRACT_OWNER_PRIVATE_KEY=\"$REWARD_CORE_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export REWARD_CORE_CONTRACT_OWNER_ADDRESS=\"$REWARD_CORE_CONTRACT_OWNER_ADDRESS\""
echo ""

echo "export NETWORK_PRIVATE_KEY=\"$NETWORK_PRIVATE_KEY\""
echo "export NETWORK_ADDRESS=\"$NETWORK_ADDRESS\""
echo "export SUBNETWORK=\"$SUBNETWORK\""
echo ""

echo -e "# Symbiotic core"
echo "export NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE | jq -r '.networkMiddlewareService')\""
echo "export OPERATOR_REGISTRY_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE | jq -r '.operatorRegistry')\""
echo "export NETWORK_REGISTRY_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE | jq -r '.networkRegistry')\""
echo "export OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE | jq -r '.operatorNetworkOptInService')\""
echo "export OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE | jq -r '.operatorVaultOptInService')\""
echo "export VAULT_FACTORY_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE | jq -r '.vaultFactory')\""

# Vault Configuration for all tokens
echo -e "# Configurations"
echo "export DEFAULT_VAULT_CONTRACT_OWNER_PRIVATE_KEY=\"$VAULT_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export DEFAULT_VAULT_CONTRACT_OWNER_ADDRESS=\"$VAULT_CONTRACT_OWNER_ADDRESS\""
echo "export DEFAULT_TOKEN_CONTRACT_OWNER_PRIVATE_KEY=\"$TOKEN_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export DEFAULT_TOKEN_CONTRACT_OWNER_ADDRESS=\"$TOKEN_CONTRACT_OWNER_ADDRESS\""
echo "export DEFAULT_TOKEN_CONTRACT_ADDRESS=\"$(echo $COLLATERAL | jq -r '.radiusTestERC20')\""
echo "export DEFAULT_COLLATERAL_CONTRACT_ADDRESS=\"$(echo $COLLATERAL | jq -r '.defaultCollateral')\""
echo "export DEFAULT_DELEGATOR_CONTRACT_ADDRESS=\"$(echo $VAULT | jq -r '.defaultDelegator')\""
echo "export DEFAULT_SLASHER_CONTRACT_ADDRESS=\"$(echo $VAULT | jq -r '.defaultSlasher')\""
echo "export DEFAULT_VAULT_CONTRACT_ADDRESS=\"$(echo $VAULT | jq -r '.defaultVault')\""
echo "export DEFAULT_OPERATOR_REWARD_CONTRACT_ADDRESS=\"$(echo $OPERATOR_REWARDS | jq -r '.defaultOperatorReward')\""
echo "export DEFAULT_STAKER_REWARD_CONTRACT_ADDRESS=\"$(echo $STAKER_REWARDS | jq -r '.defaultStakerReward')\""
echo ""

echo "export WBTC_VAULT_CONTRACT_OWNER_PRIVATE_KEY=\"$VAULT_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export WBTC_VAULT_CONTRACT_OWNER_ADDRESS=\"$VAULT_CONTRACT_OWNER_ADDRESS\""
echo "export WBTC_TOKEN_CONTRACT_OWNER_PRIVATE_KEY=\"$TOKEN_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export WBTC_TOKEN_CONTRACT_OWNER_ADDRESS=\"$TOKEN_CONTRACT_OWNER_ADDRESS\""
echo "export WBTC_TOKEN_CONTRACT_ADDRESS=\"$(echo $COLLATERAL | jq -r '.wBTCTestERC20')\""
echo "export WBTC_COLLATERAL_CONTRACT_ADDRESS=\"$(echo $COLLATERAL | jq -r '.wBTCCollateral')\""
echo "export WBTC_DELEGATOR_CONTRACT_ADDRESS=\"$(echo $VAULT | jq -r '.wBTCDelegator')\""
echo "export WBTC_SLASHER_CONTRACT_ADDRESS=\"$(echo $VAULT | jq -r '.wBTCSlasher')\""
echo "export WBTC_VAULT_CONTRACT_ADDRESS=\"$(echo $VAULT | jq -r '.wBTCVault')\""
echo "export WBTC_OPERATOR_REWARD_CONTRACT_ADDRESS=\"$(echo $OPERATOR_REWARDS | jq -r '.wBTCOperatorReward')\""
echo "export WBTC_STAKER_REWARD_CONTRACT_ADDRESS=\"$(echo $STAKER_REWARDS | jq -r '.wBTCStakerReward')\""
echo ""

echo "export STETH_VAULT_CONTRACT_OWNER_PRIVATE_KEY=\"$VAULT_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export STETH_VAULT_CONTRACT_OWNER_ADDRESS=\"$VAULT_CONTRACT_OWNER_ADDRESS\""
echo "export STETH_TOKEN_CONTRACT_OWNER_PRIVATE_KEY=\"$TOKEN_CONTRACT_OWNER_PRIVATE_KEY\""
echo "export STETH_TOKEN_CONTRACT_OWNER_ADDRESS=\"$TOKEN_CONTRACT_OWNER_ADDRESS\""
echo "export STETH_TOKEN_CONTRACT_ADDRESS=\"$(echo $COLLATERAL | jq -r '.stETHTestERC20')\""
echo "export STETH_COLLATERAL_CONTRACT_ADDRESS=\"$(echo $COLLATERAL | jq -r '.stETHCollateral')\""
echo "export STETH_DELEGATOR_CONTRACT_ADDRESS=\"$(echo $VAULT | jq -r '.stETHDelegator')\""
echo "export STETH_SLASHER_CONTRACT_ADDRESS=\"$(echo $VAULT | jq -r '.stETHSlasher')\""
echo "export STETH_VAULT_CONTRACT_ADDRESS=\"$(echo $VAULT | jq -r '.stETHVault')\""
echo "export STETH_OPERATOR_REWARD_CONTRACT_ADDRESS=\"$(echo $OPERATOR_REWARDS | jq -r '.stETHOperatorReward')\""
echo "export STETH_STAKER_REWARD_CONTRACT_ADDRESS=\"$(echo $STAKER_REWARDS | jq -r '.stETHStakerReward')\""
echo ""

echo -e "# Liveness"
echo "export LIVENESS_SERVICE_MANAGER_CONTRACT_ADDRESS=\"$(echo $LIVENESS_SERVICE_MANAGER | jq -r '.livenessServiceManager')\""
echo ""

echo -e "# Validation Service Manager"
echo "export VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS=\"$(echo $VALIDATION_MANAGER | jq -r '.validationServiceManager')\""