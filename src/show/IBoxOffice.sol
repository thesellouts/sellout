// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBoxOffice
 * @dev Interface for the BoxOffice contract responsible for ticket-related functionalities.
 */
interface IBoxOffice {
    /// @notice Creates and initializes a ticket proxy for a given show.
    /// @param showId The unique identifier of the show.
    /// @param protocol The address of the protocol for initializing the ticket proxy.
    function createAndInitializeTicketProxy(bytes32 showId, address protocol) external;

    /// @notice Retrieves the total number of tickets sold for a given show.
    /// @param showId The unique identifier of the show.
    /// @return The total number of tickets sold.
    function getTotalTicketsSold(bytes32 showId) external view returns (uint256);

    /// @notice Sets the total number of tickets sold for a specific show.
    /// @param showId The unique identifier of the show.
    /// @param amount The total number of tickets to set.
    function setTotalTicketsSold(bytes32 showId, uint256 amount) external;

    /// @notice Retrieves the price paid for a specific ticket of a show.
    /// @param showId The unique identifier of the show.
    /// @param ticketId The unique identifier of the ticket.
    /// @return The price paid for the specified ticket.
    function getTicketPricePaid(bytes32 showId, uint256 ticketId) external view returns (uint256);

    /// @notice Sets the price paid for a specific ticket of a show.
    /// @param showId The unique identifier of the show.
    /// @param ticketId The unique identifier of the ticket.
    /// @param price The price to set for the ticket.
    function setTicketPricePaid(bytes32 showId, uint256 ticketId, uint256 price) external;

    /// @notice Updates the total tickets sold and potentially the show status after a ticket refund.
    /// @param showId The unique identifier of the show.
    /// @param ticketId The ID of the ticket being refunded.
    /// @param refundAmount The amount to be refunded.
    /// @param paymentToken The payment token used for the refund.
    /// @param ticketOwner The address of the ticket owner initiating the refund.
    function updateTicketsSoldAndShowStatusAfterRefund(
        bytes32 showId,
        uint256 ticketId,
        uint256 refundAmount,
        address paymentToken,
        address ticketOwner
    ) external;

    /// @notice Checks if a given token ID exists in the wallet's list of token IDs for a specific show, signifying ticket ownership.
    /// @param showId The unique identifier of the show.
    /// @param wallet The address of the wallet to check.
    /// @param tokenId The unique identifier of the ticket.
    /// @return True if the tokenId exists in the wallet's list of tokens for the specified show, false otherwise.
    function isTokenOwner(bytes32 showId, address wallet, uint256 tokenId) external view returns (bool);

    /// @notice Adds a token ID to a user's wallet for a specific show, signifying ticket ownership.
    /// @param showId The unique identifier of the show.
    /// @param wallet The wallet address to which the ticket ID will be added.
    /// @param tokenId The unique identifier of the ticket being added to the wallet.
    function addTokenIdToWallet(bytes32 showId, address wallet, uint256 tokenId) external;

    /// @notice Removes a token ID from a user's wallet for a specific show.
    /// @param showId The unique identifier of the show.
    /// @param wallet The wallet address from which the ticket ID will be removed.
    /// @param tokenId The unique identifier of the ticket being removed from the wallet.
    function removeTokenIdFromWallet(bytes32 showId, address wallet, uint256 tokenId) external;

    /// @notice Retrieves the token IDs associated with a specific show for a given wallet.
    /// @param showId The unique identifier of the show.
    /// @param wallet The address of the wallet.
    /// @return An array of token IDs associated with the show for the specified wallet.
    function getWalletTokenIds(bytes32 showId, address wallet) external view returns (uint256[] memory);
}
