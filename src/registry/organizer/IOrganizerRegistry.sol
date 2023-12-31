// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title IOrganizerRegistry
/// @notice Interface for the OrganizerRegistry contract.
interface IOrganizerRegistry {
    event OrganizerRegistered(uint256 indexed organizerId, string name);
    event OrganizerUpdated(uint256 indexed organizerId, string name, string bio);
    event OrganizerDeregistered(uint256 indexed organizerId);
    event OrganizerWaitlisted(address indexed organizer);
    event OrganizerAccepted(uint256 indexed organizerId, address organizerAddress);


    /// @notice Accepts a waitlisted organizer into the registry.
    function acceptOrganizer() external;

    /// @notice Waitlists an organizer for referral.
    function waitlistForReferral() external;

    /// @notice Updates an organizer's profile.
    /// @param _organizerId ID of the organizer updating their profile.
    /// @param _name Updated name of the organizer.
    /// @param _bio Updated biography of the organizer.
    function updateOrganizer(uint256 _organizerId, string memory _name, string memory _bio) external;

    /// @notice Allows an organizer to deregister themselves.
    /// @param _organizerId ID of the organizer deregistering.
    function deregisterOrganizer(uint256 _organizerId) external;

    /// @notice Retrieves organizer information based on their wallet address.
    /// @param organizerAddress Address of the organizer to retrieve info for.
    /// @return name Name of the organizer.
    /// @return bio Biography of the organizer.
    /// @return wallet Wallet address of the organizer.
    function getOrganizerInfoByAddress(address organizerAddress) external view returns (string memory name, string memory bio, address wallet);
}
