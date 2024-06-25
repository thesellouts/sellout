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


    @title OrganizerRegistry
    @author taayyohh
    @dev Manages organizer profiles and their ERC1155 representations, facilitating the use of a referral system.
*/

contract OrganizerRegistry is Initializable, ERC1155Upgradeable, IOrganizerRegistry, OrganizerRegistryStorage, UUPSUpgradeable, OwnableUpgradeable {
    ReferralModule private referralModule;

    /// @dev Mapping from token IDs to their respective metadata URIs.
    mapping(uint256 => string) private _tokenURIs;

    string private contractMetadataURI;

    /// @notice Initializes the contract with metadata URI and ReferralModule address.
    /// @param initialOwner The address to be set as the owner of the contract.
    /// @param _referralModuleAddress Address of the ReferralModule to interact with referral functionalities.
    function initialize(address initialOwner, address _referralModuleAddress) public initializer {
        __ERC1155_init("https://metadata.sellouts.app/organizer/{id}.json");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        referralModule = ReferralModule(_referralModuleAddress);
    }

    /// @notice Ensures only the contract owner can perform the upgrade.
    /// @param newImplementation The address of the new contract implementation.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Accepts a nomination for organizer status.
    /// @dev Requires the sender to be nominated before accepting.
    function acceptNomination(string memory _name, string memory _bio) public {
        require(nominatedOrganizers[msg.sender], "No nomination found");
        nominatedOrganizers[msg.sender] = false;
        registerOrganizer(_name, _bio);
        emit OrganizerAccepted(msg.sender);
    }

    /// @notice Deregisters an organizer, burning their token and removing their registration.
    /// @param organizerId The ID of the organizer to deregister.
    function deregisterOrganizer(uint256 organizerId) public {
        require(organizerId <= currentOrganizerId && organizerId != 0, "Organizer does not exist");
        OrganizerRegistryTypes.OrganizerInfo storage organizer = organizers[organizerId];
        require(organizer.wallet == msg.sender, "Only the organizer can deregister themselves");

        _burn(msg.sender, organizerId, 1);
        delete organizers[organizerId];
        emit OrganizerDeregistered(organizerId);
    }

    /// @notice Retrieves organizer information by wallet address.
    /// @param organizerAddress The wallet address of the organizer.
    /// @return name The name of the organizer.
    /// @return bio The biography or description of the organizer.
    /// @return wallet The wallet address associated with the organizer.
    function getOrganizer(address organizerAddress) external view returns (string memory name, string memory bio, address wallet) {
        uint256 organizerId = addressToOrganizerId[organizerAddress];
        require(organizerId != 0, "Organizer does not exist");
        OrganizerRegistryTypes.OrganizerInfo storage organizer = organizers[organizerId];
        return (organizer.name, organizer.bio, organizer.wallet);
    }

    /// @notice Nominates an address for organizer status using a referral credit.
    /// @param nominee The address being nominated.
    function nominate(address nominee) public {
        require(!nominatedOrganizers[nominee], "Nominee already nominated");
        require(addressToOrganizerId[nominee] == 0, "Nominee already an organizer");

        ReferralTypes.ReferralCredits memory credits = referralModule.getReferralCredits(msg.sender);
        require(credits.organizer > 0, "Insufficient organizer referral credits");

        referralModule.decrementReferralCredits(msg.sender, 0, 1, 0);
        nominatedOrganizers[nominee] = true;
        emit OrganizerNominated(nominee, msg.sender);
    }

    /// @dev Registers a new organizer internally.
    /// @param name Name of the organizer.
    /// @param bio Biography or description of the organizer.
    function registerOrganizer(string memory name, string memory bio) internal {
        currentOrganizerId++;
        uint256 organizerId = currentOrganizerId;
        address walletAddress = msg.sender;

        organizers[organizerId] = OrganizerRegistryTypes.OrganizerInfo(name, bio, walletAddress);
        addressToOrganizerId[walletAddress] = organizerId;

        _mint(walletAddress, organizerId, 1, "");
        emit OrganizerRegistered(organizerId, name, walletAddress);
    }

    /// @notice Sets the URI for a specific token.
    /// @param tokenId The token ID for which to set the URI.
    /// @param newURI The new URI string to be set.
    function setTokenURI(uint256 tokenId, string memory newURI) public {
        require(
            msg.sender == owner() || msg.sender == organizers[tokenId].wallet,
            "Caller is not the owner or the organizer"
        );

        _tokenURIs[tokenId] = newURI;
    }

    /// @notice Sets or updates the URI for a specific artist token.
    /// @param newURI The new metadata URI.
    function setContractURI(string memory newURI) public {
        require(
            msg.sender == owner(),
            "Caller is not the owner"
        );
        contractMetadataURI = newURI;
        emit contractURIUpdated(newURI);
    }

    /// @notice Updates the profile information of an organizer.
    /// @param organizerId The ID of the organizer to update.
    /// @param name New name for the organizer.
    /// @param bio New biography or description.
    /// @param wallet New wallet address for the organizer.
    function updateOrganizer(uint256 organizerId, string memory name, string memory bio, address wallet) public {
        require(organizerId <= currentOrganizerId && organizerId != 0, "Organizer does not exist");
        OrganizerRegistryTypes.OrganizerInfo storage organizer = organizers[organizerId];
        require(organizer.wallet == msg.sender, "Only the organizer can update their profile");

        organizer.name = name;
        organizer.bio = bio;
        organizer.wallet = wallet;
        emit OrganizerUpdated(organizerId, name, bio, wallet);
    }

    /// @notice Checks if an address is a registered organizer.
    /// @param organizer The address to check.
    /// @return bool True if the address is a registered organizer, false otherwise.
    function isOrganizerRegistered(address organizer) public view returns (bool) {
        uint256 organizerId = addressToOrganizerId[organizer];
        // Ensuring that the organizer ID is valid and the stored wallet matches the queried address
        bool isRegistered = organizerId != 0 && organizers[organizerId].wallet == organizer;
        return isRegistered;
    }


    /// @notice Retrieves the URI associated with a specific token.
    /// @param tokenId The ID of the token.
    /// @return The URI string associated with the token.
    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory customURI = _tokenURIs[tokenId];
        if (bytes(customURI).length > 0) {
            return customURI;
        }
        return super.uri(tokenId);
    }
}
