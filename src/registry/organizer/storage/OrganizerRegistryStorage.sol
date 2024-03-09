// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { OrganizerRegistryTypes } from "../types/OrganizerRegistryTypes.sol";

/// @title OrganizerRegistryStorage
/// @notice Storage contract for OrganizerRegistry.
contract OrganizerRegistryStorage {
    using OrganizerRegistryTypes for OrganizerRegistryTypes.OrganizerInfo;

    mapping(uint256 => OrganizerRegistryTypes.OrganizerInfo) internal organizers;
    mapping(address => uint256) internal addressToOrganizerId; // Mapping to track organizer IDs by address
    mapping(address => bool) public nominatedOrganizers;
    uint256 internal currentOrganizerId;
}
