cast send $TOKEN_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $COLLATERAL_CONTRACT_ADDRESS 10000 

cast send $COLLATERAL_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $COLLATERAL_OWNER_PRIVATE_KEY \
"deposit(address recipient, uint256 amount)(uint256)" $TOKEN_CONTRACT_OWNER_ADDRESS 10000 

cast send $COLLATERAL_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $VAULT_CONTRACT_ADDRESS 10000

cast send $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"deposit(address onBehalfOf, uint256 amount)(uint256 depositedAmount, uint256 mintedShares)" $TOKEN_CONTRACT_OWNER_ADDRESS 10000

cast send $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $OPERATOR_PRIVATE_KEY \
"registerOperator()"

cast send $NETWORK_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerNetwork()"

cast send $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"setMiddleware(address middlewareAddress)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS

cast send $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $OPERATOR_PRIVATE_KEY \
"optIn(address network)" $NETWORK_ADDRESS

cast send $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $OPERATOR_PRIVATE_KEY \
"optIn(address vault)" $VAULT_CONTRACT_ADDRESS

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerToken(address tokenAddress)" $TOKEN_CONTRACT_ADDRESS

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerVault(address vaultAddress)" $VAULT_CONTRACT_ADDRESS

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerOperator(address operatorAddress, address operatingAddress)" $OPERATOR_ADDRESS $OPERATING_ADDRESS

cast send $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"setMaxNetworkLimit(uint96 identifier, uint256 amount)" 0 10000

cast send $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setNetworkLimit(bytes32 subnetwork, uint256 amount)" $SUBNETWORK 10000

cast send $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)" $SUBNETWORK $OPERATOR_ADDRESS 10000

cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"initializeCluster(string clusterId, uint256 maxSequencerNumber)" $CLUSTER_ID $MAX_SEQUENCER_NUMBER

cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"addRollup(string,(string,address,string,string,string,address,(string,string,address)))" \
"$CLUSTER_ID" "($ROLLUP_ID, $OWNER_ADDRESS, $ROLLUP_TYPE, $ENCRYPTED_TRANSACTION_TYPE, $ORDER_COMMITMENT_TYPE, $EXECUTOR_ADDRESS, ($PLATFORM, $SERVICE_PROVIDER, $VALIDATION_ADDRESS))"

cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerRollupExecutor(string clusterId, string rollupId, address executorAddress)" $CLUSTER_ID $ROLLUP_ID $EXECUTOR_ADDRESS

cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $OPERATING_PRIVATE_KEY \
"registerSequencer(string clusterId)" $CLUSTER_ID

cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"addRollup(string,(string,address,string,string,string,address,(string,string,address)))" \
"$CLUSTER_ID" "($ROLLUP_ID, $OWNER_ADDRESS, $ROLLUP_TYPE, $ENCRYPTED_TRANSACTION_TYPE, $ORDER_COMMITMENT_TYPE, $EXECUTOR_ADDRESS, ($PLATFORM, $SERVICE_PROVIDER, $VALIDATION_ADDRESS))"

cast send $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"deposit(address onBehalfOf, uint256 amount)(uint256 depositedAmount, uint256 mintedShares)" $TOKEN_CONTRACT_OWNER_ADDRESS 100

cast send $REWARDS_CORE_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"addRewardPoolConfig(string,string,address,uint256,uint256,uint256,uint256)" $CLUSTER_ID $ROLLUP_ID $TOKEN_CONTRACT_ADDRESS 10000000000000000000 10 70 30

cast send $TOKEN_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY "approve(address,uint256)" $REWARDS_CORE_ADDRESS 50000000000000000000

cast send $REWARDS_CORE_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"depositRewards(string,string,uint256)" $CLUSTER_ID $ROLLUP_ID 50000000000000000000
 