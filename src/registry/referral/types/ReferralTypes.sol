// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title ArtistRegistryTypes
/// @notice Defines data structures for the ArtistRegistry contract.
library ReferralTypes {
    /// @dev Struct to hold referral credits.
    struct ReferralCredits {
        uint256 artist; // Number of credits for artists.
        uint256 organizer; // Number of credits for organizers.
        uint256 venue; // Number of credits for venues.
    }
}
