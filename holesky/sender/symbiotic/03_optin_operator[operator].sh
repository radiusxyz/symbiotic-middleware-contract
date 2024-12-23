#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

result=$(cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address who)(bool)" $OPERATOR_ADDRESS)

if [[ "$result" == "false" ]]; then
    result=$(cast send $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $OPERATOR_PRIVATE_KEY \
    "registerOperator()")

    echo "Completed registering the operator"
else
    echo "The operator is already registered"
fi

###########################################################################################################

result=$(cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address who, address where)(bool)" $OPERATOR_ADDRESS $NETWORK_ADDRESS)

if [[ "$result" == "false" ]]; then
    result=$(cast send $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $OPERATOR_PRIVATE_KEY \
    "optIn(address network)" $NETWORK_ADDRESS)

    echo "Completed optin the operator to the network"
else
    echo "The operator is already optined to the network"
fi

###########################################################################################################

result=$(cast call $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address who, address where)(bool)" $OPERATOR_ADDRESS $VAULT_CONTRACT_ADDRESS)

if [[ "$result" == "false" ]]; then
    result=$(cast send $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $OPERATOR_PRIVATE_KEY \
    "optIn(address vault)" $VAULT_CONTRACT_ADDRESS)

    echo "Completed optin the operator to the vault"
else
    echo "The operator is already optined to the vault"
fi