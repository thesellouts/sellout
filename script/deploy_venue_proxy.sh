#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export SELLOUT_PROTOCOL_WALLET=""
export ETHERSCAN_API_KEY=""

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0xAE8C09948fE8cA98adAB9f560E352Df70C25AcC7"
export NEW_IMPLEMENTATION_ADDRESS="0x2a002B1a0CbBBb855a5480FF367400a1F0b05648" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployProxy.s.sol:DeployProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

