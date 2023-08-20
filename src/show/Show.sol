// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IShow.sol";
import "./storage/ShowStorage.sol";

/// @author fictreal
/// @title Show
/// @notice Manages show proposals, statuses, and fund distribution
contract Show is IShow, ShowStorage {
    address public ticketContract; // Address of the Ticket contract
    address public venueContract; // Address of the Venue contract
    bool private areContractsSet = false; // To ensure the addresses are set only once

    /// @notice Sets the Ticket and Venue contract addresses
    /// @param _ticketContract Address of the Ticket contract
    /// @param _venueContract Address of the Venue contract
    function setTicketAndVenueContractAddresses(address _ticketContract, address _venueContract) public {
        require(!areContractsSet, "Ticket and Venue contract addresses already set");
        ticketContract = _ticketContract;
        venueContract = _venueContract;
        areContractsSet = true;
    }

    /// @notice Deposits Ether into the vault for a specific show
    /// @param showId Unique identifier for the show
    function depositToVault(bytes32 showId) public payable onlyTicketContract onlyVenueContract {
        showVault[showId] += msg.value;
    }

    // Modifiers
    modifier onlyOrganizerOrArtist(bytes32 showId) {
        require(isOrganizer(msg.sender, showId) || isArtist(msg.sender, showId), "Not authorized");
        _;
    }
    modifier onlyTicketContract() {
        require(msg.sender == ticketContract, "Only the Ticket contract can call this function");
        _;
    }
    modifier onlyVenueContract() {
        require(msg.sender == venueContract, "Only the Ticket contract can call this function");
        _;
    }
    modifier isExpired(bytes32 showId) {
        require(shows[showId].status != Status.Expired, "Show has expired");
        _;
    }

    /// @notice Creates a show proposal between one or more artists
    /// @param name Name of the show
    /// @param description Description of the show
    /// @param artists Array of artist addresses
    /// @param venue Venue details
    /// @param sellOutThreshold Sell-out threshold percentage
    /// @param totalCapacity Total capacity of the show
    /// @param ticketPrice Ticket price details
    /// @param split Array representing the percentage split between organizer, artists, and venue
    /// @return showId Unique identifier for the proposed show
    function proposeShow(
        string memory name,
        string memory description,
        address[] memory artists,
        VenueTypes.Venue memory venue,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        TicketPrice memory ticketPrice,
        uint256[] memory split // organizer, artists[], venue
    ) public returns (bytes32 showId) {
        // Validation checks
        require(bytes(name).length > 0, "Name is required");
        require(venue.radius > 0, "Venue radius must be greater than 0");
        require(totalCapacity > 0, "Total capacity must be greater than 0");
        require(artists.length > 0, "At least one artist required");
        require(ticketPrice.maxPrice >= ticketPrice.minPrice, "Max ticket price must be greater or equal to min ticket price");
        require(sellOutThreshold >= 0 && sellOutThreshold <= 100, "Sell-out threshold must be between 0 and 100");
        require(venue.coordinates.lat >= -90 * 10**6 && venue.coordinates.lat <= 90 * 10**6, "Invalid latitude");
        require(venue.coordinates.lon >= -180 * 10**6 && venue.coordinates.lon <= 180 * 10**6, "Invalid longitude");

        validateSplit(split, artists.length);

        // Create a proposal ID by hashing the relevant parameters
        showId = keccak256(abi.encodePacked(msg.sender, artists, venue.coordinates.lat, venue.coordinates.lon, venue.radius, sellOutThreshold, totalCapacity));
        uint256 expiry = block.timestamp + 30 days;

        // Create the show proposal
        shows[showId] = Show({
            showId: showId,
            name: name,
            description: description,
            artists: artists,
            organizer: msg.sender,
            venue: venue,
            ticketPrice: ticketPrice,
            sellOutThreshold: sellOutThreshold,
            totalCapacity: totalCapacity,
            status: Status.Proposed,
            isActive: true,
            split: split,
            expiry: expiry
        });

        // Map artists to the show
        for (uint i = 0; i < artists.length; i++) {
            isArtistMapping[showId][artists[i]] = true;
        }

        emit ShowProposed(showId, msg.sender, name, artists, description, ticketPrice, sellOutThreshold, split);

        return showId;
    }

    /// @notice Updates the status of a show
    /// @param showId Unique identifier for the show
    /// @param _status New status for the show
    function updateStatus(bytes32 showId, Status _status) external onlyTicketContract onlyVenueContract {
        shows[showId].status = _status;
        emit StatusUpdated(showId, _status);
    }

    /// @notice Updates the expiry time of a show
    /// @param showId Unique identifier for the show
    /// @param expiry New expiry time for the show
    function updateExpiry(bytes32 showId, uint256 expiry) external onlyTicketContract {
        require(shows[showId].status == Status.Proposed, "Show must be in Proposed status");
        shows[showId].expiry = expiry;
        emit ExpiryUpdated(showId, expiry);
    }

    /// @notice Cancels a sold-out show
    /// @param showId Unique identifier for the show
    function cancelShow(bytes32 showId) public onlyOrganizerOrArtist(showId) {
        Show storage show = shows[showId];
        require(show.status == Status.SoldOut, "Show must be SoldOut");
        show.status = Status.Cancelled;
    }

    /// @notice Completes a show and distributes funds
    /// @param showId Unique identifier for the show
    function completeShow(bytes32 showId) public onlyTicketContract {
        Show storage show = shows[showId];
        require(show.status == Status.Accepted, "Show must be Accepted");

        uint256 totalAmount = showVault[showId];
        require(totalAmount > 0, "No funds to distribute");

        uint256[] memory split = show.split;

        // Calculate organizer's share
        uint256 organizerShare = totalAmount * split[0] / 100;
        pendingWithdrawals[showId][show.organizer] = organizerShare;

        // Calculate artists' shares
        for (uint i = 0; i < show.artists.length; i++) {
            uint256 artistShare = totalAmount * split[i + 1] / 100;
            pendingWithdrawals[showId][show.artists[i]] = artistShare;
        }

        // Calculate venue's share
        uint256 venueShare = totalAmount * split[split.length - 1] / 100;
        pendingWithdrawals[showId][show.venue.wallet] = venueShare;

        showVault[showId] = 0;

        // Update the status
        show.status = Status.Completed;
    }

    function withdraw(bytes32 showId) public {
        uint256 amount = pendingWithdrawals[showId][msg.sender];
        require(amount > 0, "No funds to withdraw");

        // Ensure the recipient can't re-entrantly call this function
        pendingWithdrawals[showId][msg.sender] = 0;

        payable(msg.sender).transfer(amount);
        emit Withdrawal(showId, msg.sender, amount);
    }


    /// @notice Retrieves the details of a show
    /// @param showId Unique identifier for the show
    /// @return name Name of the show
    /// @return description Description of the show
    /// @return organizer Organizer's address
    /// @return artists Array of artist addresses
    /// @return venue Venue details
    /// @return ticketPrice Ticket price details
    /// @return sellOutThreshold Sell-out threshold percentage
    /// @return totalCapacity Total capacity of the show
    /// @return status Status of the show
    /// @return isActive Whether the show is active
    function getShowById(bytes32 showId) public view returns (
        string memory name,
        string memory description,
        address organizer,
        address[] memory artists,
        VenueTypes.Venue memory venue,
        TicketPrice memory ticketPrice,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        Status status,
        bool isActive
    ) {
        Show storage show = shows[showId];

        return (
            show.name,
            show.description,
            show.organizer,
            show.artists,
            show.venue,
            show.ticketPrice,
            show.sellOutThreshold,
            show.totalCapacity,
            show.status,
            show.isActive
        );
    }

    /// @notice Retrieves the ticket price details of a show
    /// @param showId Unique identifier for the show
    /// @return TicketPrice structure containing min and max price
    function getTicketPrice(bytes32 showId) public view returns (TicketPrice memory) {
        return shows[showId].ticketPrice;
    }

    /// @notice Retrieves the total capacity of a show
    /// @param showId Unique identifier for the show
    /// @return Total capacity of the show
    function getTotalCapacity(bytes32 showId) public view returns (uint256) {
        return shows[showId].totalCapacity;
    }

    /// @notice Retrieves the sell-out threshold of a show
    /// @param showId Unique identifier for the show
    /// @return Sell-out threshold percentage of the show
    function getSellOutThreshold(bytes32 showId) public view returns (uint256) {
        return shows[showId].sellOutThreshold;
    }

    /// @notice Retrieves the status of a show
    /// @param showId Unique identifier for the show
    /// @return Status of the show
    function getShowStatus(bytes32 showId) public view returns (Status) {
        return shows[showId].status;
    }


    /// @notice Returns the total number of voters for a specific show, including artists and the organizer.
    /// @param showId Unique identifier for the show.
    /// @return Total number of voters (artists + organizer).
    function getNumberOfVoters(bytes32 showId) public view returns (uint256) {
        uint256 numberOfArtists = shows[showId].artists.length;

        // Adding 1 for the organizer
        return numberOfArtists + 1;
    }

    /// @notice Updates the venue information for a specific show.
    /// @param showId Unique identifier for the show.
    /// @param newVenue New venue information to be set.
    function setVenue(bytes32 showId, VenueTypes.Venue memory newVenue) external onlyVenueContract {
        // Retrieve the show using the showId
        Show storage show = shows[showId];

        // Update the venue information
        show.venue = newVenue;

        // Optionally, you could emit an event to log the change
        emit VenueUpdated(showId, newVenue);
    }


    /// @notice Checks if the given user is an organizer of the specified show.
    /// @param user Address of the user to check
    /// @param showId Unique identifier for the show
    /// @return true if the user is an organizer, false otherwise
    function isOrganizer(address user, bytes32 showId) public view returns (bool) {
        return shows[showId].organizer == user;
    }

    /// @notice Checks if the given user is an artist in the specified show.
    /// @param user Address of the user to check
    /// @param showId Unique identifier for the show
    /// @return true if the user is an artist, false otherwise
    function isArtist(address user, bytes32 showId) public view returns (bool) {
        return isArtistMapping[showId][user];
    }

    /// @notice Validates the split percentages between organizer, artists, and venue
    /// @param split Array representing the percentage split
    /// @param numArtists Number of artists in the show
    function validateSplit(uint256[] memory split, uint256 numArtists) internal pure {
        require(split.length == numArtists + 2, "Split array must have a length equal to the number of artists plus 2");

        uint256 sum = 0;
        for (uint i = 0; i < split.length; i++) {
            sum += split[i];
        }
        require(sum == 100, "Split percentages must sum to 100");
    }

    /// @notice Checks and updates the expiry status of a show
    /// @param showId Unique identifier for the show
    function checkAndUpdateExpiry(bytes32 showId) external onlyTicketContract {
        Show storage show = shows[showId];
        if (block.timestamp >= show.expiry && show.status != Status.Expired) {
            show.status = Status.Expired;
            emit ShowExpired(showId);
        }
    }
}
