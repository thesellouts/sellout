// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @title ReferralModule
 * @dev Manages referral credits for artists, organizers, and venues within a decentralized protocol.
 */
contract ReferralModule {
    /**
     * @dev Stores the number of referral credits for artists, organizers, and venues.
     */
    struct ReferralCredits {
        uint256 artist;
        uint256 organizer;
        uint256 venue;
    }

    /// @dev Maps addresses to their respective referral credits.
    mapping(address => ReferralCredits) private referralCredits;

    /// @notice Authorized address to manage show-related functionalities.
    address public showContract;

    /// @notice Authorized address to manage sellout protocol wallet-related functionalities.
    address public selloutProtocolWallet;

    /// @dev Maps addresses to their permission to decrement referral credits.
    mapping(address => bool) public canDecrementCredits;

    /// @notice Emitted when referral credits are updated.
    event ReferralCreditsUpdated(address indexed referrer, ReferralCredits credits);

    /// @notice Emitted when permission to decrement credits is updated.
    event PermissionToUpdateCredits(address indexed contractAddress, bool permission);

    /**
     * @notice Initializes the contract with show contract and sellout protocol wallet addresses.
     * @param _showContract The address of the Show contract.
     * @param _selloutProtocolWallet The address of the Sellout Protocol Wallet.
     */
    constructor(address _showContract, address _selloutProtocolWallet) {
        require(_showContract != address(0) && _selloutProtocolWallet != address(0), "Invalid address");
        showContract = _showContract;
        selloutProtocolWallet = _selloutProtocolWallet;
    }

    /**
     * @notice Sets the permission for a contract to decrement referral credits.
     * @param contractAddress The address of the contract.
     * @param permission True if the contract is allowed to decrement credits, false otherwise.
     */
    function setDecrementPermission(address contractAddress, bool permission) public {
        require(msg.sender == selloutProtocolWallet, "Only the sellout protocol wallet can set permissions");
        canDecrementCredits[contractAddress] = permission;
        emit PermissionToUpdateCredits(contractAddress, permission);
    }

    modifier onlyAuthorized() {
        require(msg.sender == showContract || msg.sender == selloutProtocolWallet || canDecrementCredits[msg.sender], "Unauthorized");
        _;
    }

    /**
     * @notice Increments referral credits for a specific referrer.
     * @dev Only authorized addresses can call this function.
     * @param referrer The address of the referrer.
     * @param artistCredits The number of artist credits to add.
     * @param organizerCredits The number of organizer credits to add.
     * @param venueCredits The number of venue credits to add.
     */
    function incrementReferralCredits(address referrer, uint256 artistCredits, uint256 organizerCredits, uint256 venueCredits) public onlyAuthorized {
        ReferralCredits storage credits = referralCredits[referrer];
        credits.artist += artistCredits;
        credits.organizer += organizerCredits;
        credits.venue += venueCredits;
        emit ReferralCreditsUpdated(referrer, credits);
    }

    /**
     * @notice Decrements referral credits for a specific referrer.
     * @dev Only authorized addresses or those with permission can call this function.
     * @param referrer The address of the referrer.
     * @param artistCredits The number of artist credits to subtract.
     * @param organizerCredits The number of organizer credits to subtract.
     * @param venueCredits The number of venue credits to subtract.
     */
    function decrementReferralCredits(address referrer, uint256 artistCredits, uint256 organizerCredits, uint256 venueCredits) public onlyAuthorized {
        ReferralCredits storage credits = referralCredits[referrer];
        require(credits.artist >= artistCredits, "Insufficient artist credits");
        require(credits.organizer >= organizerCredits, "Insufficient organizer credits");
        require(credits.venue >= venueCredits, "Insufficient venue credits");

        credits.artist -= artistCredits;
        credits.organizer -= organizerCredits;
        credits.venue -= venueCredits;

        emit ReferralCreditsUpdated(referrer, credits);
    }

    /**
     * @notice Retrieves the referral credits for a specific referrer.
     * @param referrer The address of the referrer.
     * @return The referral credits for the referrer.
     */
    function getReferralCredits(address referrer) public view returns (ReferralCredits memory) {
        return referralCredits[referrer];
    }
}
