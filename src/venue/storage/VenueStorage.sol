// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


import "../types/VenueTypes.sol";


/// @title VenueStorageV1
/// @author taayyohh
/// @notice Venue Storage contract
contract VenueStorage is VenueTypes {
    mapping(bytes32 => ProposalPeriod) public proposalPeriods;
    mapping(bytes32 => Proposal[]) public showProposals;
    mapping(bytes32 => mapping(address => bool)) public hasVoted;

}

