#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export SELLOUT_PROTOCOL_WALLET=""
export ETHERSCAN_API_KEY=""

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0x4F42857dc6e937D5b3131873561785a87AAa3E16"
export NEW_IMPLEMENTATION_ADDRESS="0xA4009241a00329edBc39D77E9D8c7cb7533C7355" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployProxy.s.sol:DeployProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

