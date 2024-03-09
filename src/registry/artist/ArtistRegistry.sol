// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ArtistRegistryTypes } from "./types/ArtistRegistryTypes.sol";
import { ArtistRegistryStorage } from "./storage/ArtistRegistryStorage.sol";
import { IArtistRegistry } from "./IArtistRegistry.sol";

import { ReferralModule } from "../referral/ReferralModule.sol";
import { ReferralTypes } from "../referral/types/ReferralTypes.sol";

import { ERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title ArtistRegistry
 * @dev Manages artist profiles with ERC1155 tokens, incorporating a referral system.
 */
contract ArtistRegistry is Initializable, ERC1155Upgradeable, IArtistRegistry, ArtistRegistryStorage, UUPSUpgradeable, OwnableUpgradeable {
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
     * @dev Registers a new artist with provided name and biography.
     * @param _name Name of the artist.
     * @param _bio Biography of the artist.
     */
    function registerArtist(string memory _name, string memory _bio) internal {
        currentArtistId++;
        uint256 artistId = currentArtistId;
        address walletAddress = msg.sender;

        artists[artistId] = ArtistRegistryTypes.ArtistInfo(_name, _bio, walletAddress);
        addressToArtistId[walletAddress] = artistId;

        _mint(walletAddress, artistId, 1, "");
        emit ArtistRegistered(artistId, _name);
    }

    /**
     * @dev Waitlists an artist for registration.
     * @param _artist Address of the artist to be waitlisted.
     */
    function nominateArtist(address _artist) internal {
        nominatedArtists[_artist] = true;
        emit ArtistNominated(_artist);
    }

    /**
     * @notice Allows an artist to accept their nomination and complete the registration.
     */
    function acceptNomination() public {
        require(nominatedArtists[msg.sender], "Not waitlisted");
        nominatedArtists[msg.sender] = false;
        registerArtist("", ""); // Placeholder for actual name and bio
        emit ArtistAccepted(currentArtistId, msg.sender);
    }

    /**
     * @notice Nominate an artist for registration using a referral credit.
     * @param nominee Address of the artist being nominated.
     */
    function nominate(address nominee) public {
        ReferralTypes.ReferralCredits memory credits = referralModule.getReferralCredits(msg.sender);
        require(credits.artist > 0, "Insufficient artist referral credits");

        referralModule.decrementReferralCredits(msg.sender, 1, 0, 0);
        nominateArtist(nominee);
    }

    /**
     * @notice Updates an artist's profile information.
     * @param _artistId ID of the artist being updated.
     * @param _name New name of the artist.
     * @param _bio New biography of the artist.
     */
    function updateArtist(uint256 _artistId, string memory _name, string memory _bio) public {
        require(_artistId <= currentArtistId && artists[_artistId].wallet == msg.sender, "Unauthorized");

        artists[_artistId].name = _name;
        artists[_artistId].bio = _bio;

        emit ArtistUpdated(_artistId, _name, _bio);
    }

    /**
     * @notice Allows an artist to deregister themselves.
     * @param _artistId ID of the artist being deregistered.
     */
    function deregisterArtist(uint256 _artistId) public {
        require(_artistId <= currentArtistId && artists[_artistId].wallet == msg.sender, "Unauthorized");

        _burn(msg.sender, _artistId, 1);
        delete artists[_artistId];

        emit ArtistDeregistered(_artistId);
    }

    /**
     * @notice Retrieves information about an artist by their wallet address.
     * @param artistAddress Wallet address of the artist.
     * @return name Name of the artist.
     * @return bio Biography of the artist.
     * @return wallet Wallet address of the artist.
     */
    function getArtistInfoByAddress(address artistAddress) external view returns (string memory name, string memory bio, address wallet) {
        uint256 artistId = addressToArtistId[artistAddress];
        require(artistId != 0, "Artist does not exist");

        ArtistRegistryTypes.ArtistInfo memory artist = artists[artistId];
        return (artist.name, artist.bio, artist.wallet);
    }
}
