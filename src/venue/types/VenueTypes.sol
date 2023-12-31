// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title VenueTypes
/// @author taayyohh
/// @notice This contract defines the data structures related to venues and their proposals.
interface VenueTypes {

    /// @notice Represents geographical coordinates with latitude and longitude scaled by 10**6.
    struct Coordinates {
        int256 lat; // Latitude, scaled by 10**6
        int256 lon; // Longitude, scaled by 10**6
    }

    /// @notice Represents details about a venue including its name, location, capacity, and associated wallet.
    struct Venue {
        string name; // Name of the venue
        Coordinates coordinates; // Geographical coordinates of the venue
        uint256 totalCapacity; // Total capacity of the venue
        address wallet; // Wallet address associated with the venue
    }

    /// @notice Represents a proposal for a venue including details about the venue, proposed dates, and voting information.
    struct Proposal {
        Venue venue; // Venue details
        uint256[] proposedDates; // Array of proposed dates for the show
        address proposer; // Address of the proposer
        uint256 bribe; // Amount of bribe offered for the proposal
        uint256 votes; // Number of votes for the proposal
        bool accepted; // Whether the proposal is accepted or not
    }

    /// @notice Represents the time period during which venue proposals can be submitted.
    struct ProposalPeriod {
        uint256 endTime; // End time of the proposal period
        bool isPeriodActive; // Whether the proposal period is active or not
    }

    /// @notice Represents the time period during which votes for venue proposals can be cast.
    struct VotingPeriod {
        uint256 endTime; // End time of the voting period
        bool isPeriodActive; // Whether the voting period is active or not
    }

    /// @notice Represents the time period during which votes for proposed show dates can be cast.
    struct DateVotingPeriod {
        uint256 endTime; // End time of the date voting period
        bool isPeriodActive; // Whether the date voting period is active or not
    }
}
