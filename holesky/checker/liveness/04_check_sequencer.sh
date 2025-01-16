#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

sequencers=$(cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getSequencerList(string clusterId)(address[] memory)" $CLUSTER_ID)

echo "Cluster sequencers: $sequencers"