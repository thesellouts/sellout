//// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
//
//import "forge-std/Test.sol";
//import { Show } from "../src/show/Show.sol";
//import { Ticket } from "../src/ticket/Ticket.sol";
//import { OrganizerRegistry } from "../src/registry/organizer/OrganizerRegistry.sol";
//import { ArtistRegistry } from "../src/registry/artist/ArtistRegistry.sol";
//import { VenueRegistry } from "../src/registry/venue/VenueRegistry.sol";
//import { ReferralModule } from "../src/registry/referral/ReferralModule.sol";
//import { VenueTypes } from "../src/venue/storage/VenueStorage.sol";
//import { ShowTypes } from "../src/show/types/ShowTypes.sol";
//import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
//
//
//contract ShowTest is Test {
//    Show public show;
//    Ticket public ticket;
//    OrganizerRegistry public organizerRegistry;
//    ArtistRegistry public artistRegistry;
//    VenueRegistry public venueRegistry;
//    ReferralModule public referralModule;
//
//    address SELLOUT_PROTOCOL_WALLET = address(1); // Use a fixed address for test environment
//
//    address public organizer = address(0x123);
//    address public artist = address(0x456);
//
//    function setUp() public {
//        // Initialize ReferralModule
//        bytes memory initDataReferralModule = abi.encodeWithSelector(ReferralModule.initialize.selector, SELLOUT_PROTOCOL_WALLET);
//        referralModule = ReferralModule(address(new ERC1967Proxy(address(new ReferralModule()), initDataReferralModule)));
//
//        // Initialize OrganizerRegistry
//        bytes memory initDataOrganizerRegistry = abi.encodeWithSelector(OrganizerRegistry.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(referralModule));
//        organizerRegistry = OrganizerRegistry(address(new ERC1967Proxy(address(new OrganizerRegistry()), initDataOrganizerRegistry)));
//
//        // Initialize ArtistRegistry
//        bytes memory initDataArtistRegistry = abi.encodeWithSelector(ArtistRegistry.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(referralModule));
//        artistRegistry = ArtistRegistry(address(new ERC1967Proxy(address(new ArtistRegistry()), initDataArtistRegistry)));
//
//        // Initialize VenueRegistry
//        bytes memory initDataVenueRegistry = abi.encodeWithSelector(VenueRegistry.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(referralModule));
//        venueRegistry = VenueRegistry(address(new ERC1967Proxy(address(new VenueRegistry()), initDataVenueRegistry)));
//
//        // Initialize Show
//        bytes memory initDataShow = abi.encodeWithSelector(Show.initialize.selector, SELLOUT_PROTOCOL_WALLET);
//        show = Show(address(new ERC1967Proxy(address(new Show()), initDataShow)));
//
//        // Initialize Ticket
//        bytes memory initDataTicket = abi.encodeWithSelector(Ticket.initialize.selector, address(show));
//        ticket = Ticket(address(new ERC1967Proxy(address(new Ticket()), initDataTicket)));
//
//        // Set protocol addresses in Show
//        show.setProtocolAddresses(address(ticket), address(venueRegistry), address(referralModule), address(artistRegistry), address(organizerRegistry), address(venueRegistry));
//    }
//
//    function testProposeShow() public {
//        string memory name = "Test Show";
//        string memory description = "This is a test show description.";
//        address[] memory artists = new address[](1);
//        artists[0] = artist;
//        VenueTypes.Coordinates memory coordinates = VenueTypes.Coordinates({lat: 1000000, lon: -1000000});
//        uint256 radius = 50;
//        uint8 sellOutThreshold = 80;
//        uint256 totalCapacity = 200;
//        ShowTypes.TicketPrice memory ticketPrice = ShowTypes.TicketPrice({minPrice: 0.1 ether, maxPrice: 1 ether});
//        uint256[] memory split = new uint256[](3); // organizer, artists, venue
//        split[0] = 50; split[1] = 25; split[2] = 25;
//
//        vm.prank(organizer);
//        bytes32 showId = show.proposeShow(name, description, artists, coordinates, radius, sellOutThreshold, totalCapacity, ticketPrice, split);
//
//        // Simplified assertion to check show status
//        ShowTypes.Status status = show.getShowStatus(showId);
//        assertEq(uint(status), uint(ShowTypes.Status.Proposed), "Show status should be Proposed.");
//    }
//
//    function testProposeShowWithUnregisteredOrganizer() public {
//        // Assuming `artist` is already registered in the setup
//        string memory name = "Unregistered Organizer Show";
//        string memory description = "Show with unregistered organizer";
//        address[] memory artists = new address[](1);
//        artists[0] = artist;
//        VenueTypes.Coordinates memory coordinates = VenueTypes.Coordinates(0, 0);
//        uint256 radius = 100;
//        uint8 sellOutThreshold = 70;
//        uint256 totalCapacity = 300;
//        ShowTypes.TicketPrice memory ticketPrice = ShowTypes.TicketPrice(0.05 ether, 0.2 ether);
//        uint256[] memory split = new uint256[](3);
//        split[0] = 50; // Organizer's share
//        split[1] = 30; // Artist's share
//        split[2] = 20; // Venue's share
//
//        address unregisteredOrganizer = address(0xdead);
//        vm.startPrank(unregisteredOrganizer);
//        vm.expectRevert("Organizer does not exist");
//        show.proposeShow(name, description, artists, coordinates, radius, sellOutThreshold, totalCapacity, ticketPrice, split);
//        vm.stopPrank();
//    }
//
//
//    // Additional tests can be added here following the same pattern
//}
