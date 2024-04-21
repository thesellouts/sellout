// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { VenueTypes } from "../types/VenueTypes.sol";
import { IShow } from "../../show/IShow.sol";
import { IShowVault } from "../../show/IShowVault.sol";
import { IVenueRegistry } from "../../registry/venue/IVenueRegistry.sol";

/// @title VenueStorageV1
/// @author taayyohh
/// @notice This contract holds all the data structures and mappings related to venues and their proposals.
contract VenueStorage is VenueTypes {
    // References to other contract interfaces that interact with this contract
    IShow public showInstance;
    IVenueRegistry public venueRegistryInstance;
    IShowVault public showVaultInstance;

    // Parameters for managing proposal periods
    uint256 public proposalPeriodDuration;
    uint256 public proposalDateExtension;
    uint256 public proposalDateMinimumFuture;
    uint256 public proposalPeriodExtensionThreshold;

    /// @notice Mapping of venue identifiers to their respective proposal periods.
    mapping(bytes32 => ProposalPeriod) public proposalPeriod;

    /// @notice Mapping of venue identifiers to lists of proposals.
    mapping(bytes32 => Proposal[]) public showProposals;

    /// @notice Mapping to track if a specific address has voted on a venue proposal.
    mapping(bytes32 => mapping(address => bool)) public hasVoted;

    /// @notice Mapping of venue identifiers to their voting periods.
    mapping(bytes32 => VotingPeriod) public votingPeriods;

    /// @notice Mapping to track if a ticket owner has voted for a venue.
    mapping(bytes32 => mapping(address => bool)) public hasTicketOwnerVoted;

    /// @notice Mapping to track the proposal index that each ticket owner has voted for.
    mapping(bytes32 => mapping(address => uint256)) public ticketOwnerVoteIndex;

    /// @notice Mapping to store the previous votes of an address for a venue.
    mapping(bytes32 => mapping(address => uint256)) public previousVote;

    /// @notice Mapping to store the votes for specific dates for a venue.
    mapping(bytes32 => mapping(uint256 => uint256)) public dateVotes;

    /// @notice Mapping to track the previous date votes of an address for a venue.
    mapping(bytes32 => mapping(address => uint256)) public previousDateVote;

    /// @notice Mapping to check if an address has voted for a date for a venue.
    mapping(bytes32 => mapping(address => bool)) public hasDateVoted;

    /// @notice Mapping to store the selected date for each venue.
    mapping(bytes32 => uint256) public selectedDate;

    /// @notice Mapping to store the index of the selected proposal for each venue.
    mapping(bytes32 => uint256) public selectedProposalIndex;

    /// @notice Mapping to track the refunds owed to proposers.
    mapping(address => uint256) public refunds;

    /// @notice Flag to indicate if ticket holder voting is active for a venue.
    mapping(bytes32 => bool) public ticketHolderVotingActive;

    /// @notice Mapping to store the ticket holder voting periods for each show.
    mapping(bytes32 => VotingPeriod) public ticketHolderVotingPeriods;
}
