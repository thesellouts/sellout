// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../../src/registry/referral/ReferralModule.sol";
import "../../src/registry/organizer/OrganizerRegistry.sol";

contract TestOrganizerRegistry is Test {
    OrganizerRegistry public organizerRegistry;
    ReferralModule public referralModule;
    address public userWithReferralCredits = address(0x123);
    address public nominee = address(0x124);

    function setUp() public {
        // Initialize the ReferralModule with the test contract acting as both showContract and selloutProtocolWallet
        referralModule = new ReferralModule(address(this), address(this));

        organizerRegistry = new OrganizerRegistry(address(referralModule));

        // Setting permission for the OrganizerRegistry to decrement referral credits
        referralModule.setCreditControlPermission(address(organizerRegistry), true);

        // Giving referral credits to a user
        referralModule.incrementReferralCredits(userWithReferralCredits, 0, 1, 0); // artist = 0, organizer = 1, venue = 0
    }

    function testOrganizerNominationAndAcceptance() public {
        // Nominate a new organizer
        vm.prank(userWithReferralCredits);
        organizerRegistry.nominate(nominee);

        // Accept the nomination
        vm.prank(nominee);
        organizerRegistry.acceptNomination();

        // Verify the nomination was successful by checking if the nominee now has organizer info
        (, , address wallet) = organizerRegistry.getOrganizerInfoByAddress(nominee);
        assertTrue(wallet == nominee, "Nominee should have organizer info after acceptance");
    }

    function testOrganizerUpdate() public {
        // Setup: Nominate and accept an organizer to update
        testOrganizerNominationAndAcceptance();

        // New name and biography for the organizer
        string memory newName = "Updated Organizer Name";
        string memory newBio = "Updated Organizer Bio";

        // Update the organizer's information
        vm.prank(nominee);
        organizerRegistry.updateOrganizer(1, newName, newBio); // Assuming ID 1 for simplicity, adjust as needed

        // Verify the update was successful
        (string memory name, string memory bio, ) = organizerRegistry.getOrganizerInfoByAddress(nominee);
        assertEq(name, newName, "Organizer name was not updated correctly.");
        assertEq(bio, newBio, "Organizer bio was not updated correctly.");
    }

    function testOrganizerDeregistration() public {
        // Setup: Nominate and accept an organizer to deregister
        testOrganizerNominationAndAcceptance();

        // Deregister the organizer
        vm.prank(nominee);
        organizerRegistry.deregisterOrganizer(1); // Assuming ID 1 for simplicity, adjust as needed

        // Attempt to fetch deregistered organizer info, check for default or empty values
        (string memory name, string memory bio, address wallet) = organizerRegistry.getOrganizerInfoByAddress(nominee);
        assertEq(wallet, address(0), "Organizer wallet should be default address.");
        assertEq(name, "", "Organizer name should be empty.");
        assertEq(bio, "", "Organizer bio should be empty.");
    }
}
