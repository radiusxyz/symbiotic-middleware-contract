#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd "$SCRIPT_PATH"

source $SCRIPT_PATH/../env.sh
source $SCRIPT_PATH/../utils.sh

rm -rf $LATEST_STATE_PATH/$CHAIN_ID
mkdir -p $LATEST_STATE_PATH/$CHAIN_ID

if [[ "$IS_LOCAL_BLOCKCHAIN" == "true" ]]; then
    start_anvil_docker "" "$LATEST_STATE_PATH/$CHAIN_ID"
fi

cd $PROJECT_ROOT_PATH

forge script script/deploy/SymbioticCoreDeploy.sol:SymbioticCoreDeploy --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast -vvvv