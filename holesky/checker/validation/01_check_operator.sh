#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

operators=$(cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getCurrentOperatorInfos()((address, address, (address, uint256)[], uint256)[])")

echo "Operators: $operators"