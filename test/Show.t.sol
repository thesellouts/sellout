//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//
//import "forge-std/Test.sol";
//import { Show } from "../../src/show/Show.sol";
//import { ReferralModule } from "../../src/registry/referral/ReferralModule.sol";
//import { OrganizerRegistry } from "../../src/registry/organizer/OrganizerRegistry.sol";
//import { VenueRegistry } from "../../src/registry/venue/VenueRegistry.sol";
//import { ArtistRegistry } from "../../src/registry/artist/ArtistRegistry.sol";
//import { TicketFactory } from "../../src/ticket/TicketFactory.sol";
//import { ShowVault } from "../../src/show/ShowVault.sol";
//import { BoxOffice } from "../../src/show/BoxOffice.sol";
//import { ShowTypes } from "../../src/show/storage/ShowStorage.sol";
//import { VenueTypes } from "../../src/venue/types/VenueTypes.sol";
//import { VenueRegistryTypes } from "../../src/registry/venue/types/VenueRegistryTypes.sol";
//import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
//import "forge-std/console.sol";
//
//contract ShowTest is Test {
//    Show show;
//    ReferralModule referralModule;
//    OrganizerRegistry organizerRegistry;
//    VenueRegistry venueRegistry;
//    ArtistRegistry artistRegistry;
//    TicketFactory ticketFactory;
//    ShowVault showVault;
//    BoxOffice boxOffice;
//    address SELLOUT_PROTOCOL_WALLET = address(0x1);
//    address ORGANIZER = address(0x2);
//    address ARTIST_1 = address(0x3);
//    address ARTIST_2 = address(0x4);
//    address VENUE_ADDRESS = address(0x5);
//
//    function setUp() external {
//        console.log("Setting up test...");
//
//        // Deploy ReferralModule
//        ReferralModule baseReferralModule = new ReferralModule();
//        bytes memory initDataReferral = abi.encodeWithSelector(ReferralModule.initialize.selector, SELLOUT_PROTOCOL_WALLET);
//        ERC1967Proxy proxyReferralModule = new ERC1967Proxy(address(baseReferralModule), initDataReferral);
//        referralModule = ReferralModule(address(proxyReferralModule));
//        console.log("Referral module initialized at:", address(referralModule));
//
//        // Deploy OrganizerRegistry
//        OrganizerRegistry baseOrganizerRegistry = new OrganizerRegistry();
//        bytes memory initDataOrganizer = abi.encodeWithSelector(OrganizerRegistry.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(referralModule));
//        ERC1967Proxy proxyOrganizerRegistry = new ERC1967Proxy(address(baseOrganizerRegistry), initDataOrganizer);
//        organizerRegistry = OrganizerRegistry(address(proxyOrganizerRegistry));
//        console.log("Organizer registry initialized at:", address(organizerRegistry));
//
//        // Deploy VenueRegistry
//        VenueRegistry baseVenueRegistry = new VenueRegistry();
//        bytes memory initDataVenue = abi.encodeWithSelector(VenueRegistry.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(referralModule));
//        ERC1967Proxy proxyVenueRegistry = new ERC1967Proxy(address(baseVenueRegistry), initDataVenue);
//        venueRegistry = VenueRegistry(address(proxyVenueRegistry));
//        console.log("Venue registry initialized at:", address(venueRegistry));
//
//        // Deploy ArtistRegistry
//        ArtistRegistry baseArtistRegistry = new ArtistRegistry();
//        bytes memory initDataArtist = abi.encodeWithSelector(ArtistRegistry.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(referralModule));
//        ERC1967Proxy proxyArtistRegistry = new ERC1967Proxy(address(baseArtistRegistry), initDataArtist);
//        artistRegistry = ArtistRegistry(address(proxyArtistRegistry));
//        console.log("Artist registry initialized at:", address(artistRegistry));
//
//        // Deploy ShowVault
//        showVault = new ShowVault();
//        console.log("Show vault initialized at:", address(showVault));
//
//        // Deploy TicketFactory
//        ticketFactory = new TicketFactory();
//        console.log("Ticket factory initialized at:", address(ticketFactory));
//
//        // Deploy BoxOffice
//        boxOffice = new BoxOffice();
//        console.log("Box office initialized at:", address(boxOffice));
//
//        // Deploy the Show contract
//        console.log("Initializing Show contract...");
//        Show baseShow = new Show();
//        bytes memory initDataShow = abi.encodeWithSelector(Show.initialize.selector, SELLOUT_PROTOCOL_WALLET);
//        try new ERC1967Proxy(address(baseShow), initDataShow) returns (ERC1967Proxy proxyShow) {
//            show = Show(address(proxyShow));
//            console.log("Show initialized at:", address(show));
//        } catch Error(string memory reason) {
//            console.log("Failed to deploy Show contract:", reason);
//        } catch (bytes memory lowLevelData) {
//            console.log("Failed to deploy Show contract with low-level error");
//            console.logBytes(lowLevelData);
//        }
//
//        // Set protocol addresses in Show
//        if (address(show) != address(0)) {
//            console.log("Setting protocol addresses in Show...");
//            try show.setProtocolAddresses(
//                address(ticketFactory),
//                address(venueRegistry),
//                address(referralModule),
//                address(artistRegistry),
//                address(organizerRegistry),
//                address(venueRegistry),
//                address(showVault),
//                address(boxOffice)
//            ) {
//                console.log("Show protocol addresses set successfully");
//            } catch Error(string memory reason) {
//                console.log("Failed to set Show protocol addresses:", reason);
//            } catch (bytes memory lowLevelData) {
//                console.logBytes(lowLevelData);
//                console.log("Failed to set Show protocol addresses with low-level error");
//            }
//        } else {
//            console.log("Skipping setting protocol addresses due to failed Show deployment");
//        }
//
//        // Set contract addresses for TicketFactory
//        console.log("Setting contract addresses in TicketFactory...");
//        try ticketFactory.setContractAddresses(address(boxOffice)) {
//            console.log("Ticket factory contract addresses set successfully");
//        } catch Error(string memory reason) {
//            console.log("Failed to set TicketFactory contract addresses:", reason);
//        } catch (bytes memory lowLevelData) {
//            console.logBytes(lowLevelData);
//            console.log("Failed to set TicketFactory contract addresses with low-level error");
//        }
//
//        // Set BoxOffice address in ShowVault
//        console.log("Setting BoxOffice address in ShowVault...");
//        try showVault.setContractAddresses(address(boxOffice)) {
//            console.log("Box office address set in ShowVault successfully");
//        } catch Error(string memory reason) {
//            console.log("Failed to set Box office address in ShowVault:", reason);
//        } catch (bytes memory lowLevelData) {
//            console.logBytes(lowLevelData);
//            console.log("Failed to set Box office address in ShowVault with low-level error");
//        }
//
//        // Provide referral credits for the organizer, artist, and venue registries
//        console.log("Setting referral permissions...");
//        vm.prank(SELLOUT_PROTOCOL_WALLET);
//        referralModule.setCreditControlPermission(address(organizerRegistry), true);
//        console.log("Credit control permission set for Organizer Registry");
//
//        vm.prank(SELLOUT_PROTOCOL_WALLET);
//        referralModule.setCreditControlPermission(address(artistRegistry), true);
//        console.log("Credit control permission set for Artist Registry");
//
//        vm.prank(SELLOUT_PROTOCOL_WALLET);
//        referralModule.setCreditControlPermission(address(venueRegistry), true);
//        console.log("Credit control permission set for Venue Registry");
//
//        if (address(show) != address(0)) {
//            vm.prank(SELLOUT_PROTOCOL_WALLET);
//            referralModule.setCreditControlPermission(address(show), true);
//            console.log("Credit control permission set for Show contract");
//        } else {
//            console.log("Skipping setting referral permissions for Show contract due to failed Show deployment");
//        }
//
//        // Increment referral credits for organizer, artist, and venue registries
//        console.log("Incrementing referral credits...");
//        vm.prank(address(organizerRegistry));
//        referralModule.incrementReferralCredits(address(organizerRegistry), 100, 0, 0);
//        console.log("Incremented referral credits for Organizer Registry");
//
//        vm.prank(address(artistRegistry));
//        referralModule.incrementReferralCredits(address(artistRegistry), 0, 100, 0);
//        console.log("Incremented referral credits for Artist Registry");
//
//        vm.prank(address(venueRegistry));
//        referralModule.incrementReferralCredits(address(venueRegistry), 0, 0, 100);
//        console.log("Incremented referral credits for Venue Registry");
//
//        // Register organizer
//        console.log("Registering Organizer...");
//        vm.prank(address(organizerRegistry));
//        organizerRegistry.nominate(ORGANIZER);
//        console.log("Organizer nominated successfully");
//
//        vm.prank(ORGANIZER);
//        organizerRegistry.acceptNomination("Organizer", "Organizer Bio");
//        console.log("Organizer accepted nomination successfully");
//
//        // Register artists
//        console.log("Registering Artists...");
//        vm.prank(address(artistRegistry));
//        artistRegistry.nominate(ARTIST_1);
//        console.log("Artist 1 nominated successfully");
//
//        vm.prank(ARTIST_1);
//        artistRegistry.acceptNomination("Artist One", "Artist One Bio");
//        console.log("Artist 1 accepted nomination successfully");
//
//        vm.prank(address(artistRegistry));
//        artistRegistry.nominate(ARTIST_2);
//        console.log("Artist 2 nominated successfully");
//
//        vm.prank(ARTIST_2);
//        artistRegistry.acceptNomination("Artist Two", "Artist Two Bio");
//        console.log("Artist 2 accepted nomination successfully");
//    }
//
//    /// @notice Tests the `initialize` function of the `Show` contract
//    function testInitialize() public {
//        console.log("Running testInitialize...");
//        address showOwner = show.owner();
//        assertEq(showOwner, SELLOUT_PROTOCOL_WALLET, "Show contract owner should be the Sellout Protocol Wallet");
//        console.log("Test initialize passed");
//    }
//
//    /// @notice Tests the `proposeShow` function of the `Show` contract
//    function testProposeShow() public {
//        ShowTypes.TicketTier[] memory ticketTiers = new ShowTypes.TicketTier[](1);
//        ticketTiers[0] = ShowTypes.TicketTier({
//            name: "General Admission",
//            price: 100,
//            ticketsAvailable: 100
//        });
//
//        VenueTypes.VenueProposalParams memory venueProposalParams = VenueTypes.VenueProposalParams({
//            proposalPeriodDuration: 30 days,
//            proposalDateExtension: 1 days,
//            proposalDateMinimumFuture: 10 days,
//            proposalPeriodExtensionThreshold: 1 hours
//        });
//
//        uint256[] memory splits = new uint256[](3);
//        splits[0] = 5;  // Organizer
//        splits[1] = 80;  // Artists
//        splits[2] = 20;  // Venue
//
//        address[] memory artists = new address[](2);
//        artists[0] = ARTIST_1;
//        artists[1] = ARTIST_2;
//
//        ShowTypes.ShowProposal memory proposal = ShowTypes.ShowProposal({
//            name: "Amazing Show",
//            description: "A truly spectacular display",
//            artists: artists,
//            coordinates: VenueRegistryTypes.Coordinates(1000000, -1000000),
//            radius: 50,
//            sellOutThreshold: 80,
//            totalCapacity: 200,
//            ticketTiers: ticketTiers,
//            split: splits,
//            currencyAddress: address(0x123),
//            venueProposalParams: venueProposalParams
//        });
//
//        // Propose the show
//        console.log("Running testProposeShow...");
//        vm.prank(ORGANIZER);
//        bytes32 showId = show.proposeShow(proposal);
//        console.log("Show proposed with ID:", showId);
//
//        // Verify show details
//        (
//            string memory name,
//            string memory description,
//            address organizer,
//            address[] memory artistsArray,
//            VenueRegistryTypes.VenueInfo memory venue,
//            ShowTypes.TicketTier[] memory ticketTiersArray,
//            uint8 sellOutThreshold,
//            uint256 totalCapacity,
//            ShowTypes.Status status,
//            address currencyAddress
//        ) = show.getShowById(showId);
//
//        assertEq(name, proposal.name, "Show name should match the created show.");
//        assertEq(description, proposal.description, "Show description should match.");
//        assertEq(organizer, ORGANIZER, "Organizer address should match.");
//        assertEq(artistsArray[0], ARTIST_1, "Artist 1 address should match.");
//        assertEq(artistsArray[1], ARTIST_2, "Artist 2 address should match.");
//        assertEq(venue.coordinates.latitude, proposal.coordinates.latitude, "Venue latitude should match.");
//        assertEq(venue.coordinates.longitude, proposal.coordinates.longitude, "Venue longitude should match.");
//        assertEq(ticketTiersArray[0].name, proposal.ticketTiers[0].name, "Ticket tier name should match.");
//        assertEq(sellOutThreshold, proposal.sellOutThreshold, "Sell-out threshold should match.");
//        assertEq(totalCapacity, proposal.totalCapacity, "Total capacity should match.");
//        assertEq(uint8(status), uint8(ShowTypes.Status.Proposed), "Show status should be 'Proposed'.");
//        assertEq(currencyAddress, proposal.currencyAddress, "Show currency address should match.");
//
//        console.log("Test propose show passed");
//    }
//}
