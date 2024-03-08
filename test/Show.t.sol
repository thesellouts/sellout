// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../src/show/Show.sol";
import "../src/ticket/Ticket.sol";
import "../src/registry/organizer/OrganizerRegistry.sol";
import "../src/registry/artist/ArtistRegistry.sol";
import "../src/registry/venue/VenueRegistry.sol";
import "../src/registry/referral/ReferralModule.sol";
import { VenueTypes } from "../src/venue/storage/VenueStorage.sol";
import { ShowTypes } from "../src/show/types/ShowTypes.sol";

contract ShowTest is Test {
    Show public show;
    Ticket public ticket;
    OrganizerRegistry public organizerRegistry;
    ArtistRegistry public artistRegistry;
    VenueRegistry public venueRegistry;
    ReferralModule public referralModule;

    address public organizer = address(0x123);
    address public artist = address(0x456);

    function setUpOrganizerAndArtist() internal {
        // Set permissions for decrementing referral credits
        referralModule.setCreditControlPermission(address(organizerRegistry), true);
        referralModule.setCreditControlPermission(address(artistRegistry), true);

        // Increment referral credits to allow registration
        referralModule.incrementReferralCredits(organizer, 0, 1, 0);
        referralModule.incrementReferralCredits(artist, 1, 0, 0);

        // Register organizer and artist
        vm.startPrank(organizer);
        organizerRegistry.nominate(organizer);
        organizerRegistry.acceptNomination();
        vm.stopPrank();

        vm.startPrank(artist);
        artistRegistry.nominate(artist);
        artistRegistry.acceptNomination();
        vm.stopPrank();
    }

    function setUp() public {
        referralModule = new ReferralModule(address(this), address(this));
        organizerRegistry = new OrganizerRegistry(address(referralModule));
        artistRegistry = new ArtistRegistry(address(referralModule));
        venueRegistry = new VenueRegistry(address(referralModule));
        show = new Show(address(this));
        ticket = new Ticket(address(show));

        show.setProtocolAddresses(address(ticket), address(venueRegistry), address(referralModule), address(artistRegistry), address(organizerRegistry), address(venueRegistry));

        setUpOrganizerAndArtist();
    }

    function testProposeShow() public {
        string memory name = "Test Show";
        string memory description = "This is a test show description.";
        address[] memory artists = new address[](1);
        artists[0] = artist;
        VenueTypes.Coordinates memory coordinates = VenueTypes.Coordinates({lat: 1000000, lon: -1000000});
        uint256 radius = 50;
        uint8 sellOutThreshold = 80;
        uint256 totalCapacity = 200;
        ShowTypes.TicketPrice memory ticketPrice = ShowTypes.TicketPrice({minPrice: 0.1 ether, maxPrice: 1 ether});
        uint256[] memory split = new uint256[](3); // organizer, artists, venue
        split[0] = 50; split[1] = 25; split[2] = 25;

        vm.prank(organizer);
        bytes32 showId = show.proposeShow(name, description, artists, coordinates, radius, sellOutThreshold, totalCapacity, ticketPrice, split);

        // Simplified assertion to check show status
        ShowTypes.Status status = show.getShowStatus(showId);
        assertEq(uint(status), uint(ShowTypes.Status.Proposed), "Show status should be Proposed.");
    }

    function testProposeShowWithUnregisteredOrganizer() public {
        // Assuming `artist` is already registered in the setup
        string memory name = "Unregistered Organizer Show";
        string memory description = "Show with unregistered organizer";
        address[] memory artists = new address[](1);
        artists[0] = artist;
        VenueTypes.Coordinates memory coordinates = VenueTypes.Coordinates(0, 0);
        uint256 radius = 100;
        uint8 sellOutThreshold = 70;
        uint256 totalCapacity = 300;
        ShowTypes.TicketPrice memory ticketPrice = ShowTypes.TicketPrice(0.05 ether, 0.2 ether);
        uint256[] memory split = new uint256[](3);
        split[0] = 50; // Organizer's share
        split[1] = 30; // Artist's share
        split[2] = 20; // Venue's share

        address unregisteredOrganizer = address(0xdead);
        vm.startPrank(unregisteredOrganizer);
        vm.expectRevert("Organizer does not exist");
        show.proposeShow(name, description, artists, coordinates, radius, sellOutThreshold, totalCapacity, ticketPrice, split);
        vm.stopPrank();
    }


    // Additional tests can be added here following the same pattern
}
