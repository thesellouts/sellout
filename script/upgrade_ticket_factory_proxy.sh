#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export ETHERSCAN_API_KEY=""
export SELLOUT_PROTOCOL_WALLET=""


# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0xe72A5818c4de87C0F9457808f63F77D6f0048554"
export NEW_IMPLEMENTATION_ADDRESS="0x77Fc66031d5b0d7AB8e24BC9382c733845e29B56" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployProxy.s.sol:DeployProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

