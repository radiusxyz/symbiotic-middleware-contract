#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

sequencers=$(cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getSequencerList(string clusterId)(address[] memory)" $CLUSTER_ID)

if [[ "$result" == "false" ]]; then
    cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $OPERATING_PRIVATE_KEY \
    "registerSequencer(string clusterId)" $CLUSTER_ID

    echo "Completed registering the executor"
else
    echo "The executor is registered"
fi

