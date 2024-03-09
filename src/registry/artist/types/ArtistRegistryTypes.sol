// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title ArtistRegistryTypes
/// @notice Defines data structures for the ArtistRegistry contract.
library ArtistRegistryTypes {
    struct ArtistInfo {
        string name;
        string bio;
        address wallet;
    }
}
