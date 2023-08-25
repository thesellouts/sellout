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

    /// @notice Purchase a ticket for a specific show
    /// @param showId The ID of the show
    function purchaseTicket(bytes32 showId) external payable;


    /// @notice Set the base URI for the NFT metadata
    /// @param baseURI The base URI string
    function setBaseURI(string memory baseURI) external;
}
