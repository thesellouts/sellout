// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


import "./types/VenueTypes.sol";


/// @title IVenue
/// @author taayyohh
/// @notice The external Ticket events, errors and functions
interface IVenue is VenueTypes {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///
    event ProposalSubmitted(bytes32 showId, address proposer, string venueName);
    event ProposalVoted(bytes32 showId, address voter, uint256 proposalIndex);
    event ProposalAccepted(bytes32 showId, uint256 proposalIndex);
    event ProposalRefunded(bytes32 showId, address proposer, uint256 amount);
    event VenueVoted(bytes32 indexed showId, address indexed voter, uint256 proposalIndex);



    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///


    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

}
