
# 0x1e043af5E9EC1Db540b719d7C4F8Dbf8e928f379
cast send 0x1e043af5E9EC1Db540b719d7C4F8Dbf8e928f379 --value 10000000000000000000 --private-key $TOKEN_CONTRACT_OWNER_PRIVATE_KEY

cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
"createNewTask((string,string,uint256,bytes32),(uint256,address[],bytes32[],uint256[],uint256[]))" \
"(\"$CLUSTER_ID\",\"$ROLLUP_ID\",1,0x24f45c36f97cee7e3afe2887ae3f1c6666fe0afbe66583b68cd2f8a44f0cec45)" \
"(0,[],[],[],[])" \
--rpc-url $RPC_URL --private-key $WBTC_OPERATOR_PRIVATE_KEY


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
"requestSlash(address,string,uint256,bytes32,uint256,bytes32[],bytes)" \
"0x90F79bf6EB2c4f870365E785982E1f101E93b906" "rollup_id_2" 1 "0xd6a1691c830e5a9bdf4d148d84ddee81ad8f14bc09fe87f40dc4e1c0aefec158" 9 "[0x86d31981f2cb0f13c3381a12de7dcf960e612457f639b312d7215badc61222ef]" "855ea03d21d702372dce55fdacd0b713061c13ba195aa669658bde89b2510f44201b1b1124f23ba4fa987fec46c3b1ed7dffcb98a8aa87af7af2b48ee107af871b" \
--rpc-url $RPC_URL --private-key f0afce91245c1efdd09a01b2fe38253bcfe9272a4c74b34bc7395622c3047ad9 --value 0.05ether




cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
"respondToSlash(bytes32,bytes32[])" \
"0xd6a1691c830e5a9bdf4d148d84ddee81ad8f14bc09fe87f40dc4e1c0aefec158" "[790020ee275dec7cfc4de9929c8d0acf2b33d01775faec1ceffbb336e0b85e29,33da9db6ea56c3bb17f2cadaf2e08b229d75417698b2b1eecb3a192a1d49658a,9eab4ffa668d1be303f43c67bcc87fb15be200d58ecb0ef5c6abfbbff2ab3836]" \
--rpc-url $RPC_URL --private-key $DEFAULT_OPERATOR_PRIVATE_KEY_SECONDARY


cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "getSlashRequestDetails(bytes32)" 0xd6a1691c830e5a9bdf4d148d84ddee81ad8f14bc09fe87f40dc4e1c0aefec158 --rpc-url $RPC_URL

cast call \
  $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
  "getSlashRequestDetails(bytes32)" \
  0xd6a1691c830e5a9bdf4d148d84ddee81ad8f14bc09fe87f40dc4e1c0aefec158 \
  --rpc-url $RPC_URL


cast call \
  $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
  "getSlashCredit(bytes32)" \
  0xd6a1691c830e5a9bdf4d148d84ddee81ad8f14bc09fe87f40dc4e1c0aefec158 \
  --rpc-url $RPC_URL

  cast send $DEFAULT_VAULT_BURNER_ROUTER --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY "triggerTransfer(address)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS

  

cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "getSlashCredit(bytes32)" "0x1129b0e2a56db3d57a744a4ecbfb9b7a0b048b83ac4f97c41e36d1cd146305ba" --rpc-url $RPC_URL


cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
"processSlashCredit(bytes32)" \
"0xd6a1691c830e5a9bdf4d148d84ddee81ad8f14bc09fe87f40dc4e1c0aefec158" \
--rpc-url $RPC_URL --private-key $WBTC_OPERATOR_PRIVATE_KEY 



cast send $DEFAULT_VAULT_BURNER_ROUTER --rpc-url $RPC_URL --private-key $NETWORK_PRIVATE_KEY "triggerTransfer(address)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS 



cast call $DEFAULT_COLLATERAL_ADDRESS "balanceOf(address)(uint256)" 0x1e043af5E9EC1Db540b719d7C4F8Dbf8e928f379

cast call $DEFAULT_COLLATERAL_ADDRESS "balanceOf(address)(uint256)" $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS
cast call $DEFAULT_COLLATERAL_ADDRESS "balanceOf(address)(uint256)" $DEFAULT_VAULT_BURNER_ROUTER