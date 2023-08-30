// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { TicketTypes } from "./storage/TicketStorage.sol";

/// @title ITicket
/// @author taayyohh
/// @notice The external Ticket events, errors, and functions
interface ITicket is TicketTypes {

    /// @notice Event emitted when a ticket is purchased
    /// @param buyer The address of the buyer
    /// @param showId The ID of the show for which the ticket was purchased
    /// @param ticketId The ID of the purchased ticket
    /// @param fanStatus The status of the fan (1-10) based on the percentage of tickets sold
    event TicketPurchased(address indexed buyer, bytes32 showId, uint256 ticketId, uint256 fanStatus);

    /// @notice Purchase a ticket for a specific show
    /// @param showId The ID of the show
    function purchaseTicket(bytes32 showId) external payable;

    /// @notice Set the base URI for the NFT metadata
    /// @param baseURI The base URI string
    function setBaseURI(string memory baseURI) external;

    /// @notice Burns a specific token, removing it from circulation
    /// @param tokenId The ID of the token to be burned
    function burnToken(uint256 tokenId) external;

    /// @notice Returns the token URI for a specific token ID
    /// @param tokenId The ID of the token
    /// @return The URI of the token
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
