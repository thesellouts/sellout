// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { ReferralModule } from "../src/registry/referral/ReferralModule.sol";
import { VenueRegistry } from "../src/registry/venue/VenueRegistry.sol";
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
        // Updated to include additional parameters
        int256 exampleLatitude = 12345678; // Example value for latitude
        int256 exampleLongitude = -87654321; // Example value for longitude
        uint256 exampleTotalCapacity = 1000; // Example value for total capacity
        string memory exampleStreetAddress = "123 Example St, City, Country"; // Example street address

        vm.prank(NOMINEE);
        venueRegistry.acceptNomination(
            "Sellout Venue",
            "The Venue.",
            exampleLatitude,
            exampleLongitude,
            exampleTotalCapacity,
            exampleStreetAddress
        );

        // Verify the venue's registration
        // Updated to capture and assert all returned values
        (,,, address wallet,,, uint256 totalCapacity, string memory streetAddress) = venueRegistry.getVenue(NOMINEE);
        assertEq(wallet, NOMINEE, "The venue's wallet address should match the nominated address.");
        assertEq(totalCapacity, exampleTotalCapacity, "The venue's total capacity should match the provided value.");
        assertEq(streetAddress, exampleStreetAddress, "The venue's street address should match the provided value.");
    }

    function testVenueUpdate() public {
        // Setup: Nominate and accept a venue to update
        testVenueNominationAndAcceptance();

        // New information for the venue
        string memory newName = "Updated Venue Name";
        string memory newBio = "Updated Venue Bio";
        address newAddr = address(3);
        int256 newLatitude = 98765432; // New example latitude
        int256 newLongitude = -23456789; // New example longitude
        uint256 newTotalCapacity = 2000; // New example total capacity
        string memory newStreetAddress = "456 Another St, New City, New Country"; // New street address

        // Update the venue's information
        // Assuming ID 1 for simplicity, adjust as needed
        vm.prank(NOMINEE);
        venueRegistry.updateVenue(1, newName, newBio, newAddr, newLatitude, newLongitude, newTotalCapacity, newStreetAddress);

        // Verify the update was successful
        // Adjusted to capture and assert all returned values
        (, string memory name, string memory bio, address wallet, int256 latitude, int256 longitude, uint256 totalCapacity, string memory streetAddress) = venueRegistry.getVenue(NOMINEE);
        assertEq(name, newName, "Venue name was not updated correctly.");
        assertEq(bio, newBio, "Venue bio was not updated correctly.");
        assertEq(wallet, newAddr, "Venue wallet was not updated correctly.");
        assertEq(latitude, newLatitude, "Venue latitude was not updated correctly.");
        assertEq(longitude, newLongitude, "Venue longitude was not updated correctly.");
        assertEq(totalCapacity, newTotalCapacity, "Venue total capacity was not updated correctly.");
        assertEq(streetAddress, newStreetAddress, "Venue street address was not updated correctly.");
    }
    function testVenueDeregistration() public {
        // Setup: Nominate and accept a venue to deregister
        testVenueNominationAndAcceptance();

        // Deregister the venue
        vm.prank(NOMINEE);
        venueRegistry.deregisterVenue(1); // Assuming ID 1 for simplicity, adjust as needed

        // Attempt to fetch deregistered venue info, check for default or empty values
        (, string memory name, string memory bio, address wallet, int latitude, int longitude, uint256 totalCapacity, string memory streetAddress) = venueRegistry.getVenue(NOMINEE);
        assertEq(wallet, address(0), "Venue wallet should be default address after deregistration.");
        assertEq(name, "", "Venue name should be empty after deregistration.");
        assertEq(bio, "", "Venue bio should be empty after deregistration.");

        // Add assertions for the additional variables
        // Assuming that the default values for latitude, longitude, totalCapacity, and streetAddress are set to 0, 0, 0, and "" respectively after deregistration
        assertEq(latitude, 0, "Venue latitude should be 0 after deregistration.");
        assertEq(longitude, 0, "Venue longitude should be 0 after deregistration.");
        assertEq(totalCapacity, 0, "Venue totalCapacity should be 0 after deregistration.");
        assertEq(streetAddress, "", "Venue streetAddress should be empty after deregistration.");
    }

    function testFailVenueNominationByUnauthorizedUser() public {
        address unauthorizedUser = address(0x3);
        vm.prank(unauthorizedUser);
        vm.expectRevert("Unauthorized");
        venueRegistry.nominate(NOMINEE);
    }
}
