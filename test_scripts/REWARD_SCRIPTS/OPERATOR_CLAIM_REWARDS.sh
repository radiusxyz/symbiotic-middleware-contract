#!/bin/bash

# Set default values for environment variables if not already set
CLUSTER_ID=${CLUSTER_ID:-"radius"}
ROLLUP_ID=${ROLLUP_ID:-"rollup_id_2"}
WBTC_OPERATOR_ADDRESS=${WBTC_OPERATOR_ADDRESS:-"0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"}
RPC_URL=${RPC_URL:-"http://localhost:8545"}
WBTC_OPERATOR_PRIVATE_KEY=${WBTC_OPERATOR_PRIVATE_KEY:-"YOUR_PRIVATE_KEY_HERE"}
WBTC_TOKEN_ADDRESS=${WBTC_TOKEN_ADDRESS:-"YOUR_WBTC_TOKEN_ADDRESS_HERE"}
NETWORK_ADDRESS=${NETWORK_ADDRESS:-"YOUR_NETWORK_ADDRESS_HERE"}

# Fetch the rewards data
echo "Fetching rewards data..."
REWARDS_DATA=$(curl -s -X GET "http://localhost:3000/operator-rewards/$CLUSTER_ID/$ROLLUP_ID/$WBTC_OPERATOR_ADDRESS")

# Check if curl command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch rewards data."
    exit 1
fi

# Extract the required values from the JSON response using jq (make sure jq is installed)
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install jq to continue."
    exit 1
fi

echo "Parsing rewards data..."

# Extract the operator rewards contract address, reward amount, and proof
OPERATOR_REWARDS_CONTRACT=$(echo "$REWARDS_DATA" | jq -r '.rewards[0].operator_rewards_contract')
REWARD_AMOUNT=$(echo "$REWARDS_DATA" | jq -r '.rewards[0].tasks[0].amount')
MERKLE_PROOF=$(echo "$REWARDS_DATA" | jq -r '.rewards[0].tasks[0].proof')
OPERATOR=$(echo "$REWARDS_DATA" | jq -r '.operator')

# Format the merkle proof for the cast send command
FORMATTED_PROOF=$(echo "$MERKLE_PROOF" | sed 's/\[//' | sed 's/\]//' | sed 's/"//g' | tr -d '[:space:]')

echo "Operator: $OPERATOR"
echo "Operator Rewards Contract: $OPERATOR_REWARDS_CONTRACT"
echo "Merkle Proof: $FORMATTED_PROOF"

# Execute the cast send command
# Check operator balance before claiming rewards
echo "Checking operator balance before claiming rewards..."
BALANCE_BEFORE=$(cast call $DEFAULT_TOKEN_ADDRESS "balanceOf(address)(uint256)" $OPERATOR --rpc-url $RPC_URL)

# Execute the claim rewards transaction
echo "Executing claim rewards transaction..."
cast send $OPERATOR_REWARDS_CONTRACT "claimRewards(address,address,address,uint256,bytes32[])" \
    $OPERATOR \
    $NETWORK_ADDRESS \
    $DEFAULT_TOKEN_ADDRESS \
    $REWARD_AMOUNT \
    "[$FORMATTED_PROOF]" \
    --rpc-url $RPC_URL \
    --private-key $WBTC_OPERATOR_PRIVATE_KEY

# Check if the cast send command was successful
if [ $? -eq 0 ]; then
    echo "✅ Successfully claimed rewards!"
    
    # Check operator balance after claiming rewards
    echo "Checking operator balance after claiming rewards..."
    sleep 2  # Wait for transaction to be mined
    BALANCE_AFTER=$(cast call $DEFAULT_TOKEN_ADDRESS "balanceOf(address)(uint256)" $OPERATOR --rpc-url $RPC_URL)
    echo "Reward Amount: $REWARD_AMOUNT"    
    echo "Balance before: $BALANCE_BEFORE"
    echo "Balance after: $BALANCE_AFTER"
    
else
    echo "❌ Failed to claim rewards."
fi