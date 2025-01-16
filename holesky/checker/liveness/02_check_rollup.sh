#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

rollupInfo=$(cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getRollupInfo(string clusterId, string rollupId)((string,address,string,string,string,address[],(string,string,address)))" $CLUSTER_ID $ROLLUP_ID)

echo "Rollup: $rollupInfo"