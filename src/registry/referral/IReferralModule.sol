// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title IReferralModule
 * @dev Interface for the ReferralModule contract.
 */
interface IReferralModule {
    /**
     * @dev Emitted when referral credits are updated for a referrer.
     * @param referrer Address of the referrer whose credits were updated.
     * @param credits Updated referral credits.
     */
    event ReferralCreditsUpdated(address indexed referrer, ReferralCredits credits);

    /**
     * @dev Emitted when permission to update credits is granted or revoked for a contract address.
     * @param contractAddress Address of the contract.
     * @param permission True if permission is granted, false if revoked.
     */
    event PermissionToUpdateCredits(address indexed contractAddress, bool permission);

    /**
     * @dev Struct to hold referral credits.
     */
    struct ReferralCredits {
        uint256 artist;
        uint256 organizer;
        uint256 venue;
    }

    /**
     * @dev Sets or revokes permission for an address to decrement referral credits.
     * @param contractAddress The address to update permission for.
     * @param permission True to allow, false to revoke.
     */
    function setCreditControlPermission(address contractAddress, bool permission) external;

    /**
     * @dev Increments referral credits for a given referrer.
     * @param referrer The address of the referrer whose credits are to be incremented.
     * @param artistCredits Number of artist credits to add.
     * @param organizerCredits Number of organizer credits to add.
     * @param venueCredits Number of venue credits to add.
     */
    function incrementReferralCredits(address referrer, uint256 artistCredits, uint256 organizerCredits, uint256 venueCredits) external;

    /**
     * @dev Decrements referral credits for a given referrer.
     * @param referrer The address of the referrer whose credits are to be decremented.
     * @param artistCredits Number of artist credits to remove.
     * @param organizerCredits Number of organizer credits to remove.
     * @param venueCredits Number of venue credits to remove.
     */
    function decrementReferralCredits(address referrer, uint256 artistCredits, uint256 organizerCredits, uint256 venueCredits) external;

    /**
     * @dev Retrieves the referral credits for a specified address.
     * @param referrer The address to retrieve referral credits for.
     * @return The referral credits of the specified address.
     */
    function getReferralCredits(address referrer) external view returns (ReferralCredits memory);
}
