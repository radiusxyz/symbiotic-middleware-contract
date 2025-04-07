#!/bin/bash
set -e -o nounset

PROJECT_ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LATEST_STATE_PATH=$PROJECT_ROOT_PATH/latest-state

# pinning at old foundry commit because of https://github.com/foundry-rs/foundry/issues/7502
FOUNDRY_IMAGE=ghcr.io/foundry-rs/foundry:nightly-5b7e4cb3c882b28f3c32ba580de27ce7381f415a

IS_LOCAL_BLOCKCHAIN=true
CHAIN_ID=31337
RPC_URL="http://127.0.0.1:8545"


echo -e "\n# Environment Variables "
echo -e "# Chain State: $LATEST_STATE_PATH/$CHAIN_ID"
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
NETWORK_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

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


#Basic Configurations
ROLLUP_ID="asdf"
CLUSTER_ID="radius"

MAX_SEQUENCER_NUMBER="30"
ROLLUP_TYPE="polygon_cdk"
ENCRYPTED_TRANSACTION_TYPE="skde"

PLATFORM="ethereum"
SERVICE_PROVIDER="radius"

ORDER_COMMITMENT_TYPE="sign"


