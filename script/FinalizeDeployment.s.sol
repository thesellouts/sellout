// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { IShow } from "../src/show/IShow.sol";
import { IReferralModule } from "../src/registry/referral/IReferralModule.sol";

contract FinalizeDeployment is Script {
    function run() external {
        vm.startBroadcast();

        // Fetch addresses from environment variables
        address showAddress = vm.envAddress("SHOW_ADDRESS");
        address ticketAddress = vm.envAddress("TICKET_ADDRESS");
        address venueAddress = vm.envAddress("VENUE_ADDRESS");
        address referralModuleAddress = vm.envAddress("REFERRAL_MODULE_ADDRESS");
        address artistRegistryAddress = vm.envAddress("ARTIST_REGISTRY_ADDRESS");
        address organizerRegistryAddress = vm.envAddress("ORGANIZER_REGISTRY_ADDRESS");
        address venueRegistryAddress = vm.envAddress("VENUE_REGISTRY_ADDRESS");

        // Set protocol addresses in Show contract
        IShow(showAddress).setProtocolAddresses(
            ticketAddress,
            venueAddress,
            referralModuleAddress,
            artistRegistryAddress,
            organizerRegistryAddress,
            venueRegistryAddress
        );

        // Set permissions
        IReferralModule(referralModuleAddress).setCreditControlPermission(artistRegistryAddress, true);
        IReferralModule(referralModuleAddress).setCreditControlPermission(organizerRegistryAddress, true);
        IReferralModule(referralModuleAddress).setCreditControlPermission(venueRegistryAddress, true);

        vm.stopBroadcast();
    }
}
