#!/bin/bash

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export ETHERSCAN_API_KEY=""
export SELLOUT_PROTOCOL_WALLET=""

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0xEe4dF1BcFf1D42D4Ad45c61cbE71978b29415f34"
export NEW_IMPLEMENTATION_ADDRESS="0x3eb9893d1C32698E82468c5e7922Bb50860F0fb8" # The address of the newly deployed implementation contract
export VERSION="1.0.0"

# Run the Forge script to upgrade the proxy to the new implementation
forge script UpgradeProxy.s.sol:UpgradeProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

