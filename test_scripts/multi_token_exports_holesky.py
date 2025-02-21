#!/usr/bin/env python3
import json

def read_json_file(filename):
    with open(filename, 'r') as f:
        return json.load(f)

# Read all deployment files
symbiotic_core = read_json_file('../latest-state/17000/symbiotic_core_deployment_output.json')['addresses']
validation_manager = read_json_file('../latest-state/17000/validation_service_manager_deployment_output.json')['addresses']
vault = read_json_file('../latest-state/17000/vault_deployment_output.json')['addresses']
collateral = read_json_file('../latest-state/17000/collateral_deployment_output.json')['addresses']
liveness_service_manager = read_json_file('../latest-state/17000/liveness_service_manager_deployment_output.json')['addresses']
rewards_core = read_json_file('../latest-state/17000/rewards_core_deployment_output.json')['addresses']
operator_rewards = read_json_file('../latest-state/17000/operator_reward_deployment_output.json')['addresses']
staker_rewards = read_json_file('../latest-state/17000/staker_reward_deployment_output.json')['addresses']
# simulation = read_json_file('../latest-state/17000/simulation_deployment_output.json')['addresses']

# Base Configuration
print('set -x RPC_URL "https://ethereum-holesky-rpc.publicnode.com"')

print('\n# Rollup side')
print('\n# Network Configuration')
print('set -x NETWORK_ADDRESS "0xdF14d78165Ae80AB2D6E30361426672cDc4b9315"')
print('set -x NETWORK_PRIVATE_KEY "44dd0d02357e07e05d07fb1a7a378b60c67edb95a08e875a6eed5f562f0d99d2"')
print('set -x PRIVATE_KEY "44dd0d02357e07e05d07fb1a7a378b60c67edb95a08e875a6eed5f562f0d99d2"')
print('set -x SUBNETWORK "0xdF14d78165Ae80AB2D6E30361426672cDc4b9315000000000000000000000000"')



print('\n# Token Contract Owner')
print('set -x TOKEN_CONTRACT_OWNER_ADDRESS "0xdF14d78165Ae80AB2D6E30361426672cDc4b9315"')
print('set -x TOKEN_CONTRACT_OWNER_PRIVATE_KEY "44dd0d02357e07e05d07fb1a7a378b60c67edb95a08e875a6eed5f562f0d99d2"')

# print('\n# Secondary Account')

# print('set -x SECONDARY_ADDRESS "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"')
# print('set -x SECONDARY_PRIVATE_KEY "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"')

print('\n# Vault Deploy')
print('set -x VAULT_OWNER_ADDRESS "0xdF14d78165Ae80AB2D6E30361426672cDc4b9315"')
print('set -x VAULT_OWNER_PRIVATE_KEY "44dd0d02357e07e05d07fb1a7a378b60c67edb95a08e875a6eed5f562f0d99d2"')


print('\n# Vault Users')
print('set -x DEFAULT_ACCOUNT_ADDRESS "0xB81C718d9d21421f079b2189F0af518661a71269"')
print('set -x DEFAULT_ACCOUNT_PRIVATE_KEY "513ecf8adc9dfd9fe310c66bc4ab2f04957913308d5c1a93c793d83d0e0dc0ca"')

print('set -x WBTC_ACCOUNT_ADDRESS "0xb2986ee904EB1DcE397aBcAC7f5f969156A15F34"')
print('set -x WBTC_ACCOUNT_PRIVATE_KEY "36a177ab248c82582fadbd26d8bd9247cc3e7027e371fb10f9ff794256bd042e"')


print('set -x STETH_ACCOUNT_ADDRESS "0x3FD9F10AF11Adf67E0D314Da4824f14cc1DcDe88"')
print('set -x STETH_ACCOUNT_PRIVATE_KEY "7b1548d98ee19d8db330ab4076764bdddbb9108999c3ef947ea9786c8d931603"')

print('\n# Operators')
print('set -x DEFAULT_OPERATOR_ADDRESS "0x13a8800770f81731F45E7b33D6761FD6f08A70f7"')
print('set -x DEFAULT_OPERATOR_PRIVATE_KEY "db0c6a5434b847d166c26e292b475b0cef3771a039bd122cfaed810052a670cd"')


print('set -x WBTC_OPERATOR_ADDRESS "0x5D51044C4cB62280EF1700F2E7378e1198648a52"')
print('set -x WBTC_OPERATOR_PRIVATE_KEY "dcea3248b6b2798e70d553cd5b97152043ec94fd58f8e707338fa317eb68fe10"')


print('set -x STETH_OPERATOR_ADDRESS "0xc6bA578acFF1eA914A6a727b2F20776eB4ad61EE"')
print('set -x STETH_OPERATOR_PRIVATE_KEY "b0de8eb532b742fb5fb2e84f78322b846569ddbd8920a68e6054d1c44a1a46db"')


print('\n# Secondary Operators')
print('set -x DEFAULT_OPERATOR_ADDRESS_SECONDARY "0xe77334f0c42BEA8749BE240DE26536127afeC9cf"')
print('set -x DEFAULT_OPERATOR_PRIVATE_KEY_SECONDARY "e32626a7358038e888d596ac8da5a034dcf211cda0f77b59b78967f8433dc3c5"')


print('set -x WBTC_OPERATOR_ADDRESS_SECONDARY "0xFf86a44c0c3e73636a8Da7eA272E80f1B87E843a"')
print('set -x WBTC_OPERATOR_PRIVATE_KEY_SECONDARY "361362fd4ae9e514d86f2b1b9246ec4f7cc605a36728dbffcb50a73917879b4c"')


print('set -x STETH_OPERATOR_ADDRESS_SECONDARY "0x50D1ed3FfaD13a1af7D0E1Cfa02461985b4e500f"')
print('set -x STETH_OPERATOR_PRIVATE_KEY_SECONDARY "8378ddbe96f368370340e299fd82244ca7c095ada5f1ea27ccc2481d8516a18d"')


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
print('set -x OPERATOR_ADDRESS "0xdF14d78165Ae80AB2D6E30361426672cDc4b9315"')
print('set -x OPERATOR_PRIVATE_KEY "44dd0d02357e07e05d07fb1a7a378b60c67edb95a08e875a6eed5f562f0d99d2"')
print('set -x OPERATING_ADDRESS "0xdF14d78165Ae80AB2D6E30361426672cDc4b9315"')
print('set -x OPERATING_PRIVATE_KEY "44dd0d02357e07e05d07fb1a7a378b60c67edb95a08e875a6eed5f562f0d99d2"')

print('\n# Collateral')
print('set -x COLLATERAL_OWNER_ADDRESS "0xdF14d78165Ae80AB2D6E30361426672cDc4b9315"')
print('set -x COLLATERAL_OWNER_PRIVATE_KEY "44dd0d02357e07e05d07fb1a7a378b60c67edb95a08e875a6eed5f562f0d99d2"')


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
print('set -x OWNER_ADDRESS 0xdF14d78165Ae80AB2D6E30361426672cDc4b9315')
print('set -x ROLLUP_TYPE polygon_cdk')
print('set -x ENCRYPTED_TRANSACTION_TYPE skde')
print('set -x PLATFORM ethereum')
print('set -x SERVICE_PROVIDER radius')
print('set -x ORDER_COMMITMENT_TYPE sign')
print('set -x EXECUTOR_ADDRESS 0xdF14d78165Ae80AB2D6E30361426672cDc4b9315')

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


