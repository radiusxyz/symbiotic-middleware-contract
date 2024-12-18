#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

executorList=$(cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
    "getExecutorList(string clusterId, string rollupId)(address[])" $CLUSTER_ID $ROLLUP_ID)

echo "Rollup executors: $executorList"