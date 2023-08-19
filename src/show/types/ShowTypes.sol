// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title ShowTypes
/// @author taayyohh
/// @notice Show Storage contract
interface ShowTypes {

    enum Status {
        Proposed,
        SoldOut,
        Accepted,
        Completed,
        Cancelled,
        Refunded,
        Expired
    }

    struct Venue {
        string name;
        string location; // lat long
        uint256 radius;
        uint256 totalCapacity;
        address wallet;
    }

    struct TicketPrice {
        uint256 minPrice;
        uint256 maxPrice;
    }

    struct Show {
        bytes32 showId;
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
        uint256[] split;
        uint256 expiry; // Expiry timestamp
    }
}
