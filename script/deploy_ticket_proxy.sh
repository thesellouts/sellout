#!/bin/bash

export ETH_RPC_URL="https://sepolia.infura.io/v3/2WzgmaEOqz7wdfQaPYe2hnAFSKg"
export PRIVATE_KEY="9ad8ea34cdd8e1f6f4272c7884a62da1c7db612377999eab3d8cf9a653e4c19a"
export ETHERSCAN_API_KEY="IPUKZ3RRCUJ47Q95JKIBW58Z3EFCDVAMX6"
export SELLOUT_PROTOCOL_WALLET="0x1dD37D479ac16113fF8f160210Ee209944d2b28d"

# Set the address of the proxy you want to upgrade
export PROXY_ADDRESS="0xd0c43b304ff5e40AE6df9578c111b9769FB798F4"
export NEW_IMPLEMENTATION_ADDRESS="0x7A7afaBbc73283DCf40Ab90Ea4884E8B6e5fC321" # The address of the newly deployed implementation contract

# Run the Forge script to upgrade the proxy to the new implementation
forge script DeployTicketProxy.s.sol:DeployTicketProxy --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key YOUR_ETHERSCAN_API_KEY

