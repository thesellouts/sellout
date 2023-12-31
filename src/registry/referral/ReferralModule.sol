// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @title ReferralModule
 * @notice Provides functionality for managing and tracking referral credits in a contract.
 * @dev This contract only tracks referral credits, not actual referral codes. It assumes
 * that the contract integrating this module will handle the logic of assigning and validating
 * referrals, while this module will simply keep track of the credits earned through referrals.
 */
contract ReferralModule {
    /// @dev Struct to keep track of different types of referral credits.
    struct ReferralCredits {
        uint256 artist;
        uint256 organizer;
        uint256 venue;
    }

    /// @dev Mapping from address to their respective referral credits.
    mapping(address => ReferralCredits) private referralCredits;

    address private showContract;  // Authorized Show contract address
    address private selloutProtocolWallet;  // Authorized Sellout Protocol Wallet address

    /// @notice Event emitted when a referrer's referral credits are updated.
    event ReferralCreditsUpdated(address indexed referrer, ReferralCredits credits);

    /// @notice Ensures that only the authorized Show contract or Sellout Protocol Wallet can call certain functions.
    modifier onlyAuthorized() {
        require(msg.sender == showContract || msg.sender == selloutProtocolWallet, "Unauthorized");
        _;
    }

    /**
     * @notice Constructs the ReferralModule.
     * @param _showContract Address of the Show contract, authorized to manage referrals.
     * @param _selloutProtocolWallet Address of the Sellout Protocol Wallet, authorized to manage referrals.
     */
    constructor(address _showContract, address _selloutProtocolWallet) {
        showContract = _showContract;
        selloutProtocolWallet = _selloutProtocolWallet;
    }

    /**
     * @notice Increments referral credits for a given referrer.
     * @dev Can only be called by authorized contracts to ensure that credits are awarded properly.
     * @param referrer The address to assign the referral credits to.
     * @param artistCredits Number of artist referral credits to add.
     * @param organizerCredits Number of organizer referral credits to add.
     * @param venueCredits Number of venue referral credits to add.
     */
    function incrementReferralCredits(
        address referrer,
        uint256 artistCredits,
        uint256 organizerCredits,
        uint256 venueCredits
    ) public onlyAuthorized {
        referralCredits[referrer].artist += artistCredits;
        referralCredits[referrer].organizer += organizerCredits;
        referralCredits[referrer].venue += venueCredits;
        emit ReferralCreditsUpdated(referrer, referralCredits[referrer]);
    }

    /**
     * @notice Decrements referral credits for a given referrer.
     * @dev Can only be called by authorized contracts to ensure that credits are adjusted properly.
     * @param referrer The address to reduce the referral credits for.
     * @param artistCredits Number of artist referral credits to subtract.
     * @param organizerCredits Number of organizer referral credits to subtract.
     * @param venueCredits Number of venue referral credits to subtract.
     */
    function decrementReferralCredits(
        address referrer,
        uint256 artistCredits,
        uint256 organizerCredits,
        uint256 venueCredits
    ) public onlyAuthorized {
        ReferralCredits storage credits = referralCredits[referrer];
        require(credits.artist >= artistCredits, "Insufficient artist credits");
        require(credits.organizer >= organizerCredits, "Insufficient organizer credits");
        require(credits.venue >= venueCredits, "Insufficient venue credits");

        credits.artist -= artistCredits;
        credits.organizer -= organizerCredits;
        credits.venue -= venueCredits;

        emit ReferralCreditsUpdated(referrer, referralCredits[referrer]);
    }

    /**
     * @notice Retrieves the referral credits for a specific referrer.
     * @param referrer The address of the referrer.
     * @return The count of each type of referral credits the referrer has.
     */
    function getReferralCredits(address referrer) public view returns (ReferralCredits memory) {
        return referralCredits[referrer];
    }
}
