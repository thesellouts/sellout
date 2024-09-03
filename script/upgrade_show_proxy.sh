#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export ETHERSCAN_API_KEY=""
export SELLOUT_PROTOCOL_WALLET=""


# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0x40d3c957F6854f8F94648CC1834E66432909237A"
export NEW_IMPLEMENTATION_ADDRESS="0x7714ab6150D42705451324a0f910E2434056325c" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployProxy.s.sol:DeployProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

