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
liveness_radius = read_json_file('../latest-state/31337/liveness_radius_deployment_output.json')['addresses']
rewards_core = read_json_file('../latest-state/31337/rewards_core_deployment_output.json')['addresses']
operator_rewards = read_json_file('../latest-state/31337/operator_reward_deployment_output.json')['addresses']
staker_rewards = read_json_file('../latest-state/31337/staker_reward_deployment_output.json')['addresses']
# simulation = read_json_file('../latest-state/31337/simulation_deployment_output.json')['addresses']

# Base Configuration
print('set -x RPC_URL "http://127.0.0.1:8545"')

print('\n# Rollup side')
print('set -x NETWORK_ADDRESS "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"')
print('set -x NETWORK_PRIVATE_KEY "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"')
print('set -x SUBNETWORK "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266000000000000000000000000"')

print('\n# Secondary Account')

print('set -x SECONDARY_ADDRESS "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"')
print('set -x SECONDARY_PRIVATE_KEY "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"')

print('\n# Vault Deploy')
print('set -x VAULT_OWNER_ADDRESS "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"')
print('set -x VAULT_OWNER_PRIVATE_KEY "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"')

print('\n# Symbiotic (Local)')
print(f'set -x NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS "{symbiotic_core["networkMiddlewareService"]}"')
print(f'set -x OPERATOR_REGISTRY_CONTRACT_ADDRESS "{symbiotic_core["operatorRegistry"]}"')
print(f'set -x NETWORK_REGISTRY_CONTRACT_ADDRESS "{symbiotic_core["networkRegistry"]}"')
print(f'set -x OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS "{symbiotic_core["operatorNetworkOptInService"]}"')
print(f'set -x OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS "{symbiotic_core["operatorVaultOptInService"]}"')
print(f'set -x VAULT_FACTORY_CONTRACT_ADDRESS "{symbiotic_core["vaultFactory"]}"')

print('\n# Vault')
print(f'set -x VAULT_CONTRACT_ADDRESS "{vault["vault"]}"')
print(f'set -x DELEGATOR_CONTRACT_ADDRESS "{vault["delegator"]}"')

print('\n# Radius')
print(f'set -x LIVENESS_CONTRACT_ADDRESS "{liveness_radius["livenessRadius"]}"')



print('\n# Rollup')
print(f'set -x VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "{validation_manager["validationServiceManager"]}"')

print('\n# Operator')
print('set -x OPERATOR_ADDRESS "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"')
print('set -x OPERATOR_PRIVATE_KEY "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"')
print('set -x OPERATING_ADDRESS "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"')
print('set -x OPERATING_PRIVATE_KEY "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"')

print('\n# Collateral')
print('set -x TOKEN_CONTRACT_OWNER_ADDRESS "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"')
print('set -x TOKEN_CONTRACT_OWNER_PRIVATE_KEY "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"')
print(f'set -x TOKEN_CONTRACT_ADDRESS "{collateral["radiusTestERC20"]}"')
print('set -x COLLATERAL_OWNER_ADDRESS "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"')
print('set -x COLLATERAL_OWNER_PRIVATE_KEY "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"')
print(f'set -x COLLATERAL_CONTRACT_ADDRESS "{collateral["defaultCollateral"]}"')


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
print(f'set -x DEFAULT_OPERATOR_REWARDS "{operator_rewards["operatorReward"]}"')


print('\n# Default Staker Rewards')
print(f'set -x DEFAULT_STAKER_REWARDS "{staker_rewards["stakerReward"]}"')

print('set -x CLUSTER_ID "radius"')
print('set -x ROLLUP_ID "rollup_id_2"')
print(f'set -x REWARD_TOKEN_ADDRESS "{collateral["radiusTestERC20"]}"')

print('set -x REWARD_RATE 1000')
print('set -x MIN_STAKE_REQUIRED 100')
print('set -x DISTRIBUTION_INTERVAL 86400')


print('\n# SIMULATION')
# print(f'set -x SIMULATION "{simulation["simulation"]}"')


