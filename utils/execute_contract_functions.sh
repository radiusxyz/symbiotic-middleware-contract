#!/bin/bash

# # STETH Token Setup
cast send $STETH_TOKEN_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"transfer(address,uint256)" $STETH_ACCOUNT_ADDRESS 50000

cast call $STETH_TOKEN_ADDRESS --rpc-url $LIVENESS_RPC_URL \
"balanceOf(address)(uint256)" $STETH_ACCOUNT_ADDRESS

cast send $STETH_TOKEN_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $STETH_ACCOUNT_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $STETH_COLLATERAL_ADDRESS 50000 

cast call $STETH_TOKEN_ADDRESS --rpc-url $LIVENESS_RPC_URL \
"allowance(address,address)(uint256)" $STETH_ACCOUNT_ADDRESS $STETH_COLLATERAL_ADDRESS

cast send $STETH_COLLATERAL_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $STETH_ACCOUNT_PRIVATE_KEY \
"deposit(address recipient, uint256 amount)(uint256)" $STETH_ACCOUNT_ADDRESS 50000 

cast call $STETH_TOKEN_ADDRESS --rpc-url $LIVENESS_RPC_URL \
"balanceOf(address)(uint256)" $STETH_ACCOUNT_ADDRESS



cast send $STETH_COLLATERAL_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $STETH_ACCOUNT_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $STETH_VAULT_ADDRESS 50000

cast send $STETH_VAULT_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $STETH_ACCOUNT_PRIVATE_KEY \
"deposit(address onBehalfOf, uint256 amount)(uint256 depositedAmount, uint256 mintedShares)" $STETH_ACCOUNT_ADDRESS 50000

cast call $STETH_VAULT_ADDRESS --rpc-url $LIVENESS_RPC_URL \
"activeSharesOf(address)(uint256)" $STETH_ACCOUNT_ADDRESS



# Register Network
cast send $NETWORK_REGISTRY_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerNetwork()"

# Verify network registration
cast call $NETWORK_REGISTRY_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL \
"isEntity(address)(bool)" $NETWORK_ADDRESS

# Set Middleware
cast send $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"setMiddleware(address middlewareAddress)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS

# Verify middleware setting
cast call $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL \
"middleware(address)(address)" $NETWORK_ADDRESS



#####################################################################################################################################
# Register Tokens with Validation Service Manager
cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerToken(address token)" $STETH_TOKEN_ADDRESS --gas-limit 200000

# Verify token registration
cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL \
"isActiveToken(address)(bool)" $STETH_TOKEN_ADDRESS

cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL "getCurrentTokens()(address[])"

#####################################################################################################################################
# Register vault
cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerVault(address vault, address stakerRewards, address operatorRewards)" $STETH_VAULT_ADDRESS $STETH_STAKER_REWARDS $STETH_OPERATOR_REWARDS

cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL \
  "isActiveVault(address vault)(bool)" \
  $STETH_VAULT_ADDRESS
#####################################################################################################################################

# Register Operators with Validation Service Manager
# cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL "NETWORK()(address)"

# cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $NETWORK_PRIVATE_KEY \
# "registerOperator(address operatorAddress, address operatingAddress)" $DEFAULT_OPERATOR_ADDRESS $DEFAULT_OPERATOR_ADDRESS

# cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $NETWORK_PRIVATE_KEY \
# "registerOperator(address operatorAddress, address operatingAddress)" $OPERATOR_ADDRESS_2 $TX_ORDERER_ADDRESS_2

# cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL \
#   "getCurrentOperatorInfos()((address, address, (address, uint256)[])[])"
#####################################################################################################################################


#####################################################################################################################################

# # STETH Delegator
cast send $STETH_DELEGATOR_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"setMaxNetworkLimit(uint96 identifier, uint256 amount)" 0 10000

cast send $STETH_DELEGATOR_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setNetworkLimit(bytes32 subnetwork, uint256 amount)" $SUBNETWORK 10000

# STETH Delegator - Primary Operator (70%)
cast send $STETH_DELEGATOR_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)" $SUBNETWORK $STETH_OPERATOR_ADDRESS 10000

# # STETH Delegator - Secondary Operator (30%)
# cast send $STETH_DELEGATOR_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
# "setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)" $SUBNETWORK $OPERATOR_ADDRESS_2 3000

cast call $STETH_DELEGATOR_ADDRESS --rpc-url $LIVENESS_RPC_URL \
  "stake(bytes32 subnetwork, address operator)(uint256)" $SUBNETWORK $STETH_OPERATOR_ADDRESS
  
# cast call $STETH_DELEGATOR_ADDRESS --rpc-url $LIVENESS_RPC_URL \
#   "stake(bytes32 subnetwork, address operator)(uint256)" $SUBNETWORK $OPERATOR_ADDRESS_2
#####################################################################################################################################


#####################################################################################################################################
# # Initialize Cluster
cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"initializeCluster(string clusterId, uint256 maxSequencerNumber)" $CLUSTER_ID $MAX_SEQUENCER_NUMBER

cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL \
  "getAllClusterIds()(string[])"

# # Add Rollup
cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"addRollup(string,(string,address,string,string,string,address,(string,string,address)))" \
"$CLUSTER_ID" "($ROLLUP_ID, $OWNER_ADDRESS, $ROLLUP_TYPE, $ENCRYPTED_TRANSACTION_TYPE, $ORDER_COMMITMENT_TYPE, $EXECUTOR_ADDRESS, ($LIVENESS_PLATFORM, $LIVENESS_SERVICE_PROVIDER, $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS))"

cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $LIVENESS_RPC_URL \
  "getRollup(string clusterId, string rollupId)((string,address,string,string,string,address[],(string,string,address)))" \
  $CLUSTER_ID $ROLLUP_ID
#####################################################################################################################################

#####################################################################################################################################
