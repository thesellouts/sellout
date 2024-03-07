// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Show } from "../show/Show.sol";
import { Ticket } from "../ticket/Ticket.sol";
import { Venue } from "../venue/Venue.sol";
import { ArtistRegistry } from "../registry/artist/ArtistRegistry.sol";
import { OrganizerRegistry } from "../registry/organizer/OrganizerRegistry.sol";
import { VenueRegistry } from "../registry/venue/VenueRegistry.sol";
import { ReferralModule } from "../registry/referral/ReferralModule.sol";

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
        // Initialize the ReferralModule with the factory (or another specified address) as admin
        referralModuleInstance = new ReferralModule(address(this), SELLOUT_PROTOCOL_WALLET);
        ticketInstance = new Ticket(address(showInstance));
        venueInstance = new Venue(address(showInstance), address(ticketInstance));

        // Deploying registry contracts with referral module address
        artistRegistryInstance = new ArtistRegistry(address(referralModuleInstance));
        organizerRegistryInstance = new OrganizerRegistry(address(referralModuleInstance));
        venueRegistryInstance = new VenueRegistry(address(referralModuleInstance));

        // Linking contracts together as required
        showInstance.setProtocolAddresses(
            address(ticketInstance),
            address(venueInstance),
            address(referralModuleInstance),
            address(artistRegistryInstance),
            address(organizerRegistryInstance),
            address(venueRegistryInstance)
        );

        // IMPORTANT: Set permission for OrganizerRegistry to decrement referral credits
        referralModuleInstance.setDecrementPermission(address(organizerRegistryInstance), true);
    }
}
