// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../show/Show.sol";
import "../show/types/ShowTypes.sol";
import "./storage/VenueStorage.sol";
import "./IVenue.sol";


contract Venue is IVenue, VenueStorage {
    Show public showInstance;

    constructor(address _showBaseContractAddress) {
        showInstance = Show(_showBaseContractAddress);
    }

    modifier onlyAuthorized(uint256 showId) {
        require(showInstance.isOrganizer(msg.sender, showId) || showInstance.isArtist(msg.sender, showId), "Not authorized");
        _;
    }

    function startProposalPeriod(uint256 showId) public {
        require(showInstance.getShowStatus(showId) == ShowTypes.Status.SoldOut, "Show must be SoldOut");
        proposalPeriods[showId] = ProposalPeriod(block.timestamp + 7 days, true);
    }

    function submitProposal(uint256 showId, string memory venueName, string memory latlong, uint256[] memory proposedDates) public payable {
        require(proposalPeriods[showId].isPeriodActive, "Proposal period is not active");
        require(block.timestamp <= proposalPeriods[showId].endTime, "Proposal period has ended");
        if (block.timestamp >= proposalPeriods[showId].endTime - 1 hours) {
            proposalPeriods[showId].endTime += 1 hours;
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

    function vote(uint256 showId, uint256 proposalIndex) public onlyAuthorized(showId) {
        require(!hasVoted[showId][msg.sender], "Already voted");
        showProposals[showId][proposalIndex].votes++;
        hasVoted[showId][msg.sender] = true;
        emit ProposalVoted(showId, msg.sender, proposalIndex);
    }


    function refundRejectedProposal(uint256 showId, uint256 proposalIndex) public {
        Proposal storage proposal = showProposals[showId][proposalIndex];
        require(!proposal.accepted, "Proposal was accepted");
        require(msg.sender == proposal.proposer, "Only the proposer can request a refund");
        uint256 refundAmount = proposal.bidAmount;
        proposal.bidAmount = 0;
        payable(proposal.proposer).transfer(refundAmount);
        emit ProposalRefunded(showId, proposal.proposer, refundAmount);
    }

    function getProposals(uint256 showId) public view returns (Proposal[] memory) {
        return showProposals[showId];
    }

    function acceptProposal(uint256 showId, uint256 proposalIndex) public onlyAuthorized(showId) {
        Proposal storage proposal = showProposals[showId][proposalIndex];
//        require(proposal.votes >= showBaseInstance.getNumberOfVoters(showId), "Not enough votes");
        proposal.accepted = true;
        emit ProposalAccepted(showId, proposalIndex);

        // Transferring funds to the ShowBase contract
        payable(address(showInstance)).transfer(proposal.bidAmount);
    }

    function hasUserVoted(uint256 showId, address user) public view returns (bool) {
        return hasVoted[showId][user];
    }
}
