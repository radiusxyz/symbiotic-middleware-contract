#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/env.sh

result=$(cast call $NETWORK_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address who)(bool)" $NETWORK_ADDRESS)

if [[ "$result" == "false" ]]; then
    result=$(cast send $NETWORK_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY "registerNetwork()")

    echo "Completed registering the network"
else
    echo "The network is registered"
fi

###########################################################################################################

result=$(cast call $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"middleware(address networkAddress)(address middlewareAddress)" $NETWORK_ADDRESS)

if [[ "$result" == "false" ]]; then
    result=$(cast send $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY "setMiddleware(address middlewareAddress)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS)

    echo "Completed setting the middleware"
else
    echo "The middleware is already set"
fi