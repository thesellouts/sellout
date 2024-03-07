// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IOrganizerRegistry.sol"; // Adjust the path as necessary
import "./storage/OrganizerRegistryStorage.sol"; // Adjust the path as necessary
import "./types/OrganizerRegistryTypes.sol";
import "../referral/ReferralModule.sol"; // Adjust the path as necessary

contract OrganizerRegistry is ERC1155, IOrganizerRegistry, OrganizerRegistryStorage {
    ReferralModule private referralModule;

    constructor(address _referralModuleAddress) ERC1155("https://api.yourapp.com/metadata/{id}.json") {
        referralModule = ReferralModule(_referralModuleAddress);
    }

    // Register an organizer
    function registerOrganizer(string memory name, string memory bio) internal {
        currentOrganizerId++;
        uint256 organizerId = currentOrganizerId;
        address walletAddress = msg.sender;

        organizers[organizerId] = OrganizerRegistryTypes.OrganizerInfo(name, bio, walletAddress);
        addressToOrganizerId[walletAddress] = organizerId;

        _mint(walletAddress, organizerId, 1, "");
        emit OrganizerRegistered(organizerId, name, walletAddress);
    }

    // Nominate another address for organizer status
    function nominate(address nominee) public {
        ReferralModule.ReferralCredits memory credits = referralModule.getReferralCredits(msg.sender);
        require(credits.organizer > 0, "Insufficient organizer referral credits");

        referralModule.decrementReferralCredits(msg.sender, 0, 1, 0);
        nominatedOrganizers[nominee] = true;
        emit OrganizerNominated(nominee, msg.sender);
    }

    // Accept nomination for organizer status
    function acceptNomination() public {
        require(nominatedOrganizers[msg.sender], "No nomination found");
        nominatedOrganizers[msg.sender] = false;
        registerOrganizer("", "");
        emit OrganizerAccepted(msg.sender);
    }

    // Update organizer information
    function updateOrganizer(uint256 organizerId, string memory name, string memory bio) public {
        require(organizerId <= currentOrganizerId && organizerId != 0, "Organizer does not exist");
        OrganizerRegistryTypes.OrganizerInfo storage organizer = organizers[organizerId];
        require(organizer.wallet == msg.sender, "Only the organizer can update their profile");

        organizer.name = name;
        organizer.bio = bio;
        emit OrganizerUpdated(organizerId, name, bio);
    }

    // Deregister an organizer
    function deregisterOrganizer(uint256 organizerId) public {
        require(organizerId <= currentOrganizerId && organizerId != 0, "Organizer does not exist");
        OrganizerRegistryTypes.OrganizerInfo storage organizer = organizers[organizerId];
        require(organizer.wallet == msg.sender, "Only the organizer can deregister themselves");

        _burn(msg.sender, organizerId, 1);
        delete organizers[organizerId];
        emit OrganizerDeregistered(organizerId);
    }

    // Retrieve organizer information by wallet address
    function getOrganizerInfoByAddress(address organizerAddress) external view returns (string memory name, string memory bio, address wallet) {
        uint256 organizerId = addressToOrganizerId[organizerAddress];
        require(organizerId != 0, "Organizer does not exist");
        OrganizerRegistryTypes.OrganizerInfo storage organizer = organizers[organizerId];
        return (organizer.name, organizer.bio, organizer.wallet);
    }
}
