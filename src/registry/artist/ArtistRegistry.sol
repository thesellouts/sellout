// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ReferralModule } from "../referral/ReferralModule.sol";
import { ArtistRegistryTypes } from "../artist/types/ArtistRegistryTypes.sol";
import { ArtistRegistryStorage } from "../artist/storage/ArtistRegistryStorage.sol";
import { IArtistRegistry } from "./IArtistRegistry.sol";


/// @title ArtistRegistry
/// @notice Contract for managing artist profiles using ERC1155 tokens, with a referral system for registrations.
contract ArtistRegistry is ERC1155, IArtistRegistry, ArtistRegistryStorage {
    ReferralModule private referralModule;

    /// @notice Constructor to set the metadata URI and initialize the ReferralModule.
    /// @param _referralModuleAddress The address of the ReferralModule contract.
    constructor(address _referralModuleAddress) ERC1155("https://api.yourapp.com/metadata/{id}.json") {
        referralModule = ReferralModule(_referralModuleAddress);
    }

    /// @notice Registers a new artist with the provided name and biography.
    /// @dev Internal function that creates a new artist entry and mints a token for them.
    /// @param _name Name of the artist.
    /// @param _bio Biography of the artist.
    function registerArtist(string memory _name, string memory _bio) internal {
        currentArtistId++;
        uint256 artistId = currentArtistId;
        address walletAddress = msg.sender;

        artists[artistId] = ArtistRegistryTypes.ArtistInfo({name: _name, bio: _bio, wallet: walletAddress});
        addressToArtistId[walletAddress] = artistId; // Link the address to the new artist ID

        _mint(walletAddress, artistId, 1, "");
        emit ArtistRegistered(artistId, _name);
    }

    /// @notice Adds an artist to the waitlist.
    /// @dev Internal function to set artist's waitlisted status to true.
    /// @param _artist Address of the artist to be waitlisted.
    function waitlistArtist(address _artist) internal {
        waitlistedArtists[_artist] = true;
        emit ArtistWaitlisted(_artist);
    }

    /// @notice Accepts a waitlisted artist into the registry.
    /// @dev Can only be called by the artist themselves to accept their waitlisted status.
    function acceptArtist() public {
        require(waitlistedArtists[msg.sender], "You are not waitlisted");
        waitlistedArtists[msg.sender] = false;
        registerArtist("", ""); // Name and bio can be set later
        emit ArtistAccepted(currentArtistId, msg.sender);
    }

    /// @notice Adds an artist to the waitlist with a referral credit.
    /// @dev This function is called after an artist has been referred.
    function waitlistForReferral() public {
        ReferralModule.ReferralCredits memory credits = referralModule.getReferralCredits(msg.sender);
        require(credits.artist > 0, "Insufficient artist referral credits");
        referralModule.decrementReferralCredits(msg.sender, 1, 0, 0);
        waitlistArtist(msg.sender); // Artist is now waitlisted
    }

    /// @notice Allows an artist to update their profile.
    /// @dev Artists can only update their own profiles.
    /// @param _artistId ID of the artist updating their profile.
    /// @param _name Updated name of the artist.
    /// @param _bio Updated biography of the artist.
    function updateArtist(uint256 _artistId, string memory _name, string memory _bio) public {
        require(_artistId <= currentArtistId, "Artist does not exist");
        require(artists[_artistId].wallet == msg.sender, "Only the artist can update their profile");
        artists[_artistId].name = _name;
        artists[_artistId].bio = _bio;
        emit ArtistUpdated(_artistId, _name, _bio);
    }

    /// @notice Allows an artist to deregister themselves.
    /// @dev Artists can only deregister themselves.
    /// @param _artistId ID of the artist deregistering.
    function deregisterArtist(uint256 _artistId) public {
        require(_artistId <= currentArtistId, "Artist does not exist");
        require(artists[_artistId].wallet == msg.sender, "Only the artist can deregister themselves");
        _burn(msg.sender, _artistId, 1);
        delete artists[_artistId];
        emit ArtistDeregistered(_artistId);
    }

    /// @notice Retrieves artist information by their wallet address.
    /// @dev Public function that returns artist's name, bio, and wallet address.
    /// @param artistAddress Wallet address of the artist.
    /// @return name Name of the artist.
    /// @return bio Biography of the artist.
    /// @return wallet Wallet address of the artist.
    function getArtistInfoByAddress(address artistAddress) external view returns (string memory name, string memory bio, address wallet) {
        uint256 artistId = addressToArtistId[artistAddress];
        require(artistId != 0, "Artist does not exist");
        ArtistRegistryTypes.ArtistInfo memory artist = artists[artistId];
        return (artist.name, artist.bio, artist.wallet);
    }
}
