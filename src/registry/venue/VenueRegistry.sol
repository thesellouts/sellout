// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { ReferralModule } from "../referral/ReferralModule.sol";

/// @title VenueRegistry
/// @notice Contract for managing venue profiles using ERC1155 tokens, with a referral system for registrations.
contract VenueRegistry is ERC1155, Ownable {
    struct VenueInfo {
        string name;
        string bio;
        address wallet;
    }

    mapping(uint256 => VenueInfo) private venues;
    uint256 private currentVenueId;

    ReferralModule private referralModule; // Instance of the ReferralModule

    event VenueRegistered(uint256 indexed venueId, string name);
    event VenueUpdated(uint256 indexed venueId, string name, string bio);
    event VenueDeregistered(uint256 indexed venueId);

    /// @notice Constructor setting the URI for the ERC1155 token and initializing the ReferralModule.
    /// @param _referralModuleAddress Address of the ReferralModule contract.
    constructor(address _referralModuleAddress) ERC1155("https://api.yourapp.com/metadata/{id}.json") {
        referralModule = ReferralModule(_referralModuleAddress);
    }

    /// @notice Registers a new venue without referral.
    /// @param _name Name of the venue.
    /// @param _bio Biography of the venue.
    function registerVenue(string memory _name, string memory _bio) internal {
        currentVenueId++;
        uint256 venueId = currentVenueId;
        venues[venueId] = VenueInfo(_name, _bio, msg.sender);
        _mint(msg.sender, venueId, 1, "");
        emit VenueRegistered(venueId, _name);
    }

    /// @notice Public function to register an venue with referral credits.
    /// @param _name Name of the venue.
    /// @param _bio Biography of the venue.
    function registerVenueWithReferral(string memory _name, string memory _bio) public {
        // Check if the sender has enough venue referral credits
        ReferralModule.ReferralCredits memory credits = referralModule.getReferralCredits(msg.sender);
        require(credits.venue > 0, "Insufficient venue referral credits");

        // Decrement referral credit for registering an venue
        referralModule.decrementReferralCredits(msg.sender, 0, 0, 1);
        registerVenue(_name, _bio);
    }

    /// @notice Allows an venue to update their profile.
    /// @param _venueId ID of the venue updating their profile.
    /// @param _name Updated name of the venue.
    /// @param _bio Updated biography of the venue.
    function updateVenue(uint256 _venueId, string memory _name, string memory _bio) public {
        require(_venueId <= currentVenueId, "Venue does not exist");
        VenueInfo storage venue = venues[_venueId];
        require(venue.wallet == msg.sender, "Only the venue can update their profile");
        venue.name = _name;
        venue.bio = _bio;
        emit VenueUpdated(_venueId, _name, _bio);
    }

    /// @notice Allows an venue to deregister themselves.
    /// @param _venueId ID of the venue deregistering.
    function deregisterVenue(uint256 _venueId) public {
        require(_venueId <= currentVenueId, "Venue does not exist");
        VenueInfo storage venue = venues[_venueId];
        require(venue.wallet == msg.sender, "Only the venue can deregister themselves");
        _burn(msg.sender, _venueId, 1);
        delete venues[_venueId];
        emit VenueDeregistered(_venueId);
    }

    /// @notice Retrieves venue information.
    /// @param _venueId ID of the venue to retrieve info for.
    /// @return VenueInfo structure with the venue's details.
    function getVenueInfo(uint256 _venueId) public view returns (VenueInfo memory) {
        require(_venueId <= currentVenueId, "Venue does not exist");
        return venues[_venueId];
    }
}
