#!/bin/bash

# # Default Token Setup
cast send $DEFAULT_TOKEN_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"transfer(address,uint256)" $DEFAULT_ACCOUNT_ADDRESS 10000

cast call $DEFAULT_TOKEN_ADDRESS --rpc-url $RPC_URL \
"balanceOf(address)(uint256)" $DEFAULT_ACCOUNT_ADDRESS

cast send $DEFAULT_TOKEN_ADDRESS --rpc-url $RPC_URL --private-key $DEFAULT_ACCOUNT_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $DEFAULT_COLLATERAL_ADDRESS 10000 

cast call $DEFAULT_TOKEN_ADDRESS --rpc-url $RPC_URL \
"allowance(address,address)(uint256)" $DEFAULT_ACCOUNT_ADDRESS $DEFAULT_COLLATERAL_ADDRESS

cast send $DEFAULT_COLLATERAL_ADDRESS --rpc-url $RPC_URL --private-key $DEFAULT_ACCOUNT_PRIVATE_KEY \
"deposit(address recipient, uint256 amount)(uint256)" $DEFAULT_ACCOUNT_ADDRESS 10000

cast call $DEFAULT_COLLATERAL_ADDRESS --rpc-url $RPC_URL \
"balanceOf(address)(uint256)" $DEFAULT_ACCOUNT_ADDRESS

cast send $DEFAULT_COLLATERAL_ADDRESS --rpc-url $RPC_URL --private-key $DEFAULT_ACCOUNT_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $DEFAULT_VAULT_ADDRESS 10000

cast send $DEFAULT_VAULT_ADDRESS --rpc-url $RPC_URL --private-key $DEFAULT_ACCOUNT_PRIVATE_KEY \
"deposit(address onBehalfOf, uint256 amount)(uint256 depositedAmount, uint256 mintedShares)" $DEFAULT_ACCOUNT_ADDRESS 10000

cast call $DEFAULT_VAULT_ADDRESS --rpc-url $RPC_URL \
"activeSharesOf(address)(uint256)" $DEFAULT_ACCOUNT_ADDRESS






# # WBTC Token Setup
cast send $WBTC_TOKEN_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"transfer(address,uint256)" $WBTC_ACCOUNT_ADDRESS 200

cast call $WBTC_TOKEN_ADDRESS --rpc-url $RPC_URL \
"balanceOf(address)(uint256)" $WBTC_ACCOUNT_ADDRESS

cast send $WBTC_TOKEN_ADDRESS --rpc-url $RPC_URL --private-key $WBTC_ACCOUNT_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $WBTC_COLLATERAL_ADDRESS 200 

cast call $WBTC_TOKEN_ADDRESS --rpc-url $RPC_URL \
"allowance(address,address)(uint256)" $WBTC_ACCOUNT_ADDRESS $WBTC_COLLATERAL_ADDRESS

cast send $WBTC_COLLATERAL_ADDRESS --rpc-url $RPC_URL --private-key $WBTC_ACCOUNT_PRIVATE_KEY \
"deposit(address recipient, uint256 amount)(uint256)" $WBTC_ACCOUNT_ADDRESS 200 

cast call $WBTC_TOKEN_ADDRESS --rpc-url $RPC_URL \
"balanceOf(address)(uint256)" $WBTC_ACCOUNT_ADDRESS

cast send $WBTC_COLLATERAL_ADDRESS --rpc-url $RPC_URL --private-key $WBTC_ACCOUNT_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $WBTC_VAULT_ADDRESS 200

cast send $WBTC_VAULT_ADDRESS --rpc-url $RPC_URL --private-key $WBTC_ACCOUNT_PRIVATE_KEY \
"deposit(address onBehalfOf, uint256 amount)(uint256 depositedAmount, uint256 mintedShares)" $WBTC_ACCOUNT_ADDRESS 200

cast call $WBTC_VAULT_ADDRESS --rpc-url $RPC_URL \
"activeSharesOf(address)(uint256)" $WBTC_ACCOUNT_ADDRESS



# # STETH Token Setup
cast send $STETH_TOKEN_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"transfer(address,uint256)" $STETH_ACCOUNT_ADDRESS 18000

cast call $STETH_TOKEN_ADDRESS --rpc-url $RPC_URL \
"balanceOf(address)(uint256)" $STETH_ACCOUNT_ADDRESS


cast send $STETH_TOKEN_ADDRESS --rpc-url $RPC_URL --private-key $STETH_ACCOUNT_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $STETH_COLLATERAL_ADDRESS 18000 

cast call $STETH_TOKEN_ADDRESS --rpc-url $RPC_URL \
"allowance(address,address)(uint256)" $STETH_ACCOUNT_ADDRESS $STETH_COLLATERAL_ADDRESS

cast send $STETH_COLLATERAL_ADDRESS --rpc-url $RPC_URL --private-key $STETH_ACCOUNT_PRIVATE_KEY \
"deposit(address recipient, uint256 amount)(uint256)" $STETH_ACCOUNT_ADDRESS 18000 

cast call $STETH_TOKEN_ADDRESS --rpc-url $RPC_URL \
"balanceOf(address)(uint256)" $STETH_ACCOUNT_ADDRESS

cast send $STETH_COLLATERAL_ADDRESS --rpc-url $RPC_URL --private-key $STETH_ACCOUNT_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $STETH_VAULT_ADDRESS 18000

cast send $STETH_VAULT_ADDRESS --rpc-url $RPC_URL --private-key $STETH_ACCOUNT_PRIVATE_KEY \
"deposit(address onBehalfOf, uint256 amount)(uint256 depositedAmount, uint256 mintedShares)" $STETH_ACCOUNT_ADDRESS 18000

cast call $STETH_VAULT_ADDRESS --rpc-url $RPC_URL \
"activeSharesOf(address)(uint256)" $STETH_ACCOUNT_ADDRESS







# Register Operators
cast send $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $DEFAULT_OPERATOR_PRIVATE_KEY \
"registerOperator()"

cast send $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $WBTC_OPERATOR_PRIVATE_KEY \
"registerOperator()"

cast send $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $STETH_OPERATOR_PRIVATE_KEY \
"registerOperator()"

# Verify operator registration
cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address)(bool)" $DEFAULT_OPERATOR_ADDRESS

# Verify operator registration
cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address)(bool)" $WBTC_OPERATOR_ADDRESS

# Verify operator registration
cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address)(bool)" $STETH_OPERATOR_ADDRESS

# Register Secondary Operators
cast send $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $DEFAULT_OPERATOR_PRIVATE_KEY_SECONDARY \
"registerOperator()"

cast send $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $WBTC_OPERATOR_PRIVATE_KEY_SECONDARY \
"registerOperator()"

cast send $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $STETH_OPERATOR_PRIVATE_KEY_SECONDARY \
"registerOperator()"

# Verify Secondary operator registration
cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address)(bool)" $DEFAULT_OPERATOR_ADDRESS_SECONDARY

# Verify Secondary operator registration
cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address)(bool)" $WBTC_OPERATOR_ADDRESS_SECONDARY

# Verify Secondary operator registration
cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address)(bool)" $STETH_OPERATOR_ADDRESS_SECONDARY

# Register Network
cast send $NETWORK_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerNetwork()"

# Verify network registration
cast call $NETWORK_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address)(bool)" $NETWORK_ADDRESS

# Set Middleware
cast send $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"setMiddleware(address middlewareAddress)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS


# Verify middleware setting
cast call $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"middleware(address)(address)" $NETWORK_ADDRESS


# Operator Network Opt-In
cast send $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $DEFAULT_OPERATOR_PRIVATE_KEY \
"optIn(address network)" $NETWORK_ADDRESS

cast send $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $WBTC_OPERATOR_PRIVATE_KEY \
"optIn(address network)" $NETWORK_ADDRESS

cast send $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $STETH_OPERATOR_PRIVATE_KEY \
"optIn(address network)" $NETWORK_ADDRESS

# Verify opt-in
cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address,address)(bool)" $DEFAULT_OPERATOR_ADDRESS $NETWORK_ADDRESS

cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address,address)(bool)" $WBTC_OPERATOR_ADDRESS $NETWORK_ADDRESS

cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address,address)(bool)" $STETH_OPERATOR_ADDRESS $NETWORK_ADDRESS


# Secondary Operator Network Opt-In
cast send $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $DEFAULT_OPERATOR_PRIVATE_KEY_SECONDARY \
"optIn(address network)" $NETWORK_ADDRESS

cast send $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $WBTC_OPERATOR_PRIVATE_KEY_SECONDARY \
"optIn(address network)" $NETWORK_ADDRESS

cast send $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $STETH_OPERATOR_PRIVATE_KEY_SECONDARY \
"optIn(address network)" $NETWORK_ADDRESS

# Verify opt-in
cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address,address)(bool)" $DEFAULT_OPERATOR_ADDRESS_SECONDARY $NETWORK_ADDRESS

cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address,address)(bool)" $WBTC_OPERATOR_ADDRESS_SECONDARY $NETWORK_ADDRESS

cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address,address)(bool)" $STETH_OPERATOR_ADDRESS_SECONDARY $NETWORK_ADDRESS


# Operator Vault Opt-In
cast send $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $DEFAULT_OPERATOR_PRIVATE_KEY \
"optIn(address vault)" $DEFAULT_VAULT_ADDRESS

cast send $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $WBTC_OPERATOR_PRIVATE_KEY \
"optIn(address vault)" $WBTC_VAULT_ADDRESS

cast send $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $STETH_OPERATOR_PRIVATE_KEY \
"optIn(address vault)" $STETH_VAULT_ADDRESS

# Secondary Operator Vault Opt-In
cast send $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $DEFAULT_OPERATOR_PRIVATE_KEY_SECONDARY \
"optIn(address vault)" $DEFAULT_VAULT_ADDRESS

cast send $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $WBTC_OPERATOR_PRIVATE_KEY_SECONDARY \
"optIn(address vault)" $WBTC_VAULT_ADDRESS

cast send $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $STETH_OPERATOR_PRIVATE_KEY_SECONDARY \
"optIn(address vault)" $STETH_VAULT_ADDRESS

# Register Tokens with Validation Service Manager
cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerToken(address token)" $DEFAULT_TOKEN_ADDRESS --gas-limit 200000

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerToken(address token)" $WBTC_TOKEN_ADDRESS --gas-limit 200000

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerToken(address token)" $STETH_TOKEN_ADDRESS --gas-limit 200000

# Verify token registration
cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isActiveToken(address)(bool)" $DEFAULT_TOKEN_ADDRESS

cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isActiveToken(address)(bool)" $WBTC_TOKEN_ADDRESS

cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isActiveToken(address)(bool)" $STETH_TOKEN_ADDRESS

cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL "getCurrentTokens()(address[])"

# Register Secondary Operators with Validation Service Manager
cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerOperator(address operatorAddress, address operatingAddress)" $DEFAULT_OPERATOR_ADDRESS_SECONDARY $DEFAULT_OPERATOR_ADDRESS_SECONDARY

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerOperator(address operatorAddress, address operatingAddress)" $WBTC_OPERATOR_ADDRESS_SECONDARY $WBTC_OPERATOR_ADDRESS_SECONDARY

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerOperator(address operatorAddress, address operatingAddress)" $STETH_OPERATOR_ADDRESS_SECONDARY $STETH_OPERATOR_ADDRESS_SECONDARY

# Register Vaults with Validation Service Manager


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerVault(address vault, address stakerRewards, address operatorRewards)" $WBTC_VAULT_ADDRESS $WBTC_STAKER_REWARDS $WBTC_OPERATOR_REWARDS
cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerVault(address vault, address stakerRewards, address operatorRewards)" $DEFAULT_VAULT_ADDRESS $DEFAULT_STAKER_REWARDS $DEFAULT_OPERATOR_REWARDS

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerVault(address vault, address stakerRewards, address operatorRewards)" $STETH_VAULT_ADDRESS $STETH_STAKER_REWARDS $STETH_OPERATOR_REWARDS

# Register Operators with Validation Service Manager
cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerOperator(address operatorAddress, address operatingAddress)" $DEFAULT_OPERATOR_ADDRESS $DEFAULT_OPERATOR_ADDRESS

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerOperator(address operatorAddress, address operatingAddress)" $WBTC_OPERATOR_ADDRESS $WBTC_OPERATOR_ADDRESS

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerOperator(address operatorAddress, address operatingAddress)" $STETH_OPERATOR_ADDRESS $STETH_OPERATOR_ADDRESS

# Set Delegator Configurations
# Default Delegator
cast send $DEFAULT_DELEGATOR_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"setMaxNetworkLimit(uint96 identifier, uint256 amount)" 0 10000

cast send $DEFAULT_DELEGATOR_ADDRESS --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setNetworkLimit(bytes32 subnetwork, uint256 amount)" $SUBNETWORK 10000

# Default Delegator - Primary Operator (70%)
cast send $DEFAULT_DELEGATOR_ADDRESS --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)" $SUBNETWORK $DEFAULT_OPERATOR_ADDRESS 7000

# Default Delegator - Secondary Operator (30%)
cast send $DEFAULT_DELEGATOR_ADDRESS --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)" $SUBNETWORK $DEFAULT_OPERATOR_ADDRESS_SECONDARY 3000



# # WBTC Delegator
cast send $WBTC_DELEGATOR_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"setMaxNetworkLimit(uint96 identifier, uint256 amount)" 0 10000

cast send $WBTC_DELEGATOR_ADDRESS --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setNetworkLimit(bytes32 subnetwork, uint256 amount)" $SUBNETWORK 10000

# WBTC Delegator - Primary Operator (70%)
cast send $WBTC_DELEGATOR_ADDRESS --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)" $SUBNETWORK $WBTC_OPERATOR_ADDRESS 7000

# WBTC Delegator - Secondary Operator (30%)
cast send $WBTC_DELEGATOR_ADDRESS --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)" $SUBNETWORK $WBTC_OPERATOR_ADDRESS_SECONDARY 3000


# # STETH Delegator
cast send $STETH_DELEGATOR_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"setMaxNetworkLimit(uint96 identifier, uint256 amount)" 0 10000

cast send $STETH_DELEGATOR_ADDRESS --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setNetworkLimit(bytes32 subnetwork, uint256 amount)" $SUBNETWORK 10000

# STETH Delegator - Primary Operator (70%)
cast send $STETH_DELEGATOR_ADDRESS --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)" $SUBNETWORK $STETH_OPERATOR_ADDRESS 7000

# STETH Delegator - Secondary Operator (30%)
cast send $STETH_DELEGATOR_ADDRESS --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)" $SUBNETWORK $STETH_OPERATOR_ADDRESS_SECONDARY 3000

# # Initialize Cluster
cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"initializeCluster(string clusterId, uint256 maxSequencerNumber)" $CLUSTER_ID $MAX_SEQUENCER_NUMBER

# # Add Rollup
cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"addRollup(string,(string,address,string,string,string,address,(string,string,address)))" \
"$CLUSTER_ID" "($ROLLUP_ID, $OWNER_ADDRESS, $ROLLUP_TYPE, $ENCRYPTED_TRANSACTION_TYPE, $ORDER_COMMITMENT_TYPE, $EXECUTOR_ADDRESS, ($PLATFORM, $SERVICE_PROVIDER, $VALIDATION_ADDRESS))"

# # Register Rollup Executor
cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerRollupExecutor(string clusterId, string rollupId, address executorAddress)" $CLUSTER_ID $ROLLUP_ID $EXECUTOR_ADDRESS

# # Register Sequencers
cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $DEFAULT_OPERATOR_PRIVATE_KEY \
"registerSequencer(string clusterId)" $CLUSTER_ID

cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $WBTC_OPERATOR_PRIVATE_KEY \
"registerSequencer(string clusterId)" $CLUSTER_ID

cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $STETH_OPERATOR_PRIVATE_KEY \
"registerSequencer(string clusterId)" $CLUSTER_ID

# # # Setup Rewards
cast send $REWARDS_CORE_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"addRewardPoolConfig(string,string,address,uint256,uint256,uint256,uint256)" $CLUSTER_ID $ROLLUP_ID $DEFAULT_TOKEN_ADDRESS 10000000000000000000 10 70 30

cast send $DEFAULT_TOKEN_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"approve(address,uint256)" $REWARD_SYSTEM_ADDRESS 50000000000000000000

cast send $DEFAULT_TOKEN_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"depositRewards(string,string,uint256)" $CLUSTER_ID $ROLLUP_ID 50000000000000000000

# cast send $REWARDS_CORE_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
# "addRewardPoolConfig(string,string,address,uint256,uint256,uint256,uint256)" $CLUSTER_ID $ROLLUP_ID $WBTC_TOKEN_ADDRESS 10000000000000000000 10 70 30

# cast send $REWARDS_CORE_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
# "addRewardPoolConfig(string,string,address,uint256,uint256,uint256,uint256)" $CLUSTER_ID $ROLLUP_ID $STETH_TOKEN_ADDRESS 10000000000000000000 10 70 30

# # Approve Rewards
cast send $DEFAULT_TOKEN_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"approve(address,uint256)" $REWARDS_CORE_ADDRESS 50000000000000000000

# cast send $WBTC_TOKEN_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
# "approve(address,uint256)" $REWARDS_CORE_ADDRESS 50000000000000000000

# cast send $STETH_TOKEN_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
# "approve(address,uint256)" $REWARDS_CORE_ADDRESS 50000000000000000000

# # Deposit Rewards
cast send $REWARDS_CORE_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"depositRewards(string,string,uint256)" $CLUSTER_ID $ROLLUP_ID 50000000000000000000
 
 
#  cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
# "registerTokenTest(address token)" $STETH_TOKEN_ADDRESS --gas-limit 200000


#  cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
# "respondToTaskTest(string clusterId,string rollupId,uint32 referenceTaskIndex,bool response)" $CLUSTER_ID $ROLLUP_ID 1 true --gas-limit 200000