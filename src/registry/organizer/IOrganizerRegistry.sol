// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Organizer Registry Interface
/// @notice Defines the interface for managing organizer profiles, including registration, updates, and deregistration.
interface IOrganizerRegistry {
    /// @notice Emitted when an organizer is successfully registered.
    /// @param organizerId The unique identifier of the organizer.
    /// @param name The name of the organizer.
    /// @param wallet The wallet address associated with the organizer.
    event OrganizerRegistered(uint256 indexed organizerId, string name, address wallet);

    /// @notice Emitted when an organizer's profile is updated.
    /// @param organizerId The unique identifier of the organizer whose profile was updated.
    /// @param name The updated name of the organizer.
    /// @param bio The updated biography of the organizer.
    /// @param wallet The updated wallet address of the organizer.
    event OrganizerUpdated(uint256 indexed organizerId, string name, string bio, address wallet);

    /// @notice Emitted when an organizer is deregistered from the system.
    /// @param organizerId The unique identifier of the deregistered organizer.
    event OrganizerDeregistered(uint256 indexed organizerId);

    /// @notice Emitted when an address is nominated to become an organizer.
    /// @param nominee The address that was nominated.
    /// @param nominator The address that made the nomination.
    event OrganizerNominated(address indexed nominee, address indexed nominator);

    /// @notice Emitted when a nominated address accepts the nomination and is registered as an organizer.
    /// @param nominee The address of the nominee who accepted the nomination.
    event OrganizerAccepted(address indexed nominee);

    /// @notice Accepts the nomination to become an organizer.
    /// @param _name The name of the nominee.
    /// @param _bio The biography or description of the nominee.
    function acceptNomination(string memory _name, string memory _bio) external;

    /// @notice Deregisters an organizer, removing their profile and associated data.
    /// @param organizerId The unique identifier of the organizer to be deregistered.
    function deregisterOrganizer(uint256 organizerId) external;

    /// @notice Retrieves detailed information about an organizer based on their wallet address.
    /// @param organizerAddress The wallet address of the organizer.
    /// @return name The name of the organizer.
    /// @return bio The biography or description of the organizer.
    /// @return wallet The wallet address associated with the organizer.
    function getOrganizer(address organizerAddress) external view returns (string memory name, string memory bio, address wallet);

    /// @notice Checks if a specific address is registered as an organizer.
    /// @param organizer The address to check.
    /// @return True if the address is registered as an organizer, otherwise false.
    function isOrganizerRegistered(address organizer) external view returns (bool);

    /// @notice Nominates an individual to become an organizer.
    /// @param nominee The address to be nominated.
    function nominate(address nominee) external;

    /// @notice Sets or updates the metadata URI for a specific organizer token.
    /// @param tokenId The unique identifier of the organizer token.
    /// @param newURI The new URI string that will represent the token's metadata.
    function setTokenURI(uint256 tokenId, string calldata newURI) external;

    /// @notice Updates the profile information of a registered organizer.
    /// @param organizerId The unique identifier of the organizer whose information is being updated.
    /// @param name The new name of the organizer.
    /// @param bio The new biography of the organizer.
    /// @param wallet The new wallet address of the organizer.
    function updateOrganizer(uint256 organizerId, string memory name, string memory bio, address wallet) external;
}
