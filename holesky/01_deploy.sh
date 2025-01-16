#!/bin/bash
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/env.sh

cd "$SCRIPT_PATH"/..

# Deploy Liveness Contract
# forge script script/deploy/holesky/LivenessRadiusHoleskyDeploy.sol:LivenessRadiusHoleskyDeploy \
# --rpc-url $RPC_URL --private-key $RADIUS_PRIVATE_KEY --broadcast -vvvv

# # Deploy Collateral
# forge script script/deploy/holesky/CollateralHoleskyDeploy.sol:CollateralHoleskyDeploy \
# --rpc-url $RPC_URL --private-key $COLLATERAL_OWNER_PRIVATE_KEY --broadcast -vvvv

# # Deploy Vault (for testing)
# forge script script/deploy/holesky/VaultHoleskyDeploy.sol:VaultHoleskyDeploy \
# --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY --broadcast -vvvv

# Deploy Validation Service Manager
# forge script script/deploy/holesky/ValidationServiceManagerHoleskyDeployer.sol:ValidationServiceManagerHoleskyDeployer \
# --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY --broadcast -vvvv