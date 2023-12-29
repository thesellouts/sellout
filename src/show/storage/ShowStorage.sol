// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ShowTypes } from "../types/ShowTypes.sol";

/// @title ShowStorageV1
/// @author taayyohh
/// @notice This contract provides storage for show-related data, including ticket mapping, total tickets sold, show details, and more.

contract ShowStorage is ShowTypes {
    // Base URI for tokens
    string internal _baseTokenURI;

    // Counter for the total number of active shows
    uint256 public activeShowCount;

    // Mapping to store show details by show ID
    mapping(bytes32 => Show) public shows;

    // Mapping to track whether a given address is an artist for a specific show
    mapping(bytes32 => mapping(address => bool)) public isArtistMapping;

    // Mapping to track the Ether balance for each show
    mapping(bytes32 => uint256) public showVault;

    // Mapping to track pending withdrawals for each show and address
    mapping(bytes32 => mapping(address => uint256)) public pendingWithdrawals;

    // Mapping to track the total number of tickets sold for each show ID
    mapping(bytes32 => uint256) public totalTicketsSold;

    // Mapping to store the ticket price paid for each ticket ID
    mapping(bytes32 => mapping(uint256 => uint256)) public ticketPricePaid;

    // Mapping to track ticket ownership for each address and show ID
    mapping(address => mapping(bytes32 => bool)) public ticketOwnership;

    // Mapping to associate wallet addresses with show IDs and token IDs
    mapping(bytes32 => mapping(address => uint256[])) public walletToShowToTokenIds;
}
