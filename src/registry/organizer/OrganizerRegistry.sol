// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IOrganizerRegistry } from "./IOrganizerRegistry.sol";
import { OrganizerRegistryStorage } from "./storage/OrganizerRegistryStorage.sol";
import { OrganizerRegistryTypes } from "./types/OrganizerRegistryTypes.sol";

import { ReferralModule } from "../referral/ReferralModule.sol";
import { ReferralTypes } from "../referral/types/ReferralTypes.sol";

import { ERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


// @title OrganizerRegistry
// @author taayyohh
// @notice Manages organizer profiles with ERC1155 tokens, incorporating a referral system.
contract OrganizerRegistry is Initializable, ERC1155Upgradeable, IOrganizerRegistry, OrganizerRegistryStorage, UUPSUpgradeable, OwnableUpgradeable {
    ReferralModule private referralModule;
    mapping(uint256 => string) private _tokenURIs;


    // @dev Initializes the contract with a metadata URI and the ReferralModule address.
     // @param _referralModuleAddress Address of the ReferralModule contract.
    function initialize(address initialOwner, address _referralModuleAddress) public initializer {
        __ERC1155_init("https://metadata.sellouts.app/organizer/{id}.json");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        referralModule = ReferralModule(_referralModuleAddress);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // Accept nomination for organizer status
    function acceptNomination(string memory _name, string memory _bio) public {
        require(nominatedOrganizers[msg.sender], "No nomination found");
        nominatedOrganizers[msg.sender] = false;
        registerOrganizer(_name, _bio);
        emit OrganizerAccepted(msg.sender);
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
    function getOrganizer(address organizerAddress) external view returns (string memory name, string memory bio, address wallet) {
        uint256 organizerId = addressToOrganizerId[organizerAddress];
        require(organizerId != 0, "Organizer does not exist");
        OrganizerRegistryTypes.OrganizerInfo storage organizer = organizers[organizerId];
        return (organizer.name, organizer.bio, organizer.wallet);
    }

    // Nominate another address for organizer status
    function nominate(address nominee) public {
        ReferralTypes.ReferralCredits memory credits = referralModule.getReferralCredits(msg.sender);
        require(credits.organizer > 0, "Insufficient organizer referral credits");

        referralModule.decrementReferralCredits(msg.sender, 0, 1, 0);
        nominatedOrganizers[nominee] = true;
        emit OrganizerNominated(nominee, msg.sender);
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

    /// @notice Sets the URI for a given token ID
    /// @param tokenId The token ID for which to set the URI
    /// @param newURI The new URI to set
    function setTokenURI(uint256 tokenId, string memory newURI) public {
        require(
            msg.sender == owner() || msg.sender == organizers[tokenId].wallet,
            "Caller is not the owner or the organizer"
        );

        _tokenURIs[tokenId] = newURI;
    }

    // Update organizer information
    function updateOrganizer(uint256 organizerId, string memory name, string memory bio, address wallet) public {
        require(organizerId <= currentOrganizerId && organizerId != 0, "Organizer does not exist");
        OrganizerRegistryTypes.OrganizerInfo storage organizer = organizers[organizerId];
        require(organizer.wallet == msg.sender, "Only the organizer can update their profile");

        organizer.name = name;
        organizer.bio = bio;
        organizer.wallet = wallet;
        emit OrganizerUpdated(organizerId, name, bio, wallet);
    }

    /// @notice Returns the URI for a specific token.
    /// @param tokenId The ID of the token.
    /// @return The URI of the token.
    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory customURI = _tokenURIs[tokenId];
        if (bytes(customURI).length > 0) {
            return customURI;
        }
        return super.uri(tokenId);
    }
}
