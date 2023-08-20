// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../types/ShowTypes.sol"; // Importing ShowTypes

/// @title ShowStorageV1
/// @author taayyohh
/// @notice This contract provides storage for show-related data, including ticket mapping, total tickets sold, show details, and more.

contract ShowStorage is ShowTypes {
    string internal _baseTokenURI; // Base URI for tokens

    // Mapping to associate ticket ID with show ID
    mapping(uint256 => uint256) public ticketToShow;

    // Mapping to track the total number of tickets sold for each show ID
    mapping(uint256 => uint256) public totalTicketsSold;

    // Mapping to store show details by show ID
    mapping(bytes32 => Show) public shows;

    // Mapping to track whether a given address is an artist for a specific show
    mapping(bytes32 => mapping(address => bool)) public isArtistMapping;

    // Mapping to track existing shows by show ID
    mapping(bytes32 => bool) public existingShows;

    // Mapping to track the Ether balance for each show
    mapping(bytes32 => uint256) public showVault;

    // Mapping to track pending withdrawals for each show and address
    mapping(bytes32 => mapping(address => uint256)) public pendingWithdrawals;

    uint256 public showCount; // Counter for the total number of shows

    // Constant address for the Sellout Protocol Wallet
    address constant SELLOUT_PROTOCOL_WALLET = 0x1234567890123456789012345678901234567890;
}
