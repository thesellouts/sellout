// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title IArtistRegistry
/// @notice Interface for the ArtistRegistry contract, including nomination functionalities.
interface IArtistRegistry {
    // Emitted when a new artist is registered
    event ArtistRegistered(uint256 indexed artistId, string name, address wallet);
    // Emitted when an artist updates their profile
    event ArtistUpdated(uint256 indexed artistId, string name, string bio, address wallet);
    // Emitted when an artist deregisters themselves
    event ArtistDeregistered(uint256 indexed artistId);
    // Emitted when an artist is waitlisted, typically after being nominated or applying for referral
    event ArtistWaitlisted(address indexed artist);
    // Emitted when a waitlisted artist is accepted into the registry
    event ArtistAccepted(uint256 indexed artistId, address artistAddress);
    // Emitted when an artist is nominated by another artist
    event ArtistNominated(address indexed nominee);

    /// @notice Accepts the nomination for the artist, allowing them to complete their registration.
    /// @dev Can only be called by the nominated artist themselves.
    function acceptNomination(string memory _name, string memory _bio) external;

    /// @notice Allows an artist to deregister themselves from the registry.
    /// @param _artistId The unique identifier of the artist.
    function deregisterArtist(uint256 _artistId) external;

    /// @notice Retrieves the information of an artist based on their wallet address.
    /// @param artistAddress The wallet address of the artist.
    /// @return name The name of the artist.
    /// @return bio The biography of the artist.
    /// @return wallet The wallet address associated with the artist.
    function getArtist(address artistAddress) external view returns (string memory name, string memory bio, address wallet);

    /// @notice Nominates an artist for registration, can only be called by an artist with referral credits.
    /// @param nominee The address of the artist being nominated.
    function nominate(address nominee) external;

    /// @notice Sets the URI for a given token ID
    /// @param tokenId The token ID for which to set the URI
    /// @param newURI The new URI to set
    function setTokenURI(uint256 tokenId, string calldata newURI) external;

    /// @notice Allows an artist to update their profile with a new name and biography.
    /// @param _artistId The unique identifier of the artist.
    /// @param _name The new name for the artist.
    /// @param _bio The new biography for the artist.
    /// @param _wallet The new wallet for the artist.
    function updateArtist(uint256 _artistId, string memory _name, string memory _bio, address _wallet) external;
}
