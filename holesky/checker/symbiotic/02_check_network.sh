#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

result=$(cast call $NETWORK_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address who)(bool)" $NETWORK_ADDRESS)

echo "Is registered network? $result"

result=$(cast call $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"middleware(address networkAddress)(address middlewareAddress)" $NETWORK_ADDRESS)

echo "Is set middleware? $result"