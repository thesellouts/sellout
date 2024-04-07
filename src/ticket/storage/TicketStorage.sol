// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../types/TicketTypes.sol";
import "../../show/IShow.sol";

/**
 * @title TicketStorage
 * @dev Storage contract for Sellout Tickets.
 */
contract TicketStorage is TicketTypes {
    /// @notice Reference to the Show contract interface to interact with show-related functionalities.
    IShow public showInstance;

    /// @notice Version of the ticket factory.
    string public version;

    /// @notice Maximum number of tickets that a single wallet can purchase for a given show.
    uint256 public constant MAX_TICKETS_PER_WALLET = 5;

    /// @notice Mapping from token ID to its associated metadata URI.
    /// Token ID is unique for each ticket, and the URI points to a metadata file that describes the ticket.
    mapping(uint256 => string) internal tokenURIs;

    // Mapping from ticket ID to tier index
    mapping(uint256 => uint256) public ticketIdToTierIndex;

    // Mapping from ticket ID to show ID
    mapping(uint256 => bytes32) internal tokenIdToShowId;

    /// @notice Mapping from show ID to the last ticket number issued for that show.
    /// This helps in generating new ticket IDs for new ticket purchases.
    mapping(bytes32 => uint256) internal lastTicketNumberForShow;


    mapping(bytes32 => uint256) internal nextTicketIdForShow;


    /// @notice The default URI prefix used for ticket metadata.
    /// This is used if a specific ticket does not have a unique URI set.
    string internal defaultURI;
}
