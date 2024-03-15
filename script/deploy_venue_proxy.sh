#!/bin/bash

export ETH_RPC_URL="https://sepolia.infura.io/v3/2WzgmaEOqz7wdfQaPYe2hnAFSKg"
export PRIVATE_KEY="9ad8ea34cdd8e1f6f4272c7884a62da1c7db612377999eab3d8cf9a653e4c19a"
export SELLOUT_PROTOCOL_WALLET="0x1dD37D479ac16113fF8f160210Ee209944d2b28d"
export ETHERSCAN_API_KEY="IPUKZ3RRCUJ47Q95JKIBW58Z3EFCDVAMX6"

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0xAE8C09948fE8cA98adAB9f560E352Df70C25AcC7"
export NEW_IMPLEMENTATION_ADDRESS="0x79c400F81aC11b87C5715ca14602cFeCf9465c69" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployProxy.s.sol:DeployProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

