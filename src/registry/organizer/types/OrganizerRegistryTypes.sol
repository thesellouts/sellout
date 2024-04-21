// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Organizer Registry Types
/// @notice Provides structured data types used by the OrganizerRegistry to manage and store organizer information.
/// @dev This library defines complex data structures to represent organizer profiles within the registry.
library OrganizerRegistryTypes {
    /// @dev Structure to hold detailed information about an organizer.
    /// @param name The public name of the organizer, used for display and identification purposes.
    /// @param bio A brief biography or description of the organizer, providing context about their background or expertise.
    /// @param wallet Ethereum address associated with the organizer, which may be used for transactions or identification.
    struct OrganizerInfo {
        string name;   ///< Name of the organizer.
        string bio;    ///< Biography or description of the organizer.
        address wallet; ///< Wallet address associated with the organizer.
    }
}
