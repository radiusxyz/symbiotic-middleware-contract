#!/bin/bash

# Run the call and store the result
RESULT=$(cast send $VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS \
"respondToSlash(bytes32,bytes32,bytes32[])" \
"0xc43a1f30c21425c3021a6362099a4355686d6817403ff144d3f99a8bd78df86c" \
"0x4d0b13707355c93681a51e525119518d6586db07ab64b878ef2cf88be29b3b3d" \
"[0xd13fcca68450d9154aec3585e2dd932c0e78588e8395dae1efb2f0aca780bcd0,0xc5f53e70a351c5101b691cac14fa249f26e6afcf82a362e64e4f559ae968d1a8]" \
--rpc-url $RPC_URL)

# Extract bytes32 values (each 64 characters after 0x)
INITIAL_HASH=${RESULT:0:66}
AFTER_PRE_MERKLE=${RESULT:66:64}
FINAL_HASH=${RESULT:130:64}
EXPECTED_ROOT=${RESULT:194:64}
IS_VALID=${RESULT:258:64}

# Convert hex to boolean for is_valid (0 = false, 1 = true)
if [ "$IS_VALID" = "0000000000000000000000000000000000000000000000000000000000000001" ]; then
    IS_VALID_BOOL="true"
else
    IS_VALID_BOOL="false"
fi

# Print the results
echo "Debug Verification Results:"
echo "------------------------"
echo "Initial Hash:       0x$INITIAL_HASH"
echo "After Pre-Merkle:   0x$AFTER_PRE_MERKLE"
echo "Final Hash:         0x$FINAL_HASH"
echo "Expected Root:      0x$EXPECTED_ROOT"
echo "Is Valid:           $IS_VALID_BOOL"