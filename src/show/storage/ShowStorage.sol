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

/// @title Show Storage for Sellout Protocol
/// @notice This contract serves as a central storage for show-related data, facilitating interactions between various components of the platform such as tickets, venues, artists, and organizers.
/// @dev Inherits from ShowTypes to utilize structured data definitions specific to shows.
contract ShowStorage is ShowTypes {
    /// @notice Address of the protocol's central wallet, which may receive funds or perform administrative tasks.
    address public SELLOUT_PROTOCOL_WALLET;

    /// @notice Cooling off period to prevent immediate actions following significant events.
    /// @dev Initially set to 2 minutes for testing; change to `2 days` for production.
    uint256 public constant COOLDOWN = 2 minutes;

    /// @notice Instance of the VenueFactory for creating and managing venue-related operations.
    IVenueFactory public venueFactoryInstance;

    /// @notice Instance of the TicketFactory for creating and managing ticket-related operations.
    ITicketFactory public ticketFactoryInstance;

    /// @notice Instance of the ReferralModule to manage referral incentives.
    ReferralModule public referralInstance;

    /// @notice Registry for managing artist data and interactions.
    IArtistRegistry public artistRegistryInstance;

    /// @notice Registry for managing organizer data and interactions.
    IOrganizerRegistry public organizerRegistryInstance;

    /// @notice Registry for managing venue data and interactions.
    IVenueRegistry public venueRegistryInstance;

    /// @notice Vault for managing financial transactions and token storage related to shows.
    IShowVault public showVaultInstance;

    /// @notice Interface to the Box Office which handles ticket sales and validations.
    IBoxOffice public boxOfficeInstance;

    /// @notice Flag indicating whether contract addresses have been set, ensuring they are only set once.
    bool internal setContracts = false;

    /// @notice Base URI for accessing token metadata.
    string internal _baseTokenURI;

    /// @notice Mapping from unique show identifier to detailed show data.
    /// @dev Used to store and retrieve show-specific information.
    mapping(bytes32 => Show) public shows;

    /// @notice Mapping from show ID to its corresponding ticket proxy address.
    /// @dev Links shows to their specific ticket management proxies.
    mapping(bytes32 => address) public showToTicketProxy;

    /// @notice Mapping from show ID to its corresponding venue proxy address.
    /// @dev Links shows to their specific venue management proxies.
    mapping(bytes32 => address) public showToVenueProxy;

    /// @notice Mapping to track whether a specific address is an artist for a given show.
    /// @dev Useful for permissions and role verifications.
    mapping(bytes32 => mapping(address => bool)) public isArtistMapping;

    /// @notice Mapping from show ID to the number of votes for an emergency refund.
    /// @dev Used to manage and tally votes for potentially refunding tickets under special circumstances.
    mapping(bytes32 => uint256) public votesForEmergencyRefund;

    /// @notice Mapping from show ID to a mapping of voter addresses to a boolean indicating if they have voted for an emergency refund.
    /// @dev Helps prevent double voting and tracks voter participation.
    mapping(bytes32 => mapping(address => bool)) public hasVotedForEmergencyRefund;
}
