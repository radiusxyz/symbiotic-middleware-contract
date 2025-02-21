cast send $DEFAULT_OPERATOR_REWARDS "claimRewards(address,address,address,uint256,bytes32[])" \
$OPERATOR_ADDRESS \
$NETWORK_ADDRESS \
$TOKEN_CONTRACT_ADDRESS \
3500000000000000000 \
"[0x0e327d660c99c279e6c71b8c847ad2c59da79b0f5a59fc2fc5269dae9ca6ad4c]" \
--rpc-url $RPC_URL \
--private-key $OPERATING_PRIVATE_KEY



cast send $DEFAULT_OPERATOR_REWARDS "claimRewards(address,address,address,uint256,bytes32[])" \
$SECONDARY_ADDRESS \
$NETWORK_ADDRESS \
$TOKEN_CONTRACT_ADDRESS \
7000000000000000000 \
"[0x294743eb18f560580479dff2192313fa4add412caf5e62ca358e6fa81b853746]" \
--rpc-url $RPC_URL \
--private-key $SECONDARY_PRIVATE_KEY


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
$CLUSTER_ID \
$ROLLUP_ID \
1 \
true \
--rpc-url $RPC_URL \
--private-key $OPERATOR_PRIVATE_KEY


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
$CLUSTER_ID \
$ROLLUP_ID \
1 \
true \
--rpc-url $RPC_URL \
--private-key $SECONDARY_PRIVATE_KEY



 cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "createNewTask(string,string,uint256,bytes32,bytes32)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  1234 \
  0x287b58b93ed6c17ace087bb87f611bf21102c0602b0956736b6e523fb41c328d \
  0x20cee38045bd1a09f831645acf68e979d1d27b83584bc81b6bd6f0b71c6676ec \
--rpc-url $RPC_URL \
--private-key $OPERATOR_PRIVATE_KEY


















cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $DEFAULT_STAKER_REWARDS
cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $REWARDS_MANAGER_ADDRESS
cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $NETWORK_ADDRESS
cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $DEFAULT_OPERATOR_REWARDS
cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $SECONDARY_ADDRESS
