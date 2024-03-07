// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./types/VenueRegistryTypes.sol";
import "./storage/VenueRegistryStorage.sol";
import "./IVenueRegistry.sol";
import "../referral/ReferralModule.sol";

/**
 * @title VenueRegistry
 * @dev Manages venue profiles using ERC1155 tokens and incorporates a referral system for venue registration.
 */
contract VenueRegistry is ERC1155, IVenueRegistry, VenueRegistryStorage {
    ReferralModule private referralModule;

    /**
     * @dev Initializes the VenueRegistry with a metadata URI for the tokens and the ReferralModule's address.
     * @param _referralModuleAddress Address of the ReferralModule contract.
     */
    constructor(address _referralModuleAddress) ERC1155("https://api.yourapp.com/metadata/{id}.json") {
        referralModule = ReferralModule(_referralModuleAddress);
    }

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
        ReferralModule.ReferralCredits memory credits = referralModule.getReferralCredits(msg.sender);
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
