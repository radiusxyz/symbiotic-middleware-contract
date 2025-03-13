#!/bin/bash
PROJECT_ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
LATEST_STATE_PATH="$PROJECT_ROOT_PATH/latest-state"

source $SCRIPT_PATH/../env.sh


STATE_DIR="$LATEST_STATE_PATH/32382"


LATEST_STATE_PATH=$PROJECT_ROOT_PATH/latest-state

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


# Base Configurations
echo -e "\n# Base Configurations"
echo "export ROLLUP_ID=\"$ROLLUP_ID\""
echo "export CLUSTER_ID=\"$CLUSTER_ID\""
echo "export RPC_URL=\"$RPC_URL\""
echo "export PRIVATE_KEY=\"$PRIVATE_KEY\""
echo "export NETWORK_PRIVATE_KEY=\"$PRIVATE_KEY\""
echo "export NETWORK_ADDRESS=\"$NETWORK_ADDRESS\""
echo "export CHAIN_ID=\"$CHAIN_ID\""

OWNER_ADDRESS=$NETWORK_ADDRESS
echo "export OWNER_ADDRESS=\"$OWNER_ADDRESS\""

SUBNETWORK="${NETWORK_ADDRESS}000000000000000000000000"
echo "export SUBNETWORK=\"$SUBNETWORK\""

echo "export MAX_SEQUENCER_NUMBER=\"$MAX_SEQUENCER_NUMBER\""
echo "export ROLLUP_TYPE=\"$ROLLUP_TYPE\""
echo "export ENCRYPTED_TRANSACTION_TYPE=\"$ENCRYPTED_TRANSACTION_TYPE\""
echo "export PLATFORM=\"$PLATFORM\""
echo "export SERVICE_PROVIDER=\"$SERVICE_PROVIDER\""
echo "export ORDER_COMMITMENT_TYPE=\"$ORDER_COMMITMENT_TYPE\""

# Defult Operators Accounts
echo -e "\n# Operator Accounts"
echo "export DEFAULT_OPERATOR_ADDRESS=\"0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266\""
echo "export DEFAULT_OPERATOR_PRIVATE_KEY=\"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80\""
echo "export WBTC_OPERATOR_ADDRESS=\"0x70997970C51812dc3A010C7d01b50e0d17dc79C8\""
echo "export WBTC_OPERATOR_PRIVATE_KEY=\"0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d\""
echo "export STETH_OPERATOR_ADDRESS=\"0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC\""
echo "export STETH_OPERATOR_PRIVATE_KEY=\"0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a\""

echo -e "\n# Symbiotic (Local)"
echo "export NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE | jq -r '.networkMiddlewareService')\""
echo "export OPERATOR_REGISTRY_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE | jq -r '.operatorRegistry')\""
echo "export NETWORK_REGISTRY_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE | jq -r '.networkRegistry')\""
echo "export OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE | jq -r '.operatorNetworkOptInService')\""
echo "export OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE | jq -r '.operatorVaultOptInService')\""
echo "export VAULT_FACTORY_CONTRACT_ADDRESS=\"$(echo $SYMBIOTIC_CORE | jq -r '.vaultFactory')\""



echo -e '\n# Token & Vault Contract Owner'
echo "export TOKEN_CONTRACT_OWNER_ADDRESS=\"$NETWORK_ADDRESS\""
echo "export TOKEN_CONTRACT_OWNER_PRIVATE_KEY=\"$PRIVATE_KEY\""
echo "export VAULT_OWNER_ADDRESS=\"$NETWORK_ADDRESS\""
echo "export VAULT_OWNER_PRIVATE_KEY=\"$PRIVATE_KEY\""

echo -e "\n# Token Accounts"
echo "export DEFAULT_ACCOUNT_ADDRESS=\"0xa0Ee7A142d267C1f36714E4a8F75612F20a79720\""
echo "export DEFAULT_ACCOUNT_PRIVATE_KEY=\"0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6\""
echo "export WBTC_ACCOUNT_ADDRESS=\"0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f\""
echo "export WBTC_ACCOUNT_PRIVATE_KEY=\"0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97\""
echo "export STETH_ACCOUNT_ADDRESS=\"0x14dC79964da2C08b23698B3D3cc7Ca32193d9955\""
echo "export STETH_ACCOUNT_PRIVATE_KEY=\"0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356\""


# Vault Configuration for all tokens
echo -e "\n# Vault Configurations"
echo "export DEFAULT_VAULT_ADDRESS=\"$(echo $VAULT | jq -r '.defaultVault')\""
echo "export DEFAULT_DELEGATOR_ADDRESS=\"$(echo $VAULT | jq -r '.defaultDelegator')\""
echo "export WBTC_VAULT_ADDRESS=\"$(echo $VAULT | jq -r '.wBTCVault')\""
echo "export WBTC_DELEGATOR_ADDRESS=\"$(echo $VAULT | jq -r '.wBTCDelegator')\""
echo "export STETH_VAULT_ADDRESS=\"$(echo $VAULT | jq -r '.stETHVault')\""
echo "export STETH_DELEGATOR_ADDRESS=\"$(echo $VAULT | jq -r '.stETHDelegator')\""

echo -e "\n# Liveness"
echo "export LIVENESS_CONTRACT_ADDRESS=\"$(echo $LIVENESS_SERVICE_MANAGER | jq -r '.livenessServiceManager')\""

echo -e "\n# Validation Service Manager"
echo "export VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS=\"$(echo $VALIDATION_MANAGER | jq -r '.validationServiceManager')\""

# Collateral Configuration for all tokens
echo -e "\n# Collateral Configurations"
echo "export DEFAULT_TOKEN_ADDRESS=\"$(echo $COLLATERAL | jq -r '.radiusTestERC20')\""
echo "export DEFAULT_COLLATERAL_ADDRESS=\"$(echo $COLLATERAL | jq -r '.defaultCollateral')\""
echo "export WBTC_TOKEN_ADDRESS=\"$(echo $COLLATERAL | jq -r '.wBTCTestERC20')\""
echo "export WBTC_COLLATERAL_ADDRESS=\"$(echo $COLLATERAL | jq -r '.wBTCCollateral')\""
echo "export STETH_TOKEN_ADDRESS=\"$(echo $COLLATERAL | jq -r '.stETHTestERC20')\""
echo "export STETH_COLLATERAL_ADDRESS=\"$(echo $COLLATERAL | jq -r '.stETHCollateral')\""

echo -e "\n# Rewards Core"
echo "export REWARDS_CORE_ADDRESS=\"$(echo $REWARDS_CORE | jq -r '.rewardsCore')\""

echo -e "\n# Default Operator Rewards"
echo "export DEFAULT_OPERATOR_REWARDS=\"$(echo $OPERATOR_REWARDS | jq -r '.defaultOperatorReward')\""
echo "export STETH_OPERATOR_REWARDS=\"$(echo $OPERATOR_REWARDS | jq -r '.stETHOperatorReward')\""
echo "export WBTC_OPERATOR_REWARDS=\"$(echo $OPERATOR_REWARDS | jq -r '.wBTCOperatorReward')\""

echo -e "\n# Default Staker Rewards"
echo "export DEFAULT_STAKER_REWARDS=\"$(echo $STAKER_REWARDS | jq -r '.defaultStakerReward')\""
echo "export STETH_STAKER_REWARDS=\"$(echo $STAKER_REWARDS | jq -r '.stETHStakerReward')\""
echo "export WBTC_STAKER_REWARDS=\"$(echo $STAKER_REWARDS | jq -r '.wBTCStakerReward')\""