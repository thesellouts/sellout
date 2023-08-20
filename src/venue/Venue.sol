// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../show/Show.sol";
import "../show/types/ShowTypes.sol";
import "./storage/VenueStorage.sol";
import "./IVenue.sol";
import "../ticket/Ticket.sol";

/// @title Venue Contract
/// @notice This contract manages the venue proposals, voting, and acceptance for shows.
contract Venue is IVenue, VenueStorage {
    Show public showInstance;
    Ticket public ticketInstance;

    /// @notice Constructor to initialize the Venue contract with Show and Ticket contract addresses.
    /// @param _showBaseContractAddress Address of the Show contract.
    /// @param _ticketBaseContractAddress Address of the Ticket contract.
    constructor(address _showBaseContractAddress, address _ticketBaseContractAddress) {
        showInstance = Show(_showBaseContractAddress);
        ticketInstance = Ticket(_ticketBaseContractAddress);
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
    /// @param radius Radius of the venue.
    /// @param totalCapacity Total capacity of the venue.
    /// @param proposedDates Array of proposed dates for the show.
    function submitProposal(
        bytes32 showId,
        string memory venueName,
        VenueTypes.Coordinates memory coordinates,
        uint256 radius,
        uint256 totalCapacity,
        uint256[] memory proposedDates
    ) public payable {
        require(showInstance.getShowStatus(showId) == ShowTypes.Status.SoldOut, "Show must be SoldOut");
        require(block.timestamp <= proposalPeriod[showId].endTime, "Proposal period has ended");
        require(coordinates.lat >= -90 * 10**6 && coordinates.lat <= 90 * 10**6, "Invalid latitude");
        require(coordinates.lon >= -180 * 10**6 && coordinates.lon <= 180 * 10**6, "Invalid longitude");
        require(proposedDates.length > 0, "At least one proposed date required");
        require(proposedDates.length <= 5, "Proposal must have 5 or less dates");

        for (uint256 i = 0; i < proposedDates.length; i++) {
            require(proposedDates[i] > proposalPeriod[showId].endTime + 7 days, "Proposed date must be in the future");
        }

        if (!proposalPeriod[showId].isPeriodActive) {
            startProposalPeriod(showId);
        }

        if (block.timestamp >= proposalPeriod[showId].endTime - 6 hours) {
            proposalPeriod[showId].endTime += 1 days; // Extend by 1 day if within the last 6 hours
        }

        VenueTypes.Venue memory venue;
        venue.name = venueName;
        venue.coordinates = coordinates;
        venue.radius = radius;
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
        require(votingPeriods[showId].isPeriodActive, "Voting period is not active");
        require(ticketInstance.isTicketOwner(msg.sender, showId), "Not a ticket owner");
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
        if (previousProposalIndex != proposalIndex) {
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
    }

    /// @notice Allows an authorized user (organizer or artist) to vote for a proposed date.
    /// @param showId Unique identifier for the show.
    /// @param dateIndex Index of the date to vote for.
    function voteForDate(bytes32 showId, uint256 dateIndex) public onlyAuthorized(showId) {
        require(dateIndex < showProposals[showId][selectedProposalIndex[showId]].proposedDates.length, "Invalid date index");

        uint256 previousDateIndex = previousDateVote[showId][msg.sender];
        if (previousDateIndex != dateIndex) {
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
    }

    /// @notice Accepts a proposal after voting has ended.
    /// @param showId Unique identifier for the show.
    /// @param proposalIndex Index of the proposal to accept.
    function acceptProposal(bytes32 showId, uint256 proposalIndex) internal {
        require(block.timestamp > votingPeriods[showId].endTime, "Voting period has not ended");
        Proposal storage proposal = showProposals[showId][proposalIndex];
        proposal.accepted = true;
        showInstance.updateStatus(showId, ShowTypes.Status.Accepted);
        emit ProposalAccepted(showId, proposalIndex);
    }

    /// @notice Accepts a proposed date after date voting has ended.
    /// @param showId Unique identifier for the show.
    /// @param dateIndex Index of the date to accept.
    function acceptDate(bytes32 showId, uint256 dateIndex) internal {
        require(showInstance.getShowStatus(showId) == ShowTypes.Status.Accepted, "Show must be Accepted");
        uint256 acceptedDate = showProposals[showId][selectedProposalIndex[showId]].proposedDates[dateIndex];
        selectedDate[showId] = acceptedDate;

        // Assuming proposalIndex is the index of the accepted proposal
        uint256 proposalIndex = selectedProposalIndex[showId];
        Proposal storage proposal = showProposals[showId][proposalIndex];

        // Setting the showDate for the accepted venue
        proposal.venue.showDate = acceptedDate;
        showInstance.setVenue(showId, proposal.venue);
        showInstance.updateStatus(showId, ShowTypes.Status.Upcoming);

        // Transferring funds to the Show contract if bribe exists
        if (proposal.bribe > 0) {
            payable(address(showInstance)).transfer(proposal.bribe);
        }
        calculateRefunds(showId);
        emit DateAccepted(showId, acceptedDate);
    }

    /// @notice Starts the proposal period for a show.
    /// @param showId Unique identifier for the show.
    function startProposalPeriod(bytes32 showId) public onlyOrganizer(showId) {
        require(showInstance.getShowStatus(showId) == ShowTypes.Status.SoldOut, "Show must be SoldOut");
        proposalPeriod[showId] = ProposalPeriod(block.timestamp + 7 days, true);
    }

    /// @notice Starts the voting period for a show.
    /// @param showId Unique identifier for the show.
    function startVotingPeriod(bytes32 showId) public onlyOrganizer(showId) {
        require(block.timestamp > proposalPeriod[showId].endTime, "Proposal period has not ended");
        votingPeriods[showId] = VotingPeriod(block.timestamp + 3 days, true);
    }

    /// @notice Starts the date voting period for a show.
    /// @param showId Unique identifier for the show.
    function startDateVotingPeriod(bytes32 showId) public {
        require(showProposals[showId][selectedProposalIndex[showId]].accepted, "Venue must be selected");
        dateVotingPeriods[showId] = DateVotingPeriod(block.timestamp + 3 days, true);
    }

    /// @notice Calculates refunds for all rejected proposals.
    /// @param showId Unique identifier for the show.
    function calculateRefunds(bytes32 showId) internal {
        Proposal[] storage proposals = showProposals[showId];

        for (uint256 i = 0; i < proposals.length; i++) {
            Proposal storage proposal = proposals[i];

            if (!proposal.accepted) {
                // Add the bribe to the refund owed to the proposer
                refunds[proposal.proposer] += proposal.bribe;

                // Clear the bribe from the proposal
                proposal.bribe = 0;
            }
        }
    }

    /// @notice Allows proposers to withdraw their refunds.
    function withdrawRefund() public {
        uint256 refundAmount = refunds[msg.sender];

        require(refundAmount > 0, "No refund owed");

        // Clear the refund before sending to prevent reentrancy attacks
        refunds[msg.sender] = 0;

        // Send the refund
        payable(msg.sender).transfer(refundAmount);

        emit RefundWithdrawn(msg.sender, refundAmount);
    }

    /// @notice Returns all proposals for a specific show.
    /// @param showId Unique identifier for the show.
    /// @return Array of proposals.
    function getProposals(bytes32 showId) public view returns (Proposal[] memory) {
        return showProposals[showId];
    }

    /// @notice Returns a specific proposal by index for a specific show.
    /// @param showId Unique identifier for the show.
    /// @param proposalIndex Index of the proposal.
    /// @return Proposal object.
    function getProposalById(bytes32 showId, uint256 proposalIndex) public view returns (Proposal memory) {
        require(proposalIndex < showProposals[showId].length, "Invalid proposal index");
        return showProposals[showId][proposalIndex];
    }

    /// @notice Checks if a user has voted for a specific show.
    /// @param showId Unique identifier for the show.
    /// @param user Address of the user.
    /// @return Boolean indicating if the user has voted.
    function hasUserVoted(bytes32 showId, address user) public view returns (bool) {
        return hasVoted[showId][user];
    }
}
