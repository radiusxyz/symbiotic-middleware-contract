#!/bin/bash

# Set WBTC values for environment variables if not already set
WBTC_STAKER_REWARDS=${WBTC_STAKER_REWARDS:-"YOUR_STAKER_REWARDS_CONTRACT_ADDRESS"}
WBTC_ACCOUNT_ADDRESS=${WBTC_ACCOUNT_ADDRESS:-"YOUR_ACCOUNT_ADDRESS"}
DEFAULT_TOKEN_ADDRESS=${DEFAULT_TOKEN_ADDRESS:-"YOUR_TOKEN_ADDRESS"}
NETWORK_ADDRESS=${NETWORK_ADDRESS:-"YOUR_NETWORK_ADDRESS"}
RPC_URL=${RPC_URL:-"http://localhost:8545"}
WBTC_ACCOUNT_PRIVATE_KEY=${WBTC_ACCOUNT_PRIVATE_KEY:-"YOUR_PRIVATE_KEY"}

echo "Using the following configuration:"
echo "Staker Rewards Contract: $WBTC_STAKER_REWARDS"
echo "Account Address: $WBTC_ACCOUNT_ADDRESS"
echo "Token Address: $DEFAULT_TOKEN_ADDRESS"
echo "Network Address: $NETWORK_ADDRESS"
echo "RPC URL: $RPC_URL"
echo "Private Key: ****" # Don't print the private key for security

# Check staker balance before claiming rewards
echo "Checking staker balance before claiming rewards..."
BALANCE_BEFORE=$(cast call $DEFAULT_TOKEN_ADDRESS "balanceOf(address)(uint256)" $WBTC_ACCOUNT_ADDRESS --rpc-url $RPC_URL)

# Execute the claim rewards transaction
echo "Executing claim staker rewards transaction..."
cast send $WBTC_STAKER_REWARDS "claimRewards(address,address,bytes)" \
    $WBTC_ACCOUNT_ADDRESS \
    $DEFAULT_TOKEN_ADDRESS \
    $(cast abi-encode "f(address,uint256,bytes[])" $NETWORK_ADDRESS 115792089237316195423570985008687907853269984665640564039457584007913129639935 []) \
    --rpc-url $RPC_URL \
    --private-key $WBTC_ACCOUNT_PRIVATE_KEY

# Check if the cast send command was successful
if [ $? -eq 0 ]; then
    echo "✅ Successfully claimed staker rewards!"
    
    # Check staker balance after claiming rewards
    echo "Checking staker balance after claiming rewards..."
    sleep 3  # Wait for transaction to be mined
    BALANCE_AFTER=$(cast call $DEFAULT_TOKEN_ADDRESS "balanceOf(address)(uint256)" $WBTC_ACCOUNT_ADDRESS --rpc-url $RPC_URL)
    echo "Balance before: $BALANCE_BEFORE"
    echo "Balance after: $BALANCE_AFTER"
    
   
else
    echo "❌ Failed to claim staker rewards."
fi