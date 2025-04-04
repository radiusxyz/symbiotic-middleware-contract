#!/bin/bash
set -e -o nounset

PROJECT_ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LATEST_STATE_PATH=$PROJECT_ROOT_PATH/latest-state

# pinning at old foundry commit because of https://github.com/foundry-rs/foundry/issues/7502
FOUNDRY_IMAGE=ghcr.io/foundry-rs/foundry:nightly-5b7e4cb3c882b28f3c32ba580de27ce7381f415a
#Basic Configurations
CHAIN_ID="31338"
IS_LOCAL_BLOCKCHAIN=true

CLUSTER_ID="radius_cluster"
ROLLUP_ID="radius_rollup"
MAX_SEQUENCER_NUMBER="30"
ROLLUP_TYPE="polygon_cdk"
ENCRYPTED_TRANSACTION_TYPE="skde"
LIVENESS_PLATFORM="ethereum"
LIVENESS_SERVICE_PROVIDER="radius"
ORDER_COMMITMENT_TYPE="sign"
EXECUTOR_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"

LIVENESS_RPC_URL="http://192.168.68.67:8545"
LIVENESS_WS_URL="ws://192.168.68.67:8545"
VALIDATION_RPC_URL="http://192.168.68.67:8545"
VALIDATION_WS_URL="ws://192.168.68.67:8545"

SYMBIOTIC_CORE_DEPLOYER_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
VAULT_OWNER_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
NETWORK_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
RADIUS_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

NETWORK_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
SYMBIOTIC_CORE_DEPLOYER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
VAULT_OWNER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
NETWORK_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
RADIUS_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

echo -e "\n# Environment Variables "
echo -e "# Chain State: $LATEST_STATE_PATH/$CHAIN_ID"

UTILS_FILE="$PROJECT_ROOT_PATH/script/utils/Utils.sol"
BACKUP_FILE="${UTILS_FILE}.bak"

if [[ -f "$UTILS_FILE" ]]; then
    cp "$UTILS_FILE" "$BACKUP_FILE"
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/address public network =.*/address public network = address($NETWORK_ADDRESS);/" "$UTILS_FILE"
    else
        sed -i "s/address public network =.*/address public network = address($NETWORK_ADDRESS);/" "$UTILS_FILE"
    fi
    rm -f "$BACKUP_FILE"  
    echo -e "\n# Updated network address in $UTILS_FILE"
else
    echo -e "\n# Warning: Utils.sol file not found at $UTILS_FILE"
fi
