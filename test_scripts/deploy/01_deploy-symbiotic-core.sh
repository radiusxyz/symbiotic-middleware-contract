#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PARENT_PATH="$(dirname "$(dirname "$SCRIPT_PATH")")"

cd "$SCRIPT_PATH"

source $PARENT_PATH/utils/env.sh
source $PARENT_PATH/utils/utils.sh

rm -rf $LATEST_STATE_PATH/$CHAIN_ID
mkdir -p $LATEST_STATE_PATH/$CHAIN_ID

cd $PROJECT_ROOT_PATH

echo "HOLEYSKY"
echo $PRIVATE_KEY

forge script script/deploy/SymbioticCoreDeploy.sol:SymbioticCoreDeploy --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast -vvvv