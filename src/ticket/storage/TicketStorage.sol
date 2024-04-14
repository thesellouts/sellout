// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TicketTypes } from "../types/TicketTypes.sol";
import { IShow } from  "../../show/IShow.sol";
import { IBoxOffice } from  "../../show/IBoxOffice.sol";
import { IShowVault } from  "../../show/IShowVault.sol";

/**
 * @title TicketStorage
 * @dev Storage contract for Sellout Tickets.
 */
contract TicketStorage is TicketTypes {
    /// @notice Reference to the Show contract interface to interact with show-related functionalities.
    IShow public showInstance;

    /// @notice Reference to the Box Office contract interface to interact with ticket-related functionalities.
    IBoxOffice public boxOfficeInstance;

    /// @notice Reference to the ShowVault contract interface to interact with ticket-related functionalities.
    IShowVault public showVaultInstance;

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

    mapping(bytes32 => string) internal showDefaultURIs;

    /// @notice The default URI prefix used for ticket metadata.
    /// This is used if a specific ticket does not have a unique URI set.
    string internal defaultURI;
}
