#!/bin/bash

# Setup placeholder file to track progress
PLACEHOLDER_FILE=".tx_placeholder"

# Check if verify mode is requested
if [[ "$1" == "verify" ]]; then
  echo "Running in verification mode only..."
  # Skip directly to verification queries
else
  # Initialize placeholder if it doesn't exist and no restart flag
  if [[ ! -f "$PLACEHOLDER_FILE" ]] || [[ "$1" != "restart" ]]; then
    echo "0" > "$PLACEHOLDER_FILE"
    echo "Starting execution from the beginning..."
  else
    echo "Restarting execution from placeholder..."
  fi

  # Read current placeholder
  CURRENT_TX=$(cat "$PLACEHOLDER_FILE")
  echo "Starting from transaction #$CURRENT_TX"

  # Function to execute transactions with placeholder tracking
  execute_tx() {
    local tx_index=$1
    local tx_command=$2
    local tx_description=$3

    # Skip transactions that have already been executed
    if [[ $tx_index -lt $CURRENT_TX ]]; then
      echo "Skipping transaction #$tx_index: $tx_description (already executed)"
      return 0
    fi

    # Update placeholder
    echo $tx_index > "$PLACEHOLDER_FILE"
    
    echo "Executing transaction #$tx_index: $tx_description"
    
    # Execute the transaction command
    eval "$tx_command"
    
    # Check if the transaction was successful
    if [[ $? -ne 0 ]]; then
      echo "Transaction #$tx_index failed. Stopping execution."
      echo "To restart from this point, run the script with 'restart' parameter."
      exit 1
    fi
    
    # Increment placeholder for next transaction
    echo $((tx_index + 1)) > "$PLACEHOLDER_FILE"
    
    # Small delay to prevent node overload
    sleep 1
  }

# All transactions listed in order with index, command, and description

# Initial ETH transfers
execute_tx 0 "cast send --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY --value 1ether \$WBTC_ACCOUNT_ADDRESS" "Fund WBTC Account"
execute_tx 1 "cast send --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY --value 1ether \$STETH_ACCOUNT_ADDRESS" "Fund STETH Account"
execute_tx 2 "cast send --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY --value 1ether \$DEFAULT_OPERATOR_ADDRESS" "Fund Default Operator"
execute_tx 3 "cast send --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY --value 1ether \$WBTC_OPERATOR_ADDRESS" "Fund WBTC Operator"
execute_tx 4 "cast send --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY --value 1ether \$STETH_OPERATOR_ADDRESS" "Fund STETH Operator"
execute_tx 5 "cast send --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY --value 1ether \$WBTC_OPERATOR_ADDRESS_SECONDARY" "Fund WBTC Secondary Operator"
execute_tx 6 "cast send --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY --value 1ether \$STETH_OPERATOR_ADDRESS_SECONDARY" "Fund STETH Secondary Operator"
execute_tx 7 "cast send --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY --value 10ether \$REWARDS_MANAGER_ACCOUNT_ADDRESSS" "Fund Rewards Manager"

# WBTC Token Setup
execute_tx 8 "cast send \$WBTC_TOKEN_ADDRESS --rpc-url \$RPC_URL --private-key \$TOKEN_CONTRACT_OWNER_PRIVATE_KEY \"transfer(address,uint256)\" \$WBTC_ACCOUNT_ADDRESS 12000000000000000000000" "Transfer WBTC tokens to account"
execute_tx 9 "cast send \$WBTC_TOKEN_ADDRESS --rpc-url \$RPC_URL --private-key \$WBTC_ACCOUNT_PRIVATE_KEY \"approve(address spender, uint256 value)(bool)\" \$WBTC_COLLATERAL_ADDRESS 12000000000000000000000" "Approve WBTC collateral"
execute_tx 10 "cast send \$WBTC_COLLATERAL_ADDRESS --rpc-url \$RPC_URL --private-key \$WBTC_ACCOUNT_PRIVATE_KEY \"deposit(address recipient, uint256 amount)(uint256)\" \$WBTC_ACCOUNT_ADDRESS 12000000000000000000000" "Deposit WBTC collateral"
execute_tx 11 "cast send \$WBTC_COLLATERAL_ADDRESS --rpc-url \$RPC_URL --private-key \$WBTC_ACCOUNT_PRIVATE_KEY \"approve(address spender, uint256 value)(bool)\" \$WBTC_VAULT_ADDRESS 12000000000000000000000" "Approve WBTC vault"

execute_tx 12 "cast send \$WBTC_VAULT_BURNER_ROUTER --rpc-url \$RPC_URL --private-key \$VAULT_OWNER_PRIVATE_KEY \"setNetworkReceiver(address, address)\" \$NETWORK_ADDRESS \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS" "Set WBTC network receiver"

execute_tx 13 "cast send \$WBTC_VAULT_ADDRESS --rpc-url \$RPC_URL --private-key \$WBTC_ACCOUNT_PRIVATE_KEY \"deposit(address onBehalfOf, uint256 amount)(uint256 depositedAmount, uint256 mintedShares)\" \$WBTC_ACCOUNT_ADDRESS 12000000000000000000000" "Deposit into WBTC vault"

execute_tx 14 "cast send \$WBTC_VAULT_BURNER_ROUTER --rpc-url \$RPC_URL --private-key \$VAULT_OWNER_PRIVATE_KEY \"acceptNetworkReceiver(address)\" \$NETWORK_ADDRESS" "Accept WBTC network receiver"

# STETH Token Setup
execute_tx 15 "cast send \$STETH_TOKEN_ADDRESS --rpc-url \$RPC_URL --private-key \$TOKEN_CONTRACT_OWNER_PRIVATE_KEY \"transfer(address,uint256)\" \$STETH_ACCOUNT_ADDRESS 25000000000000000000000" "Transfer STETH tokens to account"
execute_tx 16 "cast send \$STETH_TOKEN_ADDRESS --rpc-url \$RPC_URL --private-key \$STETH_ACCOUNT_PRIVATE_KEY \"approve(address spender, uint256 value)(bool)\" \$STETH_COLLATERAL_ADDRESS 25000000000000000000000" "Approve STETH collateral"
execute_tx 17 "cast send \$STETH_COLLATERAL_ADDRESS --rpc-url \$RPC_URL --private-key \$STETH_ACCOUNT_PRIVATE_KEY \"deposit(address recipient, uint256 amount)(uint256)\" \$STETH_ACCOUNT_ADDRESS 25000000000000000000000" "Deposit STETH collateral"
execute_tx 18 "cast send \$STETH_COLLATERAL_ADDRESS --rpc-url \$RPC_URL --private-key \$STETH_ACCOUNT_PRIVATE_KEY \"approve(address spender, uint256 value)(bool)\" \$STETH_VAULT_ADDRESS 25000000000000000000000" "Approve STETH vault"

execute_tx 19 "cast send \$STETH_VAULT_BURNER_ROUTER --rpc-url \$RPC_URL --private-key \$VAULT_OWNER_PRIVATE_KEY \"setNetworkReceiver(address, address)\" \$NETWORK_ADDRESS \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS" "Set STETH network receiver"

execute_tx 20 "cast send \$STETH_VAULT_ADDRESS --rpc-url \$RPC_URL --private-key \$STETH_ACCOUNT_PRIVATE_KEY \"deposit(address onBehalfOf, uint256 amount)(uint256 depositedAmount, uint256 mintedShares)\" \$STETH_ACCOUNT_ADDRESS 25000000000000000000000" "Deposit into STETH vault"

execute_tx 21 "cast send \$STETH_VAULT_BURNER_ROUTER --rpc-url \$RPC_URL --private-key \$VAULT_OWNER_PRIVATE_KEY \"acceptNetworkReceiver(address)\" \$NETWORK_ADDRESS" "Accept STETH network receiver"

# Register Operators
execute_tx 22 "cast send \$OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$DEFAULT_OPERATOR_PRIVATE_KEY \"registerOperator()\"" "Register default operator"
execute_tx 23 "cast send \$OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$WBTC_OPERATOR_PRIVATE_KEY \"registerOperator()\"" "Register WBTC operator"
execute_tx 24 "cast send \$OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$STETH_OPERATOR_PRIVATE_KEY \"registerOperator()\"" "Register STETH operator"
execute_tx 25 "cast send \$OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$WBTC_OPERATOR_PRIVATE_KEY_SECONDARY \"registerOperator()\"" "Register WBTC secondary operator"
execute_tx 26 "cast send \$OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$STETH_OPERATOR_PRIVATE_KEY_SECONDARY \"registerOperator()\"" "Register STETH secondary operator"

# Register Network
execute_tx 27 "cast send \$NETWORK_REGISTRY_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"registerNetwork()\"" "Register network"

# Set Middleware
execute_tx 28 "cast send \$NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"setMiddleware(address middlewareAddress)\" \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS" "Set middleware"

# Operator Network Opt-In
execute_tx 29 "cast send \$OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$DEFAULT_OPERATOR_PRIVATE_KEY \"optIn(address network)\" \$NETWORK_ADDRESS" "Default operator network opt-in"
execute_tx 30 "cast send \$OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$WBTC_OPERATOR_PRIVATE_KEY \"optIn(address network)\" \$NETWORK_ADDRESS" "WBTC operator network opt-in"
execute_tx 31 "cast send \$OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$STETH_OPERATOR_PRIVATE_KEY \"optIn(address network)\" \$NETWORK_ADDRESS" "STETH operator network opt-in"
execute_tx 32 "cast send \$OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$WBTC_OPERATOR_PRIVATE_KEY_SECONDARY \"optIn(address network)\" \$NETWORK_ADDRESS" "WBTC secondary operator network opt-in"
execute_tx 33 "cast send \$OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$STETH_OPERATOR_PRIVATE_KEY_SECONDARY \"optIn(address network)\" \$NETWORK_ADDRESS" "STETH secondary operator network opt-in"

# Operator Vault Opt-In
execute_tx 34 "cast send \$OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$DEFAULT_OPERATOR_PRIVATE_KEY \"optIn(address vault)\" \$WBTC_VAULT_ADDRESS" "Default operator WBTC vault opt-in"
execute_tx 35 "cast send \$OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$WBTC_OPERATOR_PRIVATE_KEY \"optIn(address vault)\" \$WBTC_VAULT_ADDRESS" "WBTC operator WBTC vault opt-in"
execute_tx 36 "cast send \$OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$STETH_OPERATOR_PRIVATE_KEY \"optIn(address vault)\" \$STETH_VAULT_ADDRESS" "STETH operator STETH vault opt-in"
execute_tx 37 "cast send \$OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$WBTC_OPERATOR_PRIVATE_KEY_SECONDARY \"optIn(address vault)\" \$WBTC_VAULT_ADDRESS" "WBTC secondary operator WBTC vault opt-in"
execute_tx 38 "cast send \$OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$STETH_OPERATOR_PRIVATE_KEY_SECONDARY \"optIn(address vault)\" \$STETH_VAULT_ADDRESS" "STETH secondary operator STETH vault opt-in"

# Register Tokens with Validation Service Manager
execute_tx 39 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"registerToken(address token)\" \$WBTC_TOKEN_ADDRESS" "Register WBTC token"
execute_tx 40 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"registerToken(address token)\" \$STETH_TOKEN_ADDRESS" "Register STETH token"

# Slashing configuration
# execute_tx 41 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"setSlashAmount(uint256)\" 10" "Set slash amount"
execute_tx 42 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"setSlashPeriod(uint256)\" 60" "Set slash period"

# Register Vaults with Validation Service Manager
execute_tx 43 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"registerVault(address vault, address stakerRewards, address operatorRewards, address slasher)\" \$WBTC_VAULT_ADDRESS \$WBTC_STAKER_REWARDS \$WBTC_OPERATOR_REWARDS \$WBTC_VAULT_SLASHER" "Register WBTC vault"
execute_tx 44 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"registerVault(address vault, address stakerRewards, address operatorRewards, address slasher)\" \$STETH_VAULT_ADDRESS \$STETH_STAKER_REWARDS \$STETH_OPERATOR_REWARDS \$STETH_VAULT_SLASHER" "Register STETH vault"

# Register Operators with Validation Service Manager
execute_tx 45 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"registerOperator(address operatorAddress, address txOrderer)\" \$DEFAULT_OPERATOR_ADDRESS \$DEFAULT_OPERATOR_ADDRESS" "Register default operator with VSM"
execute_tx 46 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"registerOperator(address operatorAddress, address txOrderer)\" \$WBTC_OPERATOR_ADDRESS \$WBTC_OPERATOR_ADDRESS" "Register WBTC operator with VSM"
execute_tx 47 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"registerOperator(address operatorAddress, address txOrderer)\" \$STETH_OPERATOR_ADDRESS \$STETH_OPERATOR_ADDRESS" "Register STETH operator with VSM"
execute_tx 48 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"registerOperator(address operatorAddress, address txOrderer)\" \$WBTC_OPERATOR_ADDRESS_SECONDARY \$WBTC_OPERATOR_ADDRESS_SECONDARY" "Register WBTC secondary operator with VSM"
execute_tx 49 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"registerOperator(address operatorAddress, address txOrderer)\" \$STETH_OPERATOR_ADDRESS_SECONDARY \$STETH_OPERATOR_ADDRESS_SECONDARY" "Register STETH secondary operator with VSM"

# WBTC Delegator
execute_tx 50 "cast send \$WBTC_DELEGATOR_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"setMaxNetworkLimit(uint96 identifier, uint256 amount)\" 0 12000000000000000000000" "Set WBTC max network limit"
execute_tx 51 "cast send \$WBTC_DELEGATOR_ADDRESS --rpc-url \$RPC_URL --private-key \$VAULT_OWNER_PRIVATE_KEY \"setNetworkLimit(bytes32 subnetwork, uint256 amount)\" \$SUBNETWORK 12000000000000000000000" "Set WBTC network limit"
execute_tx 52 "cast send \$WBTC_DELEGATOR_ADDRESS --rpc-url \$RPC_URL --private-key \$VAULT_OWNER_PRIVATE_KEY \"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)\" \$SUBNETWORK \$DEFAULT_OPERATOR_ADDRESS 50" "Set WBTC main operator shares (50%)"
execute_tx 53 "cast send \$WBTC_DELEGATOR_ADDRESS --rpc-url \$RPC_URL --private-key \$VAULT_OWNER_PRIVATE_KEY \"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)\" \$SUBNETWORK \$WBTC_OPERATOR_ADDRESS 30" "Set WBTC primary operator shares (30%)"
execute_tx 54 "cast send \$WBTC_DELEGATOR_ADDRESS --rpc-url \$RPC_URL --private-key \$VAULT_OWNER_PRIVATE_KEY \"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)\" \$SUBNETWORK \$WBTC_OPERATOR_ADDRESS_SECONDARY 20" "Set WBTC secondary operator shares (20%)"

# STETH Delegator
execute_tx 55 "cast send \$STETH_DELEGATOR_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"setMaxNetworkLimit(uint96 identifier, uint256 amount)\" 0 25000000000000000000000" "Set STETH max network limit"
execute_tx 56 "cast send \$STETH_DELEGATOR_ADDRESS --rpc-url \$RPC_URL --private-key \$VAULT_OWNER_PRIVATE_KEY \"setNetworkLimit(bytes32 subnetwork, uint256 amount)\" \$SUBNETWORK 25000000000000000000000" "Set STETH network limit"
execute_tx 57 "cast send \$STETH_DELEGATOR_ADDRESS --rpc-url \$RPC_URL --private-key \$VAULT_OWNER_PRIVATE_KEY \"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)\" \$SUBNETWORK \$STETH_OPERATOR_ADDRESS 70" "Set STETH primary operator shares (70%)"
execute_tx 58 "cast send \$STETH_DELEGATOR_ADDRESS --rpc-url \$RPC_URL --private-key \$VAULT_OWNER_PRIVATE_KEY \"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)\" \$SUBNETWORK \$STETH_OPERATOR_ADDRESS_SECONDARY 30" "Set STETH secondary operator shares (30%)"

# Initialize Cluster and Rollups
execute_tx 59 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"initializeCluster(string clusterId, uint256 maxSequencerNumber)\" \$CLUSTER_ID \$MAX_SEQUENCER_NUMBER" "Initialize cluster"
execute_tx 60 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"addRollup(string,(string,address,string,string,string,address,(string,string,address)))\" \"\$CLUSTER_ID\" \"(\$ROLLUP_ID, \$OWNER_ADDRESS, \$ROLLUP_TYPE, \$ENCRYPTED_TRANSACTION_TYPE, \$ORDER_COMMITMENT_TYPE, \$EXECUTOR_ADDRESS, (\$PLATFORM, \$SERVICE_PROVIDER, \$VALIDATION_ADDRESS))\"" "Add rollup"
# execute_tx 61 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"registerRollupExecutor(string clusterId, string rollupId, address executorAddress)\" \$CLUSTER_ID \$ROLLUP_ID \$EXECUTOR_ADDRESS" "Register rollup executor"

# Register Sequencers
execute_tx 62 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$DEFAULT_OPERATOR_PRIVATE_KEY \"registerTxOrderer(string clusterId)\" \$CLUSTER_ID" "Register default operator as sequencer"
execute_tx 63 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$WBTC_OPERATOR_PRIVATE_KEY \"registerTxOrderer(string clusterId)\" \$CLUSTER_ID" "Register WBTC operator as sequencer"
execute_tx 64 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$STETH_OPERATOR_PRIVATE_KEY \"registerTxOrderer(string clusterId)\" \$CLUSTER_ID" "Register STETH operator as sequencer"
execute_tx 65 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$WBTC_OPERATOR_PRIVATE_KEY_SECONDARY \"registerTxOrderer(string clusterId)\" \$CLUSTER_ID" "Register WBTC secondary operator as sequencer"
execute_tx 66 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$STETH_OPERATOR_PRIVATE_KEY_SECONDARY \"registerTxOrderer(string clusterId)\" \$CLUSTER_ID" "Register STETH secondary operator as sequencer"

# Setup Rewards
execute_tx 67 "cast send \$REWARDS_CORE_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"addRewardPoolConfig(string,string,address,uint256,uint256,uint256,uint256)\" \$CLUSTER_ID \$ROLLUP_ID \$DEFAULT_TOKEN_ADDRESS 1000000000000000000 30 70 30" "Add reward pool config"

execute_tx 68 "cast send \$DEFAULT_TOKEN_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"approve(address,uint256)\" \$REWARDS_CORE_ADDRESS 5000000000000000000000" "Approve rewards"
execute_tx 69 "cast send \$REWARDS_CORE_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"depositRewards(string,string,uint256)\" \$CLUSTER_ID \$ROLLUP_ID 5000000000000000000000" "Deposit rewards"


# Setup Slashing
execute_tx 70 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"setSlashAmount(address,uint256)\" \$WBTC_TOKEN_ADDRESS 1000000000000000000" "Register WBTC Slash Amount"

execute_tx 71 "cast send \$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url \$RPC_URL --private-key \$NETWORK_PRIVATE_KEY \"setSlashAmount(address,uint256)\" \$STETH_TOKEN_ADDRESS 15000000000000000000" "Register STETH Slash Amount"


  echo "All transactions completed successfully."
fi

echo "Running verification queries..."

# ==============================================
# Verification Queries - WBTC Token Setup
# ==============================================
echo -e "\n==== VERIFYING WBTC TOKEN SETUP ===="

# echo -e "\nChecking WBTC balance:"
# cast call $WBTC_TOKEN_ADDRESS --rpc-url $RPC_URL \
# "balanceOf(address)(uint256)" $WBTC_ACCOUNT_ADDRESS

# echo -e "\nChecking WBTC allowance for collateral:"
# cast call $WBTC_TOKEN_ADDRESS --rpc-url $RPC_URL \
# "allowance(address,address)(uint256)" $WBTC_ACCOUNT_ADDRESS $WBTC_COLLATERAL_ADDRESS

# echo -e "\nChecking WBTC account balance after deposit:"
# cast call $WBTC_TOKEN_ADDRESS --rpc-url $RPC_URL \
# "balanceOf(address)(uint256)" $WBTC_ACCOUNT_ADDRESS

echo -e "\nChecking WBTC active shares:"
cast call $WBTC_VAULT_ADDRESS --rpc-url $RPC_URL \
"activeSharesOf(address)(uint256)" $WBTC_ACCOUNT_ADDRESS



# ==============================================
# Verification Queries - STETH Token Setup
# ==============================================
echo -e "\n==== VERIFYING STETH TOKEN SETUP ===="

# echo -e "\nChecking STETH balance:"
# cast call $STETH_TOKEN_ADDRESS --rpc-url $RPC_URL \
# "balanceOf(address)(uint256)" $STETH_ACCOUNT_ADDRESS

# echo -e "\nChecking STETH allowance for collateral:"
# cast call $STETH_TOKEN_ADDRESS --rpc-url $RPC_URL \
# "allowance(address,address)(uint256)" $STETH_ACCOUNT_ADDRESS $STETH_COLLATERAL_ADDRESS

# echo -e "\nChecking STETH account balance after deposit:"
# cast call $STETH_TOKEN_ADDRESS --rpc-url $RPC_URL \
# "balanceOf(address)(uint256)" $STETH_ACCOUNT_ADDRESS

echo -e "\nChecking STETH active shares:"
cast call $STETH_VAULT_ADDRESS --rpc-url $RPC_URL \
"activeSharesOf(address)(uint256)" $STETH_ACCOUNT_ADDRESS



# ==============================================
# Verification Queries - Token Registration
# ==============================================
echo -e "\n==== VERIFYING TOKEN REGISTRATION ===="

echo -e "\nVerifying WBTC token registration:"
cast call $VSM_REGISTRY --rpc-url $RPC_URL \
"isActiveToken(address)(bool)" $WBTC_TOKEN_ADDRESS

echo -e "\nVerifying STETH token registration:"
cast call $VSM_REGISTRY --rpc-url $RPC_URL \
"isActiveToken(address)(bool)" $STETH_TOKEN_ADDRESS

echo -e "\nListing all registered tokens:"
cast call $VSM_REGISTRY --rpc-url $RPC_URL "getCurrentTokens()(address[])"

# ==============================================
# Verification Queries - Operator Stake Amounts
# ==============================================
echo -e "\nVerifying WBTC token Slash Amounts:"
cast call $VSM_REGISTRY --rpc-url $RPC_URL \
"getSlashAmount(address)(uint256)" $WBTC_TOKEN_ADDRESS

echo -e "\nVerifying STETH token Slash Amounts:"
cast call $VSM_REGISTRY --rpc-url $RPC_URL \
"getSlashAmount(address)(uint256)" $STETH_TOKEN_ADDRESS


# ==============================================
# Verification Queries - Vaults
# ==============================================
echo -e "\n==== VERIFYING VAULT REGISTRATION ===="
echo -e "\nListing all registered tokens:"
cast call $VSM_REGISTRY --rpc-url $RPC_URL "getCurrentVaults()(address[])"


# ==============================================
# Verification Queries - Burner Receivers
# ==============================================
echo -e "\n==== VERIFYING RECEIVER REGISTRATION ===="

echo -e "\nVerifying WBTC network receiver:"
cast call $WBTC_VAULT_BURNER_ROUTER "networkReceiver(address)((address))" $NETWORK_ADDRESS --rpc-url $RPC_URL
echo -e "\nVerifying STETH network receiver:"
cast call $STETH_VAULT_BURNER_ROUTER "networkReceiver(address)((address))" $NETWORK_ADDRESS --rpc-url $RPC_URL

# ==============================================
# Verification Queries - Operator Registration
# ==============================================
echo -e "\n==== VERIFYING OPERATOR REGISTRATION ===="

echo -e "\nVerifying Default Operator registration:"
cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address)(bool)" $DEFAULT_OPERATOR_ADDRESS

echo -e "\nVerifying WBTC Operator registration:"
cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address)(bool)" $WBTC_OPERATOR_ADDRESS

echo -e "\nVerifying STETH Operator registration:"
cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address)(bool)" $STETH_OPERATOR_ADDRESS

echo -e "\nVerifying WBTC Secondary Operator registration:"
cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address)(bool)" $WBTC_OPERATOR_ADDRESS_SECONDARY

echo -e "\nVerifying STETH Secondary Operator registration:"
cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address)(bool)" $STETH_OPERATOR_ADDRESS_SECONDARY

# ==============================================
# Verification Queries - Network Registration
# ==============================================
echo -e "\n==== VERIFYING NETWORK REGISTRATION ===="

echo -e "\nVerifying Network registration:"
cast call $NETWORK_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address)(bool)" $NETWORK_ADDRESS

echo -e "\nVerifying middleware setting:"
cast call $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"middleware(address)(address)" $NETWORK_ADDRESS

# ==============================================
# Verification Queries - Network Opt-In
# ==============================================
echo -e "\n==== VERIFYING NETWORK OPT-IN ===="

echo -e "\nVerifying Default Operator opt-in:"
cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address,address)(bool)" $DEFAULT_OPERATOR_ADDRESS $NETWORK_ADDRESS

echo -e "\nVerifying WBTC Operator opt-in:"
cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address,address)(bool)" $WBTC_OPERATOR_ADDRESS $NETWORK_ADDRESS

echo -e "\nVerifying WBTC Secondary Operator opt-in:"
cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address,address)(bool)" $WBTC_OPERATOR_ADDRESS_SECONDARY $NETWORK_ADDRESS

echo -e "\nVerifying STETH Operator opt-in:"
cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address,address)(bool)" $STETH_OPERATOR_ADDRESS $NETWORK_ADDRESS

echo -e "\nVerifying STETH Secondary Operator registration:"
cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address,address)(bool)" $STETH_OPERATOR_ADDRESS_SECONDARY $NETWORK_ADDRESS

 

# ==============================================
# Verification Queries - Operator Stake Amounts
# ==============================================
echo -e "\n==== VERIFYING OPERAOTR STAKES ===="

echo -e "\nVerifying WBTC Token Shares:"
echo -e "\n$DEFAULT_OPERATOR_ADDRESS - Default Operator Shares:"
cast call $VSM_REGISTRY "getCurrentOperatorTokenStake(address operator, address token)(uint256)" $DEFAULT_OPERATOR_ADDRESS $WBTC_TOKEN_ADDRESS --rpc-url $RPC_URL

echo -e "\n$WBTC_OPERATOR_ADDRESS - WBTC Operator Shares:"
cast call $VSM_REGISTRY "getCurrentOperatorTokenStake(address operator, address token)(uint256)" $WBTC_OPERATOR_ADDRESS $WBTC_TOKEN_ADDRESS --rpc-url $RPC_URL

echo -e "\n$WBTC_OPERATOR_ADDRESS_SECONDARY - WBTC Secondary Shares:"
cast call $VSM_REGISTRY "getCurrentOperatorTokenStake(address operator, address token)(uint256)" $WBTC_OPERATOR_ADDRESS_SECONDARY $WBTC_TOKEN_ADDRESS --rpc-url $RPC_URL


echo -e "\nVerifying STETH Token Shares:"
echo -e "\n$STETH_OPERATOR_ADDRESS - STETH Operator Shares:"
cast call $VSM_REGISTRY "getCurrentOperatorTokenStake(address operator, address token)(uint256)" $STETH_OPERATOR_ADDRESS $STETH_TOKEN_ADDRESS --rpc-url $RPC_URL

echo -e "\n$STETH_OPERATOR_ADDRESS_SECONDARY - STETH Secondary Shares:"
cast call $VSM_REGISTRY "getCurrentOperatorTokenStake(address operator, address token)(uint256)" $STETH_OPERATOR_ADDRESS_SECONDARY $STETH_TOKEN_ADDRESS --rpc-url $RPC_URL


# ==============================================
# Verification Queries - Rewards Core
# ==============================================
echo -e "\n==== VERIFYING OPERAOTR STAKES ===="
echo -e "\nRewards Cord Pool Config:"
cast call $REWARDS_CORE_ADDRESS --rpc-url $RPC_URL \
"getRewardPoolConfig(string,string)(address,uint256,uint256,uint256,uint256,uint256,bool)" $CLUSTER_ID $ROLLUP_ID
        