// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { VenueRegistryTypes } from "../types/VenueRegistryTypes.sol";

/// @title Venue Registry Storage
/// @notice Handles the underlying data storage for the Venue Registry, providing a stable structure for venue information.
/// @dev This contract uses the VenueRegistryTypes library to define and manage venue data.
contract VenueRegistryStorage {
    using VenueRegistryTypes for VenueRegistryTypes.VenueInfo;

    /// @notice Mapping of venue ID to VenueInfo structures.
    /// @dev Stores detailed information for each registered venue using a unique identifier.
    mapping(uint256 => VenueRegistryTypes.VenueInfo) internal venues;

    /// @notice Mapping from Ethereum address to venue ID.
    /// @dev Helps to quickly lookup the venue ID associated with a specific Ethereum address, facilitating reverse lookups.
    mapping(address => uint256) internal addressToVenueId;

    /// @notice Tracks which addresses have been nominated as venues.
    /// @dev Useful for validation before venue registration to ensure only nominated venues can register.
    mapping(address => bool) public nominatedVenues;

    /// @notice Internal counter to track the next available venue ID.
    /// @dev Incremented each time a new venue is registered to ensure each venue has a unique ID.
    uint256 internal currentVenueId;
}
