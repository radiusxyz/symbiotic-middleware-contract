
set -x STETH_OPERATOR_ADDRESS "0xc6bA578acFF1eA914A6a727b2F20776eB4ad61EE"
set -x STETH_OPERATOR_PRIVATE_KEY "b0de8eb532b742fb5fb2e84f78322b846569ddbd8920a68e6054d1c44a1a46db"




# 0x1e043af5E9EC1Db540b719d7C4F8Dbf8e928f379
cast send 0xc6bA578acFF1eA914A6a727b2F20776eB4ad61EE --rpc-url $RPC_URL --value 10000000000000000000 --private-key $NETWORK_PRIVATE_KEY
cast send 0x1e043af5E9EC1Db540b719d7C4F8Dbf8e928f379 --rpc-url $RPC_URL --value 10000000000000000000 --private-key $NETWORK_PRIVATE_KEY

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
"createNewTask((string,string,uint256,bytes32),(uint256,address[],bytes32[],uint256[],uint256[]))" \
"(\"$CLUSTER_ID\",\"$ROLLUP_ID\",5,0x9ecb94ecf2bb69f26bec3746ec442e97d2895891e88b10c4ac8abdc910301072)" \
"(0,[],[],[],[])" \
--rpc-url $RPC_URL --private-key $STETH_OPERATOR_PRIVATE_KEY


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
"requestSlash(address,string,string, uint256,bytes32,uint256,bytes32[],bytes)" \
"0xc6bA578acFF1eA914A6a727b2F20776eB4ad61EE" "radius" "rollup_id_2" 5 "0x83b002caeea5a70ec6b94fd2cf71de5321fd3b94e7ce4535aea3028e31f3b10d" 1 "[0x785ce2b2dd56887f772fa80fcdf0fee6cd2cb77c5450c6b63191407a24ea0d3c]" "f256936928bfdb22fc15cbcfb57f222b37261681dae25782b92d44f5194ad7157f3c7123f38e02e51f26d9068a863619abb3a36daa6d6df874e09edcf478d3251b" \
--rpc-url $RPC_URL --private-key f0afce91245c1efdd09a01b2fe38253bcfe9272a4c74b34bc7395622c3047ad9 --value 0.05ether


# cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
# "processSlashRequest(bytes32,)" \
# "0xd6a1691c830e5a9bdf4d148d84ddee81ad8f14bc09fe87f40dc4e1c0aefec158" \
# --rpc-url $RPC_URL --private-key $DEFAULT_OPERATOR_PRIVATE_KEY_SECONDARY
# [0xd378fe5f015286bcc2f2107a098d90d47ef122e2e23a98ad3f4fff1938130650,0x6e0134af21b041b1732e906f49f58cdbf121d593b5c1df04ac5b59509af5b24f,0x4b8b6643654922574370b37e0fd799973a1d2d16d038df6eb76363f407976c84]


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
"respondToSlash(bytes32,bytes32[])" \
"0x83b002caeea5a70ec6b94fd2cf71de5321fd3b94e7ce4535aea3028e31f3b10d" "[0x83b002caeea5a70ec6b94fd2cf71de5321fd3b94e7ce4535aea3028e31f3b10d]" \
--rpc-url $RPC_URL --private-key b0de8eb532b742fb5fb2e84f78322b846569ddbd8920a68e6054d1c44a1a46db 


# cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "getSlashRequestDetails(bytes32)" 0xdf1f0807a5dfdc3acf7021e6d68235d6de7bd0fb30ed0d26612c566fcd6e28a2 --rpc-url $RPC_URL

cast call \
  $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
  "getSlashRequestDetails(bytes32)((address,address,string,uint256,bytes32,uint256,bytes32[],bytes,uint256,uint8,bool,uint256))" \
  0x83b002caeea5a70ec6b94fd2cf71de5321fd3b94e7ce4535aea3028e31f3b10d \
  --rpc-url $RPC_URL


cast call \
  $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
  "getSlashCredit(bytes32)" \
  0x83b002caeea5a70ec6b94fd2cf71de5321fd3b94e7ce4535aea3028e31f3b10d \
  --rpc-url $RPC_URL

  cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "getSlashCreditDetails(bytes32)((address,address,address,uint256,uint64,uint256,uint8,uint256))" 0x83b002caeea5a70ec6b94fd2cf71de5321fd3b94e7ce4535aea3028e31f3b10d --rpc-url $RPC_URL

  cast send $DEFAULT_VAULT_BURNER_ROUTER --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY "triggerTransfer(address)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS

  

cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "getSlashCredit(bytes32)" "0x1129b0e2a56db3d57a744a4ecbfb9b7a0b048b83ac4f97c41e36d1cd146305ba" --rpc-url $RPC_URL


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
"processSlashCredit(bytes32)" \
"0x83b002caeea5a70ec6b94fd2cf71de5321fd3b94e7ce4535aea3028e31f3b10d" \
--rpc-url $RPC_URL --private-key f0afce91245c1efdd09a01b2fe38253bcfe9272a4c74b34bc7395622c3047ad9

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
"processSlashRequest(bytes32)" \
"0x83b002caeea5a70ec6b94fd2cf71de5321fd3b94e7ce4535aea3028e31f3b10d" \
--rpc-url $RPC_URL --private-key f0afce91245c1efdd09a01b2fe38253bcfe9272a4c74b34bc7395622c3047ad9



cast send $DEFAULT_VAULT_BURNER_ROUTER --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY "triggerTransfer(address)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS 

cast send $WBTC_VAULT_BURNER_ROUTER --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY "triggerTransfer(address)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS 

cast send $STETH_VAULT_BURNER_ROUTER --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY "triggerTransfer(address)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS 



    cast call $DEFAULT_COLLATERAL_ADDRESS "balanceOf(address)(uint256)" 0x1e043af5E9EC1Db540b719d7C4F8Dbf8e928f379
    cast call $WBTC_COLLATERAL_ADDRESS "balanceOf(address)(uint256)" 0x1e043af5E9EC1Db540b719d7C4F8Dbf8e928f379
    cast call $STETH_COLLATERAL_ADDRESS "balanceOf(address)(uint256)" 0x1e043af5E9EC1Db540b719d7C4F8Dbf8e928f379

cast call $DEFAULT_COLLATERAL_ADDRESS "balanceOf(address)(uint256)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS
cast call $DEFAULT_COLLATERAL_ADDRESS "balanceOf(address)(uint256)" $DEFAULT_VAULT_BURNER_ROUTER


    cast call $DEFAULT_COLLATERAL_ADDRESS "balanceOf(address)(uint256)" 0x1e043af5E9EC1Db540b719d7C4F8Dbf8e928f379


cast send $STETH_VAULT_ADDRESS withdraw 0x1e043af5E9EC1Db540b719d7C4F8Dbf8e928f379 10 --rpc-url $RPC_URL --private-key f0afce91245c1efdd09a01b2fe38253bcfe9272a4c74b34bc7395622c3047ad9




cast call $STETH_VAULT_ADDRESS "totalStake()(uint256)" --rpc-url $RPC_URL
cast call $STETH_VAULT_ADDRESS "activeStake()(uint256)" --rpc-url $RPC_URL


cast call $VSM_REGISTRY "getCurrentOperatorAllTokenStakes(address)((address,uint256)[])" $STETH_OPERATOR_ADDRESS --rpc-url $RPC_URL

cast call $VSM_REGISTRY "getCurrentOperatorTokenStake(address operator, address token)(uint256)" $STETH_OPERATOR_ADDRESS $STETH_TOKEN_ADDRESS --rpc-url $RPC_URL

cast call $VSM_REGISTRY "getCurrentOperatorTokenStake(address operator, address token)(uint256)" $STETH_OPERATOR_ADDRESS_SECONDARY $STETH_TOKEN_ADDRESS --rpc-url $RPC_URL



cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY "setSlashPeriod(uint256)" 60