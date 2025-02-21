
TASK_COUNT="$1"


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  $TASK_COUNT \
  true \
--rpc-url $RPC_URL \
--private-key $DEFAULT_OPERATOR_PRIVATE_KEY

sleep 0.1


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  $TASK_COUNT \
  true \
--rpc-url $RPC_URL \
--private-key $WBTC_OPERATOR_PRIVATE_KEY

sleep 0.1



cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  $TASK_COUNT \
  true \
--rpc-url $RPC_URL \
--private-key $STETH_OPERATOR_PRIVATE_KEY

sleep 0.1



# cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
#   $CLUSTER_ID \
#   $ROLLUP_ID \
#   $TASK_COUNT \
#   true \
# --rpc-url $RPC_URL \
# --private-key $DEFAULT_OPERATOR_PRIVATE_KEY_SECONDARY


sleep 0.1

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  $TASK_COUNT \
  true \
--rpc-url $RPC_URL \
--private-key $WBTC_OPERATOR_PRIVATE_KEY_SECONDARY


sleep 0.1

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  $TASK_COUNT \
  true \
--rpc-url $RPC_URL \
--private-key $STETH_OPERATOR_PRIVATE_KEY_SECONDARY

sleep 0.1


 