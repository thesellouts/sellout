#!/bin/bash

# Define environment variables
export ETH_RPC_URL=""
export PRIVATE_KEY=""
export ETHERSCAN_API_KEY=""
export SELLOUT_PROTOCOL_WALLET=""
# Navigate to the directory where your deployment script is located, if necessary
# cd path/to/your/scripts

# Execute the deployment script
deployedContract=$(forge script DeployImplementation.s.sol:DeployImplementation --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -- --sellout-protocol-wallet $SELLOUT_PROTOCOL_WALLET | grep "NewShowImplementation deployed at" | awk '{print $NF}')

# Export the deployed contract address for further use
export DEPLOYED_ADDRESS=$deployedContract

echo "Deployed Contract Address: $DEPLOYED_ADDRESS"
