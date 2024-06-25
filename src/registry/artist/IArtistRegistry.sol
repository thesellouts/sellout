// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Artist Registry Interface
/// @notice Defines the interface for managing artist profiles and nominations within a decentralized registry.
interface IArtistRegistry {
    /// @notice Emitted when a new artist is successfully registered in the registry.
    /// @param artistId Unique identifier for the newly registered artist.
    /// @param name Name of the artist registered.
    /// @param wallet Wallet address associated with the artist.
    event ArtistRegistered(uint256 indexed artistId, string name, address wallet);

    /// @notice Emitted when an existing artist updates their profile information.
    /// @param artistId Unique identifier of the artist whose profile is updated.
    /// @param name Updated name of the artist.
    /// @param bio Updated biography or description of the artist.
    /// @param wallet Updated wallet address of the artist.
    event ArtistUpdated(uint256 indexed artistId, string name, string bio, address wallet);

    /// @notice Emitted when an artist chooses to deregister themselves from the registry.
    /// @param artistId Unique identifier of the deregistered artist.
    event ArtistDeregistered(uint256 indexed artistId);

    /// @notice Emitted when an artist is waitlisted, often after nomination or referral application.
    /// @param artist Address of the artist who is waitlisted.
    event ArtistWaitlisted(address indexed artist);

    /// @notice Emitted when a waitlisted artist accepts their nomination and completes registration.
    /// @param artistId Unique identifier assigned to the artist upon registration.
    /// @param artistAddress Wallet address of the artist who was accepted.
    event ArtistAccepted(uint256 indexed artistId, address artistAddress);

    /// @notice Emitted when an artist is nominated by another artist, typically backed by referral credits.
    /// @param nominee Wallet address of the artist being nominated.
    event ArtistNominated(address indexed nominee);

    /// @notice Emitted when the general token URI is updated.
    /// @param newURI The new URI that has been set.
    event contractURIUpdated(string newURI);

    /// @notice Emitted when the URI of a specific artist token is updated.
    /// @param newURI The new metadata URI.
    /// @param tokenId The token ID for which the URI was updated.
    event tokenURIUpdated(string newURI, uint256 tokenId);

    /// @notice Accepts a nomination to become a registered artist.
    /// @param _name Name to register under.
    /// @param _bio Biography or description to accompany the registration.
    function acceptNomination(string memory _name, string memory _bio) external;

    /// @notice Allows an artist to voluntarily deregister themselves from the registry.
    /// @param _artistId The unique identifier of the artist to deregister.
    function deregisterArtist(uint256 _artistId) external;

    /// @notice Retrieves detailed information about an artist using their wallet address.
    /// @param artistAddress Wallet address of the artist.
    /// @return name Name of the artist.
    /// @return bio Biography or description of the artist.
    /// @return wallet Wallet address of the artist.
    function getArtist(address artistAddress) external view returns (string memory name, string memory bio, address wallet);

    /// @notice Nominates an individual to become an artist within the registry.
    /// @param nominee Wallet address of the individual being nominated.
    function nominate(address nominee) external;

    /// @notice Updates the metadata URI for a specific artist token.
    /// @param tokenId Unique token identifier associated with the artist.
    /// @param newURI New URI to set for the artist token.
    function setTokenURI(uint256 tokenId, string calldata newURI) external;

    /// @notice Updates the metadata URI for the contract.
    /// @param newURI New URI to set for the artist token.
    function setContractURI(string calldata newURI) external;

    /// @notice Updates the profile of a registered artist.
    /// @param _artistId Unique identifier of the artist whose profile is being updated.
    /// @param _name New name for the artist.
    /// @param _bio New biography or description for the artist.
    /// @param _wallet New wallet address for the artist.
    function updateArtist(uint256 _artistId, string memory _name, string memory _bio, address _wallet) external;

    /// @notice Checks whether a specific wallet address is registered as an artist.
    /// @param artistAddress Address to check against the registry.
    /// @return isRegistered True if the address is registered as an artist, false otherwise.
    function isArtistRegistered(address artistAddress) external view returns (bool isRegistered);
}
