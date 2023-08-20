// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./types/VenueTypes.sol";

/// @title IVenue
/// @author taayyohh
/// @notice The external Venue events, errors, and functions
interface IVenue is VenueTypes {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when a new proposal is submitted
    /// @param showId Unique identifier for the show
    /// @param proposer Address of the proposer
    /// @param venueName Name of the venue
    event ProposalSubmitted(bytes32 showId, address proposer, string venueName);

    /// @notice Emitted when a proposal is voted on
    /// @param showId Unique identifier for the show
    /// @param voter Address of the voter
    /// @param proposalIndex Index of the proposal
    event ProposalVoted(bytes32 showId, address voter, uint256 proposalIndex);

    /// @notice Emitted when a proposal is accepted
    /// @param showId Unique identifier for the show
    /// @param proposalIndex Index of the accepted proposal
    event ProposalAccepted(bytes32 showId, uint256 proposalIndex);

    /// @notice Emitted when a proposal is refunded
    /// @param showId Unique identifier for the show
    /// @param proposer Address of the proposer
    /// @param amount Amount refunded
    event ProposalRefunded(bytes32 showId, address proposer, uint256 amount);

    /// @notice Emitted when a venue is voted on by a ticket holder
    /// @param showId Unique identifier for the show
    /// @param voter Address of the voter
    /// @param proposalIndex Index of the proposal
    event VenueVoted(bytes32 indexed showId, address indexed voter, uint256 proposalIndex);

    /// @notice Emitted when a venue is accepted
    /// @param showId Unique identifier for the show
    /// @param proposalIndex Index of the accepted proposal
    event VenueAccepted(bytes32 showId, uint256 proposalIndex);

    /// @notice Emitted when a date is voted on
    /// @param showId Unique identifier for the show
    /// @param voter Address of the voter
    /// @param dateIndex Index of the date
    event DateVoted(bytes32 indexed showId, address indexed voter, uint256 dateIndex);

    /// @notice Emitted when a date is accepted
    /// @param showId Unique identifier for the show
    /// @param date Accepted date
    event DateAccepted(bytes32 showId, uint256 date);

    /// @notice Emitted when a refund is withdrawn
    /// @param withdrawer Address of the withdrawer
    /// @param refundAmount Amount withdrawn
    event RefundWithdrawn(address indexed withdrawer, uint256 refundAmount);

    /// @notice Submit a proposal for a venue for a specific show
    function submitProposal(
        bytes32 showId,
        string memory venueName,
        VenueTypes.Coordinates memory coordinates,
        uint256 radius,
        uint256 totalCapacity,
        uint256[] memory proposedDates
    ) external payable;

    /// @notice Allows a ticket holder to vote for a venue proposal
    function ticketHolderVenueVote(bytes32 showId, uint256 proposalIndex) external;

    /// @notice Allows an authorized user (organizer or artist) to vote for a venue proposal
    function vote(bytes32 showId, uint256 proposalIndex) external;

    /// @notice Allows an authorized user (organizer or artist) to vote for a proposed date
    function voteForDate(bytes32 showId, uint256 dateIndex) external;

    /// @notice Starts the proposal period for a show
    function startProposalPeriod(bytes32 showId) external;

    /// @notice Starts the voting period for a show
    function startVotingPeriod(bytes32 showId) external;

    /// @notice Starts the date voting period for a show
    function startDateVotingPeriod(bytes32 showId) external;

    /// @notice Allows proposers to withdraw their refunds
    function withdrawRefund() external;

    /// @notice Returns all proposals for a specific show
    function getProposals(bytes32 showId) external view returns (Proposal[] memory);

    /// @notice Returns a specific proposal by index for a specific show
    function getProposalById(bytes32 showId, uint256 proposalIndex) external view returns (Proposal memory);

    /// @notice Checks if a user has voted for a specific show
    function hasUserVoted(bytes32 showId, address user) external view returns (bool);
}
