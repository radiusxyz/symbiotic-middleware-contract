RPC_URL=http://127.0.0.1:8545
VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS=0xc3e53F4d16Ae77Db1c982e75a937B9f60FE63690
OPERATOR_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
"registerOperator(address operatorAddress, address operatingAddress)" $OPERATOR_ADDRESS $OPERATOR_ADDRESS

cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "isActiveVault(uint256 index)(bool)"  0

cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "getCurrentEpoch()(uint48)" 
cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "getOperatorStake(address operator, uint48 epoch)(uint256)" $OPERATOR_ADDRESS 14403
cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "getTotalStake(uint48 epoch)(uint256)" 14242

cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "NETWORK()(address)" 
cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "OPERATOR_REGISTRY()(address)" 
cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "OPERATOR_NET_OPTIN()(address)" 
cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "VAULT_REGISTRY()(address)" 
cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "owner()(address)" 

cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "EPOCH_DURATION()(uint48)" 
cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "SLASHING_WINDOW()(uint48)" 
cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "START_TIME()(uint48)" 

cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "getCurrentEpoch()(uint48)" 
cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "getEpochStartTs(uint48 epoch)(uint48)" 93 
cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "getEpochAtTs(uint48 epoch)(uint48)" 1728530952 

cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "getValidatorSet(uint48 epoch)(address)" 3558 
cast call --rpc-url $RPC_URL $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "getSubnetwork(uint96 index)(bytes32)"  0

forge script script/validation_service_manager/Getter.sol:Getter --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast -vvvv \
--sig "getRollupTaskInfo(string rollupId)" "rollupId"
