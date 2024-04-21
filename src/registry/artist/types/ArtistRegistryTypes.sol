// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Artist Registry Types
/// @notice Provides structured data types used by the ArtistRegistry to manage and store artist information.
/// @dev This library defines complex data structures to represent artist profiles within the registry.
library ArtistRegistryTypes {
    /// @dev Structure to hold detailed information about an artist.
    /// @param name The public name of the artist, used for display and identification purposes.
    /// @param bio A brief biography or description of the artist, providing context about their background, style, or influences.
    /// @param wallet Ethereum address associated with the artist, which may be used for transactions or identification.
    struct ArtistInfo {
        string name;   ///< Name of the artist.
        string bio;    ///< Biography or description of the artist.
        address wallet; ///< Wallet address associated with the artist.
    }
}
