#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export ETHERSCAN_API_KEY=""
export SELLOUT_PROTOCOL_WALLET=""

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0x363e6044FfE912a87813e28240eba20D16dE8870"
export NEW_IMPLEMENTATION_ADDRESS="0xf30d9BB0918B26daE62902D586fa42321FB8cBb3" # The address of the newly deployed implementation contract
export VERSION="1.0.0"

# Run the Forge script to upgrade the proxy to the new implementation
forge script UpgradeProxy.s.sol:UpgradeProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

