// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title IArtistRegistry
/// @notice Interface for the ArtistRegistry contract.
interface IArtistRegistry {
    event ArtistRegistered(uint256 indexed artistId, string name);
    event ArtistUpdated(uint256 indexed artistId, string name, string bio);
    event ArtistDeregistered(uint256 indexed artistId);
    event ArtistWaitlisted(address indexed artist);
    event ArtistAccepted(uint256 indexed artistId, address artistAddress);
    /// @notice Accepts a waitlisted artist into the registry.
    function acceptArtist() external;

    /// @notice Waitlists an artist for referral.
    function waitlistForReferral() external;

    /// @notice Allows an artist to update their profile.
    /// @param _artistId ID of the artist updating their profile.
    /// @param _name Updated name of the artist.
    /// @param _bio Updated biography of the artist.
    function updateArtist(uint256 _artistId, string memory _name, string memory _bio) external;

    /// @notice Allows an artist to deregister themselves.
    /// @param _artistId ID of the artist deregistering.
    function deregisterArtist(uint256 _artistId) external;

    /// @notice Retrieves artist information by their wallet address.
    /// @param artistAddress Wallet address of the artist.
    /// @return name Name of the artist.
    /// @return bio Biography of the artist.
    /// @return wallet Wallet address of the artist.
    function getArtistInfoByAddress(address artistAddress) external view returns (string memory name, string memory bio, address wallet);
}
