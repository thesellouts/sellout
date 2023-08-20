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

    // Mapping to associate ticket ID with show ID
    mapping(uint256 => bytes32) public ticketToShow;

    // Mapping to track the total number of tickets sold for each show ID
    mapping(bytes32 => uint256) public totalTicketsSold;

    // Mapping to store the ticket price paid for each ticket ID
    mapping(uint256 => uint256) public ticketPricePaid;

    // Mapping to track ticket ownership for each address and show ID
    mapping(address => mapping(bytes32 => bool)) public ticketOwnership;

    /// @notice Internal function to get the next token ID by incrementing the counter
    /// @return The next available token ID
    function getNextTokenId() internal returns (uint256) {
        _tokenIdCounter.increment(); // Incrementing the token ID counter
        return _tokenIdCounter.current(); // Returning the current token ID
    }
}
