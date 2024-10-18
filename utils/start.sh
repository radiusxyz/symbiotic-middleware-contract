#!/bin/bash

# cd to the directory of this script so that this can be run from anywhere
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd "$SCRIPT_PATH"

source $SCRIPT_PATH/env.sh
source $SCRIPT_PATH/utils.sh

start_anvil_docker $LATEST_STATE_PATH/$CHAIN_ID ""

cd $PROJECT_ROOT_PATH

cast rpc evm_setIntervalMining 2 --rpc-url http://0.0.0.0:8545

echo "advancing chain... current block-number:" $(cast block-number)

# Bring Anvil back to the foreground
docker attach anvil