#!/bin/sh


# Define teams
teams="Operator1|$DEFAULT_OPERATOR_ADDRESS|$DEFAULT_OPERATOR_ADDRESS
Operator2|$WBTC_OPERATOR_ADDRESS|$WBTC_OPERATOR_ADDRESS
Operator3|$STETH_OPERATOR_ADDRESS|$STETH_OPERATOR_ADDRESS
Operator4|$WBTC_OPERATOR_ADDRESS_SECONDARY|$WBTC_OPERATOR_ADDRESS_SECONDARY
Operator5|$STETH_OPERATOR_ADDRESS_SECONDARY|$STETH_OPERATOR_ADDRESS_SECONDARY"

# Function to get vault address by name
get_vault() {
  case "$1" in
    "WBTC") echo "$WBTC_VAULT_ADDRESS" ;;
    "STETH") echo "$STETH_VAULT_ADDRESS" ;;
    *) echo "Unknown token" ;;
  esac
}

# Function to get delegator address by name
get_delegator() {
  case "$1" in
    "WBTC") echo "$WBTC_DELEGATOR_ADDRESS" ;;
    "STETH") echo "$STETH_DELEGATOR_ADDRESS" ;;
    *) echo "Unknown token" ;;
  esac
}

# Function to get token address by name
get_token() {
  case "$1" in
    "WBTC") echo "$WBTC_TOKEN_ADDRESS" ;;
    "STETH") echo "$STETH_TOKEN_ADDRESS" ;;
    *) echo "Unknown token" ;;
  esac
}

# Function to get team vault by team name
get_team_vault() {
  case "$1" in
    "Operator1") echo "WBTC:$(get_vault "WBTC")" ;;
    "Operator2") echo "WBTC:$(get_vault "WBTC")" ;;
    "Operator3") echo "STETH:$(get_vault "STETH")" ;;
    "Operator4") echo "WBTC:$(get_vault "WBTC")" ;;
    "Operator5") echo "STETH:$(get_vault "STETH")" ;;
    *) echo "Unknown team" ;;
  esac
}

# Function to get token names for iteration
get_token_names() {
  echo "WBTC STETH"
}

# Function to get delegator names for iteration
get_delegator_names() {
  echo "WBTC STETH"
}

check_team() {
  team_name=$1
  operator_address=$2
  operating_address=$3

  echo "=============================="
  echo "team: $team_name"
  echo "=============================="

  result1=$(cast call $LIVENESS_CONTRACT_ADDRESS --rpc-url $RPC_URL \
    "isTxOrdererRegistered(string clusterId, address operating)(bool)" $CLUSTER_ID $operating_address)
  echo "1. Check register tx orderer - ('$CLUSTER_ID', $operating_address): $result1"

  result2=$(cast call $OPERATOR_REGISTRY_CONTRACT_ADDRESS --rpc-url $RPC_URL \
    "isEntity(address who)(bool)" $operator_address)
  echo "2. Check register operator - ($operator_address): $result2"

  result3=$(cast call $OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
    "isOptedIn(address who, address where)(bool)" $operator_address $NETWORK_ADDRESS)
  echo "3. Check Optin to network - ($operator_address, $NETWORK_ADDRESS): $result3"

  vaults=$(get_team_vault "$team_name")
  
  # Split vault entry into vault_name and vault_address
  vault_entry=$vaults
  vault_name=$(echo "$vault_entry" | cut -d':' -f1)
  vault_address=$(echo "$vault_entry" | cut -d':' -f2)

  echo "4. Check Optin to Vaults and operator network shares"
  result_vault=$(cast call $OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS --rpc-url $RPC_URL \
    "isOptedIn(address who, address where)(bool)" $operator_address $vault_address)
  echo " - $vault_name ($vault_address): $result_vault"

  # Loop through delegators
  for delegator_name in $(get_delegator_names); do
    delegator_address=$(get_delegator "$delegator_name")
    
    if [ "$vault_name" = "$delegator_name" ]; then
      result_share=$(cast call $delegator_address --rpc-url $RPC_URL \
        "operatorNetworkShares(bytes32 subnetwork, address operator)(uint256)" $SUBNETWORK $operator_address)
      
      echo "   * Share amount - $result_share"
    fi
  done

  echo "6. Check register operator in middleware contract"
  cast_output=$(cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
  "getCurrentOperatorInfos()((address, address, (address, uint256)[])[])")

  if echo "$cast_output" | grep -q "$operator_address"; then
    echo "   * It exists in the middleware contract."

    echo "7. Check staking amount for each token"
    for token_name in $(get_token_names); do
      token_address=$(get_token "$token_name")
      
      staking_amount=$(cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS --rpc-url $RPC_URL \
      "getCurrentOperatorTokenStake(address operator, address token)(uint256)" \
      $operator_address $token_address)
    
      echo "   * $token_name ($token_address) - $staking_amount"
    done
  else
    echo "Address $operator_address does not exist in the middleware contract."
  fi

  echo ""
}

# Process each team
echo "$teams" | while IFS= read -r team; do
  # Skip empty lines
  [ -z "$team" ] && continue
  
  name=$(echo "$team" | cut -d'|' -f1)
  operator=$(echo "$team" | cut -d'|' -f2)
  operating=$(echo "$team" | cut -d'|' -f3)
  
  check_team "$name" "$operator" "$operating"
done