// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IShow } from "../show/IShow.sol";
import { ShowTypes } from "../show/storage/ShowStorage.sol";
import { VenueStorage, VenueTypes } from "./storage/VenueStorage.sol";
import { IVenue } from "./IVenue.sol";
import { ITicket } from "../ticket/ITicket.sol";

/// @title Venue Contract
/// @author taayyohh
/// @notice This contract manages the venue proposals, voting, and acceptance for shows.
contract Venue is IVenue, VenueStorage {
    IShow public showInstance;
    ITicket public ticketInstance;

    // Constants for durations
    uint256 constant PROPOSAL_PERIOD_DURATION = 7 days;
    uint256 constant PUBLIC_VOTING_PERIOD_DURATION = 3 days;
    uint256 constant PROPOSAL_DATE_EXTENSION = 1 days;
    uint256 constant PROPOSAL_DATE_MINIMUM_FUTURE = 30 days;
    uint256 constant PROPOSAL_PERIOD_EXTENSION_THRESHOLD = 6 hours;

    /// @notice Constructor to initialize the Venue contract with Show and Ticket contract addresses.
    /// @param _showBaseContractAddress Address of the Show contract.
    /// @param _ticketBaseContractAddress Address of the Ticket contract.
    constructor(address _showBaseContractAddress, address _ticketBaseContractAddress) {
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
        require(showInstance.isTicketOwner(msg.sender, showId), "Not a ticket owner");
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
}
