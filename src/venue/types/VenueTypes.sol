// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title VenueTypes
/// @author taayyohh
/// @notice Venue Types contract defining the data structures related to venues and their proposals
interface VenueTypes {

    // Structure to represent geographical coordinates
    struct Coordinates {
        int256 lat; // Latitude, scaled by 10**6
        int256 lon; // Longitude, scaled by 10**6
    }

    // Structure to represent a venue
    struct Venue {
        string name; // Name of the venue
        Coordinates coordinates; // Geographical coordinates of the venue
        uint256 radius; // Radius of acceptable distance around venue
        uint256 totalCapacity; // Total capacity of the venue
        address wallet; // Wallet address associated with the venue
        uint256 showDate; // Date of the show at the venue
    }

    // Structure to represent a proposal for a venue
    struct Proposal {
        Venue venue; // Venue details
        uint256[] proposedDates; // Array of proposed dates for the show
        address proposer; // Address of the proposer
        uint256 bribe; // Amount of bribe offered for the proposal
        uint256 votes; // Number of votes for the proposal
        bool accepted; // Whether the proposal is accepted or not
    }

    // Structure to represent the proposal period for a venue
    struct ProposalPeriod {
        uint256 endTime; // End time of the proposal period
        bool isPeriodActive; // Whether the proposal period is active or not
    }

    // Structure to represent the voting period for a venue
    struct VotingPeriod {
        uint256 endTime; // End time of the voting period
        bool isPeriodActive; // Whether the voting period is active or not
    }

    // Structure to represent the date voting period for a venue
    struct DateVotingPeriod {
        uint256 endTime; // End time of the date voting period
        bool isPeriodActive; // Whether the date voting period is active or not
    }

}
