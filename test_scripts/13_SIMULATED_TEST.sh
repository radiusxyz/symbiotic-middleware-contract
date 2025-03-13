#!/bin/bash

# Set up logging
LOGFILE="validator_script_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "======================================================"
echo "Starting validator script at $(date)"
echo "Logs are being saved to $LOGFILE"
echo "======================================================"

# Function to format arrays for JSON/solidity
format_array() {
    local type=$1
    shift
    local array=("$@")

    if [[ ${#array[@]} -eq 0 ]]; then
        echo -n "[]"
        return
    fi
    
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

# Function to parse contract data from cast call output
parse_contract_data() {
    local data="$1"
    
    # Handle empty input
    if [[ -z "$data" ]]; then
        echo "Empty contract data, returning empty arrays."
        echo "" # Empty vaults
        echo "" # Empty merkle roots
        echo "" # Empty staker rewards
        echo "" # Empty operator rewards
        return
    fi
    
    # Log raw data for debugging (truncated to avoid overwhelming logs)
    echo "Raw contract data (truncated):"
    echo "${data:0:500}..."
    
    # Parse addresses (first array in return value)
    vaults=$(echo "$data" | grep -o '0x[0-9a-fA-F]\{40\}')
    
    # Parse merkle roots (second array in return value)
    merkle_roots=$(echo "$data" | grep -o '0x[0-9a-fA-F]\{64\}')
    
    # Parse staker rewards and operator rewards
    # Note: This is tricky and depends on format of cast output
    # Assume values are on separate lines after merkle roots
    
    # Get the lines after the last merkle root
    remaining_data=$(echo "$data" | awk -v RS="" '{gsub(/.*0x[0-9a-fA-F]{64}[^0-9]*/,""); print}')
    
    # Count the number of vaults
    vault_count=$(echo "$vaults" | wc -l)
    
    # If there are no vaults, set rewards to empty
    if [[ "$vault_count" -eq 0 ]]; then
        staker_rewards=""
        operator_rewards=""
    else
        # Split into separate arrays (assuming first chunk is staker rewards, second is operator rewards)
        staker_rewards=$(echo "$remaining_data" | grep -o '[0-9]\+' | head -n "$vault_count")
        operator_rewards=$(echo "$remaining_data" | grep -o '[0-9]\+' | tail -n "$vault_count")
    fi
    
    echo "Parsed contract data:"
    echo "Vaults (count: $(echo "$vaults" | wc -l)):"
    echo "$vaults" | head -5 # Just show first 5 entries
    echo "Merkle Roots (count: $(echo "$merkle_roots" | wc -l)):"
    echo "$merkle_roots" | head -5 # Just show first 5 entries
    echo "Staker Rewards (count: $(echo "$staker_rewards" | wc -l)):"
    echo "$staker_rewards" | head -5 # Just show first 5 entries
    echo "Operator Rewards (count: $(echo "$operator_rewards" | wc -l)):"
    echo "$operator_rewards" | head -5 # Just show first 5 entries
    
    # Return parsed data
    echo "$vaults"
    echo "$merkle_roots"
    echo "$staker_rewards"
    echo "$operator_rewards"
}

# Function to compare arrays
compare_arrays() {
    local name="$1"
    local arr1=("$2")
    local arr2=("$3")
    
    if [[ "${#arr1[@]}" -ne "${#arr2[@]}" ]]; then
        echo "$name array lengths don't match (response: ${#arr1[@]}, contract: ${#arr2[@]})"
        return 1
    fi
    
    for i in "${!arr1[@]}"; do
        if [[ "${arr1[$i],,}" != "${arr2[$i],,}" ]]; then
            echo "$name mismatch at index $i: ${arr1[$i]} vs ${arr2[$i]}"
            return 1
        fi
    done
    
    return 0
}

# Function to respond to tasks with multiple operators
respond_to_task() {
    local task_id="$1"
    local response="$2"
    
    echo "Responding to task ID: $task_id with response: $response"
    
    # Define array of private keys
    operators=(
        "$DEFAULT_OPERATOR_PRIVATE_KEY"
        "$WBTC_OPERATOR_PRIVATE_KEY"
        "$STETH_OPERATOR_PRIVATE_KEY"
        "$DEFAULT_OPERATOR_PRIVATE_KEY_SECONDARY"
        "$WBTC_OPERATOR_PRIVATE_KEY_SECONDARY"
        "$STETH_OPERATOR_PRIVATE_KEY_SECONDARY"
    )
    
    # Send response for each operator
    for operator_key in "${operators[@]}"; do
        echo "Sending response for operator with key ending in ${operator_key: -4}..."
        
        cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS "respondToTask(string,string,uint256,bool)" \
          "$CLUSTER_ID" \
          "$ROLLUP_ID" \
          "$task_id" \
          "$response" \
          --rpc-url $RPC_URL \
          --private-key "$operator_key"
        
        tx_status=$?
        if [[ $tx_status -ne 0 ]]; then
            echo "Failed to send response transaction (exit code: $tx_status)"
        else
            echo "Response sent successfully"
        fi
        
        sleep 0.1
    done
    
    echo "All operators have responded to task ID $task_id"
}


TASK_COUNT=3
# Main loop
while true; do
    echo "--------------------------------------------------------------"
    echo "Starting new validation cycle at $(date)"
    # Step 1: Query create_new_task endpoint
    echo "Querying create_new_task endpoint..."
    create_task_response=$(curl -s -X POST http://localhost:3000/create_new_task \
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
    
    # Check if the request was successful
    if [[ -z "$create_task_response" || $(echo "$create_task_response" | jq -r 'has("result")') == "false" ]]; then
        echo "Failed to get valid response from create_new_task endpoint. Retrying in 10 seconds..."
        sleep 10
        continue
    fi
    
    # Extract the distribution_data array from the response
    json_string=$(echo "$create_task_response" | jq -r '.result.distribution_data')
    
    # Check if distribution_data exists and is not empty
    if [[ -z "$json_string" || "$json_string" == "null" ]]; then
        echo "No distribution data found in response. Retrying in 10 seconds..."
        sleep 10
        continue
    fi
    
    # Extract data using jq and store in arrays
    vaults=($(echo "$json_string" | jq -r '.[].vault'))
    staker_rewards=($(echo "$json_string" | jq -r '.[].total_staker_reward'))
    operator_rewards=($(echo "$json_string" | jq -r '.[].total_operator_reward'))
    merkle_roots=($(echo "$json_string" | jq -r '.[].operator_merkle_root'))
    
    # Check if we got any data
    # if [[ ${#vaults[@]} -eq 0 ]]; then
    #     echo "No vault data found. Retrying in 10 seconds..."
    #     sleep 10
    #     continue
    # fi
    
    # Calculate total rewards
    total_staker_rewards=$(echo "$json_string" | jq -r '[.[].total_staker_reward | tonumber] | add' | awk '{printf "%.0f", $1}')
    total_operator_rewards=$(echo "$json_string" | jq -r '[.[].total_operator_reward | tonumber] | add' | awk '{printf "%.0f", $1}')
    
    # Print totals and data summary
    echo "Total Staker Rewards: $total_staker_rewards"
    echo "Total Operator Rewards: $total_operator_rewards"
    echo "Number of vaults: ${#vaults[@]}"
    
    # Build the formatted arrays for contract call
    task_id=$(echo "$create_task_response" | jq -r '.result.task_id')
    
    if [[ -z "$task_id" || "$task_id" == "null" ]]; then
        echo "No task ID found in response. Retrying in 10 seconds..."
        sleep 10
        continue
    fi
    
    echo "Task ID: $task_id"
    
    vaults_formatted=$(format_array "address" "${vaults[@]}")
    merkle_roots_formatted=$(format_array "hex" "${merkle_roots[@]}")
    staker_rewards_formatted=$(format_array "number" "${staker_rewards[@]}")
    operator_rewards_formatted=$(format_array "number" "${operator_rewards[@]}")
    
    # Step 2: Execute createNewTask transaction
    echo "Executing createNewTask transaction..."
    
    # For debugging, print the command parameters
    echo "Command parameters:"
    echo "  Cluster ID: $CLUSTER_ID"
    echo "  Rollup ID: $ROLLUP_ID"
    echo "  Task ID: $task_id"
    echo "  Vaults count: ${#vaults[@]}"
    echo "  Merkle Roots count: ${#merkle_roots[@]}"
    
    # Execute the transaction
    cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
      "createNewTask((string,string,uint256,bytes32),(uint256,address[],bytes32[],uint256[],uint256[]))" \
      "(\"$CLUSTER_ID\",\"$ROLLUP_ID\",12,0x287b58b93ed6c17ace087bb87f611bf21102c0602b0956736b6e523fb41c328d)" \
      "($task_id,$vaults_formatted,$merkle_roots_formatted,$staker_rewards_formatted,$operator_rewards_formatted)" \
      --rpc-url $RPC_URL --private-key $DEFAULT_OPERATOR_PRIVATE_KEY
    
    tx_status=$?
    if [[ $tx_status -ne 0 ]]; then
        echo "Failed to execute createNewTask transaction (exit code: $tx_status). Retrying in 10 seconds..."
        sleep 10
        continue
    fi
    
    echo "createNewTask transaction successful"

    # Wait for transaction to be mined
    echo "Waiting for transaction to be mined..."
    sleep 2
    
    # Step 3: Query respond_to_task endpoint
    echo "Querying respond_to_task endpoint..."
    respond_task_response=$(curl -s -X POST http://localhost:3000/respond_to_task \
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
    
    # Check if the request was successful
    if [[ -z "$respond_task_response" || $(echo "$respond_task_response" | jq -r 'has("result")') == "false" ]]; then
        echo "Failed to get valid response from respond_to_task endpoint. Retrying in 10 seconds..."
        sleep 10
        continue
    fi
    
    # Extract task_id from the response
    reward_task_id=$(echo "$respond_task_response" | jq -r '.result.task_id')
    
    if [[ -z "$reward_task_id" || "$reward_task_id" == "null" ]]; then
        echo "No task ID found in response. Retrying in 10 seconds..."
        sleep 10
        continue
    fi
    
    echo "Response Task ID: $TASK_COUNT"
    
    # Extract distribution data from the response
    response_json_string=$(echo "$respond_task_response" | jq -r '.result.distribution_data')
    
    # Check if distribution_data exists and is not empty
    if [[ -z "$response_json_string" || "$response_json_string" == "null" ]]; then
        echo "No distribution data found in response. Retrying in 10 seconds..."
        sleep 10
        continue
    fi
    
    # Extract data using jq and store in arrays
    response_vaults=($(echo "$response_json_string" | jq -r '.[].vault'))
    response_staker_rewards=($(echo "$response_json_string" | jq -r '.[].total_staker_reward'))
    response_operator_rewards=($(echo "$response_json_string" | jq -r '.[].total_operator_reward'))
    response_merkle_roots=($(echo "$response_json_string" | jq -r '.[].operator_merkle_root'))
    
    # Check if we got any data
    # if [[ ${#response_vaults[@]} -eq 0 ]]; then
    #     echo "No vault data found in response. Retrying in 10 seconds..."
    #     sleep 10
    #     continue
    # fi
    
    # Step 4: Call getDistributionData function to get data from contract
    echo "Getting distribution data from contract for reward task ID: $reward_task_id..."
    contract_data=$(cast call $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
      "getDistributionData(string,string,uint256)(address[],bytes32[],uint256[],uint256[])" \
      "$CLUSTER_ID" "$ROLLUP_ID" "$reward_task_id" \
      --rpc-url $RPC_URL)
    
    call_status=$?
    if [[ $call_status -ne 0 ]]; then
        echo "Failed to call getDistributionData (exit code: $call_status). Retrying in 10 seconds..."
        sleep 10
        continue
    fi
    
    # Parse the contract data if not empty
    if [[ -n "$contract_data" ]]; then
        parsed_data=$(parse_contract_data "$contract_data")
        
        # Split the parsed data into arrays
        readarray -t parsed_lines <<< "$parsed_data"
        readarray -t contract_vaults <<< "${parsed_lines[0]}"
        readarray -t contract_merkle_roots <<< "${parsed_lines[1]}"
        readarray -t contract_staker_rewards <<< "${parsed_lines[2]}"
        readarray -t contract_operator_rewards <<< "${parsed_lines[3]}"
    else
        # Leave arrays empty if no contract data
        echo "No contract data to parse, using empty arrays."
    fi
    
    # Debug output of the parsed data
    echo "Response data (from API):"
    echo "Vaults (${#response_vaults[@]}): ${response_vaults[*]:0:100}..." # Limit output length
    echo "Merkle Roots (${#response_merkle_roots[@]}): ${response_merkle_roots[*]:0:100}..." # Limit output length
    echo "Staker Rewards (${#response_staker_rewards[@]}): ${response_staker_rewards[*]:0:100}..." # Limit output length
    echo "Operator Rewards (${#response_operator_rewards[@]}): ${response_operator_rewards[*]:0:100}..." # Limit output length
    
    echo "Contract data (from blockchain):"
    echo "Vaults (${#contract_vaults[@]}): ${contract_vaults[*]:0:100}..." # Limit output length
    echo "Merkle Roots (${#contract_merkle_roots[@]}): ${contract_merkle_roots[*]:0:100}..." # Limit output length
    echo "Staker Rewards (${#contract_staker_rewards[@]}): ${contract_staker_rewards[*]:0:100}..." # Limit output length
    echo "Operator Rewards (${#contract_operator_rewards[@]}): ${contract_operator_rewards[*]:0:100}..." # Limit output length
    
    # Step 5: Compare the data
    echo "Comparing response data with contract data..."
    match=true
    
    # Special case - if both have empty arrays, consider it a match
    if [[ ${#response_vaults[@]} -eq 0 && ${#contract_vaults[@]} -eq 0 &&
          ${#response_merkle_roots[@]} -eq 0 && ${#contract_merkle_roots[@]} -eq 0 &&
          ${#response_staker_rewards[@]} -eq 0 && ${#contract_staker_rewards[@]} -eq 0 &&
          ${#response_operator_rewards[@]} -eq 0 && ${#contract_operator_rewards[@]} -eq 0 ]]; then
        echo "Both response and contract have empty arrays - this is a match"
    # Regular comparison for non-empty arrays
    elif [[ "${#response_vaults[@]}" -ne "${#contract_vaults[@]}" ]]; then
        echo "Vault array lengths don't match (response: ${#response_vaults[@]}, contract: ${#contract_vaults[@]})"
        match=false
    elif [[ "${#response_merkle_roots[@]}" -ne "${#contract_merkle_roots[@]}" ]]; then
        echo "Merkle root array lengths don't match (response: ${#response_merkle_roots[@]}, contract: ${#contract_merkle_roots[@]})"
        match=false
    elif [[ "${#response_staker_rewards[@]}" -ne "${#contract_staker_rewards[@]}" ]]; then
        echo "Staker rewards array lengths don't match (response: ${#response_staker_rewards[@]}, contract: ${#contract_staker_rewards[@]})"
        match=false
    elif [[ "${#response_operator_rewards[@]}" -ne "${#contract_operator_rewards[@]}" ]]; then
        echo "Operator rewards array lengths don't match (response: ${#response_operator_rewards[@]}, contract: ${#contract_operator_rewards[@]})"
        match=false
    else
        # Compare vaults if there are any to compare
        if [[ ${#response_vaults[@]} -gt 0 ]]; then
            for i in "${!response_vaults[@]}"; do
                if [[ "${response_vaults[$i],,}" != "${contract_vaults[$i],,}" ]]; then # Lowercase comparison
                    echo "Vault mismatch at index $i: ${response_vaults[$i]} vs ${contract_vaults[$i]}"
                    match=false
                    break
                fi
            done
        fi
        
        # Compare merkle roots if still matching and there are any to compare
        if [[ "$match" == true && ${#response_merkle_roots[@]} -gt 0 ]]; then
            for i in "${!response_merkle_roots[@]}"; do
                if [[ "${response_merkle_roots[$i],,}" != "${contract_merkle_roots[$i],,}" ]]; then # Lowercase comparison
                    echo "Merkle root mismatch at index $i: ${response_merkle_roots[$i]} vs ${contract_merkle_roots[$i]}"
                    match=false
                    break
                fi
            done
        fi
        
        # Compare staker rewards if still matching and there are any to compare
        if [[ "$match" == true && ${#response_staker_rewards[@]} -gt 0 ]]; then
            for i in "${!response_staker_rewards[@]}"; do
                if [[ "${response_staker_rewards[$i]}" != "${contract_staker_rewards[$i]}" ]]; then
                    echo "Staker reward mismatch at index $i: ${response_staker_rewards[$i]} vs ${contract_staker_rewards[$i]}"
                    match=false
                    break
                fi
            done
        fi
        
        # Compare operator rewards if still matching and there are any to compare
        if [[ "$match" == true && ${#response_operator_rewards[@]} -gt 0 ]]; then
            for i in "${!response_operator_rewards[@]}"; do
                if [[ "${response_operator_rewards[$i]}" != "${contract_operator_rewards[$i]}" ]]; then
                    echo "Operator reward mismatch at index $i: ${response_operator_rewards[$i]} vs ${contract_operator_rewards[$i]}"
                    match=false
                    break
                fi
            done
        fi
    fi
    
    # Step 6: Respond to the task based on the match result
    if [[ "$match" == true ]]; then
        echo "Data matches. Responding to task with 'true'..."
        respond_to_task "$TASK_COUNT" "true"
    else
        echo "Data does not match. Skipping task response."
        # Optional: Respond with false if you want to explicitly indicate a mismatch
        # respond_to_task "$response_task_id" "false"
    fi
    
    echo "Cycle complete at $(date). Waiting for next cycle..."
    TASK_COUNT=$((TASK_COUNT + 1))

    sleep 10
done