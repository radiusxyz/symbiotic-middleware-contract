RPC_URL=http://127.0.0.1:8545
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
OPERATOR_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

TEST_ERC20_CONTRACT_ADDRESS=0x59b670e9fA9D0A427751Af201D676719a970857b
COLLATERAL_CONTRACT_ADDRESS=0x0665FbB86a3acECa91Df68388EC4BBE11556DDce

VAULT_CONTRACT_ADDRESS=0xD705344cBdD83a0d28E86783AA836F4b8Ff8fdD9
DELEGATOR_CONTRACT_ADDRESS=0x799A1524DfA6084803934F927d2C3F8Ff6F3E4B6

NETWORK_OPTIN_SERVICE_CONTRACT_ADDRESS=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
NETWORK_ADDRESS=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
SUBNETWORK=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266000000000000000000000000

VAULT_OPTIN_SERVICE_CONTRACT_ADDRESS=""

cast send 0x010F5B294C54b8A5A53B10694C31CDB50Ab4C857 --rpc-url $RPC_URL --private-key $PRIVATE_KEY --value 1000000000000000000
cast send 0xD19c3705A7e5143c8a80Fdb2d7e90ED537521764 --rpc-url $RPC_URL --private-key $PRIVATE_KEY --value 1000000000000000000

cast chain-id --rpc-url $RPC_URL

# eth_chainId
# anvil_metadata
# eth_blockNumber
# eth_call

# ERC20 - 사용 승인 (operator -> collateral)
cast send $TEST_ERC20_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"approve(address,uint256)" $COLLATERAL_CONTRACT_ADDRESS 1000

# Collateral - deposit - ERC20을 collateral에 예치
cast send $COLLATERAL_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"deposit(address recipient, uint256 amount) (uint256)" $OPERATOR_ADDRESS 100

# Collateral - balanceOf - operator의 잔액 확인
cast call $COLLATERAL_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"balanceOf(address)(uint256)" $OPERATOR_ADDRESS

# Collateral - 사용 승인 (operator -> vault)
cast send $COLLATERAL_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"approve(address,uint256)" $VAULT_CONTRACT_ADDRESS 100

# Vault - deposit - Collateral에서 받은 ERC20을 Vault에 예치
cast send $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"deposit(address onBehalfOf, uint256 amount)(uint256 depositedAmount, uint256 mintedShares)" $OPERATOR_ADDRESS 100

# 총 Staking양 확인
cast call $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL "totalStake()(uint256)"

# Active Staking양 확인
cast call $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL "activeStake()(uint256)"

################################################################################

# Delegator 함수
# Subnetwork의 최대 네트워크 제한 설정
cast send $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"setMaxNetworkLimit(uint96 identifier, uint256 amount)" 0 100 

# Subnetwork의 최대 네트워크 제한 확인
cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"maxNetworkLimit(bytes32 subnetwork)(uint256)" $SUBNETWORK

# Subnetwork의 네트워크 제한 설정
cast send $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"setNetworkLimit(bytes32 subnetwork, uint256 amount)" $SUBNETWORK 10

# Subnetwork의 네트워크 제한 확인
cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"networkLimit(bytes32 subnetwork)(uint256)" $SUBNETWORK

# NetworkDelegation - Subnetwork에 Operator share 설정
cast send $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"setOperatorNetworkShares(bytes32 subnetwork, address operator, uint256 shares)" $SUBNETWORK $OPERATOR_ADDRESS 10

# Subnetwork에 Operator share 확인
cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL "operatorNetworkShares(bytes32 subnetwork, address operator)(uint256)" $SUBNETWORK $OPERATOR_ADDRESS

# Subnetwork에 총 share 확인
cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL "totalOperatorNetworkShares(bytes32 subnetwork)(uint256)" $SUBNETWORK

# Staking양 확인
cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"stake(bytes32 subnetwork, address operator)(uint256)" $SUBNETWORK $OPERATOR_ADDRESS

# OPERATOR_VAULT_OPT_IN_SERVICE 주소 확인 
cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"OPERATOR_VAULT_OPT_IN_SERVICE()(address)"

#################
OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS=0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6
VAULT_ADDRESS=0x9978Efc2A9e4Ce47C08DC76095783C9ca4f4dB7D
cast call $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"isOptedIn(address who, address where)(bool)" $OPERATOR_ADDRESS $VAULT_ADDRESS

cast call $NETWORK_OPTIN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"isOptedIn(address who, address where)(bool)" $OPERATOR_ADDRESS $NETWORK_ADDRESS

cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL "totalOperatorNetworkShares(bytes32 subnetwork)(uint256)" $SUBNETWORK

cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL "operatorNetworkShares(bytes32 subnetwork, address operator)(uint256)" $SUBNETWORK $OPERATOR_ADDRESS

cast call $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL "activeStake()(uint256)"

cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"networkLimit(bytes32 subnetwork)(uint256)" $SUBNETWORK

## Full에만 있는 함수
cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"operatorNetworkLimit(bytes32 subnetwork, address operator)(uint256)" $SUBNETWORK $OPERATOR_ADDRESS
#################

# isOptedIn
cast call $DELEGATOR_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"stakeAt(bytes32 subnetwork, address operator, uint48 timestamp, bytes memory hints)(uint256)" $SUBNETWORK $OPERATOR_ADDRESS 1728840904 "0x"

# depositWhitelist 설정
cast send $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"setDepositWhitelist(bool status)" true
cast call $VAULT_CONTRACT_ADDRESS "depositWhitelist()(bool)" --rpc-url $RPC_URL

cast call $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"isDepositorWhitelisted(address)(bool)" $OPERATOR_ADDRESS

cast send $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"setDepositorWhitelistStatus(address account, bool status)" $OPERATOR_ADDRESS true

cast send $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"deposit(address onBehalfOf, uint256 amount)(uint256 depositedAmount, uint256 mintedShares)" $OPERATOR_ADDRESS 10

# Check list 작성
# ------------------------
# 1. 너네가 돌려봐라 
# 2. 우리가 테스트 해줄게
# ------------------------

# ------------------------
# 끌만이 테스트한번 해볼것
# 하고싶은 방향에서 테스트 해볼것 
# ------------------------

# ------------------------
# ERC20 토큰 전송 테스트 (컨트랙트 배포)
# 실행 명령어
# ------------------------

# ------------------------
# CDK에서 프로포절에 PR 작성
# PR은 릴리즈 연말
# ------------------------

setSlasher(address slasher)
setDelegator(address delegator)
setDepositLimit(uint256 limit)
setIsDepositLimit(bool status)
setDepositWhitelist(bool status)
setDepositorWhitelistStatus(address account, bool status)

#####################################

cast call 0x592c09083aa3e1edfb393c6dc0b59e70b378af36 --rpc-url "https://holesky.infura.io/v3/45ea6e32af764f3cb6df2c21240b0ff1" \
"getCurrentEpoch() (uint256)"

cast call 0x592c09083aa3e1edfb393c6dc0b59e70b378af36 --rpc-url "https://holesky.infura.io/v3/45ea6e32af764f3cb6df2c21240b0ff1" \
"getTotalStake(uint256)(uint256)" 465323

cast call 0x592c09083aa3e1edfb393c6dc0b59e70b378af36 --rpc-url "https://holesky.infura.io/v3/45ea6e32af764f3cb6df2c21240b0ff1" \
"getOperatorStake(address operator, uint48 epoch)(uint256)" 0x55aE254C7bDbb7C17F6B158c7FA8653FB845eC3D 465323

cast call $VAULT_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"delegator()(address)"

