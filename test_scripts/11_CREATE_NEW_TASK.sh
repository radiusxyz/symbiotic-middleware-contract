cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
"createNewTask((string,string,uint256,bytes32),(uint256,address[],bytes32[],uint256[],uint256[]))" \
"(\"$CLUSTER_ID\",\"$ROLLUP_ID\",1,9863afe88811d11aef049e23bcc1eb75a6e06ce0a8193d7b3dc39dd68e8391d8)" \
"(0,[],[],[],[])" \
--rpc-url $RPC_URL --private-key $WBTC_OPERATOR_PRIVATE_KEY