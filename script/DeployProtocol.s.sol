//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
//
//import "forge-std/Script.sol";
//import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
//import "../src/registry/referral/ReferralModule.sol";
//import "../src/registry/artist/ArtistRegistry.sol";
//import "../src/registry/organizer/OrganizerRegistry.sol";
//import "../src/registry/venue/VenueRegistry.sol";
//import "../src/show/Show.sol";
//import "../src/ticket/Ticket.sol";
//import "../src/venue/Venue.sol";
//
//contract DeployProtocol is Script {
//    address public SELLOUT_PROTOCOL_WALLET = address(0xc1951eF408265A3b90d07B0BE030e63CCc7da6c6); // Update with your wallet address
//
//    function run() external {
//        vm.startBroadcast();
//
//        // Deploy ReferralModule with SELLOUT_PROTOCOL_WALLET as initial owner
//        ReferralModule referralModuleImpl = new ReferralModule();
//        bytes memory initDataReferralModule = abi.encodeWithSelector(ReferralModule.initialize.selector, SELLOUT_PROTOCOL_WALLET);
//        ERC1967Proxy proxyReferralModule = new ERC1967Proxy(address(referralModuleImpl), initDataReferralModule);
//        ReferralModule referralModule = ReferralModule(address(proxyReferralModule));
//
//        // Repeat the pattern for ArtistRegistry, OrganizerRegistry, and VenueRegistry
//        // Make sure to pass SELLOUT_PROTOCOL_WALLET as the initialOwner argument in their initialize calls
//
//        // Deploy ArtistRegistry with SELLOUT_PROTOCOL_WALLET as initial owner
//        ArtistRegistry artistRegistryImpl = new ArtistRegistry();
//        bytes memory initDataArtistRegistry = abi.encodeWithSelector(ArtistRegistry.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(referralModule));
//        ERC1967Proxy proxyArtistRegistry = new ERC1967Proxy(address(artistRegistryImpl), initDataArtistRegistry);
//        ArtistRegistry artistRegistry = ArtistRegistry(address(proxyArtistRegistry));
//
//        // Deploy OrganizerRegistry with SELLOUT_PROTOCOL_WALLET as initial owner
//        OrganizerRegistry organizerRegistryImpl = new OrganizerRegistry();
//        bytes memory initDataOrganizerRegistry = abi.encodeWithSelector(OrganizerRegistry.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(referralModule));
//        ERC1967Proxy proxyOrganizerRegistry = new ERC1967Proxy(address(organizerRegistryImpl), initDataOrganizerRegistry);
//        OrganizerRegistry organizerRegistry = OrganizerRegistry(address(proxyOrganizerRegistry));
//
//        // Deploy VenueRegistry with SELLOUT_PROTOCOL_WALLET as initial owner
//        VenueRegistry venueRegistryImpl = new VenueRegistry();
//        bytes memory initDataVenueRegistry = abi.encodeWithSelector(VenueRegistry.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(referralModule));
//        ERC1967Proxy proxyVenueRegistry = new ERC1967Proxy(address(venueRegistryImpl), initDataVenueRegistry);
//        VenueRegistry venueRegistry = VenueRegistry(address(proxyVenueRegistry));
//
//        // Deploy Show with SELLOUT_PROTOCOL_WALLET as initial owner
//        Show showImpl = new Show();
//        bytes memory initDataShow = abi.encodeWithSelector(Show.initialize.selector, SELLOUT_PROTOCOL_WALLET);
//        ERC1967Proxy proxyShow = new ERC1967Proxy(address(showImpl), initDataShow);
//        Show show = Show(address(proxyShow));
//
//        // Deploy Ticket with SELLOUT_PROTOCOL_WALLET as initial owner
//        Ticket ticketImpl = new Ticket();
//        bytes memory initDataTicket = abi.encodeWithSelector(Ticket.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(show));
//        ERC1967Proxy proxyTicket = new ERC1967Proxy(address(ticketImpl), initDataTicket);
//        Ticket ticket = Ticket(address(proxyTicket));
//
//        // Deploy Venue with SELLOUT_PROTOCOL_WALLET as initial owner
//        Venue venueImpl = new Venue();
//        bytes memory initDataVenue = abi.encodeWithSelector(Venue.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(show), address(ticket));
//        ERC1967Proxy proxyVenue = new ERC1967Proxy(address(venueImpl), initDataVenue);
//        Venue venue = Venue(address(proxyVenue));
//
//        // Linking contracts together as required
//        show.setProtocolAddresses(
//            address(ticket),
//            address(venue),
//            address(referralModule),
//            address(artistRegistry),
//            address(organizerRegistry),
//            address(venueRegistry)
//        );
//
//        // Set permission for OrganizerRegistry to decrement referral credits
//        referralModule.setCreditControlPermission(address(organizerRegistry), true);
//
//        vm.stopBroadcast();
//    }
//}
