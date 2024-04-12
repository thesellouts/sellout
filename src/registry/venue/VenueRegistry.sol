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

    mapping(uint256 => string) private _tokenURIs;

    // @notice Initializes the contract with a metadata URI and the ReferralModule address.
    // @param _referralModuleAddress Address of the ReferralModule contract.
    function initialize(address initialOwner, address _referralModuleAddress) public initializer {
        __ERC1155_init("https://metadata.sellouts.app/venue/{id}.json");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        referralModule = ReferralModule(_referralModuleAddress);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


    /// @notice Accepts the nomination to become a registered venue.
    /// @param _name Name of the nominated Venue.
    /// @param _bio Bio of the nominated Venue.
    /// @param _latitude Latitude part of the venue's coordinates.
    /// @param _longitude Longitude part of the venue's coordinates.
    /// @param _totalCapacity Total capacity of the venue.
    /// @param _streetAddress Street address of the venue.
    function acceptNomination(
        string memory _name,
        string memory _bio,
        int256 _latitude,
        int256 _longitude,
        uint256 _totalCapacity,
        string memory _streetAddress
    ) public {
        require(nominatedVenues[msg.sender], "No nomination found");
        nominatedVenues[msg.sender] = false;

        registerVenue(_name, _bio, _latitude, _longitude, _totalCapacity, _streetAddress);

        emit VenueAccepted(currentVenueId, msg.sender);
    }

    ///  @dev Registers a venue with the provided details. Only callable internally.
    ///  @param _name Name of the venue.
    ///  @param _bio Biography of the venue.
    ///  @param _latitude Latitude part of the venue's coordinates.
    ///  @param _longitude Longitude part of the venue's coordinates.
    ///  @param _streetAddress Street address of the venue.
    function registerVenue(
        string memory _name,
        string memory _bio,
        int256 _latitude,
        int256 _longitude,
        uint256 _totalCapacity,
        string memory _streetAddress
    ) internal {
        currentVenueId++;
        uint256 venueId = currentVenueId;
        address walletAddress = msg.sender;

        VenueRegistryTypes.Coordinates memory coords = VenueRegistryTypes.Coordinates({
            latitude: _latitude,
            longitude: _longitude
        });

        venues[venueId] = VenueRegistryTypes.VenueInfo({
            name: _name,
            bio: _bio,
            wallet: walletAddress,
            coordinates: coords,
            totalCapacity: _totalCapacity,
            streetAddress: _streetAddress
        });

        addressToVenueId[walletAddress] = venueId;

        _mint(walletAddress, venueId, 1, "");
        emit VenueRegistered(venueId, _name);
    }

    /// @notice Allows a venue to deregister themselves from the registry.
    /// @param _venueId Unique identifier of the venue wishing to deregister.
    function deregisterVenue(uint256 _venueId) public {
        require(_venueId <= currentVenueId && venues[_venueId].wallet == msg.sender, "Unauthorized or non-existent venue");

        _burn(msg.sender, _venueId, 1);
        delete venues[_venueId];
        emit VenueDeregistered(_venueId);
    }

    /// @notice Retrieves information about a venue using their wallet address.
    /// @param venueAddress Wallet address of the venue.
    /// @return name Name of the venue.
    /// @return bio Biography of the venue.
    /// @return wallet Wallet address of the venue.
    /// @return latitude Latitude part of the venue's coordinates.
    /// @return longitude Longitude part of the venue's coordinates.
    /// @return totalCapacity Total capacity of the venue.
    /// @return streetAddress Street address of the venue.
    function getVenue(address venueAddress) external view returns (
        string memory name,
        string memory bio,
        address wallet,
        int256 latitude,
        int256 longitude,
        uint256 totalCapacity,
        string memory streetAddress
    ) {
        uint256 venueId = addressToVenueId[venueAddress];
        require(venueId != 0, "Venue does not exist");

        VenueRegistryTypes.VenueInfo memory venue = venues[venueId];
        return (
            venue.name,
            venue.bio,
            venue.wallet,
            venue.coordinates.latitude,
            venue.coordinates.longitude,
            venue.totalCapacity,
            venue.streetAddress
        );
    }

    /// @notice Nominates another address as a venue, provided the caller has sufficient referral credits.
    /// @param nominee The address being nominated as a venue.
    function nominate(address nominee) public {
        ReferralTypes.ReferralCredits memory credits = referralModule.getReferralCredits(msg.sender);
        require(credits.venue > 0, "Insufficient venue referral credits");

        referralModule.decrementReferralCredits(msg.sender, 0, 0, 1);
        nominatedVenues[nominee] = true;
        emit VenueNominated(nominee);
    }

    /// @notice Sets the URI for a given token ID
    /// @param tokenId The token ID for which to set the URI
    /// @param newURI The new URI to set
    function setTokenURI(uint256 tokenId, string memory newURI) public {
        require(
            msg.sender == owner() || msg.sender == venues[tokenId].wallet,
            "Caller is not the owner or the organizer"
        );

        _tokenURIs[tokenId] = newURI;
    }


    /// @notice Allows a registered venue to update their profile information.
    /// @param _venueId Unique identifier of the venue.
    /// @param _name New name of the venue.
    /// @param _bio New biography of the venue.
    /// @param _wallet New wallet address of the venue.
    /// @param _latitude New latitude for the venue's location.
    /// @param _longitude New longitude for the venue's location.
    /// @param _totalCapacity New total capacity of the venue.
    /// @param _streetAddress New street address of the venue.
    function updateVenue(
        uint256 _venueId,
        string memory _name,
        string memory _bio,
        address _wallet,
        int256 _latitude,
        int256 _longitude,
        uint256 _totalCapacity,
        string memory _streetAddress
    ) public {
        require(_venueId <= currentVenueId && venues[_venueId].wallet == msg.sender, "Unauthorized or non-existent venue");

        VenueRegistryTypes.VenueInfo storage venue = venues[_venueId];
        venue.name = _name;
        venue.bio = _bio;
        venue.wallet = _wallet;
        venue.coordinates.latitude = _latitude;
        venue.coordinates.longitude = _longitude;
        venue.totalCapacity = _totalCapacity;
        venue.streetAddress = _streetAddress;

        // Emit the updated event with all parameters
        emit VenueUpdated(
            _venueId,
            _name,
            _bio,
            _wallet,
            _latitude,
            _longitude,
            _totalCapacity,
            _streetAddress
        );
    }

    /// @notice Checks if a venue is registered in the registry.
    /// @param venueAddress Address of the venue to check.
    /// @return isRegistered True if the venue is registered, false otherwise.
    function isVenueRegistered(address venueAddress) public view returns (bool isRegistered) {
        uint256 venueId = addressToVenueId[venueAddress];
        isRegistered = venueId != 0 && venues[venueId].wallet == venueAddress;
        return isRegistered;
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
