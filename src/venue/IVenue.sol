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
    event ProposalSubmitted(uint256 showId, address proposer, string venueName);
    event ProposalVoted(uint256 showId, address voter, uint256 proposalIndex);
    event ProposalAccepted(uint256 showId, uint256 proposalIndex);
    event ProposalRefunded(uint256 showId, address proposer, uint256 amount);


    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///


    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

}
