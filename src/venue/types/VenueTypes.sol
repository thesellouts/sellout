// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import { VenueRegistryTypes } from "../../registry/venue/types/VenueRegistryTypes.sol";

/// @title VenueTypes
/// @author taayyohh
/// @notice This contract defines the data structures related to venues and their proposals.
interface VenueTypes {
    /// @notice Defines the parameters for a venue proposal period.
    /// @dev This structure is used when setting up or modifying the rules for venue proposal submissions.
    struct VenueProposalParams {
        uint32 proposalPeriodDuration;
        uint32 proposalDateExtension;
        uint32 proposalDateMinimumFuture;
        uint32 proposalPeriodExtensionThreshold;
    }

    /// @notice Describes a venue proposal including operational details, voting, and bribes.
    /// @dev This structure captures all relevant information about a venue proposal.
    struct Proposal {
        VenueRegistryTypes.VenueInfo venue; // Venue details
        uint256[] proposedDates; // Array of proposed dates for the show
        address proposer; // Address of the proposer
        uint256 bribe; // Amount of bribe offered for the proposal
        uint256 votes; // Number of votes for the proposal
        bool accepted; // Whether the proposal is accepted or not
        address paymentToken; // ERC20 token address for the bribe (address(0) for ETH)
    }

    /// @notice Represents the time period during which venue proposals can be submitted.
    struct ProposalPeriod {
        uint256 endTime; // End time of the proposal period
        bool hasProposalPeriodStarted; // Whether the proposal period is active or not
    }

    /// @notice Represents the time period during which votes for venue proposals can be cast.
    struct VotingPeriod {
        uint256 endTime; // End time of the voting period
        bool hasProposalPeriodStarted; // Whether the voting period is active or not
    }

    /// @notice Represents the time period during which votes for proposed show dates can be cast.
    struct DateVotingPeriod {
        uint256 endTime; // End time of the date voting period
        bool hasProposalPeriodStarted; // Whether the date voting period is active or not
    }
}
