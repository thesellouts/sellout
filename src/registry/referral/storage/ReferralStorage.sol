// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ReferralTypes } from "../types/ReferralTypes.sol";

/// @title ReferralStorage
/// @notice Storage contract for ReferralModule.
contract ReferralStorage {
    /// @dev Mapping from an address to its ReferralCredits.
    mapping(address => ReferralTypes.ReferralCredits) internal referralCredits;

    /// @dev Mapping to keep track of addresses authorized to decrement credits.
    mapping(address => bool) public isCreditor;

    /// @dev Event emitted when referral credits are updated.
    event ReferralCreditsUpdated(address indexed referrer, ReferralTypes.ReferralCredits credits);

    /// @dev Event emitted when an address is given or revoked permission to update credits.
    event PermissionToUpdateCredits(address indexed contractAddress, bool permission);
}
