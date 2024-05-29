// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ArtistRegistryTypes } from "../types/ArtistRegistryTypes.sol";

/// @title Artist Registry Storage
/// @notice Provides dedicated storage for managing artist data within the Sellout ArtistRegistry.
/// @dev This contract is responsible for storing and managing all artist-related data, including mappings for artist identification and nomination status.
contract ArtistRegistryStorage {
    using ArtistRegistryTypes for ArtistRegistryTypes.ArtistInfo;

    /// @notice Maps artist IDs to their corresponding detailed information.
    /// @dev Used to store and retrieve artist profiles using their unique identifiers.
    mapping(uint256 => ArtistRegistryTypes.ArtistInfo) internal artists;

    /// @notice Maps artist wallet addresses to their unique artist IDs.
    /// @dev Facilitates the retrieval of artist IDs using wallet addresses, allowing quick lookups.
    mapping(address => uint256) internal addressToArtistId;

    /// @notice Tracks nomination status of addresses to become artists.
    /// @dev Helps manage the flow from nomination to registration, ensuring that only nominated artists can register.
    mapping(address => bool) public nominatedArtists;

    /// @notice Internal counter used to assign unique IDs to each new artist.
    /// @dev Incremented each time an artist is registered to ensure each artist receives a unique identifier.
    uint256 internal currentArtistId;
}
