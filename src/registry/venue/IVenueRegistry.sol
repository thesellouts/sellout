// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title IVenueRegistry
/// @notice Interface for the VenueRegistry contract.
interface IVenueRegistry {
    event VenueRegistered(uint256 indexed venueId, string name);
    event VenueUpdated(uint256 indexed venueId, string name, string bio);
    event VenueDeregistered(uint256 indexed venueId);
    event VenueWaitlisted(address indexed venue);
    event VenueAccepted(uint256 indexed venueId, address venueAddress);


    /// @notice Accepts a waitlisted venue into the registry.
    function acceptVenue() external;

    /// @notice Waitlists a venue for referral.
    function waitlistForReferral() external;

    /// @notice Allows a venue to update their profile.
    /// @param _venueId ID of the venue updating their profile.
    /// @param _name Updated name of the venue.
    /// @param _bio Updated biography of the venue.
    function updateVenue(uint256 _venueId, string memory _name, string memory _bio) external;

    /// @notice Allows a venue to deregister themselves.
    /// @param _venueId ID of the venue deregistering.
    function deregisterVenue(uint256 _venueId) external;

    /// @notice Retrieves venue information by their wallet address.
    /// @param venueAddress Wallet address of the venue.
    /// @return name Name of the venue.
    /// @return bio Biography of the venue.
    /// @return wallet Wallet address of the venue.
    function getVenueInfoByAddress(address venueAddress) external view returns (string memory name, string memory bio, address wallet);
}
