#!/bin/bash
set -e -o nounset

PROJECT_ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LATEST_STATE_PATH=$PROJECT_ROOT_PATH/latest-state

# pinning at old foundry commit because of https://github.com/foundry-rs/foundry/issues/7502
FOUNDRY_IMAGE=ghcr.io/foundry-rs/foundry:nightly-5b7e4cb3c882b28f3c32ba580de27ce7381f415a

IS_LOCAL_BLOCKCHAIN=true
CHAIN_ID=31337
RPC_URL="http://127.0.0.1:8545"

PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
OPERATOR_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

DEPOSIT_AMOUNT=10000
