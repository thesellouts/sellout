// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


import "../types/VenueTypes.sol";


/// @title VenueStorageV1
/// @author taayyohh
/// @notice Venue Storage contract
contract VenueStorage is VenueTypes {
    mapping(uint256 => ProposalPeriod) public proposalPeriods;
    mapping(uint256 => Proposal[]) public showProposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

}

