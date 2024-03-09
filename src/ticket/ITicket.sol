// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { TicketTypes } from "./storage/TicketStorage.sol";

/// @title ITicket
/// @notice The external Ticket interface for the ERC1155 standard
interface ITicket is TicketTypes {
    /// @notice Event emitted when a ticket is purchased
    /// @param buyer The address of the buyer
    /// @param showId The ID of the show for which the ticket was purchased
    /// @param ticketId The ID of the purchased ticket
    /// @param amount The amount of tickets purchased
    /// @param fanStatus The fan status based on the percentage of tickets sold
    event TicketPurchased(address indexed buyer, bytes32 indexed showId, uint256 indexed ticketId, uint256 amount, uint256 fanStatus);

    /// @notice Purchase multiple tickets for a specific show
    /// @param showId The ID of the show
    /// @param amount The amount of tickets to purchase
    function purchaseTickets(bytes32 showId, uint256 amount) external payable;

    /// @notice Burns a specific amount of tokens, removing them from circulation
    /// @param tokenId The ID of the token type to be burned
    /// @param amount The amount of tokens to be burned
    function burnTokens(uint256 tokenId, uint256 amount) external;

    /// @notice Sets the URI for a given token ID
    /// @param showId The ID of the show for which to set the URI
    /// @param tokenId The token ID for which to set the URI
    /// @param newURI The new URI to set
    function setTokenURI(bytes32 showId, uint256 tokenId, string calldata newURI) external;

    /// @notice Sets the default URI for all tokens
    /// @param newDefaultURI The new default URI to be set
    /// @param showId The ID of the show for which the default URI is set
    function setDefaultURI(string calldata newDefaultURI, bytes32 showId) external;
}
