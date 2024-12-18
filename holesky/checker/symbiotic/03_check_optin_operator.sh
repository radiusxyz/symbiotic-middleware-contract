#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

result=$(cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address who)(bool)" $OPERATOR_ADDRESS)

echo "Is registered operator? $result"

result=$(cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address who, address where)(bool)" $OPERATOR_ADDRESS $NETWORK_ADDRESS)

echo "Is opted in operator to network? $result"

result=$(cast call $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address who, address where)(bool)" $OPERATOR_ADDRESS $VAULT_CONTRACT_ADDRESS)

echo "Is opted in operator to vault? $result"