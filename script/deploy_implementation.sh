#!/bin/bash

# Define environment variables
export ETH_RPC_URL="https://sepolia.infura.io/v3/2WzgmaEOqz7wdfQaPYe2hnAFSKg"
export PRIVATE_KEY="9ad8ea34cdd8e1f6f4272c7884a62da1c7db612377999eab3d8cf9a653e4c19a"
export ETHERSCAN_API_KEY="IPUKZ3RRCUJ47Q95JKIBW58Z3EFCDVAMX6"
export SELLOUT_PROTOCOL_WALLET="0x1dD37D479ac16113fF8f160210Ee209944d2b28d"

# Navigate to the directory where your deployment script is located, if necessary
# cd path/to/your/scripts

# Execute the deployment script
deployedContract=$(forge script DeployImplementation.s.sol:DeployImplementation --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -- --sellout-protocol-wallet $SELLOUT_PROTOCOL_WALLET | grep "NewShowImplementation deployed at" | awk '{print $NF}')

# Export the deployed contract address for further use
export DEPLOYED_ADDRESS=$deployedContract

echo "Deployed Contract Address: $DEPLOYED_ADDRESS"
