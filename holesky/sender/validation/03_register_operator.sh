#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

operators=$(cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getCurrentOperatorInfos()((address, address, (address, uint256)[], uint256)[])")

if echo "$operators" | grep -q "$OPERATOR_ADDRESS"; then
    echo "The operator is already registered"
else
    operators=$(cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
    "registerOperator(address operatorAddress, address operatingAddress)" $OPERATOR_ADDRESS $OPERATING_ADDRESS)

    echo "Completed registering the operator"
fi
