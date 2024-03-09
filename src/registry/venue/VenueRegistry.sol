// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { VenueRegistryTypes } from "./types/VenueRegistryTypes.sol";
import { VenueRegistryStorage } from "./storage/VenueRegistryStorage.sol";
import { IVenueRegistry } from "./IVenueRegistry.sol";

import { ReferralModule } from "../referral/ReferralModule.sol";
import { ReferralTypes } from "../referral/types/ReferralTypes.sol";

import { ERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


/**
 * @title VenueRegistry
 * @dev Manages venue profiles using ERC1155 tokens and incorporates a referral system for venue registration.
 */
contract VenueRegistry is Initializable, ERC1155Upgradeable, IVenueRegistry, VenueRegistryStorage, UUPSUpgradeable, OwnableUpgradeable {
    ReferralModule private referralModule;

    /**
    * @dev Initializes the contract with a metadata URI and the ReferralModule address.
     * @param _referralModuleAddress Address of the ReferralModule contract.
     */
    function initialize(address initialOwner, address _referralModuleAddress) public initializer {
        __ERC1155_init("https://api.yourapp.com/metadata/{id}.json");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        referralModule = ReferralModule(_referralModuleAddress);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Registers a venue with the provided name and biography. Only callable internally.
     * @param _name Name of the venue.
     * @param _bio Biography of the venue.
     */
    function registerVenue(string memory _name, string memory _bio) internal {
        currentVenueId++;
        uint256 venueId = currentVenueId;
        address walletAddress = msg.sender;

        venues[venueId] = VenueRegistryTypes.VenueInfo(_name, _bio, walletAddress);
        addressToVenueId[walletAddress] = venueId;

        _mint(walletAddress, venueId, 1, "");
        emit VenueRegistered(venueId, _name);
    }

    /**
     * @notice Nominates another address as a venue, provided the caller has sufficient referral credits.
     * @param nominee The address being nominated as a venue.
     */
    function nominate(address nominee) public {
        ReferralTypes.ReferralCredits memory credits = referralModule.getReferralCredits(msg.sender);
        require(credits.venue > 0, "Insufficient venue referral credits");

        referralModule.decrementReferralCredits(msg.sender, 0, 0, 1);
        nominatedVenues[nominee] = true;
        emit VenueNominated(nominee);
    }

    /**
     * @notice Accepts the nomination to become a registered venue.
     */
    function acceptNomination() public {
        require(nominatedVenues[msg.sender], "No nomination found");
        nominatedVenues[msg.sender] = false; // Clear the nomination
        registerVenue("", ""); // Placeholder for venue's real name and biography
        emit VenueAccepted(currentVenueId, msg.sender);
    }

    /**
     * @notice Allows a registered venue to update their profile information.
     * @param _venueId Unique identifier of the venue.
     * @param _name New name of the venue.
     * @param _bio New biography of the venue.
     */
    function updateVenue(uint256 _venueId, string memory _name, string memory _bio) public {
        require(_venueId <= currentVenueId && venues[_venueId].wallet == msg.sender, "Unauthorized or non-existent venue");

        venues[_venueId].name = _name;
        venues[_venueId].bio = _bio;
        emit VenueUpdated(_venueId, _name, _bio);
    }

    /**
     * @notice Allows a venue to deregister themselves from the registry.
     * @param _venueId Unique identifier of the venue wishing to deregister.
     */
    function deregisterVenue(uint256 _venueId) public {
        require(_venueId <= currentVenueId && venues[_venueId].wallet == msg.sender, "Unauthorized or non-existent venue");

        _burn(msg.sender, _venueId, 1);
        delete venues[_venueId];
        emit VenueDeregistered(_venueId);
    }

    /**
     * @notice Retrieves information about a venue using their wallet address.
     * @param venueAddress Wallet address of the venue.
     * @return name Name of the venue.
     * @return bio Biography of the venue.
     * @return wallet Wallet address of the venue.
     */
    function getVenueInfoByAddress(address venueAddress) external view returns (string memory name, string memory bio, address wallet) {
        uint256 venueId = addressToVenueId[venueAddress];
        require(venueId != 0, "Venue does not exist");

        VenueRegistryTypes.VenueInfo memory venue = venues[venueId];
        return (venue.name, venue.bio, venue.wallet);
    }
}
