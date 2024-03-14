#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export ETHERSCAN_API_KEY=""
export SELLOUT_PROTOCOL_WALLET=""

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0x687e7CAF767F1952964c5b92f1a7e3b113553D2C"
export NEW_IMPLEMENTATION_ADDRESS="0x707fbBFD0496aa488B179cfBF0097d9B356DD3fa" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployTicketProxy.s.sol:DeployTicketProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

