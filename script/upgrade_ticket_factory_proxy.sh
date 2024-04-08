#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export SELLOUT_PROTOCOL_WALLET=""
export ETHERSCAN_API_KEY=""

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0x1756E8ECDF73D58304e2BF8F6a8bF361B9FC29F4"
export NEW_IMPLEMENTATION_ADDRESS="0x872BD206F13F28882EBF3719c7D0A4494E9D0Ec8" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployProxy.s.sol:DeployProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

