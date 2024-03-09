// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title IVenueRegistry
/// @notice Interface for the VenueRegistry contract that manages venue profiles with ERC1155 tokens.
interface IVenueRegistry {
    /// @dev Emitted when a venue is registered in the registry.
    event VenueRegistered(uint256 indexed venueId, string name);

    /// @dev Emitted when a venue's profile is updated.
    event VenueUpdated(uint256 indexed venueId, string name, string bio);

    /// @dev Emitted when a venue deregisters from the registry.
    event VenueDeregistered(uint256 indexed venueId);

    /// @dev Emitted when a venue is nominated for registration.
    event VenueNominated(address indexed nominee);

    /// @dev Emitted when a nominated venue accepts its nomination and completes registration.
    event VenueAccepted(uint256 indexed venueId, address venueAddress);

    /**
     * @notice Nominates a venue for registration, utilizing a referral credit.
     * @param nominee The address of the venue being nominated.
     */
    function nominate(address nominee) external;

    /**
     * @notice Accepts the nomination for venue registration by the nominated venue.
     */
    function acceptNomination() external;

    /**
     * @notice Allows a venue to update their profile with new name and bio.
     * @param _venueId The unique identifier of the venue.
     * @param _name The new name of the venue.
     * @param _bio The new biography or description of the venue.
     */
    function updateVenue(uint256 _venueId, string memory _name, string memory _bio) external;

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
     */
    function getVenueInfoByAddress(address venueAddress) external view returns (string memory name, string memory bio, address wallet);
}
