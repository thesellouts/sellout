// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title TicketTypes
/// @author taayyohh
/// @notice Ticket Types contract
interface TicketTypes {

    /**
     * @notice Data structure to hold information needed for ticket purchase to reduce stack depth.
     */
    struct PurchaseData {
        uint256 pricePerTicket;
        uint256 ticketsAvailable;
        uint256 totalPayment;
        uint256 tokenId;
    }
}
