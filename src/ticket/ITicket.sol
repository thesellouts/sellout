// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./types/TicketTypes.sol";

/// @title ITicket
/// @author taayyohh
/// @notice The external Ticket events, errors, and functions
interface ITicket is TicketTypes {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    event TicketPurchased(address indexed buyer, bytes32 showId, uint256 ticketId, uint256 fanStatus);
    event TicketRefunded(address indexed owner, bytes32 showId, uint256 ticketId);

    /// @notice Purchase a ticket for a specific show
    /// @param showId The ID of the show
    function purchaseTicket(bytes32 showId) external payable;

    /// @notice Refund a ticket and get the amount paid back
    /// @param ticketId The ID of the ticket to refund
    function refundTicket(uint256 ticketId) external;

    /// @notice Get the total capacity of a show
    /// @param showId The ID of the show
    /// @return The total capacity of the show
    function totalCapacityOfShow(bytes32 showId) external view returns (uint256);

    /// @notice Check if an address owns a ticket for a specific show
    /// @param owner The address to check
    /// @param showId The ID of the show
    /// @return true if the address owns a ticket for the show, false otherwise
    function isTicketOwner(address owner, bytes32 showId) external view returns (bool);

    /// @notice Set the base URI for the NFT metadata
    /// @param baseURI The base URI string
    function setBaseURI(string memory baseURI) external;
}
