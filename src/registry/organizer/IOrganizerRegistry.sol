// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title IOrganizerRegistry
/// @notice Interface for the OrganizerRegistry contract.
interface IOrganizerRegistry {
    event OrganizerRegistered(uint256 indexed organizerId, string name, address wallet);
    event OrganizerUpdated(uint256 indexed organizerId, string name, string bio);
    event OrganizerDeregistered(uint256 indexed organizerId);
    event OrganizerNominated(address indexed nominee, address indexed nominator);
    event OrganizerAccepted(address indexed nominee);

    /// @notice Nominates an address for organizer status, can only be called by an existing organizer.
    /// @param nominee The address being nominated for organizer status.
    function nominate(address nominee) external;

    /// @notice Accepts nomination for organizer status. Must be called by the nominee.
    function acceptNomination() external;

    /// @notice Updates an organizer's profile information.
    /// @param organizerId The ID of the organizer whose profile is being updated.
    /// @param name The updated name of the organizer.
    /// @param bio The updated biography of the organizer.
    function updateOrganizer(uint256 organizerId, string memory name, string memory bio) external;

    /// @notice Deregisters an organizer from the registry. Can only be called by the organizer themselves.
    /// @param organizerId The ID of the organizer being deregistered.
    function deregisterOrganizer(uint256 organizerId) external;

    /// @notice Retrieves information about an organizer based on their wallet address.
    /// @param organizerAddress The wallet address of the organizer.
    /// @return name The name of the organizer.
    /// @return bio The biography of the organizer.
    /// @return wallet The wallet address of the organizer.
    function getOrganizerInfoByAddress(address organizerAddress) external view returns (string memory name, string memory bio, address wallet);
}
