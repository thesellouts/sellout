#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export ETHERSCAN_API_KEY=""
export SELLOUT_PROTOCOL_WALLET=""

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0x8406e793409bE7A70c304785cfEa1dBcD91fECc4"
export NEW_IMPLEMENTATION_ADDRESS="0x8593Addd86Ddd81871F6ED15fAF44639ad934C2B" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployShowProxy.s.sol:DeployShowProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

