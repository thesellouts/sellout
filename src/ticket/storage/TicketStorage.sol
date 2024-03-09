// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Counters } from "@openzeppelin-contracts/utils/Counters.sol";
import { TicketTypes } from  "../types/TicketTypes.sol";

/// @title TicketStorage
/// @notice This contract provides storage for ticket-related data, including ticket mapping, total tickets sold, ticket price paid, and more.
contract TicketStorage is TicketTypes {
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIdCounter; // Counter for generating unique token IDs

    // Mapping to track tickets purchased per show per user
    mapping(bytes32 => mapping(address => uint256)) internal ticketsPurchasedCount;

    uint256 public constant MAX_TICKETS_PER_WALLET = 5;

    /// @notice Internal function to get the next token ID by incrementing the counter
    /// @return The next available token ID
    function getNextTokenId() internal returns (uint256) {
        _tokenIdCounter.increment(); // Incrementing the token ID counter
        return _tokenIdCounter.current(); // Returning the current token ID
    }
}
