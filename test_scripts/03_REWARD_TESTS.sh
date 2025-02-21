########################################################################################
# Rewards Test Commands
# Sequence: addRewardPoolConfig, Token Approve, depositRewards
# Secondary Functions: addWhitelistedDepositor, Transfer token to secondary account, Token Approve, depositRewards
# WIP: Emergency Withdrawal, Distribution
cast send $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"setMiddleware(address middlewareAddress)" $REWARD_SYSTEM_ADDRESS


cast send $REWARD_SYSTEM_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"addRewardPoolConfig(string,string,address,uint256,uint256,uint256,uint256,uint256)" $CLUSTER_ID $ROLLUP_ID $TOKEN_CONTRACT_ADDRESS 100 10000 10 70 30

cast send $TOKEN_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"approve(address,uint256)" $REWARD_SYSTEM_ADDRESS 1000000

cast send $REWARD_SYSTEM_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"depositRewards(string,string,uint256)" $CLUSTER_ID $ROLLUP_ID 1000000

cast send $REWARD_SYSTEM_ADDRESS "distributeRewards(string,string,bytes32,uint48,bytes,bytes,uint256)" $CLUSTER_ID $ROLLUP_ID 0xa6990e50b43e0c4966db704a0a6390be1c258b89afdd4ae4a02ac141771f5120 1702483200 0x0001 0x0001 100 --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY


# 1. Check current root
cast call $DEFAULT_OPERATOR_REWARDS "root(address,address)(bytes32)" \
    $REWARD_SYSTEM_ADDRESS \
    $TOKEN_CONTRACT_ADDRESS

# 2. Check current balance
cast call $DEFAULT_OPERATOR_REWARDS "balance(address,address)(uint256)" \
    $REWARD_SYSTEM_ADDRESS \
    $TOKEN_CONTRACT_ADDRESS

# 3. Check claimed amount
cast call $DEFAULT_OPERATOR_REWARDS "claimed(address,address,address)(uint256)" \
    $REWARD_SYSTEM_ADDRESS \
    $TOKEN_CONTRACT_ADDRESS \
    0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266



  address recipient,
        address network,
        address token,
        uint256 totalClaimable,


cast send $DEFAULT_OPERATOR_REWARDS "claimRewards(address,address,address,uint256,bytes32[])" \
    0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
    $NETWORK_ADDRESS \
    $TOKEN_CONTRACT_ADDRESS \
    700000 \
    "[]" \
    --rpc-url $RPC_URL \
    --private-key $OPERATING_PRIVATE_KEY



# Query Token Balances
cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $SECONDARY_ADDRESS
cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $REWARDS_CORE_ADDRESS
cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $NETWORK_ADDRESS
cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $DEFAULT_OPERATOR_REWARDS

# Get reward pool balance
cast call $REWARDS_CORE_ADDRESS --rpc-url $RPC_URL \
"getRewardPoolBalance(string,string)(uint256)" $CLUSTER_ID $ROLLUP_ID

# Get reward pool config
cast call $REWARDS_CORE_ADDRESS --rpc-url $RPC_URL \
"getRewardPoolConfig(string,string)((address,uint256,uint256,uint256,bool))" $CLUSTER_ID $ROLLUP_ID

# Get whitelisted depositors
cast call $REWARDS_CORE_ADDRESS --rpc-url $RPC_URL \
"getWhitelistedDepositors(string,string)(address[])" $CLUSTER_ID $ROLLUP_ID

# Get default operator rewards address
cast call $REWARDS_CORE_ADDRESS --rpc-url $RPC_URL \
"DEFAULT_OPERATOR_REWARDS()(address)"

# Get default staker rewards address
cast call $REWARD_SYSTEM_ADDRESS --rpc-url $RPC_URL \
"DEFAULT_STAKER_REWARDS()(address)"

# Send Tokens to Secondary Account
cast send --private-key $NETWORK_PRIVATE_KEY $TOKEN_CONTRACT_ADDRESS "transfer(address,uint256)" $SECONDARY_ADDRESS 10000

# Token approval for deposits
cast send $TOKEN_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"approve(address,uint256)" $REWARD_SYSTEM_ADDRESS 1000000

cast send $TOKEN_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $SECONDARY_PRIVATE_KEY \
"approve(address,uint256)" $REWARD_SYSTEM_ADDRESS 1000000

# Add reward config (owner only)
cast send $REWARD_SYSTEM_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"addRewardPoolConfig(string,string,address,uint256,uint256,uint256,uint256,uint256)" $CLUSTER_ID $ROLLUP_ID $TOKEN_CONTRACT_ADDRESS 100 10000 10 70 30

# Update reward config (owner only)
cast send $REWARD_SYSTEM_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"updateRewardPoolConfig(string,string,uint256,uint256,uint256)" $CLUSTER_ID $ROLLUP_ID $NEW_OPERATOR_SHARE $NEW_STAKER_SHARE $NEW_MIN_STAKE

# Add whitelisted depositor (whitelisted only)
cast send $REWARD_SYSTEM_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"addWhitelistedDepositor(string,string,address)" $CLUSTER_ID $ROLLUP_ID $SECONDARY_ADDRESS

# Remove whitelisted depositor (whitelisted only)
cast send $REWARD_SYSTEM_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"removeWhitelistedDepositor(string,string,address)" $CLUSTER_ID $ROLLUP_ID $DEPOSITOR_TO_REMOVE

# Deposit rewards (primary)
cast send $REWARD_SYSTEM_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"depositRewards(string,string,uint256)" $CLUSTER_ID $ROLLUP_ID 1000000

# Deposit rewards (secondary)
cast send $REWARD_SYSTEM_ADDRESS --rpc-url $RPC_URL --private-key $SECONDARY_PRIVATE_KEY \
"depositRewards(string,string,uint256)" $CLUSTER_ID $ROLLUP_ID 10000

# Distribute rewards
cast send $REWARD_SYSTEM_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"distributeRewards(string,string,bytes32,uint48,bytes,bytes,uint256)" $CLUSTER_ID $ROLLUP_ID $OPERATOR_MERKLE_ROOT $STAKER_TIMESTAMP $ACTIVE_SHARES_HINT $ACTIVE_STAKE_HINT $MAX_ADMIN_FEE

# Emergency withdraw
cast send $REWARD_SYSTEM_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"emergencyWithdraw(string,string,uint256)" $CLUSTER_ID $ROLLUP_ID $AMOUNT


# Example data
# Let's say we want to distribute rewards where:
# - operator1 can claim 100 tokens (0x1111...1111)
# - operator2 can claim 200 tokens (0x2222...2222)
#
# Merkle tree construction (simplified example):
# leaf1 = keccak256(abi.encode(operator1, 100))
# leaf2 = keccak256(abi.encode(operator2, 200))
# root = keccak256(abi.encodePacked(leaf1, leaf2))

# For this example, we're using a simple case with these values:
# operator1_address = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
# operator1_amount = 700000
# merkle_root = ?

########################################################################################
# Distribute Rewards (called by middleware)
########################################################################################

cast call $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS "middleware(address)(address)" $NETWORK_ADDRESS


cast send $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"setMiddleware(address middlewareAddress)" $REWARD_SYSTEM_ADDRESS


cast send $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"setMiddleware(address middlewareAddress)" $REWARD_SYSTEM_ADDRESS


# First approve tokens
cast send $TOKEN_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"approve(address,uint256)" 0xa63bA08402aF74196569F3442b3a44946Cf149eA 1000

# Then distribute with merkle root
    # function distributeRewards(address network, address token, uint256 amount, bytes32 root_) external nonReentrant {

cast send 0xa63bA08402aF74196569F3442b3a44946Cf149eA --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"distributeRewards(address,address,uint256,bytes32)" $REWARD_SYSTEM_ADDRESS $TOKEN_CONTRACT_ADDRESS 100 0x0c3af26cf4bd766f3a2a565a9ae5991c3cf1530c75214d6876726447860c759d


cast send $REWARD_SYSTEM_ADDRESS "distributeRewards(string,string,bytes32,uint48,bytes,bytes,uint256)" $CLUSTER_ID $ROLLUP_ID 0x0c3af26cf4bd766f3a2a565a9ae5991c3cf1530c75214d6876726447860c759d 1702483200 0x0001 0x0001 100 --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY

1702483200 \
0x0001 \
0x0001 \
100 \

cast call $REWARD_TOKEN_ADDRESS "allowance(address,address)(uint256)" $REWARD_SYSTEM_ADDRESS $DEFAULT_OPERATOR_REWARDS
cast send $REWARD_TOKEN_ADDRESS "approve(address,uint256)" $DEFAULT_OPERATOR_REWARDS 1000000 --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY



cast send $REWARD_SYSTEM_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"distributeRewards(string,string,bytes32,uint48,bytes,bytes,uint256)" $CLUSTER_ID $ROLLUP_ID 0x0c3af26cf4bd766f3a2a565a9ae5991c3cf1530c75214d6876726447860c759d 1734073969 1 1 1

########################################################################################
# Claim Rewards (called by operator)
########################################################################################

# Example proof for operator1 claiming 100 tokens
cast send 0xa63bA08402aF74196569F3442b3a44946Cf149eA --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"claimRewards(address,address,address,uint256,bytes32[])" $OPERATOR_ADDRESS $NETWORK_ADDRESS $TOKEN_ADDRESS 100 "[0x8a3552d60a98e0ade765adddad0a2e420ca9b1eef5f326ba7ab860bb4ea72c95]"

# Query balance after distribution
cast call $DEFAULT_OPERATOR_REWARDS --rpc-url $RPC_URL \
"balance(address,address)(uint256)" $NETWORK_ADDRESS $TOKEN_ADDRESS

# Query claimed amount
cast call $OPERATOR_REWARDS_ADDRESS --rpc-url $RPC_URL \
"claimed(address,address,address)(uint256)" $NETWORK_ADDRESS $TOKEN_ADDRESS $OPERATOR_ADDRESS

# Query current root
cast call $OPERATOR_REWARDS_ADDRESS --rpc-url $RPC_URL \
"root(address,address)(bytes32)" $NETWORK_ADDRESS $TOKEN_ADDRESS

########################################################################################
# Notes:
# 1. The merkle root and proof above are examples - you'll need to generate actual values
#    based on your distribution data
# 2. The proof array can contain multiple hashes for deeper merkle trees
# 3. Make sure the operator's address and amount match what was used to generate the root
########################################################################################


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "distributeRewards(string,string,bytes32,uint48,bytes,bytes,uint256)" $CLUSTER_ID $ROLLUP_ID 0xa6990e50b43e0c4966db704a0a6390be1c258b89afdd4ae4a02ac141771f5120 1702483200 0x0001 0x0001 100 --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY






cast call $DEFAULT_STAKER_REWARDS "rewardsLength(address,address)(uint256)" $REWARD_TOKEN_ADDRESS $REWARD_SYSTEM_ADDRESS
cast call $OPERATOR_REWARDS_ADDRESS "rewardsLength(address,address)(uint256)" $REWARD_TOKEN_ADDRESS $REWARD_SYSTEM_ADDRESS


cast call $DEFAULT_OPERATOR_REWARDS "balance(address,address)(uint256)" $NETWORK_ADDRESS $TOKEN_CONTRACT_ADDRESS



cast call $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
"middleware(address networkAddress)(address middlewareAddress)" $NETWORK_ADDRESS







cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --private-key $NETWORK_PRIVATE_KEY --rpc-url $RPC_URL\
  "distributeRewards(string,string,address,bytes32,uint48,bytes,bytes,uint256)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  $NETWORK_ADDRESS \
  0x287b58b93ed6c17ace087bb87f611bf21102c0602b0956736b6e523fb41c328d \
  1735618467 \
  "0x" "0x" 10000



# address recipient,
#         address network,
#         address token,
#         uint256 totalClaimable,
#         bytes32[] calldata proof

  cast send $DEFAULT_OPERATOR_REWARDS --private-key $OPERATING_PRIVATE_KEY --rpc-url $RPC_URL \
  "claimRewards(address,address,address,uint256,bytes32[])" \
  $OPERATOR_ADDRESS \
  $NETWORK \
  $TOKEN_CONTRACT_ADDRESS \
  10000 \
  []



cast send $DEFAULT_OPERATOR_REWARDS "claimRewards(address,address,address,uint256,bytes32[])" \
$OPERATOR_ADDRESS \
$NETWORK_ADDRESS \
$TOKEN_CONTRACT_ADDRESS \
7000000000000000000 \
"[0x0000000000000000000000000000000000000000000000000000000000000000]" \
--rpc-url $RPC_URL \
--private-key $OPERATING_PRIVATE_KEY



cast send $DEFAULT_OPERATOR_REWARDS "claimRewards(address,address,address,uint256,bytes32[])" \
$SECONDARY_ADDRESS \
$NETWORK_ADDRESS \
$TOKEN_CONTRACT_ADDRESS \
3000000000000000000 \
"[0x9543eb0d43cff4872c9a627d355e02990db82a37882ef80abaca5a7fc41cffc9]" \
--rpc-url $RPC_URL \
--private-key $SECONDARY_PRIVATE_KEY


cast call $DEFAULT_OPERATOR_REWARDS --rpc-url $RPC_URL \
"root(address,address)(bytes32)" $NETWORK_ADDRESS $TOKEN_CONTRACT_ADDRESS

 


cast send $DEFAULT_OPERATOR_REWARDS \
  "claimRewards(address,address,address,uint256,bytes32[])" \
  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  $NETWORK \
  0x59b670e9fA9D0A427751Af201D676719a970857b \
  100000000000000000 \
  []

cast call $REWARDS_CORE_ADDRESS \
"getDistributionInfo(string,string)" \
$CLUSTER_ID $ROLLUP_ID

# 2. Check if the reward pool config exists
cast call $REWARDS_CORE_ADDRESS \
"rewardPoolExists(string,string)" \
$CLUSTER_ID $ROLLUP_ID

# 3. Check the reward pool balance
cast call $REWARDS_CORE_ADDRESS \
"getRewardPoolBalance(string,string)" \
$CLUSTER_ID $ROLLUP_ID


cast call $NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS \
"middleware(address)" \
$NETWORK_ADDRESS


cast call $DEFAULT_OPERATOR_REWARDS --rpc-url $RPC_URL \
"claimed(address,address,address)(uint256)" $NETWORK_ADDRESS $TOKEN_CONTRACT_ADDRESS $OPERATOR_ADDRESS


cast call $DEFAULT_OPERATOR_REWARDS "balance(address,address)(uint256)" \
    $REWARD_SYSTEM_ADDRESS \
    $NETWORK_ADDRESS


    cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $DEFAULT_OPERATOR_REWARDS


 
cast send $SIMULATION --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY "emitPoolCreated(string,string,address)" $CLUSTER_ID $ROLLUP_ID $REWARD_TOKEN_ADDRESS

cast send $SIMULATION --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"emitParticipation(string,string,address,uint256)" $CLUSTER_ID $ROLLUP_ID $OPERATOR_ADDRESS 1

cast send $SIMULATION --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY \
"emitClaimRewards(address,uint256)" $OPERATOR_ADDRESS 10000000000000000000




cast send $DEFAULT_STAKER_REWARDS "claimRewards(address,address,bytes)" \
$TOKEN_CONTRACT_OWNER_ADDRESS \
$TOKEN_CONTRACT_ADDRESS \
$(cast --from-utf8 $(python3 -c "import eth_abi; print('0x' + eth_abi.encode(['address', 'uint256', 'bytes[]'], ['$NETWORK_ADDRESS', 115792089237316195423570985008687907853269984665640564039457584007913129639935, []]).hex())")) \
--rpc-url $RPC_URL \
--private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY

cast send $DEFAULT_STAKER_REWARDS "claimRewards(address,address,bytes)" \
$TOKEN_CONTRACT_OWNER_ADDRESS \
$TOKEN_CONTRACT_ADDRESS \
$(cast abi-encode "f(address,uint256,bytes[])" $NETWORK_ADDRESS 115792089237316195423570985008687907853269984665640564039457584007913129639935 []) \
--rpc-url $RPC_URL \
--private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY

cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $TOKEN_CONTRACT_OWNER_ADDRESS

999999955999999999999990000
999999952999999999999990000


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "createNewTask(string,string,uint256,bytes32,bytes32)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  1234 \
  0x287b58b93ed6c17ace087bb87f611bf21102c0602b0956736b6e523fb41c328d \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
--rpc-url $RPC_URL \
--private-key $OPERATOR_PRIVATE_KEY


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  1 \
  true \
--rpc-url $RPC_URL \
--private-key $OPERATOR_PRIVATE_KEY



# Query Token Balances
cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $DEFAULT_STAKER_REWARDS
cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $REWARDS_CORE_ADDRESS
cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $NETWORK_ADDRESS
cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $DEFAULT_OPERATOR_REWARDS
cast call $TOKEN_CONTRACT_ADDRESS "balanceOf(address)(uint256)" $SECONDARY_ADDRESS



Sender: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Starting distributeRewards for cluster: radius
Starting distributeRewards for rollup: rollup_id_2
Network address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Distribution info - Eligible: true
Available amount: 10000000000000000000
Reward token: 0x59b670e9fA9D0A427751Af201D676719a970857b
Time until next distribution: 0
Approved amount: 10000000000000000000
Operator amount (70%): 7000000000000000000
Staker amount (30%): 3000000000000000000
Processing operator rewards transfer
Approved operator rewards contract to spend: 7000000000000000000
rewardToken:  0x59b670e9fA9D0A427751Af201D676719a970857b
DEFAULT_OPERATOR_REWARDS:  0xa63bA08402aF74196569F3442b3a44946Cf149eA
Operator rewards distributed successfully
Processing staker rewards transfer
Approved staker rewards contract to spend: 3000000000000000000
stakerTimestamp: 1735619353
maxAdminFee: 5000000000000000


Starting distributeRewards for cluster: radius
Starting distributeRewards for rollup: rollup_id_2
Network address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Distribution info - Eligible: true
Available amount: 10000000000000000000
Reward token: 0x59b670e9fA9D0A427751Af201D676719a970857b
Time until next distribution: 0
Approved amount: 10000000000000000000
Operator amount (70%): 7000000000000000000
Staker amount (30%): 3000000000000000000
Processing operator rewards transfer
Approved operator rewards contract to spend: 7000000000000000000
rewardToken:  0x59b670e9fA9D0A427751Af201D676719a970857b
DEFAULT_OPERATOR_REWARDS:  0xa63bA08402aF74196569F3442b3a44946Cf149eA
Operator rewards distributed successfully
Processing staker rewards transfer
Approved staker rewards contract to spend: 3000000000000000000
stakerTimestamp: 1735619379
maxAdminFee: 10000


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --private-key $NETWORK_PRIVATE_KEY --rpc-url $RPC_URL\
  "distributeRewards(string,string,address,bytes32,uint48,bytes,bytes,uint256)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  $NETWORK_ADDRESS \
  0x287b58b93ed6c17ace087bb87f611bf21102c0602b0956736b6e523fb41c328d \
  $(expr $(date +%s) - 1) \
  "0x" "0x" 10000


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "createNewTask(string,string,uint256,bytes32,bytes32)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  1234 \
  0x287b58b93ed6c17ace087bb87f611bf21102c0602b0956736b6e523fb41c328d \
  0x20cee38045bd1a09f831645acf68e979d1d27b83584bc81b6bd6f0b71c6676ec \
--rpc-url $RPC_URL \
--private-key $OPERATOR_PRIVATE_KEY





cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
$CLUSTER_ID \
$ROLLUP_ID \
4 \
true \
--rpc-url $RPC_URL \
--private-key $OPERATOR_PRIVATE_KEY


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
$CLUSTER_ID \
$ROLLUP_ID \
4 \
true \
--rpc-url $RPC_URL \
--private-key $SECONDARY_PRIVATE_KEY





cast send $DEFAULT_OPERATOR_REWARDS "claimRewards(address,address,address,uint256,bytes32[])" \
$OPERATOR_ADDRESS \
$NETWORK_ADDRESS \
$TOKEN_CONTRACT_ADDRESS \
7000000000000000000 \
"[0x4ef3866300122664d1e7ae0489890fd57600af223d41b2a70a3a7f96d95989eb]" \
--rpc-url $RPC_URL \
--private-key $OPERATING_PRIVATE_KEY



cast send $DEFAULT_OPERATOR_REWARDS "claimRewards(address,address,address,uint256,bytes32[])" \
$SECONDARY_ADDRESS \
$NETWORK_ADDRESS \
$TOKEN_CONTRACT_ADDRESS \
7000000000000000000 \
"[0x294743eb18f560580479dff2192313fa4add412caf5e62ca358e6fa81b853746]" \
--rpc-url $RPC_URL \
--private-key $SECONDARY_PRIVATE_KEY



cast call $DEFAULT_OPERATOR_REWARDS "claimed(address,address,address)(uint256)" \
    $NETWORK_ADDRESS \
    $TOKEN_CONTRACT_ADDRESS \
    $SECONDARY_ADDRESS

 cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "createNewTask(string,string,uint256,bytes32,bytes32)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  1234 \
  0x287b58b93ed6c17ace087bb87f611bf21102c0602b0956736b6e523fb41c328d \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
--rpc-url $RPC_URL \
--private-key $OPERATOR_PRIVATE_KEY


string calldata clusterId,
string calldata rollupId,
uint256 blockNumber,
bytes32 blockCommitment,
bytes32[] calldata merkleRoots,
uint256[] calldata stakerAmounts


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "createNewTask(string,string,uint256,bytes32,bytes32[],uint256[])" $CLUSTER_ID $ROLLUP_ID 12 0x287b58b93ed6c17ace087bb87f611bf21102c0602b0956736b6e523fb41c328d [] [] --rpc-url $RPC_URL --private-key $DEFAULT_OPERATOR_PRIVATE_KEY


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  0 \
  true \
--rpc-url $RPC_URL \
--private-key $DEFAULT_OPERATOR_PRIVATE_KEY

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  0 \
  true \
--rpc-url $RPC_URL \
--private-key $WBTC_OPERATOR_PRIVATE_KEY


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  0 \
  true \
--rpc-url $RPC_URL \
--private-key $STETH_OPERATOR_PRIVATE_KEY


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  0 \
  true \
--rpc-url $RPC_URL \
--private-key $DEFAULT_OPERATOR_PRIVATE_KEY_SECONDARY

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  0 \
  true \
--rpc-url $RPC_URL \
--private-key $WBTC_OPERATOR_PRIVATE_KEY_SECONDARY


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint32,bool)" \
  $CLUSTER_ID \
  $ROLLUP_ID \
  2 \
  true \
--rpc-url $RPC_URL \
--private-key $STETH_OPERATOR_PRIVATE_KEY_SECONDARY





cast send <contract-address> "createNewTask(string,string,uint256,bytes32,address[],bytes32[],uint256[])" \
  $CLUSTER_ID $ROLLUP_ID 12 \
  0x287b58b93ed6c17ace087bb87f611bf21102c0602b0956736b6e523fb41c328d \
  ["0x8615436b4ae383b2320a8545e728db98e05e0c06","0x0400b7fcf3e4e02c5585078e3c850b532b65da37"] \
  ["0xc71ca16ff2885d228f7b6d5e307047151f499ca8eb9fdd10a7b9dfa3b2ec410e","0xc77f3a8260b51e1e1b2020abcc074be1bbd57cb3d59bd7fba0511de4772910c6"] \
 [21697952516063172, 1748516602714823936, 1229785444769113344]


 cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "createNewTask(string,string,uint256,bytes32,address[],bytes32[],uint256[])" $CLUSTER_ID $ROLLUP_ID 12 0x287b58b93ed6c17ace087bb87f611bf21102c0602b0956736b6e523fb41c328d [] [] [] --rpc-url $RPC_URL --private-key $DEFAULT_OPERATOR_PRIVATE_KEY


cast send $DEFAULT_STAKER_REWARDS "claimRewards(address,address,bytes)" $DEFAULT_ACCOUNT_ADDRESS $DEFAULT_TOKEN_ADDRESS $(cast --from-utf8 $(python3 -c "import eth_abi; print('0x' + eth_abi.encode(['address', 'uint256', 'bytes[]'], ['$NETWORK_ADDRESS', 115792089237316195423570985008687907853269984665640564039457584007913129639935, []]).hex())")) --rpc-url $RPC_URL --private-key $DEFAULT_ACCOUNT_PRIVATE_KEY


cast send $DEFAULT_STAKER_REWARDS "claimRewards(address,address,bytes)" \
$DEFAULT_ACCOUNT_ADDRESS \
$DEFAULT_TOKEN_ADDRESS \
$(cast abi-encode "f(address,uint256,bytes[])" $NETWORK_ADDRESS 115792089237316195423570985008687907853269984665640564039457584007913129639935 []) \
--rpc-url $RPC_URL \
--private-key $DEFAULT_ACCOUNT_PRIVATE_KEY


cast send $WBTC_STAKER_REWARDS "claimRewards(address,address,bytes)" \
$WBTC_ACCOUNT_ADDRESS \
$DEFAULT_TOKEN_ADDRESS \
$(cast abi-encode "f(address,uint256,bytes[])" $NETWORK_ADDRESS 115792089237316195423570985008687907853269984665640564039457584007913129639935 []) \
--rpc-url $RPC_URL \
--private-key $WBTC_ACCOUNT_PRIVATE_KEY

cast send $WBTC_STAKER_REWARDS "claimRewards(address,address,bytes)" \
$WBTC_OPERATOR_ADDRESS_SECONDARY \
$DEFAULT_TOKEN_ADDRESS \
$(cast abi-encode "f(address,uint256,bytes[])" $NETWORK_ADDRESS 115792089237316195423570985008687907853269984665640564039457584007913129639935 []) \
--rpc-url $RPC_URL \
--private-key $WBTC_ACCOUNT_PRIVATE_KEY_SECONDARY




cast call $DEFAULT_TOKEN_ADDRESS "balanceOf(address)(uint256)" $DEFAULT_STAKER_REWARDS
cast call $DEFAULT_TOKEN_ADDRESS "balanceOf(address)(uint256)" $DEFAULT_OPERATOR_REWARDS
cast call $DEFAULT_TOKEN_ADDRESS "balanceOf(address)(uint256)" $WBTC_STAKER_REWARDS
cast call $DEFAULT_TOKEN_ADDRESS "balanceOf(address)(uint256)" $STETH_STAKER_REWARDS

cast call $DEFAULT_TOKEN_ADDRESS "balanceOf(address)(uint256)" $WBTC_ACCOUNT_ADDRESS

cast call $DEFAULT_TOKEN_ADDRESS "balanceOf(address)(uint256)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS


cast call $DEFAULT_TOKEN_ADDRESS "balanceOf(address)(uint256)" $DEFAULT_OPERATOR_ADDRESS
cast call $DEFAULT_TOKEN_ADDRESS "balanceOf(address)(uint256)" $DEFAULT_OPERATOR_ADDRESS_SECONDARY
