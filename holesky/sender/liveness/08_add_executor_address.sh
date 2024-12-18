#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/env.sh

result=$(cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isRegisteredRollupExecutor(string clusterId, string rollupId, address executorAddress)(bool)" $CLUSTER_ID $ROLLUP_ID $EXECUTOR_ADDRESS)

if [[ "$result" == "false" ]]; then
    cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
    "registerRollupExecutor(string clusterId, string rollupId, address executorAddress)" $CLUSTER_ID $ROLLUP_ID $EXECUTOR_ADDRESS

    echo "Completed registering the executor"

    cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
    "getExecutorList(string clusterId, string rollupId)(address[])" $CLUSTER_ID $ROLLUP_ID
else
    echo "The executor is registered"
fi

