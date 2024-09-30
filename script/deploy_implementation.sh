#!/bin/bash

# Define environment variables

export ETH_RPC_URL=""
export PRIVATE_KEY=""
export ETHERSCAN_API_KEY=""
export SELLOUT_PROTOCOL_WALLET=""

# Function to deploy the contract
deploy_contract() {
    local gas_price=$1
    forge script DeployImplementation.s.sol:DeployImplementation \
        --rpc-url $ETH_RPC_URL \
        --private-key $PRIVATE_KEY \
        --broadcast \
        --verify \
        --etherscan-api-key $ETHERSCAN_API_KEY \
        --gas-price $gas_price \
        --force \
        -- --sellout-protocol-wallet $SELLOUT_PROTOCOL_WALLET
}

# Fetch current gas price and increase it significantly
current_gas_price=$(cast gas-price --rpc-url $ETH_RPC_URL)
adjusted_gas_price=$(echo "$current_gas_price * 3" | bc | cut -d '.' -f 1)

echo "Attempting deployment with gas price $adjusted_gas_price wei"

# Deploy the contract and capture full output
output=$(deploy_contract $adjusted_gas_price 2>&1)

# Log the full output for debugging
echo "Full deployment output:"
echo "$output"
echo "----------------------"

# Check for error messages
if echo "$output" | grep -q "error"; then
    echo "Warning: Error detected in output. Please review the full output above."
fi

# Check if deployment was successful despite errors
if echo "$output" | grep -q "NewArtistRegistryImplementation deployed at"; then
    deployedContract=$(echo "$output" | grep "NewArtistRegistryImplementation deployed at" | awk '{print $NF}')
    echo "Deployment appears to be successful despite errors!"
    echo "Deployed Contract Address: $deployedContract"
    export DEPLOYED_ADDRESS=$deployedContract
elif echo "$output" | grep -q "NewShowImplementation deployed at"; then
    deployedContract=$(echo "$output" | grep "NewShowImplementation deployed at" | awk '{print $NF}')
    echo "Deployment appears to be successful despite errors!"
    echo "Deployed Contract Address: $deployedContract"
    export DEPLOYED_ADDRESS=$deployedContract
else
    echo "Unable to find deployed contract address in the output."
    exit 1
fi

# Verify the deployment
echo "Attempting to verify the deployed contract..."
cast code $DEPLOYED_ADDRESS --rpc-url $ETH_RPC_URL
if [ $? -eq 0 ]; then
    echo "Contract verified successfully at address $DEPLOYED_ADDRESS"
else
    echo "Warning: Unable to verify contract at $DEPLOYED_ADDRESS"
fi
