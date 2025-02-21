#!/usr/bin/env python3
import json

def read_json_file(filename):
    with open(filename, 'r') as f:
        return json.load(f)

# Read all deployment files
symbiotic_core = read_json_file('../latest-state/31337/symbiotic_core_deployment_output.json')['addresses']
validation_manager = read_json_file('../latest-state/31337/validation_service_manager_deployment_output.json')['addresses']
vault = read_json_file('../latest-state/31337/vault_deployment_output.json')['addresses']
collateral = read_json_file('../latest-state/31337/collateral_deployment_output.json')['addresses']
liveness_service_manager = read_json_file('../latest-state/31337/liveness_service_manager_deployment_output.json')['addresses']
rewards_core = read_json_file('../latest-state/31337/rewards_core_deployment_output.json')['addresses']
operator_rewards = read_json_file('../latest-state/31337/operator_reward_deployment_output.json')['addresses']
staker_rewards = read_json_file('../latest-state/31337/staker_reward_deployment_output.json')['addresses']
# simulation = read_json_file('../latest-state/31337/simulation_deployment_output.json')['addresses']

# Base Configuration
print('set -x RPC_URL "http://127.0.0.1:8545"')

print('\n# Rollup side')
print('\n# Network Configuration')
print('set -x NETWORK_ADDRESS "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"')
print('set -x NETWORK_PRIVATE_KEY "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"')
print('set -x SUBNETWORK "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266000000000000000000000000"')

print('\n# Token Contract Owner')
print('set -x TOKEN_CONTRACT_OWNER_ADDRESS "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"')
print('set -x TOKEN_CONTRACT_OWNER_PRIVATE_KEY "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"')

# print('\n# Secondary Account')

# print('set -x SECONDARY_ADDRESS "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"')
# print('set -x SECONDARY_PRIVATE_KEY "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"')

print('\n# Vault Deploy')
print('set -x VAULT_OWNER_ADDRESS "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"')
print('set -x VAULT_OWNER_PRIVATE_KEY "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"')


print('\n# Vault Users')
print('set -x DEFAULT_ACCOUNT_ADDRESS "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720"')
print('set -x DEFAULT_ACCOUNT_PRIVATE_KEY "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6"')
print('set -x WBTC_ACCOUNT_ADDRESS "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f"')
print('set -x WBTC_ACCOUNT_PRIVATE_KEY "0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97"')
print('set -x STETH_ACCOUNT_ADDRESS "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955"')
print('set -x STETH_ACCOUNT_PRIVATE_KEY "0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356"')

print('\n# Operators')
print('set -x DEFAULT_OPERATOR_ADDRESS "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"')
print('set -x DEFAULT_OPERATOR_PRIVATE_KEY "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"')
print('set -x WBTC_OPERATOR_ADDRESS "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"')
print('set -x WBTC_OPERATOR_PRIVATE_KEY "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"')
print('set -x STETH_OPERATOR_ADDRESS "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"')
print('set -x STETH_OPERATOR_PRIVATE_KEY "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"')


print('\n# Secondary Operators')
print('set -x DEFAULT_OPERATOR_ADDRESS_SECONDARY "0x90F79bf6EB2c4f870365E785982E1f101E93b906"')
print('set -x DEFAULT_OPERATOR_PRIVATE_KEY_SECONDARY "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"')
print('set -x WBTC_OPERATOR_ADDRESS_SECONDARY "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"')
print('set -x WBTC_OPERATOR_PRIVATE_KEY_SECONDARY "0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"')
print('set -x STETH_OPERATOR_ADDRESS_SECONDARY "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc"')
print('set -x STETH_OPERATOR_PRIVATE_KEY_SECONDARY "0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba"')


print('\n# Symbiotic (Local)')
print(f'set -x NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS "{symbiotic_core["networkMiddlewareService"]}"')
print(f'set -x OPERATOR_REGISTRY_CONTRACT_ADDRESS "{symbiotic_core["operatorRegistry"]}"')
print(f'set -x NETWORK_REGISTRY_CONTRACT_ADDRESS "{symbiotic_core["networkRegistry"]}"')
print(f'set -x OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS "{symbiotic_core["operatorNetworkOptInService"]}"')
print(f'set -x OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS "{symbiotic_core["operatorVaultOptInService"]}"')
print(f'set -x VAULT_FACTORY_CONTRACT_ADDRESS "{symbiotic_core["vaultFactory"]}"')

# Vault Configuration for all tokens
print('\n# Vault Configurations')
print(f'set -x DEFAULT_VAULT_ADDRESS "{vault["defaultVault"]}"')
print(f'set -x DEFAULT_DELEGATOR_ADDRESS "{vault["defaultDelegator"]}"')
print(f'set -x WBTC_VAULT_ADDRESS "{vault["wBTCVault"]}"')
print(f'set -x WBTC_DELEGATOR_ADDRESS "{vault["wBTCDelegator"]}"')
print(f'set -x STETH_VAULT_ADDRESS "{vault["stETHVault"]}"')
print(f'set -x STETH_DELEGATOR_ADDRESS "{vault["stETHDelegator"]}"')

print('\n# Liveness')
print(f'set -x LIVENESS_CONTRACT_ADDRESS "{liveness_service_manager["livenessServiceManager"]}"')



print('\n# Rollup')
print(f'set -x VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "{validation_manager["validationServiceManager"]}"')

print('\n# Operator')
print('set -x OPERATOR_ADDRESS "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"')
print('set -x OPERATOR_PRIVATE_KEY "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"')
print('set -x OPERATING_ADDRESS "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"')
print('set -x OPERATING_PRIVATE_KEY "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"')

print('\n# Collateral')
print('set -x COLLATERAL_OWNER_ADDRESS "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"')
print('set -x COLLATERAL_OWNER_PRIVATE_KEY "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"')


# Collateral Configuration for all tokens
print('\n# Collateral Configurations')
print(f'set -x DEFAULT_TOKEN_ADDRESS "{collateral["radiusTestERC20"]}"')
print(f'set -x DEFAULT_COLLATERAL_ADDRESS "{collateral["defaultCollateral"]}"')
print(f'set -x WBTC_TOKEN_ADDRESS "{collateral["wBTCTestERC20"]}"')
print(f'set -x WBTC_COLLATERAL_ADDRESS "{collateral["wBTCCollateral"]}"')
print(f'set -x STETH_TOKEN_ADDRESS "{collateral["stETHTestERC20"]}"')
print(f'set -x STETH_COLLATERAL_ADDRESS "{collateral["stETHCollateral"]}"')


print('\n# Rollups')


print('set -x CLUSTER_ID radius')
print('set -x MAX_SEQUENCER_NUMBER 30')
print('set -x ROLLUP_ID rollup_id_2')
print('set -x OWNER_ADDRESS 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266')
print('set -x ROLLUP_TYPE polygon_cdk')
print('set -x ENCRYPTED_TRANSACTION_TYPE skde')
print('set -x PLATFORM ethereum')
print('set -x SERVICE_PROVIDER radius')
print('set -x ORDER_COMMITMENT_TYPE sign')
print('set -x EXECUTOR_ADDRESS 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266')

print(f'set -x VALIDATION_ADDRESS "{validation_manager["validationServiceManager"]}"')



print('\n# Rewards')
print(f'set -x REWARDS_CORE_ADDRESS "{rewards_core["rewardsCore"]}"')

print('\n# Default Operator Rewards')
print(f'set -x DEFAULT_OPERATOR_REWARDS "{operator_rewards["defaultOperatorReward"]}"')
print(f'set -x STETH_OPERATOR_REWARDS "{operator_rewards["stETHOperatorReward"]}"')
print(f'set -x WBTC_OPERATOR_REWARDS "{operator_rewards["wBTCOperatorReward"]}"')


print('\n# Default Staker Rewards')
print(f'set -x DEFAULT_STAKER_REWARDS "{staker_rewards["defaultStakerReward"]}"')
print(f'set -x STETH_STAKER_REWARDS "{staker_rewards["stETHStakerReward"]}"')
print(f'set -x WBTC_STAKER_REWARDS "{staker_rewards["wBTCStakerReward"]}"')

print('set -x CLUSTER_ID "radius"')
print('set -x ROLLUP_ID "rollup_id_2"')
print(f'set -x REWARD_TOKEN_ADDRESS "{collateral["defaultCollateral"]}"')

print('set -x REWARD_RATE 1000')
print('set -x MIN_STAKE_REQUIRED 100')
print('set -x DISTRIBUTION_INTERVAL 86400')


print('\n# SIMULATION')
# print(f'set -x SIMULATION "{simulation["simulation"]}"')


