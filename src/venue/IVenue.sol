// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { VenueTypes } from "./storage/VenueStorage.sol";

/// @title IVenue Interface
/// @author taayyohh
/// @notice This interface defines the methods for the Venue contract.
interface IVenue {

    /// @notice Emitted when a new venue proposal is submitted.
    /// @param showId Unique identifier for the show.
    /// @param proposer Address of the proposer.
    /// @param venueName Name of the proposed venue.
    event ProposalSubmitted(bytes32 indexed showId, address indexed proposer, string venueName);

    /// @notice Emitted when a ticket holder votes for a venue proposal.
    /// @param showId Unique identifier for the show.
    /// @param voter Address of the voter.
    /// @param proposalIndex Index of the proposal being voted for.
    event VenueVoted(bytes32 indexed showId, address indexed voter, uint256 proposalIndex);

    /// @notice Emitted when an authorized user (organizer or artist) votes for a venue proposal.
    /// @param showId Unique identifier for the show.
    /// @param voter Address of the voter.
    /// @param proposalIndex Index of the proposal being voted for.
    event ProposalVoted(bytes32 indexed showId, address indexed voter, uint256 proposalIndex);

    /// @notice Emitted when an authorized user (organizer or artist) votes for a proposed date.
    /// @param showId Unique identifier for the show.
    /// @param voter Address of the voter.
    /// @param dateIndex Index of the date being voted for.
    event DateVoted(bytes32 indexed showId, address indexed voter, uint256 dateIndex);

    /// @notice Emitted when a proposal period starts.
    /// @param showId Unique identifier for the show.
    /// @param endTime End time of the proposal period.
    event ProposalPeriodStarted(bytes32 indexed showId, uint256 endTime);

    /// @notice Emitted when a public voting period starts.
    /// @param showId Unique identifier for the show.
    /// @param endTime End time of the voting period.
    event PublicVotingPeriodStarted(bytes32 indexed showId, uint256 endTime);

    /// @notice Emitted when a proposal is accepted.
    /// @param showId Unique identifier for the show.
    /// @param proposalIndex Index of the accepted proposal.
    event ProposalAccepted(bytes32 indexed showId, uint256 proposalIndex);

    /// @notice Emitted when a date is accepted.
    /// @param showId Unique identifier for the show.
    /// @param dateIndex Index of the accepted date.
    event DateAccepted(bytes32 indexed showId, uint256 dateIndex);

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
    ) external payable;

    /// @notice Allows a ticket holder to vote for a venue proposal.
    /// @param showId Unique identifier for the show.
    /// @param proposalIndex Index of the proposal to vote for.
    function ticketHolderVenueVote(bytes32 showId, uint256 proposalIndex) external;

    /// @notice Allows an authorized user (organizer or artist) to vote for a venue proposal.
    /// @param showId Unique identifier for the show.
    /// @param proposalIndex Index of the proposal to vote for.
    function vote(bytes32 showId, uint256 proposalIndex) external;

    /// @notice Allows an authorized user (organizer or artist) to vote for a proposed date.
    /// @param showId Unique identifier for the show.
    /// @param dateIndex Index of the date to vote for.
    function voteForDate(bytes32 showId, uint256 dateIndex) external;
}
