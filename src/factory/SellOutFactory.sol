// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Show } from "../show/Show.sol";
import { Ticket } from "../ticket/Ticket.sol";
import { Venue } from "../venue/Venue.sol";
import { ArtistRegistry } from "../registry/artist/ArtistRegistry.sol";
import { OrganizerRegistry } from "../registry/organizer/OrganizerRegistry.sol";
import { VenueRegistry } from "../registry/venue/VenueRegistry.sol";
import { ReferralModule } from "../registry/referral/ReferralModule.sol";

/// @title SellOutFactory
/// @notice Factory contract to deploy and link all SellOut protocol contracts including Show, Ticket, Venue, registries, and ReferralModule.
contract SellOutFactory {
    Show public showInstance;
    Ticket public ticketInstance;
    Venue public venueInstance;
    ArtistRegistry public artistRegistryInstance;
    OrganizerRegistry public organizerRegistryInstance;
    VenueRegistry public venueRegistryInstance;
    ReferralModule public referralModuleInstance;

    address public SELLOUT_PROTOCOL_WALLET;

    constructor() {
        SELLOUT_PROTOCOL_WALLET = msg.sender;

        // Deploying core contracts
        showInstance = new Show(SELLOUT_PROTOCOL_WALLET);
        ticketInstance = new Ticket(address(showInstance));
        venueInstance = new Venue(address(showInstance), address(ticketInstance));
        referralModuleInstance = new ReferralModule(address(showInstance), SELLOUT_PROTOCOL_WALLET);

        // Deploying registry contracts with referral module address
        artistRegistryInstance = new ArtistRegistry(address(referralModuleInstance));
        organizerRegistryInstance = new OrganizerRegistry(address(referralModuleInstance));
        venueRegistryInstance = new VenueRegistry(address(referralModuleInstance));

        // Linking contracts together as required
        showInstance.setProtocolAddresses(address(ticketInstance), address(venueInstance), address(referralModuleInstance));
    }

}
