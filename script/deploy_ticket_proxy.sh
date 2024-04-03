#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export SELLOUT_PROTOCOL_WALLET=""
export ETHERSCAN_API_KEY=""

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0xB7396333135FD3D20e357c29A6685F0ae8aa699a"
export NEW_IMPLEMENTATION_ADDRESS="0xc5D3dE61b8988ffb36813CCA34EfbC9F06d90a34" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployProxy.s.sol:DeployProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

