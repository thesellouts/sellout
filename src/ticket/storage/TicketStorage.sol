// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TicketTypes } from "../types/TicketTypes.sol";
import { IShow } from  "../../show/IShow.sol";
import { IBoxOffice } from  "../../show/IBoxOffice.sol";
import { IShowVault } from  "../../show/IShowVault.sol";

/// @title Ticket Storage for Sellout Tickets
/// @dev Storage contract for ticket data associated with shows.
contract TicketStorage is TicketTypes {
    /// @notice Reference to the Show contract for interaction with show-related functionalities.
    IShow public showInstance;

    /// @notice Reference to the Box Office contract for managing ticket sales and queries.
    IBoxOffice public boxOfficeInstance;

    /// @notice Reference to the ShowVault contract for handling ticket-related financial transactions.
    IShowVault public showVaultInstance;

    /// @notice Version identifier for the ticket storage implementation.
    string public version;

    /// @notice Maximum number of tickets a single wallet is allowed to purchase per show.
    uint256 public constant MAX_TICKETS_PER_WALLET = 5;

    /// @notice Mapping from each ticket's unique token ID to its metadata URI.
    /// @dev The URI points to a metadata file that describes the ticket and its attributes.
    mapping(uint256 => string) internal tokenURIs;

    /// @notice Mapping from ticket ID to its tier index within a show.
    /// @dev Tiers are used to categorize tickets by price, location, and other characteristics.
    mapping(uint256 => uint256) public ticketIdToTierIndex;

    /// @notice Mapping from ticket ID to the corresponding show ID.
    /// @dev Helps associate each ticket with a specific show.
    mapping(uint256 => bytes32) internal tokenIdToShowId;

    /// @notice Mapping from show ID to a default URI for tickets.
    /// @dev This URI is used when a specific ticket does not have its own unique URI.
    mapping(bytes32 => string) internal showDefaultURIs;

    /// @notice Default URI prefix used for generating metadata for tickets.
    /// @dev This prefix is appended with other data to generate full URIs for tickets lacking unique metadata.
    string internal defaultURI;
}
