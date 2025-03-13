cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "executeDistributions(string,string)" $CLUSTER_ID $ROLLUP_ID \
  --rpc-url $RPC_URL \
  --private-key $NETWORK_PRIVATE_KEY --gas-limit 15000000