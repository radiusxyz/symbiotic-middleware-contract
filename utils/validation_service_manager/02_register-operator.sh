#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd "$SCRIPT_PATH"

source $SCRIPT_PATH/../env.sh
source $SCRIPT_PATH/../utils.sh

cd $PROJECT_ROOT_PATH

forge script script/validation_service_manager/RegisterOperator.sol:RegisterOperator \
--rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast -vvvv \
--sig "run(address)" $OPERATOR_ADDRESS