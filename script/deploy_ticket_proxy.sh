#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export ETHERSCAN_API_KEY=""
export SELLOUT_PROTOCOL_WALLET=""

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0xd0c43b304ff5e40AE6df9578c111b9769FB798F4"
export NEW_IMPLEMENTATION_ADDRESS="0x346EaF7117fE9655D97eCc4427c0b2A901289Be5" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployTicketProxy.s.sol:DeployTicketProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

