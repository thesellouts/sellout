// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ReferralModule } from "../referral/ReferralModule.sol";
import { IVenueRegistry } from "./IVenueRegistry.sol";
import { VenueRegistryStorage } from "./storage/VenueRegistryStorage.sol";
import { VenueRegistryTypes } from "./types/VenueRegistryTypes.sol";

/// @title VenueRegistry
/// @notice Contract for managing venue profiles using ERC1155 tokens, with a referral system for registrations.
contract VenueRegistry is ERC1155, IVenueRegistry, VenueRegistryStorage {
    ReferralModule private referralModule;

    /// @notice Constructor to set the metadata URI and initialize the ReferralModule.
    /// @param _referralModuleAddress The address of the ReferralModule contract.
    constructor(address _referralModuleAddress) ERC1155("https://api.yourapp.com/metadata/{id}.json") {
        referralModule = ReferralModule(_referralModuleAddress);
    }

    /// @notice Registers a new venue with provided name and biography.
    /// @dev Internal function that creates a new venue entry and mints a token for them.
    /// @param _name Name of the venue.
    /// @param _bio Biography of the venue.
    function registerVenue(string memory _name, string memory _bio) internal {
        currentVenueId++;
        uint256 venueId = currentVenueId;
        address walletAddress = msg.sender;

        venues[venueId] = VenueRegistryTypes.VenueInfo({name: _name, bio: _bio, wallet: walletAddress});
        addressToVenueId[walletAddress] = venueId; // Link the address to the new venue ID

        _mint(walletAddress, venueId, 1, "");
        emit VenueRegistered(venueId, _name);
    }

    /// @notice Adds a venue to the waitlist.
    /// @dev Internal function to set venue's waitlisted status to true.
    /// @param _venue Address of the venue to be waitlisted.
    function waitlistVenue(address _venue) internal {
        waitlistedVenues[_venue] = true;
        emit VenueWaitlisted(_venue);
    }

    /// @notice Accepts a waitlisted venue into the registry.
    /// @dev Can only be called by the venue themselves to accept their waitlisted status.
    function acceptVenue() public {
        require(waitlistedVenues[msg.sender], "You are not waitlisted");
        waitlistedVenues[msg.sender] = false;
        registerVenue("", ""); // Name and bio can be set later
        emit VenueAccepted(currentVenueId, msg.sender);
    }

    /// @notice Waitlists a venue for referral.
    /// @dev This function is called after a venue has been referred.
    function waitlistForReferral() public {
        ReferralModule.ReferralCredits memory credits = referralModule.getReferralCredits(msg.sender);
        require(credits.venue > 0, "Insufficient venue referral credits");
        referralModule.decrementReferralCredits(msg.sender, 0, 0, 1);
        waitlistVenue(msg.sender); // Venue is now waitlisted
    }

    /// @notice Allows a venue to update their profile.
    /// @dev Venues can only update their own profiles.
    /// @param _venueId ID of the venue updating their profile.
    /// @param _name Updated name of the venue.
    /// @param _bio Updated biography of the venue.
    function updateVenue(uint256 _venueId, string memory _name, string memory _bio) public {
        require(_venueId <= currentVenueId, "Venue does not exist");
        require(venues[_venueId].wallet == msg.sender, "Only the venue can update their profile");
        venues[_venueId].name = _name;
        venues[_venueId].bio = _bio;
        emit VenueUpdated(_venueId, _name, _bio);
    }

    /// @notice Allows a venue to deregister themselves.
    /// @dev Venues can only deregister themselves.
    /// @param _venueId ID of the venue deregistering.
    function deregisterVenue(uint256 _venueId) public {
        require(_venueId <= currentVenueId, "Venue does not exist");
        require(venues[_venueId].wallet == msg.sender, "Only the venue can deregister themselves");
        _burn(msg.sender, _venueId, 1);
        delete venues[_venueId];
        emit VenueDeregistered(_venueId);
    }

    /// @notice Retrieves venue information by their wallet address.
    /// @dev Public function that returns venue's name, bio, and wallet address.
    /// @param venueAddress Wallet address of the venue.
    /// @return name Name of the venue.
    /// @return bio Biography of the venue.
    /// @return wallet Wallet address of the venue.
    function getVenueInfoByAddress(address venueAddress) external view returns (string memory name, string memory bio, address wallet) {
        uint256 venueId = addressToVenueId[venueAddress];
        require(venueId != 0, "Venue does not exist");
        VenueRegistryTypes.VenueInfo memory venue = venues[venueId];
        return (venue.name, venue.bio, venue.wallet);
    }
}
