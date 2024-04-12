#!/bin/bash

# Set the RPC URL and the private key for the deployment account
export ETH_RPC_URL="https://sepolia.infura.io/v3/2WzgmaEOqz7wdfQaPYe2hnAFSKg"
export PRIVATE_KEY="9ad8ea34cdd8e1f6f4272c7884a62da1c7db612377999eab3d8cf9a653e4c19a"
export ETHERSCAN_API_KEY="IPUKZ3RRCUJ47Q95JKIBW58Z3EFCDVAMX6"
export SELLOUT_PROTOCOL_WALLET="0x1dD37D479ac16113fF8f160210Ee209944d2b28d"

# Deploy ReferralModule and capture its address
referralModuleAddress=$(forge script DeployReferralModule.s.sol:DeployReferralModule --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -- --sellout-protocol-wallet $SELLOUT_PROTOCOL_WALLET | grep "ReferralModule deployed at" | awk '{print $NF}')
export REFERRAL_MODULE_ADDRESS=$referralModuleAddress

# Deploy ArtistRegistry with the address of ReferralModule
artistRegistryAddress=$(forge script DeployArtistRegistry.s.sol:DeployArtistRegistry --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -- --sellout-protocol-wallet $SELLOUT_PROTOCOL_WALLET --referral-module-address $referralModuleAddress | grep "ArtistRegistry deployed at" | awk '{print $NF}')
export ARTIST_REGISTRY_ADDRESS=$artistRegistryAddress

# Deploy OrganizerRegistry with the address of ReferralModule
organizerRegistryAddress=$(forge script DeployOrganizerRegistry.s.sol:DeployOrganizerRegistry --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -- --sellout-protocol-wallet $SELLOUT_PROTOCOL_WALLET --referral-module-address $referralModuleAddress | grep "OrganizerRegistry deployed at" | awk '{print $NF}')
export ORGANIZER_REGISTRY_ADDRESS=$organizerRegistryAddress

# Deploy VenueRegistry with the address of ReferralModule
venueRegistryAddress=$(forge script DeployVenueRegistry.s.sol:DeployVenueRegistry --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -- --sellout-protocol-wallet $SELLOUT_PROTOCOL_WALLET --referral-module-address $referralModuleAddress | grep "VenueRegistry deployed at" | awk '{print $NF}')
export VENUE_REGISTRY_ADDRESS=$venueRegistryAddress

# Deploy Show with Sellout Protocol Wallet as an argument
showAddress=$(forge script DeployShow.s.sol:DeployShow --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -- --sellout-protocol-wallet $SELLOUT_PROTOCOL_WALLET | grep "Show deployed at" | awk '{print $NF}')
export SHOW_ADDRESS=$showAddress

# Deploy Venue with Show Address, Ticket Address, and Sellout Protocol Wallet as arguments
#venueAddress=$(forge script DeployVenue.s.sol:DeployVenue --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -- --sellout-protocol-wallet $SELLOUT_PROTOCOL_WALLET --show-address $showAddress | grep "Venue deployed at" | awk '{print $NF}')
#export VENUE_ADDRESS=$venueAddress

## Deploy the Ticket implementation (template) contract first and capture its address
ticketFactoryAddress=$(forge script DeployTicketFactory.s.sol:DeployTicketFactory --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -- --show-address $showAddress | grep "TicketFactory deployed at" | awk '{print $NF}')
export TICKET_FACTORY_ADDRESS=$ticketFactoryAddress

## Deploy the Ticket implementation (template) contract first and capture its address
venueFactoryAddress=$(forge script DeployVenueFactory.s.sol:DeployVenueFactory --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -- --show-address $showAddress | grep "VenueFactory deployed at" | awk '{print $NF}')
export VENUE_FACTORY_ADDRESS=$venueFactoryAddress

# Assuming all deployment addresses have been exported as environment variables
forge script FinalizeDeployment.s.sol:FinalizeDeployment --rpc-url $ETH_RPC_URL --private-key $PRIVATE_KEY --broadcast

echo "Deployed ReferralModule at $referralModuleAddress"
echo "Deployed ArtistRegistry at $artistRegistryAddress"
echo "Deployed OrganizerRegistry at $organizerRegistryAddress"
echo "Deployed VenueRegistry at $venueRegistryAddress"
echo "Deployed Show at $showAddress"
echo "Deployed VenueFactory at venueFactoryAddress $venueFactoryAddress"
echo "Deployed TicketFactory at $ticketFactoryAddress"
