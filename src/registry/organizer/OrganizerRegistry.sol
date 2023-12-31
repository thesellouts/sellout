// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ReferralModule } from "../referral/ReferralModule.sol";
import { IOrganizerRegistry } from "./IOrganizerRegistry.sol";
import { OrganizerRegistryStorage } from "./storage/OrganizerRegistryStorage.sol";
import { OrganizerRegistryTypes } from "./types/OrganizerRegistryTypes.sol";

/// @title OrganizerRegistry
/// @notice Contract for managing venue profiles using ERC1155 tokens, with a referral system for registrations.
contract OrganizerRegistry is ERC1155, IOrganizerRegistry, OrganizerRegistryStorage {
    ReferralModule private referralModule;

    constructor(address _referralModuleAddress) ERC1155("https://api.yourapp.com/metadata/{id}.json") {
        referralModule = ReferralModule(_referralModuleAddress);
    }

    function registerOrganizer(string memory _name, string memory _bio) internal {
        currentOrganizerId++;
        uint256 organizerId = currentOrganizerId;
        address walletAddress = msg.sender;

        organizers[organizerId] = OrganizerRegistryTypes.OrganizerInfo(_name, _bio, walletAddress);
        addressToOrganizerId[walletAddress] = organizerId;

        _mint(walletAddress, organizerId, 1, "");
        emit OrganizerRegistered(organizerId, _name);
    }

    function waitlistOrganizer(address _organizer) internal {
        waitlistedOrganizers[_organizer] = true;
        emit OrganizerWaitlisted(_organizer);
    }

    function acceptOrganizer() public {
        require(waitlistedOrganizers[msg.sender], "You are not waitlisted");
        waitlistedOrganizers[msg.sender] = false;
        registerOrganizer("", ""); // Name and bio can be set later
        emit OrganizerAccepted(currentOrganizerId, msg.sender);
    }

    function waitlistForReferral() public {
        ReferralModule.ReferralCredits memory credits = referralModule.getReferralCredits(msg.sender);
        require(credits.organizer > 0, "Insufficient organizer referral credits");
        referralModule.decrementReferralCredits(msg.sender, 0, 1, 0);
        waitlistOrganizer(msg.sender); // Organizer is now waitlisted
    }

    function updateOrganizer(uint256 _organizerId, string memory _name, string memory _bio) public {
        require(_organizerId <= currentOrganizerId, "Organizer does not exist");
        OrganizerRegistryTypes.OrganizerInfo storage organizer = organizers[_organizerId];
        require(organizer.wallet == msg.sender, "Only the organizer can update their profile");
        organizer.name = _name;
        organizer.bio = _bio;
        emit OrganizerUpdated(_organizerId, _name, _bio);
    }

    function deregisterOrganizer(uint256 _organizerId) public {
        require(_organizerId <= currentOrganizerId, "Organizer does not exist");
        OrganizerRegistryTypes.OrganizerInfo storage organizer = organizers[_organizerId];
        require(organizer.wallet == msg.sender, "Only the organizer can deregister themselves");
        _burn(msg.sender, _organizerId, 1);
        delete organizers[_organizerId];
        emit OrganizerDeregistered(_organizerId);
    }

    /// @notice Retrieves organizer information by wallet address.
    /// @param organizerAddress Address of the organizer to retrieve info for.
    /// @return name Name of the organizer.
    /// @return bio Biography of the organizer.
    /// @return wallet Wallet address of the organizer.
    function getOrganizerInfoByAddress(address organizerAddress) external view returns (string memory name, string memory bio, address wallet) {
        uint256 organizerId = addressToOrganizerId[organizerAddress];
        require(organizerId != 0, "Organizer does not exist"); // Ensure the organizer is registered
        OrganizerRegistryTypes.OrganizerInfo storage organizer = organizers[organizerId];
        return (organizer.name, organizer.bio, organizer.wallet);
    }
}
