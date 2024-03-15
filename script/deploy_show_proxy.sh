#!/bin/bash

export ETH_RPC_URL="https://sepolia.infura.io/v3/2WzgmaEOqz7wdfQaPYe2hnAFSKg"
export PRIVATE_KEY="9ad8ea34cdd8e1f6f4272c7884a62da1c7db612377999eab3d8cf9a653e4c19a"
export SELLOUT_PROTOCOL_WALLET="0x1dD37D479ac16113fF8f160210Ee209944d2b28d"
export ETHERSCAN_API_KEY="IPUKZ3RRCUJ47Q95JKIBW58Z3EFCDVAMX6"

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0xe9c1727B668Ce1106FAA49ceA48bf1b33527E913"
export NEW_IMPLEMENTATION_ADDRESS="0x8ed4A2dB90e1439144a93a136E056c16710269D0" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployProxy.s.sol:DeployProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

