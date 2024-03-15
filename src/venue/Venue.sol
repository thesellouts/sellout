// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { VenueStorage, VenueTypes } from "./storage/VenueStorage.sol";
import { IVenue } from "./IVenue.sol";

import { ITicket } from "../ticket/ITicket.sol";

import { IShow } from "../show/IShow.sol";
import { ShowTypes } from "../show/storage/ShowStorage.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Venue Contract
/// @author taayyohh
/// @notice This contract manages the venue proposals, voting, and acceptance for shows.
contract Venue is Initializable, IVenue, VenueStorage, UUPSUpgradeable, OwnableUpgradeable {
    IShow public showInstance;
    ITicket public ticketInstance;

    // Constants for durations
//    uint256 constant PROPOSAL_PERIOD_DURATION = 7 days;
//    uint256 constant PUBLIC_VOTING_PERIOD_DURATION = 3 days;
//    uint256 constant PROPOSAL_DATE_EXTENSION = 1 days;
//    uint256 constant PROPOSAL_DATE_MINIMUM_FUTURE = 30 days;
//    uint256 constant PROPOSAL_PERIOD_EXTENSION_THRESHOLD = 6 hours;

    // Constants for durations adjusted for quick testing
    uint256 constant PROPOSAL_PERIOD_DURATION = 2 hours; // From 7 days
    uint256 constant PUBLIC_VOTING_PERIOD_DURATION = 10 minutes; // From 3 days
    uint256 constant PROPOSAL_DATE_EXTENSION = 5 minutes; // From 1 day
    uint256 constant PROPOSAL_DATE_MINIMUM_FUTURE = 45 minutes; // From 30 days
    uint256 constant PROPOSAL_PERIOD_EXTENSION_THRESHOLD = 2 minutes; // From 6 hours

    /// @notice Initializes the Venue contract with Show and Ticket contract addresses.
    /// @param _showBaseContractAddress Address of the Show contract.
    /// @param _ticketBaseContractAddress Address of the Ticket contract.
    function initialize(address initialOwner,address _showBaseContractAddress, address _ticketBaseContractAddress) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        showInstance = IShow(_showBaseContractAddress);
        ticketInstance = ITicket(_ticketBaseContractAddress);
    }

    modifier onlyOrganizer(bytes32 showId) {
        require(showInstance.isOrganizer(msg.sender, showId), "Not an organizer");
        _;
    }

    modifier onlyAuthorized(bytes32 showId) {
        require(showInstance.isOrganizer(msg.sender, showId) || showInstance.isArtist(msg.sender, showId), "Not authorized");
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Submit a proposal for a venue for a specific show.
    /// @param showId Unique identifier for the show.
    /// @param venueName Name of the venue.
    /// @param coordinates Coordinates of the venue location.
    /// @param totalCapacity Total capacity of the venue.
    /// @param proposedDates Array of proposed dates for the show.
    function submitProposal(
        bytes32 showId,
        string memory venueName,
        VenueTypes.Coordinates memory coordinates,
        uint256 totalCapacity,
        uint256[] memory proposedDates
    ) public payable {
        require(showInstance.getShowStatus(showId) == ShowTypes.Status.SoldOut, "Show must be SoldOut");
        require(proposalPeriod[showId].endTime == 0 || block.timestamp <= proposalPeriod[showId].endTime, "Proposal period has ended");
        require(coordinates.lat >= -90 * 10**6 && coordinates.lat <= 90 * 10**6, "Invalid latitude");
        require(coordinates.lon >= -180 * 10**6 && coordinates.lon <= 180 * 10**6, "Invalid longitude");
        require(proposedDates.length > 0, "At least one proposed date required");
        require(proposedDates.length <= 5, "Proposal must have 5 or less dates");

        for (uint256 i = 0; i < proposedDates.length; i++) {
            require(proposedDates[i] > proposalPeriod[showId].endTime + PROPOSAL_DATE_MINIMUM_FUTURE, "Proposed date must be 60 days in the future");
        }

        if (!proposalPeriod[showId].isPeriodActive) {
            startProposalPeriod(showId);
        }

        if (block.timestamp >= proposalPeriod[showId].endTime - PROPOSAL_PERIOD_EXTENSION_THRESHOLD) {
            proposalPeriod[showId].endTime += PROPOSAL_DATE_EXTENSION; // Extend by 1 day if within the last 6 hours
        }

        VenueTypes.Venue memory venue;
        venue.name = venueName;
        venue.coordinates = coordinates;
        venue.totalCapacity = totalCapacity;
        venue.wallet = msg.sender;
        venue.venueId = keccak256(abi.encodePacked(venueName, coordinates.lat, coordinates.lon, totalCapacity));


    VenueTypes.Proposal memory proposal;
        proposal.venue = venue;
        proposal.proposedDates = proposedDates;
        proposal.proposer = msg.sender;
        proposal.bribe = msg.value;
        proposal.votes = 0;
        proposal.accepted = false;
        showProposals[showId].push(proposal);
        emit ProposalSubmitted(showId, msg.sender, venueName);
    }

    /// @notice Allows a ticket holder to vote for a venue proposal.
    /// @param showId Unique identifier for the show.
    /// @param proposalIndex Index of the proposal to vote for.
    function ticketHolderVenueVote(bytes32 showId, uint256 proposalIndex) public {
        // If the voting period has never been started (endTime is 0) and is not active, start it
        if (votingPeriods[showId].endTime == 0 && !votingPeriods[showId].isPeriodActive) {
            startPublicVotingPeriod(showId);
        }

        require(votingPeriods[showId].isPeriodActive, "Voting period is not active");
        require(showInstance.hasTicket(msg.sender, showId), "Not a ticket owner");
        require(!hasTicketOwnerVoted[showId][msg.sender], "Already voted");
        showProposals[showId][proposalIndex].votes++;
        hasTicketOwnerVoted[showId][msg.sender] = true;
        emit VenueVoted(showId, msg.sender, proposalIndex);
    }

    /// @notice Allows an authorized user (organizer or artist) to vote for a venue proposal.
    /// @param showId Unique identifier for the show.
    /// @param proposalIndex Index of the proposal to vote for.
    function vote(bytes32 showId, uint256 proposalIndex) public onlyAuthorized(showId) {
        require(proposalIndex < showProposals[showId].length, "Invalid proposal index");

        uint256 previousProposalIndex = previousVote[showId][msg.sender];
        require(previousProposalIndex != proposalIndex, "Already voted for this venue");

        // Decrement the vote count for the previously voted proposal (if any)
        if (hasVoted[showId][msg.sender]) {
            showProposals[showId][previousProposalIndex].votes--;
        }

        // Increment the vote count for the newly voted proposal
        showProposals[showId][proposalIndex].votes++;
        hasVoted[showId][msg.sender] = true;
        previousVote[showId][msg.sender] = proposalIndex; // Update the user's previous vote
        emit ProposalVoted(showId, msg.sender, proposalIndex);

        // Check if all required votes have been received
        uint256 requiredVotes = showInstance.getNumberOfVoters(showId); // Assuming this returns the count of organizer plus artists
        if (showProposals[showId][proposalIndex].votes == requiredVotes) {
            acceptProposal(showId, proposalIndex);
        }
    }

    /// @notice Allows an authorized user (organizer or artist) to vote for a proposed date.
    /// @param showId Unique identifier for the show.
    /// @param dateIndex Index of the date to vote for.
    function voteForDate(bytes32 showId, uint256 dateIndex) public onlyAuthorized(showId) {
        require(dateIndex < showProposals[showId][selectedProposalIndex[showId]].proposedDates.length, "Invalid date index");

        uint256 previousDateIndex = previousDateVote[showId][msg.sender];
        require(previousDateIndex != dateIndex, "Already voted for this date");

        // Decrement the vote count for the previously voted date (if any)
        if (hasDateVoted[showId][msg.sender]) {
            dateVotes[showId][previousDateIndex]--;
        }

        // Increment the vote count for the newly voted date
        dateVotes[showId][dateIndex]++;
        hasDateVoted[showId][msg.sender] = true;
        previousDateVote[showId][msg.sender] = dateIndex; // Update the user's previous date vote
        emit DateVoted(showId, msg.sender, dateIndex);

        // Check if all required votes have been received
        uint256 requiredVotes = showInstance.getNumberOfVoters(showId); // Assuming this returns the count of organizer plus artists
        if (dateVotes[showId][dateIndex] == requiredVotes) {
            acceptDate(showId, dateIndex);
        }
    }

    /// @notice Starts the proposal period for a show.
    /// @dev Sets the proposal period as active and sets the end time to 2 weeks from the current timestamp.
    /// @param showId Unique identifier for the show.
    function startProposalPeriod(bytes32 showId) internal {
        proposalPeriod[showId].isPeriodActive = true;
        proposalPeriod[showId].endTime = block.timestamp + PROPOSAL_PERIOD_DURATION;
        emit ProposalPeriodStarted(showId, proposalPeriod[showId].endTime);
    }

    /// @notice Starts the public voting period for a show.
    /// @dev Sets the voting period as active and sets the end time to 1 week from the current timestamp.
    /// @param showId Unique identifier for the show.
    function startPublicVotingPeriod(bytes32 showId) internal {
        votingPeriods[showId].isPeriodActive = true;
        votingPeriods[showId].endTime = block.timestamp + PUBLIC_VOTING_PERIOD_DURATION;
        emit PublicVotingPeriodStarted(showId, votingPeriods[showId].endTime);
    }

    /// @notice Accepts a proposal after voting has ended.
    /// @dev Sets the proposal as accepted and updates the selected proposal index.
    /// @param showId Unique identifier for the show.
    /// @param proposalIndex Index of the proposal to accept.
    function acceptProposal(bytes32 showId, uint256 proposalIndex) internal {
        showProposals[showId][proposalIndex].accepted = true;
        selectedProposalIndex[showId] = proposalIndex;
        emit ProposalAccepted(showId, proposalIndex);
    }

    /// @notice Accepts a proposed date after date voting has ended.
    /// @dev Updates the selected date for the show.
    /// @param showId Unique identifier for the show.
    /// @param date The proposed date to accept.
    function acceptDate(bytes32 showId, uint256 date) internal {
        selectedDate[showId] = date;
        emit DateAccepted(showId, date);
    }

    /// @notice Retrieves the proposal period for a specific venue.
    /// @param venueId The unique identifier of the venue.
    /// @return The proposal period of the venue.
    function getProposalPeriod(bytes32 venueId) public view returns (ProposalPeriod memory) {
        return proposalPeriod[venueId];
    }

    /// @notice Retrieves all the proposals for a specific venue.
    /// @param venueId The unique identifier of the venue.
    /// @return An array of proposals for the venue.
    function getShowProposals(bytes32 venueId) public view returns (Proposal[] memory) {
        return showProposals[venueId];
    }

    /// @notice Checks if a specific address has voted for a venue proposal.
    /// @param venueId The unique identifier of the venue.
    /// @param user The address of the user.
    /// @return True if the user has voted, false otherwise.
    function getHasVoted(bytes32 venueId, address user) public view returns (bool) {
        return hasVoted[venueId][user];
    }

    /// @notice Retrieves the voting period for a specific venue.
    /// @param venueId The unique identifier of the venue.
    /// @return The voting period of the venue.
    function getVotingPeriods(bytes32 venueId) public view returns (VotingPeriod memory) {
        return votingPeriods[venueId];
    }

    /// @notice Checks if a ticket owner has voted for a venue.
    /// @param venueId The unique identifier of the venue.
    /// @param user The address of the user.
    /// @return True if the ticket owner has voted, false otherwise.
    function getHasTicketOwnerVoted(bytes32 venueId, address user) public view returns (bool) {
        return hasTicketOwnerVoted[venueId][user];
    }

    /// @notice Retrieves the previous vote of an address for a venue.
    /// @param venueId The unique identifier of the venue.
    /// @param user The address of the user.
    /// @return The previous vote of the user.
    function getPreviousVote(bytes32 venueId, address user) public view returns (uint256) {
        return previousVote[venueId][user];
    }

    /// @notice Retrieves the votes for specific dates for a venue.
    /// @param venueId The unique identifier of the venue.
    /// @param date The date for which votes are being queried.
    /// @return The number of votes for the specified date.
    function getDateVotes(bytes32 venueId, uint256 date) public view returns (uint256) {
        return dateVotes[venueId][date];
    }

    /// @notice Retrieves the previous date vote of an address for a venue.
    /// @param venueId The unique identifier of the venue.
    /// @param user The address of the user.
    /// @return The previous date vote of the user.
    function getPreviousDateVote(bytes32 venueId, address user) public view returns (uint256) {
        return previousDateVote[venueId][user];
    }

    /// @notice Checks if an address has voted for a date for a venue.
    /// @param venueId The unique identifier of the venue.
    /// @param user The address of the user.
    /// @return True if the user has voted for a date, false otherwise.
    function getHasDateVoted(bytes32 venueId, address user) public view returns (bool) {
        return hasDateVoted[venueId][user];
    }

    /// @notice Retrieves the selected date for each venue.
    /// @param venueId The unique identifier of the venue.
    /// @return The selected date for the venue.
    function getSelectedDate(bytes32 venueId) public view returns (uint256) {
        return selectedDate[venueId];
    }

    /// @notice Retrieves the index of the selected proposal for each venue.
    /// @param venueId The unique identifier of the venue.
    /// @return The index of the selected proposal for the venue.
    function getSelectedProposalIndex(bytes32 venueId) public view returns (uint256) {
        return selectedProposalIndex[venueId];
    }

    /// @notice Retrieves the refunds owed to a proposer.
    /// @param user The address of the user (proposer).
    /// @return The amount of refund owed to the proposer.
    function getRefunds(address user) public view returns (uint256) {
        return refunds[user];
    }
}
