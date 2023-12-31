// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../types/ArtistRegistryTypes.sol";

/// @title ArtistRegistryStorage
/// @notice Storage contract for ArtistRegistry.
contract ArtistRegistryStorage {
    using ArtistRegistryTypes for ArtistRegistryTypes.ArtistInfo;

    mapping(uint256 => ArtistRegistryTypes.ArtistInfo) internal artists;
    mapping(address => uint256) internal addressToArtistId; // Mapping to track artist IDs by address
    mapping(address => bool) public waitlistedArtists;
    uint256 internal currentArtistId;
}
