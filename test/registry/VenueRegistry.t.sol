// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { ReferralModule } from "../../src/registry/referral/ReferralModule.sol";
import { VenueRegistry } from "../../src/registry/venue/VenueRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract VenueRegistryTest is Test {
    ReferralModule referralModule;
    VenueRegistry venueRegistry;
    address SELLOUT_PROTOCOL_WALLET = address(1);
    address NOMINEE = address(2);

    function setUp() external {
        // Deploy ReferralModule through a proxy
        bytes memory initDataReferral = abi.encodeWithSelector(ReferralModule.initialize.selector, SELLOUT_PROTOCOL_WALLET);
        ERC1967Proxy proxyReferral = new ERC1967Proxy(address(new ReferralModule()), initDataReferral);
        referralModule = ReferralModule(address(proxyReferral));

        // Deploy VenueRegistry through a proxy
        bytes memory initDataVenueRegistry = abi.encodeWithSelector(VenueRegistry.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(referralModule));
        ERC1967Proxy proxyVenueRegistry = new ERC1967Proxy(address(new VenueRegistry()), initDataVenueRegistry);
        venueRegistry = VenueRegistry(address(proxyVenueRegistry));

        // Set permission for the VenueRegistry to decrement referral credits
        vm.prank(SELLOUT_PROTOCOL_WALLET);
        referralModule.setCreditControlPermission(address(proxyVenueRegistry), true);

        // Adding some referral credits for testing
        vm.prank(address(proxyVenueRegistry));
        referralModule.incrementReferralCredits(address(this), 0, 0, 10); // Adding venue credits for simplicity
    }

    function testVenueNominationAndAcceptance() public {
        // Assume this contract has referral credits to nominate venues
        venueRegistry.nominate(NOMINEE); // Nominate a new venue

        // Accept the nomination from the nominated venue's perspective
        vm.prank(NOMINEE);
        venueRegistry.acceptNomination("Sellout Venue", "The Venue.");

        // Verify the venue's registration
        (,, address wallet) = venueRegistry.getVenue(NOMINEE);
        assertEq(wallet, NOMINEE, "The venue's wallet address should match the nominated address.");
    }

    function testVenueUpdate() public {
        // Setup: Nominate and accept a venue to update
        testVenueNominationAndAcceptance();

        // New name and biography for the venue
        string memory newName = "Updated Venue Name";
        string memory newBio = "Updated Venue Bio";
        address newAddr = address(3);

        // Update the venue's information
        vm.prank(NOMINEE);
        venueRegistry.updateVenue(1, newName, newBio, newAddr); // Assuming ID 1 for simplicity, adjust as needed

        // Verify the update was successful
        (string memory name, string memory bio, address wallet) = venueRegistry.getVenue(NOMINEE);
        assertEq(name, newName, "Venue name was not updated correctly.");
        assertEq(bio, newBio, "Venue bio was not updated correctly.");
        assertEq(wallet, newAddr, "Venue wallet was not updated correctly.");

    }

    function testVenueDeregistration() public {
        // Setup: Nominate and accept a venue to deregister
        testVenueNominationAndAcceptance();

        // Deregister the venue
        vm.prank(NOMINEE);
        venueRegistry.deregisterVenue(1); // Assuming ID 1 for simplicity, adjust as needed

        // Attempt to fetch deregistered venue info, check for default or empty values
        (string memory name, string memory bio, address wallet) = venueRegistry.getVenue(NOMINEE);
        assertEq(wallet, address(0), "Venue wallet should be default address.");
        assertEq(name, "", "Venue name should be empty.");
        assertEq(bio, "", "Venue bio should be empty.");
    }
}
