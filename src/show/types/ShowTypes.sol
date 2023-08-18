// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title ShowTypes
/// @author taayyohh
/// @notice Show Storage contract
interface ShowTypes {

    enum Status {
        Proposed,
        Accepted,
        SoldOut,
        Active,
        Completed,
        Cancelled,
        Refunded
    }

    struct Venue {
        string name;
        string location;
        uint256 totalCapacity;
    }

    struct TicketPrice {
        uint256 minPrice;
        uint256 maxPrice;
    }

    struct Show {
        string name;
        string description;
        address organizer;
        address[] artists;
        Venue venue;
        TicketPrice ticketPrice;
        uint256 sellOutThreshold;
        uint256 totalCapacity;
        Status status;
        bool isActive;
    }
}
