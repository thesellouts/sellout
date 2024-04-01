// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { VenueTypes } from "../../venue/storage/VenueStorage.sol";

/// @title ShowTypes
/// @author taayyohh
/// @notice This contract defines the types and structures related to shows, including status, ticket pricing, and show details.

interface ShowTypes {

    /// @notice Enum representing the various statuses a show can have.
    enum Status {
        Proposed,   // Show has been proposed
        SoldOut,    // Show has sold out
        Accepted,   // Show has been accepted
        Upcoming,   // Show is upcoming
        Completed,  // Show has been completed
        Cancelled,  // Show has been cancelled
        Refunded,   // Show has been refunded
        Expired     // Show has expired
    }

    /// @notice Struct representing the price range for tickets to a show.
    struct TicketTier {
        string name;
        uint256 price;
        uint256 ticketsAvailable;
    }


    /// @notice Struct representing the details of a show.
    struct Show {
        bytes32 showId;               // Unique identifier for the show
        string name;                  // Name of the show
        string description;           // Description of the show
        address organizer;            // Address of the organizer
        address[] artists;            // Addresses of the artists
        VenueTypes.Venue venue;       // Venue details
        uint256 radius;               // radius for proposed show venue
        TicketTier[] ticketTiers;     // tiers of tickets
        uint256 sellOutThreshold;     // Threshold for considering the show as sold out
        uint256 totalCapacity;        // Total capacity of the show
        Status status;                // Current status of the show
        bool isActive;                // Whether the show is active
        uint256[] split;              // Split percentages for revenue distribution
        uint256 expiry;               // Expiry timestamp of the show
        uint256 showDate;             // Final show date
        address currencyAddress;      // Show Currency Address
    }
}
