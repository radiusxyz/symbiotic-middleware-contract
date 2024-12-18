#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/env.sh

vaults=$(cast call "$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS" --rpc-url "$RPC_URL" \
    "getCurrentVaults()(address[])")

if echo "$vaults" | grep -q "$VAULT_CONTRACT_ADDRESS"; then
    echo "The vault is already registered"
else
    result=$(cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
    "registerToken(address tokenAddress)" $TOKEN_CONTRACT_ADDRESS)

    echo "Completed registering the token"

    cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
    "registerVault(address vaultAddress)" $VAULT_CONTRACT_ADDRESS

    echo "Completed registering the vault"
fi
