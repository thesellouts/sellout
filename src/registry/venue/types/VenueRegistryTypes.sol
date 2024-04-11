// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title VenueRegistryTypes
/// @notice Defines data structures for the VenueRegistry contract.
library VenueRegistryTypes {
    struct Coordinates {
        int256 latitude;
        int256 longitude;
    }

    struct VenueInfo {
        string name;
        string bio;
        address wallet;
        Coordinates coordinates; // Added coordinates as a struct
        uint256 totalCapacity; // Using uint256 to represent a large integer
        string streetAddress; // New field for street address
    }
}
