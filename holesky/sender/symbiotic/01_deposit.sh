#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

cast send $TOKEN_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $COLLATERAL_CONTRACT_ADDRESS $DEPOSIT_AMOUNT

cast send $COLLATERAL_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $COLLATERAL_OWNER_PRIVATE_KEY \
"deposit(address recipient, uint256 amount)(uint256)" $TOKEN_CONTRACT_OWNER_ADDRESS $DEPOSIT_AMOUNT

cast send $COLLATERAL_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $VAULT_CONTRACT_ADDRESS $DEPOSIT_AMOUNT

cast send $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"deposit(address onBehalfOf, uint256 amount)(uint256 depositedAmount, uint256 mintedShares)" $TOKEN_CONTRACT_OWNER_ADDRESS $DEPOSIT_AMOUNT

cast call $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL "totalStake()(uint256)"