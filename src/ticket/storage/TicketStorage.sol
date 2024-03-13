// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { TicketTypes } from  "../types/TicketTypes.sol";

/// @title TicketStorage
/// @notice This contract provides storage for ticket-related data, including ticket mapping, total tickets sold, ticket price paid, and more.
contract TicketStorage is TicketTypes {
    mapping(bytes32 => mapping(address => uint256)) internal ticketsPurchasedCount;

    uint256 public constant MAX_TICKETS_PER_WALLET = 5;
}
