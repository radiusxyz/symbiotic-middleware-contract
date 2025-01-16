#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

clusters=$(cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getClustersByOwner(address owner)(string[])" $NETWORK_ADDRESS)

echo "Clusters: $clusters"