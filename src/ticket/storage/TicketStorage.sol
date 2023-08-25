// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol"; // Importing OpenZeppelin's Counters library
import "../types/TicketTypes.sol"; // Importing TicketTypes

/// @title TicketStorage
/// @author taayyohh
/// @notice This contract provides storage for ticket-related data, including ticket mapping, total tickets sold, ticket price paid, and more.

contract TicketStorage is TicketTypes {
    using Counters for Counters.Counter; // Using OpenZeppelin's Counters library for managing token IDs
    Counters.Counter internal _tokenIdCounter; // Counter for generating unique token IDs

    string internal _baseTokenURI; // Base URI for tokens

    uint256 public constant MAX_TICKETS_PER_WALLET = 5; // or any number you choose



    /// @notice Internal function to get the next token ID by incrementing the counter
    /// @return The next available token ID
    function getNextTokenId() internal returns (uint256) {
        _tokenIdCounter.increment(); // Incrementing the token ID counter
        return _tokenIdCounter.current(); // Returning the current token ID
    }
}
