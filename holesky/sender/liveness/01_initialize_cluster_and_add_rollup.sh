#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

clusters=$(cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getClustersByOwner(address owner)(string[])" $NETWORK_ADDRESS)

if echo "$clusters" | grep -q "$CLUSTER_ID"; then
    echo "Cluster already exists"
else
    result=$(cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
    "initializeCluster(string clusterId, uint256 maxSequencerNumber)" $CLUSTER_ID $MAX_SEQUENCER_NUMBER)

    echo "Completed initializing the cluster"
fi 

rollupInfo=$(cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getRollupInfo(string clusterId, string rollupId)((string,address,string,string,string,address[],(string,string,address)))" $CLUSTER_ID $ROLLUP_ID)

if echo "$rollupInfo" | grep -q "$ROLLUP_ID"; then
    echo "Rollup already exists"
else
    result=$(cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
    "addRollup(string,(string,address,string,string,string,address,(string,string,address)))" \
    "$CLUSTER_ID" "($ROLLUP_ID, $OWNER_ADDRESS, $ROLLUP_TYPE, $ENCRYPTED_TRANSACTION_TYPE, $ORDER_COMMITMENT_TYPE, $EXECUTOR_ADDRESS, ($PLATFORM, $SERVICE_PROVIDER, $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS))")

    echo "Completed adding the rollup"
fi 




