#!/bin/bash
cleanup() {
    echo "Executing cleanup function..."
    set +e
    docker rm -f anvil
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo "Script exited due to set -e on line $1 with command '$2'. Exit status: $exit_status"
    fi
}

# start_anvil_docker $LOAD_STATE_FILE $DUMP_STATE_FILE $CHAIN_ID
start_anvil_docker() {
    LOAD_STATE_FILE=$1
    DUMP_STATE_FILE=$2
    # CHAIN_ID=${3:-11155111}  # 기본값으로 1337 사용

    LOAD_STATE_VOLUME_DOCKER_ARG=$([[ -z $LOAD_STATE_FILE ]] && echo "" || echo "-v $LOAD_STATE_FILE:/load-state.json")
    DUMP_STATE_VOLUME_DOCKER_ARG=$([[ -z $DUMP_STATE_FILE ]] && echo "" || echo "-v $DUMP_STATE_FILE:/dump-state.json")

    LOAD_STATE_ANVIL_ARG=$([[ -z $LOAD_STATE_FILE ]] && echo "" || echo "--load-state /load-state.json")
    DUMP_STATE_ANVIL_ARG=$([[ -z $DUMP_STATE_FILE ]] && echo "" || echo "--dump-state /dump-state.json")

    trap 'docker stop anvil' EXIT
    docker run --rm -d --name anvil -p 8545:8545 $LOAD_STATE_VOLUME_DOCKER_ARG $DUMP_STATE_VOLUME_DOCKER_ARG \
        --entrypoint anvil \
        $FOUNDRY_IMAGE \
        $LOAD_STATE_ANVIL_ARG $DUMP_STATE_ANVIL_ARG --host 0.0.0.0 # --chain-id $CHAIN_ID
    sleep 2
}