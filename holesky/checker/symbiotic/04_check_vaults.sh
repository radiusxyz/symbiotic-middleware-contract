#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

vaults=$(cast call "$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS" --rpc-url "$RPC_URL" \
    "getCurrentVaults()(address[])")

echo "Vaults: $vaults"