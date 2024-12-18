#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/../../env.sh

cast call $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL "totalStake()(uint256)"