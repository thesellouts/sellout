#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export ETHERSCAN_API_KEY=""
export SELLOUT_PROTOCOL_WALLET=""

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0xa9EFaECF8ddcf638555c682Fe4F98bC869880aBC"
export NEW_IMPLEMENTATION_ADDRESS="0xA0A970e224D31b54cC95E76225a9d3d1b3Cc51eD" # The address of the newly deployed implementation contrac

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployProxy.s.sol:DeployProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

