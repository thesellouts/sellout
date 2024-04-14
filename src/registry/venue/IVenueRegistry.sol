// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { VenueRegistryTypes } from "./types/VenueRegistryTypes.sol";

/// @title IVenueRegistry
/// @notice Interface for the VenueRegistry contract that manages venue profiles with ERC1155 tokens.
interface IVenueRegistry {
    /// @dev Emitted when a venue is registered in the registry.
    event VenueRegistered(uint256 indexed venueId, string name);

    /// @dev Emitted when a venue's profile is updated.
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

    /// @dev Emitted when a venue deregisters from the registry.
    event VenueDeregistered(uint256 indexed venueId);

    /// @dev Emitted when a venue is nominated for registration.
    event VenueNominated(address indexed nominee);

    /// @dev Emitted when a nominated venue accepts its nomination and completes registration.
    event VenueAccepted(uint256 indexed venueId, address venueAddress);


    /**
     * @notice Accepts the nomination for venue registration by the nominated venue.
     * @param _name Name of the nominated venue.
     * @param _bio Biography or description of the nominated venue.
     * @param _latitude Latitude part of the venue's coordinates.
     * @param _longitude Longitude part of the venue's coordinates.
     * @param _totalCapacity Total capacity of the venue.
     * @param _streetAddress Street address of the venue.
     */
    function acceptNomination(
        string memory _name,
        string memory _bio,
        int256 _latitude,
        int256 _longitude,
        uint256 _totalCapacity,
        string memory _streetAddress
    ) external;

    /**
     * @notice Allows a venue to deregister itself from the registry.
     * @param _venueId The unique identifier of the deregistering venue.
     */
    function deregisterVenue(uint256 _venueId) external;

    /**
     * @notice Retrieves information about a venue by its wallet address.
     * @param venueAddress The wallet address of the venue.
     * @return name The name of the venue.
     * @return bio The biography or description of the venue.
     * @return wallet The wallet address of the venue.
     * @return latitude Latitude part of the venue's coordinates.
     * @return longitude Longitude part of the venue's coordinates.
     * @return totalCapacity Total capacity of the venue.
     * @return streetAddress Street address of the venue.
     */
    function getVenue(address venueAddress) external view returns (
        string memory name,
        string memory bio,
        address wallet,
        int latitude,
        int longitude,
        uint256 totalCapacity,
        string memory streetAddress
    );


    function getVenueById(uint256 venueId) external view returns (VenueRegistryTypes.VenueInfo memory);


    /**
     * @notice Nominates a venue for registration, utilizing a referral credit.
     * @param nominee The address of the venue being nominated.
     */
    function nominate(address nominee) external;

    /// @notice Sets the URI for a given token ID
    /// @param tokenId The token ID for which to set the URI
    /// @param newURI The new URI to set
    function setTokenURI(uint256 tokenId, string calldata newURI) external;

    /**
     * @notice Allows a venue to update their profile information.
     * @param _venueId The unique identifier of the venue.
     * @param _name The new name of the venue.
     * @param _bio The new biography or description of the venue.
     * @param _wallet The new wallet address of the venue.
     * @param _latitude New latitude for the venue's location.
     * @param _longitude New longitude for the venue's location.
     * @param _totalCapacity New total capacity of the venue.
     * @param _streetAddress New street address of the venue.
     */
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

    function isVenueRegistered(address venueAddress) external view returns (bool);
}
