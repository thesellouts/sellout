// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { VenueRegistryTypes } from "./types/VenueRegistryTypes.sol";

/// @title Venue Registry Interface
/// @notice Interface for managing venue profiles and their associated functionalities within the ERC1155 framework.
/// @dev Provides functions for venue registration, updates, and queries.
interface IVenueRegistry {

    /// @notice Emitted when a new venue is registered in the system.
    /// @param venueId Unique identifier for the newly registered venue.
    /// @param name Name of the venue registered.
    /// @param wallet The wallet address associated with the organizer.
    event VenueRegistered(uint256 indexed venueId, string name, address wallet);

    /// @notice Emitted when a venue's information is updated in the registry.
    /// @param venueId Unique identifier for the venue being updated.
    /// @param name Updated name of the venue.
    /// @param bio Updated biography or description of the venue.
    /// @param wallet Updated wallet address associated with the venue.
    /// @param latitude Updated latitude coordinate of the venue.
    /// @param longitude Updated longitude coordinate of the venue.
    /// @param totalCapacity Updated total capacity figure of the venue.
    /// @param streetAddress Updated physical street address of the venue.
    event VenueUpdated(
        uint256 indexed venueId,
        string name,
        string bio,
        address wallet,
        int256 latitude,
        int256 longitude,
        uint256 totalCapacity,
        string streetAddress
    );

    /// @notice Emitted when a venue is deregistered from the system.
    /// @param venueId Unique identifier for the venue being deregistered.
    event VenueDeregistered(uint256 indexed venueId);

    /// @notice Emitted when a new venue is nominated for registration.
    /// @param nominee Address of the venue being nominated.
    event VenueNominated(address indexed nominee);

    /// @notice Emitted when a nominated venue accepts its nomination and completes the registration process.
    /// @param venueId Unique identifier assigned to the newly accepted venue.
    /// @param venueAddress Wallet address of the venue that has been accepted.
    event VenueAccepted(uint256 indexed venueId, address venueAddress);

    /// @notice Emitted when the general token URI is updated.
    /// @param newURI The new URI that has been set.
    event contractURIUpdated(string newURI);

    /// @notice Emitted when the URI of a specific artist token is updated.
    /// @param newURI The new metadata URI.
    /// @param tokenId The token ID for which the URI was updated.
    event tokenURIUpdated(string newURI, uint256 tokenId);

    /// @notice Allows a nominated venue to accept its nomination and register.
    /// @param _name Name of the venue.
    /// @param _bio Biography or description of the venue.
    /// @param _latitude Geographic latitude coordinate of the venue.
    /// @param _longitude Geographic longitude coordinate of the venue.
    /// @param _totalCapacity Maximum capacity of the venue.
    /// @param _streetAddress Physical street address of the venue.
    function acceptNomination(
        string memory _name,
        string memory _bio,
        int256 _latitude,
        int256 _longitude,
        uint256 _totalCapacity,
        string memory _streetAddress
    ) external;

    /// @notice Deregisters a venue from the registry.
    /// @param _venueId Unique identifier of the venue to be deregistered.
    function deregisterVenue(uint256 _venueId) external;

    /// @notice Retrieves venue information by wallet address.
    /// @param venueAddress Wallet address of the venue.
    /// @return venueId Unique identifier of the venue.
    /// @return name Name of the venue.
    /// @return bio Biography or description of the venue.
    /// @return wallet Wallet address associated with the venue.
    /// @return latitude Geographic latitude coordinate of the venue.
    /// @return longitude Geographic longitude coordinate of the venue.
    /// @return totalCapacity Maximum capacity of the venue.
    /// @return streetAddress Physical street address of the venue.
    function getVenue(address venueAddress) external view returns (
        uint256 venueId,
        string memory name,
        string memory bio,
        address wallet,
        int latitude,
        int longitude,
        uint256 totalCapacity,
        string memory streetAddress
    );

    /// @notice Retrieves venue information by its unique identifier.
    /// @param venueId Unique identifier of the venue.
    /// @return VenueInfo Struct containing all relevant data of the venue.
    function getVenueById(uint256 venueId) external view returns (VenueRegistryTypes.VenueInfo memory);

    /// @notice Nominates a new venue for registration using a referral credit.
    /// @param nominee Address of the venue being nominated.
    function nominate(address nominee) external;

    /// @notice Sets a new URI for a specified token, updating the metadata link.
    /// @param tokenId Token ID for which to set the new URI.
    /// @param newURI New URI string to update.
    function setTokenURI(uint256 tokenId, string calldata newURI) external;

    /// @notice Updates the metadata URI for the contract.
    /// @param newURI New URI to set for the artist token.
    function setContractURI(string calldata newURI) external;

    /// @notice Updates the profile information of a registered venue.
    /// @param _venueId Unique identifier of the venue.
    /// @param _name New name of the venue.
    /// @param _bio New biography or description of the venue.
    /// @param _wallet New wallet address associated with the venue.
    /// @param _latitude New latitude coordinate for the venue.
    /// @param _longitude New longitude coordinate for the venue.
    /// @param _totalCapacity New maximum capacity figure for the venue.
    /// @param _streetAddress New physical address of the venue.
    function updateVenue(
        uint256 _venueId,
        string memory _name,
        string memory _bio,
        address _wallet,
        int256 _latitude,
        int256 _longitude,
        uint256 _totalCapacity,
        string memory _streetAddress
    ) external;

    /// @notice Checks if a venue is registered in the registry by its address.
    /// @param venueAddress Address of the venue to check.
    /// @return bool True if the venue is registered, false otherwise.
    function isVenueRegistered(address venueAddress) external view returns (bool);
}
