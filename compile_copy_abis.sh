#!/bin/bash

# Step 1: Build your contracts with Forge
forge build

# Step 2: Copy ABIs to your desired location
mkdir -p abis
cp -R out/*.sol/*.json abis/

echo "ABIs copied to the ../abis/ directory."
