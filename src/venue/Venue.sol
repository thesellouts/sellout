// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../show/Show.sol";
import "../show/types/ShowTypes.sol";
import "./storage/VenueStorage.sol";
import "./IVenue.sol";
import "../ticket/Ticket.sol";

contract Venue is IVenue, VenueStorage {
    Show public showInstance;
    Ticket public ticketInstance;

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

    function startProposalPeriod(bytes32 showId) public onlyOrganizer(showId) {
        require(showInstance.getShowStatus(showId) == ShowTypes.Status.SoldOut, "Show must be SoldOut");
        proposalPeriods[showId] = ProposalPeriod(block.timestamp + 7 days, true);
    }

    function submitProposal(bytes32 showId, string memory venueName, string memory latlong, uint256[] memory proposedDates) public payable {
        require(proposalPeriods[showId].isPeriodActive, "Proposal period is not active");
        require(block.timestamp <= proposalPeriods[showId].endTime, "Proposal period has ended");

        // Validate proposed dates
        for (uint256 i = 0; i < proposedDates.length; i++) {
            require(proposedDates[i] > block.timestamp, "Proposed date must be in the future");
        }

        if (block.timestamp >= proposalPeriods[showId].endTime - 6 hours) {
            proposalPeriods[showId].endTime += 1 days; // Extend by 1 day if within the last 6 hours
        }

        Proposal memory proposal;
        proposal.bidAmount = msg.value;
        proposal.venueName = venueName;
        proposal.latlong = latlong;
        proposal.proposedDates = proposedDates;
        proposal.proposer = msg.sender;
        proposal.accepted = false;
        proposal.votes = 0;
        showProposals[showId].push(proposal);
        emit ProposalSubmitted(showId, msg.sender, venueName);
    }

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

    function startVotingPeriod(bytes32 showId) public onlyOrganizer(showId) {
        require(block.timestamp > proposalPeriods[showId].endTime, "Proposal period has not ended");
        votingPeriods[showId] = VotingPeriod(block.timestamp + 3 days, true);
    }

    function voteForVenue(bytes32 showId, uint256 proposalIndex) public {
        require(votingPeriods[showId].isPeriodActive, "Voting period is not active");
        require(ticketInstance.isTicketOwner(msg.sender, showId), "Not a ticket owner");
        require(!hasTicketOwnerVoted[showId][msg.sender], "Already voted");
        showProposals[showId][proposalIndex].votes++;
        hasTicketOwnerVoted[showId][msg.sender] = true;
        emit VenueVoted(showId, msg.sender, proposalIndex);
    }

    function acceptProposal(bytes32 showId, uint256 proposalIndex) internal {
        require(block.timestamp > votingPeriods[showId].endTime, "Voting period has not ended");
        Proposal storage proposal = showProposals[showId][proposalIndex];
        proposal.accepted = true;
        emit ProposalAccepted(showId, proposalIndex);

        // Transferring funds to the ShowBase contract
        payable(address(showInstance)).transfer(proposal.bidAmount);
    }

    function refundRejectedProposal(bytes32 showId, uint256 proposalIndex) public {
        Proposal storage proposal = showProposals[showId][proposalIndex];
        require(!proposal.accepted, "Proposal was accepted");
        require(msg.sender == proposal.proposer, "Only the proposer can request a refund");
        uint256 refundAmount = proposal.bidAmount;
        proposal.bidAmount = 0;
        payable(proposal.proposer).transfer(refundAmount);
        emit ProposalRefunded(showId, proposal.proposer, refundAmount);
    }

    function getProposals(bytes32 showId) public view returns (Proposal[] memory) {
        return showProposals[showId];
    }

    function hasUserVoted(bytes32 showId, address user) public view returns (bool) {
        return hasVoted[showId][user];
    }
}
