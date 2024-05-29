#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export ETHERSCAN_API_KEY=""
export SELLOUT_PROTOCOL_WALLET=""

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS=""
export NEW_IMPLEMENTATION_ADDRESS="" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployProxy.s.sol:DeployProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

