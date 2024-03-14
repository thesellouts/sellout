#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export ETHERSCAN_API_KEY=""
export SELLOUT_PROTOCOL_WALLET=""

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0xe9c1727B668Ce1106FAA49ceA48bf1b33527E913"
export NEW_IMPLEMENTATION_ADDRESS="0x06Cf41d3F387494C319F81D4c14C5a22caBd6544" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployShowProxy.s.sol:DeployShowProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

