// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../../src/registry/referral/ReferralModule.sol";
import "../../src/registry/venue/VenueRegistry.sol";

contract TestVenueRegistry is Test {
    VenueRegistry public venueRegistry;
    ReferralModule public referralModule;
    address public userWithReferralCredits = address(0x123);
    address public nominee = address(0x124);

    function setUp() public {
        // Initialize the ReferralModule with the test contract acting as both showContract and selloutProtocolWallet
        referralModule = new ReferralModule(address(this), address(this));

        venueRegistry = new VenueRegistry(address(referralModule));

        // Setting permission for the OrganizerRegistry to decrement referral credits
        referralModule.setDecrementPermission(address(venueRegistry), true);

        // Giving referral credits to a user
        referralModule.incrementReferralCredits(userWithReferralCredits, 0, 0, 1); // artist = 0, organizer = 1, venue = 0
    }

    function testVenueNominationAndAcceptance() public {
        // Nominate a new venue
        vm.prank(userWithReferralCredits);
        venueRegistry.nominate(nominee);

        // Accept the nomination
        vm.prank(nominee);
        venueRegistry.acceptNomination();

        // Verify the nomination was successful by checking if the nominee now has venue info
        (, , address wallet) = venueRegistry.getVenueInfoByAddress(nominee);
        assertTrue(wallet == nominee, "Nominee should have venue info after acceptance");
    }

    function testVenueUpdate() public {
        // Setup: Nominate and accept a venue to update
        testVenueNominationAndAcceptance();

        // New name and biography for the venue
        string memory newName = "Updated Venue Name";
        string memory newBio = "Updated Venue Bio";

        // Update the venue's information
        vm.prank(nominee);
        venueRegistry.updateVenue(1, newName, newBio); // Assuming ID 1 for simplicity, adjust as needed

        // Verify the update was successful
        (string memory name, string memory bio, ) = venueRegistry.getVenueInfoByAddress(nominee);
        assertEq(name, newName, "Venue name was not updated correctly.");
        assertEq(bio, newBio, "Venue bio was not updated correctly.");
    }

    function testVenueDeregistration() public {
        // Setup: Nominate and accept a venue to deregister
        testVenueNominationAndAcceptance();

        // Deregister the venue
        vm.prank(nominee);
        venueRegistry.deregisterVenue(1); // Assuming ID 1 for simplicity, adjust as needed

        // Attempt to fetch deregistered venue info, check for default or empty values
        (string memory name, string memory bio, address wallet) = venueRegistry.getVenueInfoByAddress(nominee);
        assertEq(wallet, address(0), "Venue wallet should be default address.");
        assertEq(name, "", "Venue name should be empty.");
        assertEq(bio, "", "Venue bio should be empty.");
    }
}
