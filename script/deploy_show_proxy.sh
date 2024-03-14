#!/bin/bash

export ETH_RPC_URL="https://sepolia.infura.io/v3/2WzgmaEOqz7wdfQaPYe2hnAFSKg"
export PRIVATE_KEY="9ad8ea34cdd8e1f6f4272c7884a62da1c7db612377999eab3d8cf9a653e4c19a"
export ETHERSCAN_API_KEY="IPUKZ3RRCUJ47Q95JKIBW58Z3EFCDVAMX6"
export SELLOUT_PROTOCOL_WALLET="0x1dD37D479ac16113fF8f160210Ee209944d2b28d"


# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0x8406e793409bE7A70c304785cfEa1dBcD91fECc4"
export NEW_IMPLEMENTATION_ADDRESS="0x5cF69cfA4cB5e77b6bD7F701b623aEbDfCA75E4B" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployShowProxy.s.sol:DeployShowProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

