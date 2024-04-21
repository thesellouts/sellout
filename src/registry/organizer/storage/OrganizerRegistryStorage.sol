// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { OrganizerRegistryTypes } from "../types/OrganizerRegistryTypes.sol";

/// @title Organizer Registry Storage
/// @notice Provides storage management for organizer data in the OrganizerRegistry.
/// @dev This contract is responsible for storing organizer details and managing mappings related to organizer identities.
contract OrganizerRegistryStorage {
    using OrganizerRegistryTypes for OrganizerRegistryTypes.OrganizerInfo;

    /// @notice Maps organizer IDs to their corresponding OrganizerInfo data structures.
    /// @dev This mapping stores detailed information for each registered organizer.
    mapping(uint256 => OrganizerRegistryTypes.OrganizerInfo) internal organizers;

    /// @notice Maps wallet addresses to organizer IDs to quickly look up organizers by address.
    /// @dev Useful for validating whether a particular address corresponds to a registered organizer.
    mapping(address => uint256) internal addressToOrganizerId;

    /// @notice Tracks whether a given address has been nominated to become an organizer.
    /// @dev This mapping helps in managing the nomination process before actual registration.
    mapping(address => bool) public nominatedOrganizers;

    /// @notice Counter to keep track of the current number of organizers and to generate unique organizer IDs.
    /// @dev Incremented each time a new organizer is registered to ensure uniqueness of organizer IDs.
    uint256 internal currentOrganizerId;
}
