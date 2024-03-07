// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./types/ArtistRegistryTypes.sol";
import "./storage/ArtistRegistryStorage.sol";
import "./IArtistRegistry.sol";
import "../referral/ReferralModule.sol";

/**
 * @title ArtistRegistry
 * @dev Manages artist profiles with ERC1155 tokens, incorporating a referral system.
 */
contract ArtistRegistry is ERC1155, IArtistRegistry, ArtistRegistryStorage {
    ReferralModule private referralModule;

    /**
     * @dev Initializes the contract with a metadata URI and the ReferralModule address.
     * @param _referralModuleAddress Address of the ReferralModule contract.
     */
    constructor(address _referralModuleAddress) ERC1155("https://api.yourapp.com/metadata/{id}.json") {
        referralModule = ReferralModule(_referralModuleAddress);
    }

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
        ReferralModule.ReferralCredits memory credits = referralModule.getReferralCredits(msg.sender);
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
