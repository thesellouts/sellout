// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { VenueTypes } from "../types/VenueTypes.sol";


/// @title VenueStorageV1
/// @author taayyohh
/// @notice Venue Storage contract that holds all the data structures and mappings related to venues and their proposals
contract VenueStorage is VenueTypes {

    // Mapping to store the proposal period for each venue
    mapping(bytes32 => ProposalPeriod) public proposalPeriod;

    // Mapping to store all the proposals for a specific venue
    mapping(bytes32 => Proposal[]) public showProposals;

    // Mapping to check if a specific address has voted for a venue proposal
    mapping(bytes32 => mapping(address => bool)) public hasVoted;

    // Mapping to store the voting period for each venue
    mapping(bytes32 => VotingPeriod) public votingPeriods;

    // Mapping to check if a ticket owner has voted for a venue
    mapping(bytes32 => mapping(address => bool)) public hasTicketOwnerVoted;

    // Mapping to store the previous vote of an address for a venue
    mapping(bytes32 => mapping(address => uint256)) public previousVote;

    // Mapping to store the votes for specific dates for a venue
    mapping(bytes32 => mapping(uint256 => uint256)) public dateVotes;

    // Mapping to store the previous date vote of an address for a venue
    mapping(bytes32 => mapping(address => uint256)) public previousDateVote;

    // Mapping to check if an address has voted for a date for a venue
    mapping(bytes32 => mapping(address => bool)) public hasDateVoted;

    // Mapping to store the selected date for each venue
    mapping(bytes32 => uint256) public selectedDate;

    // Mapping to store the index of the selected proposal for each venue
    mapping(bytes32 => uint256) public selectedProposalIndex;

    // Mapping to track the refunds owed to proposers
    mapping(address => uint256) public refunds;
}
