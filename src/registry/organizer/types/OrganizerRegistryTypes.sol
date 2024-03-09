// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title OrganizerRegistryTypes
/// @notice Defines data structures for the OrganizerRegistry contract.
library OrganizerRegistryTypes {
    struct OrganizerInfo {
        string name;
        string bio;
        address wallet;
    }
}
