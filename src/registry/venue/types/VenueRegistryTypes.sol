// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Venue Registry Types
/// @notice Provides structured data types used by the VenueRegistry contract to manage and store venue information efficiently.
library VenueRegistryTypes {

    /// @dev Structure for holding geographical coordinates.
    /// @param latitude The latitude part of the geographic coordinates, stored as an integer.
    /// @param longitude The longitude part of the geographic coordinates, stored as an integer.
    struct Coordinates {
        int256 latitude;
        int256 longitude;
    }

    /// @dev Structure to hold detailed information about a venue.
    /// @param venueId Unique identifier for the venue, used to track and reference the venue in the registry.
    /// @param name Human-readable name of the venue, typically used for display purposes.
    /// @param bio Short biography or description of the venue, providing additional context or details.
    /// @param wallet Ethereum address associated with the venue, which may be used for transactions or identification.
    /// @param coordinates Nested `Coordinates` struct storing the geographic coordinates of the venue.
    /// @param totalCapacity Maximum number of people the venue can accommodate, reflecting physical or legal limits.
    /// @param streetAddress Physical street address of the venue, providing specific location details.
    struct VenueInfo {
        uint256 venueId;
        string name;
        string bio;
        address wallet;
        Coordinates coordinates;
        uint256 totalCapacity;
        string streetAddress;
    }
}
