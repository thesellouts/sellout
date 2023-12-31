// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../types/VenueRegistryTypes.sol";

/// @title VenueRegistryStorage
/// @notice Storage contract for VenueRegistry.
contract VenueRegistryStorage {
    using VenueRegistryTypes for VenueRegistryTypes.VenueInfo;
    mapping(uint256 => VenueRegistryTypes.VenueInfo) internal venues;
    mapping(address => uint256) internal addressToVenueId; // Mapping to track venue IDs by address
    mapping(address => bool) public waitlistedVenues;
    uint256 internal currentVenueId;

}

