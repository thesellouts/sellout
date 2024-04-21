// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ITicketFactory } from '../../ticket/ITicketFactory.sol';
import { IShow } from '../IShow.sol';
import { IShowVault } from '../IShowVault.sol';

/// @title Box Office Storage for Shows and Tickets
/// @notice This contract serves as a dedicated storage module for the Box Office, maintaining records of tickets sales, payments, and ownership.
/// @dev This contract holds references to other contract instances and mappings related to ticket management.
contract BoxOfficeStorage {
    /// @notice Instance of the IShow contract to interact with show-related functionalities.
    IShow public showContractInstance;

    /// @notice Instance of the ITicketFactory contract used for ticket creation and management.
    ITicketFactory public ticketFactoryInstance;

    /// @notice Instance of the IShowVault contract to handle financial transactions related to shows.
    IShowVault public showVaultInstance;

    /// @notice Mapping from show ID to the total number of tickets sold for that show.
    /// @dev Used to track and limit the total number of tickets sold, ensuring capacity constraints are respected.
    mapping(bytes32 => uint256) public totalTicketsSold;

    /// @notice Mapping from show ID to token ID, then to the price paid for that particular ticket.
    /// @dev This mapping helps in tracking how much was paid for each ticket, useful for refunds or secondary sales analysis.
    mapping(bytes32 => mapping(uint256 => uint256)) public ticketPricePaid;

    /// @notice Mapping to associate wallet addresses with show IDs and token IDs of purchased tickets.
    /// @dev This mapping is critical for identifying which tickets are owned by which wallets, facilitating transfers, and viewing ownership.
    mapping(bytes32 => mapping(address => uint256[])) public walletToShowToTokenIds;
}
