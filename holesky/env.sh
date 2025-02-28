export RPC_URL="https://ethereum-holesky-rpc.publicnode.com"

export RADIUS_ADDRESS="0x96C969D31b4fa8A93a081aCB1271D13fb157bd1e"
export RADIUS_PRIVATE_KEY="0x2141478fe814f58de31b5a6fb2a7682b7dae755cc19bab6acdbfa1fcfe6e64e1"

# Rollup side 
export NETWORK_ADDRESS="0x96C969D31b4fa8A93a081aCB1271D13fb157bd1e"
export NETWORK_PRIVATE_KEY="0x2141478fe814f58de31b5a6fb2a7682b7dae755cc19bab6acdbfa1fcfe6e64e1"

export SUBNETWORK="0x96C969D31b4fa8A93a081aCB1271D13fb157bd1e000000000000000000000000"

####### Radius
export LIVENESS_CONTRACT_ADDRESS="0xF05D4533801F921ae57f244EfD15B48f6E60a0ba"
export INITIAL_SUPPLY="1000000000000000000000000000"
#######
export TOKEN_CONTRACT_OWNER_ADDRESS="0x96C969D31b4fa8A93a081aCB1271D13fb157bd1e"
export TOKEN_CONTRACT_OWNER_PRIVATE_KEY="0x2141478fe814f58de31b5a6fb2a7682b7dae755cc19bab6acdbfa1fcfe6e64e1"
export TOKEN_CONTRACT_ADDRESS="0x099483Fc4164803FAd1aDb880C03129D4F05acc0"

export COLLATERAL_OWNER_ADDRESS="0x96C969D31b4fa8A93a081aCB1271D13fb157bd1e"
export COLLATERAL_OWNER_PRIVATE_KEY="0x2141478fe814f58de31b5a6fb2a7682b7dae755cc19bab6acdbfa1fcfe6e64e1"
export COLLATERAL_CONTRACT_ADDRESS="0x1E4dE50B7765394de8D1363eaDBCB8875fd56b39"

####### Symbiotic (holesky) 
export VAULT_CONFIGURATOR_ADDRESS="0xD2191FE92987171691d552C219b8caEf186eb9cA"
export OPERATOR_REGISTRY_CONTRACT_ADDRESS="0x6F75a4ffF97326A00e52662d82EA4FdE86a2C548"
export VAULT_FACTORY_CONTRACT_ADDRESS="0x407A039D94948484D356eFB765b3c74382A050B4"
export OPERATOR_NETWORK_OPT_IN_SERVICE_CONTRACT_ADDRESS="0x58973d16FFA900D11fC22e5e2B6840d9f7e13401"
export NETWORK_MIDDLEWARE_SERVICE_CONTRACT_ADDRESS="0x62a1ddfD86b4c1636759d9286D3A0EC722D086e3"
export NETWORK_REGISTRY_CONTRACT_ADDRESS="0x7d03b7343BF8d5cEC7C0C27ecE084a20113D15C9"
export OPERATOR_VAULT_OPT_IN_SERVICE_CONTRACT_ADDRESS="0x95CC0a052ae33941877c9619835A233D21D57351"
#######

export VALIDATION_SERVICE_MANAGER_EPOCH_DURATION=12

####### Vault
export VAULT_OWNER_ADDRESS="0x96C969D31b4fa8A93a081aCB1271D13fb157bd1e"
export VAULT_OWNER_PRIVATE_KEY="0x2141478fe814f58de31b5a6fb2a7682b7dae755cc19bab6acdbfa1fcfe6e64e1"
export VAULT_CONTRACT_ADDRESS="0x919c0EbA1b68803cd453fF218b0E59e174d8C2b0"
export SLASHER="0x0000000000000000000000000000000000000000"
export DELEGATOR_CONTRACT_ADDRESS="0xb595750e2b8f98DdF052107078BdC34579A0d505"
#######

####### Rollup
export VALIDATION_SERVICE_MANAGER_CONTRACT_ADDRESS="0xE8Bab05Db590449FA71D69DE64cFABD7317b64e3"
#######


####### Operator
# ./sender/symbiotic/03_optin_operator.sh
# ./sender/validation/02_register_operator.sh
# ./sender/liveness/03_register_sequencer.sh 

# export OPERATOR_ADDRESS="0x96C969D31b4fa8A93a081aCB1271D13fb157bd1e"
# export OPERATOR_PRIVATE_KEY="0x2141478fe814f58de31b5a6fb2a7682b7dae755cc19bab6acdbfa1fcfe6e64e1"
# export OPERATING_ADDRESS="0x96C969D31b4fa8A93a081aCB1271D13fb157bd1e"
# export OPERATING_PRIVATE_KEY="0x2141478fe814f58de31b5a6fb2a7682b7dae755cc19bab6acdbfa1fcfe6e64e1"

# export OPERATOR_ADDRESS="0xef0A6084c6b0c21f09E7E3c8Fe56466B96E9dFFC"
# export OPERATOR_PRIVATE_KEY="0xabe756f4bc9ad050f245c3feb5f59b8636080003a205ebe3b661255a0feac684"
# export OPERATING_ADDRESS="0xef0A6084c6b0c21f09E7E3c8Fe56466B96E9dFFC"
# export OPERATING_PRIVATE_KEY="0xabe756f4bc9ad050f245c3feb5f59b8636080003a205ebe3b661255a0feac684"

# export OPERATOR_ADDRESS="0x4eFD3aE99ac12829A391e4cdD609D7389DCD7E96"
# export OPERATOR_PRIVATE_KEY="0x426b32ddfedee270f855555147f7a42ee7a3b8b606ad9efca61f8733fe579734"
# export OPERATING_ADDRESS="0x4eFD3aE99ac12829A391e4cdD609D7389DCD7E96"
# export OPERATING_PRIVATE_KEY="0x426b32ddfedee270f855555147f7a42ee7a3b8b606ad9efca61f8733fe579734"

export OPERATOR_ADDRESS="0x65c73C1a165f0fcFBD0DcAF60a02E5bD59F7faf3"
export OPERATOR_PRIVATE_KEY="0x42f1bfd88712d4c6e18fdaa2fbc75509ca47ea26ff076c53010105e7d82be97a"
export OPERATING_ADDRESS="0x65c73C1a165f0fcFBD0DcAF60a02E5bD59F7faf3"
export OPERATING_PRIVATE_KEY="0x42f1bfd88712d4c6e18fdaa2fbc75509ca47ea26ff076c53010105e7d82be97a"
#######

export CLUSTER_ID="radius"
export MAX_SEQUENCER_NUMBER=30

export ROLLUP_ID="radius_rollup"
export OWNER_ADDRESS=$NETWORK_ADDRESS
export ROLLUP_TYPE="polygon_cdk"
export ENCRYPTED_TRANSACTION_TYPE="skde"
export PLATFORM="ethereum"
export SERVICE_PROVIDER="symbiotic"
export ORDER_COMMITMENT_TYPE="sign"
export EXECUTOR_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"

export DEPOSIT_AMOUNT="1000"