cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
                                                                                        "createNewTask((string,string,uint256,bytes32),(uint256,address[],bytes32[],uint256[],uint256[]))" \
                                                                                        "(\"$CLUSTER_ID\",\"$ROLLUP_ID\",12,0x287b58b93ed6c17ace087bb87f611bf21102c0602b0956736b6e523fb41c328d)" \
                                                                                        "(0,[],[],[],[])" \
                                                                                        --rpc-url $RPC_URL --private-key $WBTC_OPERATOR_PRIVATE_KEY