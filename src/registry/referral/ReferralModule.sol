// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ReferralStorage } from "./storage/ReferralStorage.sol";
import { ReferralTypes } from "./types/ReferralTypes.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/*

    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@, ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@                         @@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@               .@@@                @@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      (@@@@@@@@@@@@@
    @@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@
    @@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@
    @@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@
    @@@@@@@@@     ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@
    @@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@
    @@@@@@@@     @@@@@@@@@@@@@@@/ @@@@@@@@@@@@@@@@@@@@@ #@@@@@@@@@@@@@@@     @@@@@@@
    @@@@@@@@     @@@@@@@@@@            @@@@@@@@@@@            @@@@@@@@@@     @@@@@@@
    @@@@@@@@     @@@@@@@@        @       @@@@@@@       @        @@@@@@@@     @@@@@@@
    @@@@@@@@     @@@@@@@@     @@@@@@@     @@@@@     @@@@@@@     @@@@@@@@     @@@@@@@
    @@@@@@@@@     @@@@@@@     @@@@@@@     @@@@@     @@@@@@@     @@@@@@@     @@@@@@@@
    @@@@@@@@@     .@@@@@@                @@@@@@@                @@@@@@      @@@@@@@@
    @@@@@@@@@@      @@@@@@@            @@@@@@@@@@@            @@@@@@@      @@@@@@@@@
    @@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@
    @@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@
    @@@@@@@@@@@@@@(      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      &@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@       @@@@@@@@@@@ @@@@@@@@@ @@@@@@@@@@@       @@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@         @@@@@     @@@@@     @@@@@        .@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@     @@@@@     @@@@@     @@@@@     @@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@     @@@@@     @@@@@     @@@@@     @@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@                                 @@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


    @title ReferralModule
    @author taayyohh
    @dev This contract manages referral credits within a decentralized protocol, supporting upgradeability.
*/

contract ReferralModule is Initializable, ReferralStorage, OwnableUpgradeable, UUPSUpgradeable  {
    // @dev Modifier to allow only authorized addresses to execute a function.
    modifier onlyAuthorized() {
        require(isCreditor[msg.sender], "Unauthorized");
        _;
    }

    // @dev Initializes the contract by setting the initial owner and preparing it for upgradeability.
    // @param initialOwner Address to be set as the initial owner.
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    // @dev Ensures only the owner can authorize contract upgrades.
    // @param newImplementation Address of the new contract implementation.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // @dev Sets or revokes permission for an address to decrement referral credits.
    // @param contractAddress The address to update permission for.
    // @param permission True to allow, false to revoke.
    function setCreditControlPermission(address contractAddress, bool permission) public onlyOwner {
        isCreditor[contractAddress] = permission;
        emit PermissionToUpdateCredits(contractAddress, permission);
    }

    // @dev Increments referral credits for a given referrer.
    // @param referrer The address of the referrer whose credits are to be incremented.
    // @param artistCredits Number of artist credits to add.
    // @param organizerCredits Number of organizer credits to add.
    // @param venueCredits Number of venue credits to add.
    function incrementReferralCredits(address referrer, uint256 artistCredits, uint256 organizerCredits, uint256 venueCredits) public onlyAuthorized {
        ReferralTypes.ReferralCredits storage credits = referralCredits[referrer];
        credits.artist += artistCredits;
        credits.organizer += organizerCredits;
        credits.venue += venueCredits;
        emit ReferralCreditsUpdated(referrer, credits);
    }

    // @dev Decrements referral credits for a given referrer.
    // @param referrer The address of the referrer whose credits are to be decremented.
    // @param artistCredits Number of artist credits to remove.
    // @param organizerCredits Number of organizer credits to remove.
    // @param venueCredits Number of venue credits to remove.
    function decrementReferralCredits(address referrer, uint256 artistCredits, uint256 organizerCredits, uint256 venueCredits) public onlyAuthorized {
        ReferralTypes.ReferralCredits storage credits = referralCredits[referrer];
        require(credits.artist >= artistCredits && credits.organizer >= organizerCredits && credits.venue >= venueCredits, "Insufficient credits");
        credits.artist -= artistCredits;
        credits.organizer -= organizerCredits;
        credits.venue -= venueCredits;
        emit ReferralCreditsUpdated(referrer, credits);
    }

    // @dev Retrieves the referral credits for a specified address.
    // @param referrer The address to retrieve referral credits for.
    // @return The referral credits of the specified address.
    function getReferralCredits(address referrer) public view returns (ReferralTypes.ReferralCredits memory) {
        return referralCredits[referrer];
    }
}
