// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title VenueTypes
/// @author taayyohh
/// @notice Venue Types contract
interface VenueTypes {

    struct Proposal {
        uint256 bidAmount;
        string venueName;
        string latlong;
        uint256[] proposedDates;
        address proposer;
        bool accepted;
        uint256 votes;
    }

    struct ProposalPeriod {
        uint256 endTime;
        bool isPeriodActive;
    }

}
