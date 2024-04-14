// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { VenueStorage } from "./storage/VenueStorage.sol";
import { IVenue } from "./IVenue.sol";
import { VenueTypes } from "./types/VenueTypes.sol";
import { IVenueRegistry } from "../registry/venue/IVenueRegistry.sol";
import { VenueRegistryTypes } from "../registry/venue/types/VenueRegistryTypes.sol";
import { IShow } from "../show/IShow.sol";
import { ShowTypes } from "../show/storage/ShowStorage.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from  "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/// @title Venue Contract
/// @author taayyohh
/// @notice This contract manages the venue proposals, voting, and acceptance for shows.
contract Venue is Initializable, IVenue, VenueStorage, UUPSUpgradeable, OwnableUpgradeable {
    IShow public showInstance;
    IVenueRegistry public venueRegistryInstance;

    // Add variables for storing the duration constants
    uint256 public proposalPeriodDuration;
    uint256 public proposalDateExtension;
    uint256 public proposalDateMinimumFuture;
    uint256 public proposalPeriodExtensionThreshold;

    /// @notice Initializes the Venue contract with Show and Ticket contract addresses and proposal period settings.
    /// @param initialOwner Address of the initial owner of the venue.
    /// @param _proposalPeriodDuration Duration in seconds for how long the proposal period lasts.
    /// @param _proposalDateExtension Duration in seconds by which the proposal date is extended upon certain conditions.
    /// @param _proposalDateMinimumFuture Duration in seconds to set the minimum future date for a proposal from the current time.
    /// @param _proposalPeriodExtensionThreshold Duration in seconds to set the threshold for extending the proposal period.
    function initialize(
        address initialOwner,
        uint256 _proposalPeriodDuration,
        uint256 _proposalDateExtension,
        uint256 _proposalDateMinimumFuture,
        uint256 _proposalPeriodExtensionThreshold
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        proposalPeriodDuration = _proposalPeriodDuration;
        proposalDateExtension = _proposalDateExtension;
        proposalDateMinimumFuture = _proposalDateMinimumFuture;
        proposalPeriodExtensionThreshold = _proposalPeriodExtensionThreshold;
    }

    modifier onlyOrganizer(bytes32 showId) {
        require(showInstance.isOrganizer(msg.sender, showId), "!o");
        _;
    }

    modifier onlyAuthorized(bytes32 showId) {
        require(showInstance.isOrganizer(msg.sender, showId) || showInstance.isArtist(msg.sender, showId), "!au");
        _;
    }

    modifier onlyShowContract() {
        require(msg.sender == address(showInstance), "!s");
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Submits a venue proposal for a specific show using the venue's token ID.
    /// @param showId The unique identifier for the show.
    /// @param venueId The token ID of the venue, which references the venue's details.
    /// @param proposedDates List of potential dates for the show.
    /// @param paymentToken ERC20 token address for bribe payment (address(0) for ETH).
    function submitProposal(
        bytes32 showId,
        uint256 venueId,
        uint256[] memory proposedDates,
        address paymentToken
    ) public payable {
        require(venueRegistryInstance.isVenueRegistered(msg.sender), "Venue not registered");

        validateProposalSubmission(showId, proposedDates);
        if (!proposalPeriod[showId].isPeriodActive) {
            startProposalPeriod(showId);
        }
        adjustProposalPeriodIfNeeded(showId);

        VenueRegistryTypes.VenueInfo memory venueInfo = venueRegistryInstance.getVenueById(venueId);

        uint256 bribeAmount = processPayment(showId, paymentToken);
        storeProposal(showId, venueInfo, proposedDates, bribeAmount, paymentToken);
    }


    /// @dev Validates the proposal submission parameters.
    /// @param showId Unique identifier for the show.
    /// @param proposedDates List of potential dates for the event.
    function validateProposalSubmission(bytes32 showId, uint256[] memory proposedDates) private view {
        require(showInstance.getShowStatus(showId) == ShowTypes.Status.SoldOut, "Show not in 'Sold Out' status");
        require(proposalPeriod[showId].endTime == 0 || block.timestamp <= proposalPeriod[showId].endTime, "Proposal period ended");
        require(proposedDates.length > 0 && proposedDates.length <= 5, "Invalid number of proposed dates");
    }

    // @dev Adjusts the proposal period if necessary based on current time.
    // @param showId Unique identifier for the show.
    function adjustProposalPeriodIfNeeded(bytes32 showId) private {
        if (block.timestamp >= proposalPeriod[showId].endTime - proposalPeriodExtensionThreshold) {
            proposalPeriod[showId].endTime += proposalDateExtension; // Extend if within the last hours
        }
    }

    /// @dev Stores the proposal in the contract state.
    /// @param showId Unique identifier for the show.
    /// @param venue Venue details for the proposal.
    /// @param proposedDates List of potential dates for the show.
    /// @param bribeAmount Amount of bribe paid to prioritize the proposal.
    /// @dev Stores the proposal in the contract state.
/// @param showId Unique identifier for the show.
/// @param venue Venue details for the proposal.
/// @param proposedDates List of potential dates for the show.
/// @param bribeAmount Amount of bribe paid to prioritize the proposal.
/// @param paymentToken Token used for the bribe payment.
    function storeProposal(
        bytes32 showId,
        VenueRegistryTypes.VenueInfo memory venue,
        uint256[] memory proposedDates,
        uint256 bribeAmount,
        address paymentToken
    ) private {
        VenueTypes.Proposal memory proposal = VenueTypes.Proposal({
            venue: venue,
            proposedDates: proposedDates,
            proposer: msg.sender,
            bribe: bribeAmount,
            votes: 0,
            accepted: false,
            paymentToken: paymentToken
        });
        showProposals[showId].push(proposal);
        emit ProposalSubmitted(showId, msg.sender, venue.name, bribeAmount);
    }

    // @dev Processes the payment for a proposal, either in ETH or ERC20, with the possibility of zero payment.
    // @param showId The show identifier the proposal is for.
    // @param paymentToken ERC20 token address, or address(0) for ETH.
    // @return The amount of bribe paid.
    function processPayment(bytes32 showId, address paymentToken) private returns (uint256) {
        uint256 bribeAmount = msg.value;
        if (paymentToken == address(0)) {
            if (msg.value > 0) {
                showInstance.depositToVault{value: msg.value}(showId);
            }
        } else {
            require(msg.value == 0, "Do not send ETH with ERC20 payment");
            ERC20Upgradeable token = ERC20Upgradeable(paymentToken);
            bribeAmount = token.allowance(msg.sender, address(this));
            if (bribeAmount > 0) {
                token.transferFrom(msg.sender, address(this), bribeAmount);
                showInstance.depositToVaultERC20(showId, bribeAmount, paymentToken, msg.sender);
            }
        }
        return bribeAmount;
    }

    /// @notice Allows a ticket holder to vote for a venue proposal during the proposal period, or switch their vote.
    /// @param showId Unique identifier for the show.
    /// @param proposalIndex Index of the proposal to vote for.
    function ticketHolderVenueVote(bytes32 showId, uint256 proposalIndex) public {
        require(showInstance.hasTicket(msg.sender, showId), "Not a ticket owner");
        require(block.timestamp <= proposalPeriod[showId].endTime, "Proposal period has ended");
        require(proposalIndex < showProposals[showId].length, "Invalid proposal index");

        if (hasTicketOwnerVoted[showId][msg.sender]) {
            // User has voted before; check if they're changing their vote
            uint256 currentVoteIndex = ticketOwnerVoteIndex[showId][msg.sender];
            require(currentVoteIndex != proposalIndex, "Already voted for this proposal");

            // Decrement the vote for their previous choice, ensuring no underflow
            showProposals[showId][currentVoteIndex].votes -= 1;
        }

        // Increment the vote for their new choice
        showProposals[showId][proposalIndex].votes++;
        ticketOwnerVoteIndex[showId][msg.sender] = proposalIndex;
        hasTicketOwnerVoted[showId][msg.sender] = true; // Mark the voter as having voted

        emit VenueVoted(showId, msg.sender, proposalIndex);
    }

    /// @notice Allows an authorized user (organizer or artist) to vote for a venue proposal.
    /// @param showId Unique identifier for the show.
    /// @param proposalIndex Index of the proposal to vote for.
    function vote(bytes32 showId, uint256 proposalIndex) public onlyAuthorized(showId) {
        require(proposalIndex < showProposals[showId].length, "Invalid proposal index");
        require(proposalPeriod[showId].endTime != 0 && block.timestamp > proposalPeriod[showId].endTime, "Voting period has not ended yet");
        require(!ticketHolderVotingActive[showId] || block.timestamp > ticketHolderVotingPeriods[showId].endTime, "Ticket holder voting phase must conclude first");

        bool hasVotedBefore = hasVoted[showId][msg.sender];
        uint256 previousProposalIndex = previousVote[showId][msg.sender];

        // Check if the user is trying to vote for a different proposal
        if(hasVotedBefore) {
            require(previousProposalIndex != proposalIndex, "Already voted for this venue");
            // Decrement the vote count for the previously voted proposal
            showProposals[showId][previousProposalIndex].votes--;
        }

        // Increment the vote count for the newly voted proposal
        showProposals[showId][proposalIndex].votes++;
        hasVoted[showId][msg.sender] = true;
        previousVote[showId][msg.sender] = proposalIndex; // Update the user's previous vote
        emit ProposalVoted(showId, msg.sender, proposalIndex);

        // Check if all required votes have been received
        uint256 requiredVotes = showInstance.getNumberOfVoters(showId);
        if (showProposals[showId][proposalIndex].votes >= requiredVotes) {
            // If the proposal reaches the required votes, accept the proposal
            acceptProposal(showId, proposalIndex);
        }
    }

    /// @notice Accepts a proposal once it has received the required votes.
    /// @param showId Unique identifier for the show.
    /// @param proposalIndex Index of the proposal to accept.
    function acceptProposal(bytes32 showId, uint256 proposalIndex) internal {
        require(proposalIndex < showProposals[showId].length, "Invalid proposal index");
        VenueRegistryTypes.VenueInfo memory venue = showProposals[showId][proposalIndex].venue;
        showProposals[showId][proposalIndex].accepted = true;
        selectedProposalIndex[showId] = proposalIndex;

        // Update show status to indicate that a venue has been selected
        showInstance.updateStatus(showId, ShowTypes.Status.Accepted);

        // Update the venue information in the Show contract
        showInstance.updateShowVenue(showId, venue);

        emit ProposalAccepted(showId, proposalIndex);
    }

    /// @notice Allows an authorized user (organizer or artist) to vote for a proposed date.
    /// @param showId Unique identifier for the show.
    /// @param dateIndex Index of the date to vote for.
    function voteForDate(bytes32 showId, uint256 dateIndex) public onlyAuthorized(showId) {
        // Ensure the selected proposal index is valid for the showId.
        require(selectedProposalIndex[showId] < showProposals[showId].length, "No selected proposal for this show");

        // Ensure the dateIndex is within the range of proposed dates for the selected proposal.
        require(dateIndex < showProposals[showId][selectedProposalIndex[showId]].proposedDates.length, "Invalid date index");

        // Checking if the voting period has ended is critical for date voting as well.
        require(proposalPeriod[showId].endTime != 0 && block.timestamp > proposalPeriod[showId].endTime, "Voting period has not ended yet");

        bool hasVotedForDateBefore = hasDateVoted[showId][msg.sender];
        uint256 previousDateIndex = previousDateVote[showId][msg.sender];

        // Allow changing the vote to a different date
        if (hasVotedForDateBefore && previousDateIndex != dateIndex) {
            // Safe to decrement as Solidity 0.8.x handles underflow by reverting
            dateVotes[showId][previousDateIndex]--;
        }

        // Increment the vote count for the new date
        dateVotes[showId][dateIndex]++;
        hasDateVoted[showId][msg.sender] = true;
        previousDateVote[showId][msg.sender] = dateIndex;
        emit DateVoted(showId, msg.sender, dateIndex);

        // Check if all required votes have been received to accept the date
        uint256 requiredVotes = showInstance.getNumberOfVoters(showId);
        if (dateVotes[showId][dateIndex] >= requiredVotes) {
            acceptDate(showId, dateIndex);
        }
    }

    /// @notice Accepts a proposed date after date voting has ended.
    /// @dev Updates the selected date for the show and sets the show's status to Upcoming.
    /// @param showId Unique identifier for the show.
    /// @param dateIndex Index of the proposed date to accept.
    function acceptDate(bytes32 showId, uint256 dateIndex) internal {
        // Assuming dateIndex is valid and within the range of proposedDates
        // for the selected proposal
        uint256 acceptedDate = showProposals[showId][selectedProposalIndex[showId]].proposedDates[dateIndex];
        selectedDate[showId] = acceptedDate;
        showInstance.updateShowDate(showId, acceptedDate);

        emit DateAccepted(showId, acceptedDate);

        // Update the show's status to Upcoming
        showInstance.updateStatus(showId, ShowTypes.Status.Upcoming);
    }

    /// @notice Starts the proposal period for a show.
    /// @param showId Unique identifier for the show.
    function startProposalPeriod(bytes32 showId) internal {
        proposalPeriod[showId].isPeriodActive = true;
        proposalPeriod[showId].endTime = block.timestamp + proposalPeriodDuration;
        ticketHolderVotingActive[showId] = true;
        ticketHolderVotingPeriods[showId] = VenueTypes.VotingPeriod({
            endTime: proposalPeriod[showId].endTime, // Ticket holder voting ends when proposal period ends
            isPeriodActive: true
        });

        emit ProposalPeriodStarted(showId, proposalPeriod[showId].endTime);
    }

    // Updated to set both Show and Venue Registry addresses
    function setShowAndVenueRegistryAddresses(address _showContractAddress, address _venueRegistryAddress) external {
        require(address(showInstance) == address(0), "Show contract already set");
        require(address(venueRegistryInstance) == address(0), "Venue registry already set");

        showInstance = IShow(_showContractAddress);
        venueRegistryInstance = IVenueRegistry(_venueRegistryAddress);
    }

    function resetBribe(bytes32 showId, uint256 proposalIndex) external onlyShowContract {
        require(proposalIndex < showProposals[showId].length, "Invalid proposal index");

        VenueTypes.Proposal memory proposal = showProposals[showId][proposalIndex];
        proposal.bribe = 0;
    }

    /// @notice Retrieves the proposal period for a specific venue.
    /// @param showId The unique identifier of the venue.
    /// @return The proposal period of the venue.
    function getProposalPeriod(bytes32 showId) public view returns (ProposalPeriod memory) {
        return proposalPeriod[showId];
    }

    /// @notice Retrieves all the proposals for a specific venue.
    /// @param showId The unique identifier of the venue.
    /// @return An array of proposals for the venue.
    function getShowProposals(bytes32 showId) public view returns (Proposal[] memory) {
        return showProposals[showId];
    }

    function getProposal(bytes32 showId, uint256 proposalIndex) external view returns (Proposal memory) {
        return showProposals[showId][proposalIndex];
    }

    function getProposalsCount(bytes32 showId) external view returns (uint256) {
        return showProposals[showId].length;
    }

    /// @notice Checks if a specific address has voted for a venue proposal.
    /// @param showId The unique identifier of the venue.
    /// @param user The address of the user.
    /// @return True if the user has voted, false otherwise.
    function getHasVoted(bytes32 showId, address user) public view returns (bool) {
        return hasVoted[showId][user];
    }

    /// @notice Retrieves the voting period for a specific venue.
    /// @param showId The unique identifier of the venue.
    /// @return The voting period of the venue.
    function getVotingPeriods(bytes32 showId) public view returns (VotingPeriod memory) {
        return votingPeriods[showId];
    }

    /// @notice Checks if a ticket owner has voted for a venue.
    /// @param showId The unique identifier of the venue.
    /// @param user The address of the user.
    /// @return True if the ticket owner has voted, false otherwise.
    function getHasTicketOwnerVoted(bytes32 showId, address user) public view returns (bool) {
        return hasTicketOwnerVoted[showId][user];
    }

    /// @notice Retrieves the previous vote of an address for a venue.
    /// @param showId The unique identifier of the venue.
    /// @param user The address of the user.
    /// @return The previous vote of the user.
    function getPreviousVote(bytes32 showId, address user) public view returns (uint256) {
        return previousVote[showId][user];
    }

    /// @notice Retrieves the votes for specific dates for a show.
    /// @param showId The unique identifier of the show.
    /// @param date The date for which votes are being queried.
    /// @return The number of votes for the specified date.
    function getDateVotes(bytes32 showId, uint256 date) public view returns (uint256) {
        return dateVotes[showId][date];
    }

    /// @notice Retrieves the previous date vote of an address for a show.
    /// @param showId The unique identifier of the show.
    /// @param user The address of the user.
    /// @return The previous date vote of the user.
    function getPreviousDateVote(bytes32 showId, address user) public view returns (uint256) {
        return previousDateVote[showId][user];
    }

    /// @notice Checks if an address has voted for a date for a show.
    /// @param showId The unique identifier of the show.
    /// @param user The address of the user.
    /// @return True if the user has voted for a date, false otherwise.
    function getHasDateVoted(bytes32 showId, address user) public view returns (bool) {
        return hasDateVoted[showId][user];
    }

    /// @notice Retrieves the selected date for each show.
    /// @param showId The unique identifier of the show.
    /// @return The selected date for the show.
    function getSelectedDate(bytes32 showId) public view returns (uint256) {
        return selectedDate[showId];
    }

    /// @notice Retrieves the index of the selected proposal for each show.
    /// @param showId The unique identifier of the show.
    /// @return The index of the selected proposal for the show.
    function getSelectedProposalIndex(bytes32 showId) public view returns (uint256) {
        return selectedProposalIndex[showId];
    }

    /// @notice Retrieves the refunds owed to a proposer.
    /// @param user The address of the user (proposer).
    /// @return The amount of refund owed to the proposer.
    function getRefunds(address user) public view returns (uint256) {
        return refunds[user];
    }
}
