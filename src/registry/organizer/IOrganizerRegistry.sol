// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title IOrganizerRegistry
/// @notice Interface for the OrganizerRegistry contract.
interface IOrganizerRegistry {
    event OrganizerRegistered(uint256 indexed organizerId, string name, address wallet);
    event OrganizerUpdated(uint256 indexed organizerId, string name, string bio, address wallet);
    event OrganizerDeregistered(uint256 indexed organizerId);
    event OrganizerNominated(address indexed nominee, address indexed nominator);
    event OrganizerAccepted(address indexed nominee);

    /// @notice Accepts nomination for organizer status. Must be called by the nominee.
    function acceptNomination(string memory _name, string memory _bio) external;

    /// @notice Deregisters an organizer from the registry. Can only be called by the organizer themselves.
    /// @param organizerId The ID of the organizer being deregistered.
    function deregisterOrganizer(uint256 organizerId) external;

    /// @notice Retrieves information about an organizer based on their wallet address.
    /// @param organizerAddress The wallet address of the organizer.
    /// @return name The name of the organizer.
    /// @return bio The biography of the organizer.
    /// @return wallet The wallet address of the organizer.
    function getOrganizer(address organizerAddress) external view returns (string memory name, string memory bio, address wallet);

    /// @notice Determines if a given address is a registered organizer.
    /// @param organizer Address to check for registration.
    /// @return True if the address is registered as an organizer, otherwise false.
    function isOrganizerRegistered(address organizer) external view returns (bool);

    /// @notice Nominates an address for organizer status, can only be called by an existing organizer.
    /// @param nominee The address being nominated for organizer status.
    function nominate(address nominee) external;

    /// @notice Sets the URI for a given token ID
    /// @param tokenId The token ID for which to set the URI
    /// @param newURI The new URI to set
    function setTokenURI(uint256 tokenId, string calldata newURI) external;

    /// @notice Updates an organizer's profile information.
    /// @param organizerId The ID of the organizer whose profile is being updated.
    /// @param name The updated name of the organizer.
    /// @param bio The updated biography of the organizer.
    /// @param wallet The updated wallet for the organizer.
    function updateOrganizer(uint256 organizerId, string memory name, string memory bio, address wallet) external;
}
