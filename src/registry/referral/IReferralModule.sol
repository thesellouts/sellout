// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Referral Module Interface
/// @dev Defines the interface for the ReferralModule, responsible for managing referral credits within the platform.
interface IReferralModule {
    /// @notice Emitted when referral credits for a referrer are updated.
    /// @param referrer Address of the referrer whose credits were updated.
    /// @param credits Struct containing the updated referral credits across different categories.
    event ReferralCreditsUpdated(address indexed referrer, ReferralCredits credits);

    /// @notice Emitted when a contract is granted or revoked permission to update referral credits.
    /// @param contractAddress Address of the contract whose permission was updated.
    /// @param permission Boolean indicating whether the permission was granted (`true`) or revoked (`false`).
    event PermissionToUpdateCredits(address indexed contractAddress, bool permission);

    /// @dev Struct to encapsulate referral credits across various categories.
    struct ReferralCredits {
        uint256 artist;     ///< Credits related to artist referrals.
        uint256 organizer;  ///< Credits related to organizer referrals.
        uint256 venue;      ///< Credits related to venue referrals.
    }

    /// @notice Grants or revokes permission for a contract to adjust referral credits.
    /// @dev Only callable by the contract owner or an authorized admin.
    /// @param contractAddress Address of the contract to update permissions for.
    /// @param permission `true` to grant permission, `false` to revoke.
    function setCreditControlPermission(address contractAddress, bool permission) external;

    /// @notice Increments the referral credits for a given referrer.
    /// @dev Typically called when a referred transaction successfully completes.
    /// @param referrer Address of the referrer to receive more credits.
    /// @param artistCredits Number of credits to add to the artist category.
    /// @param organizerCredits Number of credits to add to the organizer category.
    /// @param venueCredits Number of credits to add to the venue category.
    function incrementReferralCredits(address referrer, uint256 artistCredits, uint256 organizerCredits, uint256 venueCredits) external;

    /// @notice Decrements the referral credits for a given referrer.
    /// @dev Used to reduce credits when they are redeemed or if a referred transaction is reversed or invalidated.
    /// @param referrer Address of the referrer whose credits are to be reduced.
    /// @param artistCredits Number of artist credits to decrement.
    /// @param organizerCredits Number of organizer credits to decrement.
    /// @param venueCredits Number of venue credits to decrement.
    function decrementReferralCredits(address referrer, uint256 artistCredits, uint256 organizerCredits, uint256 venueCredits) external;

    /// @notice Retrieves the current referral credits for a specified referrer.
    /// @dev Can be used to display credit balances or determine eligibility for benefits.
    /// @param referrer Address for which to retrieve referral credits.
    /// @return ReferralCredits Struct containing the counts of credits for each category.
    function getReferralCredits(address referrer) external view returns (ReferralCredits memory);
}
