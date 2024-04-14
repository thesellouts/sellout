// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ShowTypes } from "../types/ShowTypes.sol";
import { ReferralModule } from "../../registry/referral/ReferralModule.sol";
import { ITicketFactory } from "../../ticket/ITicketFactory.sol";
import { IVenueFactory } from "../../venue/IVenueFactory.sol";
import { IArtistRegistry } from "../../registry/artist/IArtistRegistry.sol";
import { IOrganizerRegistry } from "../../registry/organizer/IOrganizerRegistry.sol";
import { IVenueRegistry } from "../../registry/venue/IVenueRegistry.sol";
import { IShowVault } from "../IShowVault.sol";
import { IBoxOffice } from "../IBoxOffice.sol";

/// @title ShowStorageV1
/// @author taayyohh
/// @notice This contract provides storage for show-related data, including ticket mapping, total tickets sold, show details, and more.

contract ShowStorage is ShowTypes {
    address public SELLOUT_PROTOCOL_WALLET;

    IVenueFactory public venueFactoryInstance;
    ITicketFactory public ticketFactoryInstance;
    ReferralModule public referralInstance;
    IArtistRegistry public artistRegistryInstance;
    IOrganizerRegistry public organizerRegistryInstance;
    IVenueRegistry public venueRegistryInstance;
    IShowVault public showVaultInstance;
    IBoxOffice public boxOfficeInstance;

    bool internal setContracts = false;

    // Base URI for tokens
    string internal _baseTokenURI;

    // Mapping to store show details by show ID
    mapping(bytes32 => Show) public shows;

    // Mapping of show to its ticket proxy address
    mapping(bytes32 => address) public showToTicketProxy;

    // Mapping of show to its ticket proxy address
    mapping(bytes32 => address) public showToVenueProxy;

    // Mapping to track whether a given address is an artist for a specific show
    mapping(bytes32 => mapping(address => bool)) public isArtistMapping;

    // Maps showId to votes for cancellation
    mapping(bytes32 => uint256) public votesForEmergencyRefund;

    // Maps showId to a mapping of voter addresses to bool
    mapping(bytes32 => mapping(address => bool)) public hasVotedForEmergencyRefund;
}
