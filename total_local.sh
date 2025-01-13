RPC_URL="http://127.0.0.1:8545"

# Rollup side 
NETWORK_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
NETWORK_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
SUBNETWORK=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266000000000000000000000000

# Vault Deploy (For testing)
VAULT_OWNER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
VAULT_OWNER_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

####### Symbiotic (Local) 
NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS="0xa513E6E4b8f2a923D98304ec87F64353C4D5C853"
OPERATOR_REGISTRY_CONTRACT_ADDRESS="0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9"
NETWORK_REGISTRY_CONTRACT_ADDRESS="0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"
OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS="0x8A791620dd6260079BF849Dc5567aDC3F2FdC318"
OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS="0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6"
VAULT_FACTORY_CONTRACT_ADDRESS="0x5FbDB2315678afecb367f032d93F642f64180aa3"
#######

####### Vault
VAULT_CONTRACT_ADDRESS="0x7C79BE2454128557c341a96e5C6b92815b65E98E"
DELEGATOR_CONTRACT_ADDRESS="0xFF1F4c11A96775b0fba0bA0643B732f765bE9591"
#######

####### Radius
LIVENESS_CONTRACT_ADDRESS="0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB"
#######

####### Rollup
VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS="0xc3e53F4d16Ae77Db1c982e75a937B9f60FE63690"
#######

####### Operator
OPERATOR_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
OPERATOR_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
OPERATING_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
OPERATING_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
#######

####### Collateral
TOKEN_CONTRACT_OWNER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
TOKEN_CONTRACT_OWNER_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
TOKEN_CONTRACT_ADDRESS="0x59b670e9fA9D0A427751Af201D676719a970857b"

COLLATERAL_OWNER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
COLLATERAL_OWNER_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
COLLATERAL_CONTRACT_ADDRESS="0x0665FbB86a3acECa91Df68388EC4BBE11556DDce"
#######

# Vault Delegator check (number 1)
cast call $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"delegator()(address)"

# total Staking check (number 2)
cast call $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL "totalStake()(uint256)"
cast call $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL "activeStake()(uint256)"
####################
cast send $TOKEN_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $COLLATERAL_CONTRACT_ADDRESS 1000

cast send $COLLATERAL_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $COLLATERAL_OWNER_PRIVATE_KEY \
"deposit(address recipient, uint256 amount)(uint256)" $TOKEN_CONTRACT_OWNER_ADDRESS 1000

cast send $COLLATERAL_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"approve(address spender, uint256 value)(bool)" $VAULT_CONTRACT_ADDRESS 100

cast send $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"deposit(address onBehalfOf, uint256 amount)(uint256 depositedAmount, uint256 mintedShares)" $TOKEN_CONTRACT_OWNER_ADDRESS 100
#####################

# Operator register check (number 3)
cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address who)(bool)" $OPERATOR_ADDRESS
#####################
cast send $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $OPERATOR_PRIVATE_KEY \
"registerOperator()"
#####################

# Network register check (number 4)
cast call $NETWORK_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address who)(bool)" $NETWORK_ADDRESS
#####################
cast send $NETWORK_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerNetwork()"
#####################

# Middleware가 등록되었는지 check(5번)
cast call $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"middleware(address networkAddress)(address middlewareAddress)" $NETWORK_ADDRESS
#####################
cast send $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"setMiddleware(address middlewareAddress)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS
#####################

# Operator가 network에 Optin 되었는지 check (6번)
cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address who, address where)(bool)" $OPERATOR_ADDRESS $NETWORK_ADDRESS
#####################
cast send $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $OPERATOR_PRIVATE_KEY \
"optIn(address network)" $NETWORK_ADDRESS
#####################

# Operator가 vault에 Optin 되었는지 check (7번)
cast call $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isOptedIn(address who, address where)(bool)" $OPERATOR_ADDRESS $VAULT_CONTRACT_ADDRESS
#####################
cast send $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $OPERATOR_PRIVATE_KEY \
"optIn(address vault)" $VAULT_CONTRACT_ADDRESS
#####################

# Vault가 register 되었는지 check (8번)
cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"vaultLen()(uint256)" 
cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getCurrentVaults()(address[])" 
cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isActiveVault(address vault)(bool)" $VAULT_CONTRACT_ADDRESS
#####################
cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerToken(address tokenAddress)" $TOKEN_CONTRACT_ADDRESS

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerVault(address vaultAddress)" $VAULT_CONTRACT_ADDRESS
#####################

# Operator가 register 되었는지 check (9번)
cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getCurrentOperatorInfos()((address, address, (address, uint256)[], uint256)[])"
#####################
cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerOperator(address operatorAddress, address operatingAddress)" $OPERATOR_ADDRESS $OPERATING_ADDRESS
#####################

# MaxNetworkLimit check (10번)
cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"maxNetworkLimit(bytes32 subnetwork)(uint256 maxNetworkLimit)" $SUBNETWORK
#####################
cast send $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"setMaxNetworkLimit(uint96 identifier, uint256 amount)" 0 10000
#####################

# networkLimit check (11번)
cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"networkLimit(bytes32 subnetwork)(uint256 networkLimit)" $SUBNETWORK
#####################
cast send $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setNetworkLimit(bytes32 subnetwork, uint256 amount)" $SUBNETWORK 30
#####################

# (12번)
cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"operatorNetworkShares(bytes32 subnetwork, address operator)(uint256)" $SUBNETWORK $OPERATOR_ADDRESS
cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"totalOperatorNetworkShares(bytes32 subnetwork)(uint256)" $SUBNETWORK
cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"stake(bytes32 subnetwork, address operator)(uint256)" $SUBNETWORK $OPERATOR_ADDRESS
#####################
cast send $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $VAULT_OWNER_PRIVATE_KEY \
"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)" $SUBNETWORK $OPERATOR_ADDRESS 100
#####################
####################################################################################
cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getCurrentTotalStake()(uint256)"
cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getCurrentTokenTotalStake(address token)(uint256)" $TOKEN_CONTRACT_ADDRESS
cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getCurrentOperatorStake(address operator)(uint256)" $OPERATOR_ADDRESS
cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getCurrentOperatorEachStakeInfo(address operator)((address, uint256)[])" $OPERATOR_ADDRESS
cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getCurrentOperatorStakeInfo(address operator, address token)(uint256)" $OPERATOR_ADDRESS $TOKEN_CONTRACT_ADDRESS
####################################################################################

#####################################################################################
# initializeCluster (13번)
CLUSTER_ID="radius"
MAX_SEQUENCER_NUMBER=30

ROLLUP_ID="rollup_id"
OWNER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
ROLLUP_TYPE="polygon_cdk"
ENCRYPTED_TRANSACTION_TYPE="skde"
PLATFORM="ethereum"
SERVICE_PROVIDER="symbiotic"
VALIDATION_ADDRESS=$VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS
ORDER_COMMITMENT_TYPE="sign"
EXECUTOR_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getClustersByOwner(address owner)(string[])" $NETWORK_ADDRESS
#####################
cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"initializeCluster(string clusterId, uint256 maxSequencerNumber)" $CLUSTER_ID $MAX_SEQUENCER_NUMBER
#####################

# addRollup (14번)
cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getRollupInfo(string clusterId, string rollupId)((string,address,string,string,string,address[],(string,string,address)))" $CLUSTER_ID $ROLLUP_ID
#####################
cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"addRollup(string,(string,address,string,string,string,address,(string,string,address)))" \
"$CLUSTER_ID" "($ROLLUP_ID, $OWNER_ADDRESS, $ROLLUP_TYPE, $ENCRYPTED_TRANSACTION_TYPE, $ORDER_COMMITMENT_TYPE, $EXECUTOR_ADDRESS, ($PLATFORM, $SERVICE_PROVIDER, $VALIDATION_ADDRESS))"
#####################

##################### Register executor #####################
cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getExecutorList(string clusterId, string rollupId)(address[])" $CLUSTER_ID $ROLLUP_ID
cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isRegisteredRollupExecutor(string clusterId, string rollupId, address executorAddress)(bool)" $CLUSTER_ID $ROLLUP_ID $EXECUTOR_ADDRESS
#####################
cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerRollupExecutor(string clusterId, string rollupId, address executorAddress)" $CLUSTER_ID $ROLLUP_ID $EXECUTOR_ADDRESS
#####################
#############################################################

# registerSequencer (14번)
cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"getSequencerList(string clusterId)(address[] memory)" $CLUSTER_ID
#####################
cast send $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $OPERATING_PRIVATE_KEY \
"registerSequencer(string clusterId)" $CLUSTER_ID
#####################

#########################################################################################################################################

################## Testing ##################
forge script script/deploy/LivenessRadiusDeployer.sol:LivenessRadiusDeployer --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY --broadcast -vvvv
cast send 0x4c5859f0F772848b2D91F1D83E2Fe57935348029 --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"initializeCluster(string clusterId, uint256 maxSequencerNumber)" $CLUSTER_ID $MAX_SEQUENCER_NUMBER
cast call 0x4c5859f0F772848b2D91F1D83E2Fe57935348029 --rpc-url $RPC_URL \
"getClustersByOwner(address owner)(string[])" $NETWORK_ADDRESS
cast send 0x4c5859f0F772848b2D91F1D83E2Fe57935348029 --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"addRollup(string,(string,address,string,string,string,address,(string,string,address)))" \
"$CLUSTER_ID" "($ROLLUP_ID, $OWNER_ADDRESS, $ROLLUP_TYPE, $ENCRYPTED_TRANSACTION_TYPE, $ORDER_COMMITMENT_TYPE, $EXECUTOR_ADDRESS, ($PLATFORM, $SERVICE_PROVIDER, $VALIDATION_ADDRESS))"
cast call 0x4c5859f0F772848b2D91F1D83E2Fe57935348029 --rpc-url $RPC_URL \
"getRollupInfo(string clusterId, string rollupId)((string,address,string,string,string,address[],(string,string,address)))" $CLUSTER_ID $ROLLUP_ID
############################################

#########################################################################################################################################

##########
RPC_URL="https://ethereum-holesky-rpc.publicnode.com"
VAULT_CONTRACT_ADDRESS="0x87Fb558A19ac2954546Bf4A7aE013751afd60265"
VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS="0xB52B38186107C473779805C41a0e9B23df8f25Fb"
NETWORK_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
OPERATOR_ADDRESS="0x010F5B294C54b8A5A53B10694C31CDB50Ab4C857" 
OPERATING_ADDRESS="0x65018cBDB7C496D9a404C7fCB80ee77825daAB34"

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"registerOperator(address operatorAddress, address operatingAddress)" $OPERATOR_ADDRESS $OPERATING_ADDRESS

#################
# Vault register check
cast call $VAULT_FACTORY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isEntity(address who)(bool)" $VAULT_CONTRACT_ADDRESS
#####################
cast send $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY \
"deposit(address onBehalfOf, uint256 amount)(uint256 depositedAmount, uint256 mintedShares)" $TOKEN_CONTRACT_OWNER_ADDRESS 100
#####################
cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"SLASHING_WINDOW()(uint48)"
cast call $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"epochDuration()(uint48)"
cast call $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"slasher()(address)"


##################################################
forge script script/deploy/VaultHoleskyDeploy.sol:VaultHoleskyDeploy --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY --broadcast -vvvv
##################################################