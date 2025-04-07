#!/bin/bash

# Initialize task counter
TASK_COUNT=0

# Function to create a new task
create_new_task() {
    echo "Creating task #$TASK_COUNT..."
    
    # Query the rewards endpoint and store the response
    response=$(curl -X POST http://localhost:3000/create_new_task \
        -H "Content-Type: application/json" \
        -d '{
            "jsonrpc": "2.0",
            "method": "get_rewards",
            "params": {
                "cluster_id": "'$CLUSTER_ID'",
                "rollup_id": "'$ROLLUP_ID'"
            },
            "id": 1
        }')

    # Extract the distribution_data array from the response
    json_string=$(echo "$response" | jq -r '.result.distribution_data')

    # Extract data using jq and store in arrays
    vaults=($(echo "$json_string" | jq -r '.[].vault'))
    staker_rewards=($(echo "$json_string" | jq -r '.[].total_staker_reward'))
    operator_rewards=($(echo "$json_string" | jq -r '.[].total_operator_reward'))
    merkle_roots=($(echo "$json_string" | jq -r '.[].operator_merkle_root'))

    # Calculate total rewards
    total_staker_rewards=$(echo "$json_string" | jq -r '[.[].total_staker_reward | tonumber] | add' | awk '{printf "%.0f", $1}')
    total_operator_rewards=$(echo "$json_string" | jq -r '[.[].total_operator_reward | tonumber] | add' | awk '{printf "%.0f", $1}')

    # Print totals
    echo ""
    echo "Total Staker Rewards: $total_staker_rewards"
    echo "Total Operator Rewards: $total_operator_rewards"
    echo "----------------------------------------"

    # Build the formatted arrays
    rewarded_task_index=$(echo "$response" | jq -r '.result.rewarded_task_index')
    vaults_formatted=$(format_array "address" "${vaults[@]}")
    merkle_roots_formatted=$(format_array "hex" "${merkle_roots[@]}")
    staker_rewards_formatted=$(format_array "number" "${staker_rewards[@]}")
    operator_rewards_formatted=$(format_array "number" "${operator_rewards[@]}")

    echo "Executing cast send command..."

    # Execute the cast send command directly
    cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
      "createNewTask((string,string,uint256,bytes32),(uint256,address[],bytes32[],uint256[],uint256[]))" \
      "(\"$CLUSTER_ID\",\"$ROLLUP_ID\",12,0x287b58b93ed6c17ace087bb87f611bf21102c0602b0956736b6e523fb41c328d)" \
      "($rewarded_task_index,$vaults_formatted,$merkle_roots_formatted,$staker_rewards_formatted,$operator_rewards_formatted)" \
      --rpc-url $RPC_URL --private-key $DEFAULT_OPERATOR_PRIVATE_KEY

    # Print confirmation
    echo "Command executed with exit code: $?"
}

# Function to respond to tasks
respond_to_task() {
    local task_count=$1
    echo "Responding to task #$task_count..."
    
    # First operator response
    cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint256,bool)" \
      $CLUSTER_ID \
      $ROLLUP_ID \
      $task_count \
      true \
      --rpc-url $RPC_URL \
      --private-key $DEFAULT_OPERATOR_PRIVATE_KEY
    sleep 0.1
    
    # WBTC operator response
    cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint256,bool)" \
      $CLUSTER_ID \
      $ROLLUP_ID \
      $task_count \
      true \
      --rpc-url $RPC_URL \
      --private-key $WBTC_OPERATOR_PRIVATE_KEY
    sleep 0.1
    
    # STETH operator response
    cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint256,bool)" \
      $CLUSTER_ID \
      $ROLLUP_ID \
      $task_count \
      true \
      --rpc-url $RPC_URL \
      --private-key $STETH_OPERATOR_PRIVATE_KEY
    sleep 0.1
    
    # DEFAULT SECONDARY operator response
    cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint256,bool)" \
      $CLUSTER_ID \
      $ROLLUP_ID \
      $task_count \
      true \
      --rpc-url $RPC_URL \
      --private-key $DEFAULT_OPERATOR_PRIVATE_KEY_SECONDARY
    sleep 0.1
    
    # WBTC SECONDARY operator response
    cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint256,bool)" \
      $CLUSTER_ID \
      $ROLLUP_ID \
      $task_count \
      true \
      --rpc-url $RPC_URL \
      --private-key $WBTC_OPERATOR_PRIVATE_KEY_SECONDARY
    sleep 0.1
    
    # STETH SECONDARY operator response
    cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint256,bool)" \
      $CLUSTER_ID \
      $ROLLUP_ID \
      $task_count \
      true \
      --rpc-url $RPC_URL \
      --private-key $STETH_OPERATOR_PRIVATE_KEY_SECONDARY
    sleep 0.1
    
    echo "All operators have responded to task #$task_count"
}

# Function to format arrays for the contract call
format_array() {
    local type=$1
    shift
    local array=("$@")
    
    echo -n "["
    for i in "${!array[@]}"; do
        if [[ "$type" == "number" ]]; then
            # No quotes for numbers
            echo -n "${array[i]}"
        elif [[ "${array[i]}" == 0x* ]]; then
            # No quotes for hex addresses
            echo -n "${array[i]}"
        else
            # Add quotes for other strings
            echo -n "\"${array[i]}\""
        fi
        if [[ $i -lt $((${#array[@]} - 1)) ]]; then
            echo -n ","
        fi
    done
    echo -n "]"
}

# Trap CTRL+C to exit the script cleanly
trap "echo 'Script terminated by user'; exit 0" INT

# Main loop
echo "Starting task automation loop. Press CTRL+C to stop."
while true; do
    echo "======================"
    echo "Starting iteration for task #$TASK_COUNT"
    echo "======================"
    
    # Create new task
    create_new_task
    
    # Wait 3 seconds after creating task
    echo "Waiting 3 seconds before responding to task..."
    sleep 3
    
    # Respond to the task
    respond_to_task $TASK_COUNT
    
    # Increment task counter
    TASK_COUNT=$((TASK_COUNT + 1))
    
    # Wait 10 seconds before next iteration
    echo "Waiting 10 seconds before next iteration..."
    sleep 10
done