// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../../src/registry/referral/ReferralModule.sol";
import "../../src/registry/artist/ArtistRegistry.sol";

contract TestArtistRegistry is Test {
    ArtistRegistry public artistRegistry;
    ReferralModule public referralModule;
    address public userWithReferralCredits = address(0x123);
    address public nominee = address(0x124);

    function setUp() public {
        // Initialize the ReferralModule with the test contract acting as both showContract and selloutProtocolWallet
        referralModule = new ReferralModule(address(this), address(this));

        artistRegistry = new ArtistRegistry(address(referralModule));

        // Setting permission for the ArtistRegistry to decrement referral credits
        referralModule.setCreditControlPermission(address(artistRegistry), true);

        // Giving referral credits to a user
        referralModule.incrementReferralCredits(userWithReferralCredits, 1, 0, 0); // artist = 1, organizer = 0, venue = 0
    }

    function testArtistNominationAndAcceptance() public {
        // Nominate a new artist
        vm.prank(userWithReferralCredits);
        artistRegistry.nominate(nominee);

        // Accept the nomination
        vm.prank(nominee);
        artistRegistry.acceptNomination();

        // Verify the nomination was successful by checking if the nominee now has artist info
        (, , address wallet) = artistRegistry.getArtistInfoByAddress(nominee);
        assertTrue(wallet == nominee, "Nominee should have artist info after acceptance");
    }

    function testArtistUpdate() public {
        // Setup: Nominate and accept an artist to update
        testArtistNominationAndAcceptance();

        // New name and biography for the artist
        string memory newName = "Updated Artist Name";
        string memory newBio = "Updated Artist Bio";

        // Update the artist's information
        vm.prank(nominee);
        artistRegistry.updateArtist(1, newName, newBio); // Assuming ID 1 for simplicity, adjust as needed

        // Verify the update was successful
        (string memory name, string memory bio, ) = artistRegistry.getArtistInfoByAddress(nominee);
        assertEq(name, newName, "Artist name was not updated correctly.");
        assertEq(bio, newBio, "Artist bio was not updated correctly.");
    }

    function testArtistDeregistration() public {
        // Setup: Nominate and accept an artist to deregister
        testArtistNominationAndAcceptance();

        // Deregister the artist
        vm.prank(nominee);
        artistRegistry.deregisterArtist(1); // Assuming ID 1 for simplicity, adjust as needed

        // Attempt to fetch deregistered artist info, check for default or empty values
        (string memory name, string memory bio, address wallet) = artistRegistry.getArtistInfoByAddress(nominee);
        assertEq(wallet, address(0), "Artist wallet should be default address.");
        assertEq(name, "", "Artist name should be empty.");
        assertEq(bio, "", "Artist bio should be empty.");
    }
}
