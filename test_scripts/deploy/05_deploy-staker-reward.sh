#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PARENT_PATH="$(dirname "$(dirname "$SCRIPT_PATH")")"

cd "$SCRIPT_PATH"

source $PARENT_PATH/utils/env.sh
source $PARENT_PATH/utils/utils.sh

cd $PROJECT_ROOT_PATH

forge script script/deploy/StakerRewardDeploy.sol:StakerRewardDeploy --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast -vvvv