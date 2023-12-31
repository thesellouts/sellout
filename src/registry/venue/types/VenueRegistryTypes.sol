// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title VenueRegistryTypes
/// @notice Defines data structures for the VenueRegistry contract.
library VenueRegistryTypes {
    struct VenueInfo {
        string name;
        string bio;
        address wallet;
    }
}
