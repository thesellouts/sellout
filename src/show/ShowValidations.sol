// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ShowTypes } from "./types/ShowTypes.sol";

library ShowValidations {
    error InvalidName();
    error InvalidDescription();
    error InvalidCapacity();
    error InvalidSellOutThreshold();
    error InvalidLatitude();
    error InvalidLongitude();
    error InvalidSplitArrayLength();
    error InvalidSplitSum();
    error InvalidVenueProposalParameters();
    error TicketCapacityMismatch();

    /// @notice Validates the main aspects of a show proposal.
    /// @param proposal The ShowProposal struct containing the details to be validated.
    function validateShowProposal(
        ShowTypes.ShowProposal memory proposal
    ) internal pure {
        if (bytes(proposal.name).length == 0) revert InvalidName();
        if (proposal.radius <= 0) revert InvalidCapacity();
        if (bytes(proposal.description).length == 0 || bytes(proposal.description).length > 1000) revert InvalidDescription();
        if (proposal.totalCapacity < 50) revert InvalidCapacity();
        if (proposal.sellOutThreshold < 50 || proposal.sellOutThreshold > 100) revert InvalidSellOutThreshold();
        if (proposal.coordinates.latitude < -90 * 10**6 || proposal.coordinates.latitude > 90 * 10**6) revert InvalidLatitude();
        if (proposal.coordinates.longitude < -180 * 10**6 || proposal.coordinates.longitude > 180 * 10**6) revert InvalidLongitude();
        if (proposal.venueProposalParams.proposalPeriodDuration < 30 minutes) revert InvalidVenueProposalParameters();
        if (proposal.venueProposalParams.proposalDateExtension < 5 minutes) revert InvalidVenueProposalParameters();
        if (proposal.venueProposalParams.proposalDateMinimumFuture < 45 minutes) revert InvalidVenueProposalParameters();
        if (proposal.venueProposalParams.proposalPeriodExtensionThreshold < 2 minutes) revert InvalidVenueProposalParameters();

        validateSplit(proposal.split, proposal.artists.length);
    }

    /// @notice Validates the split percentages between organizer, artists, and venue.
    /// @param split Array representing the percentage split.
    /// @param numArtists Number of artists in the show.
    function validateSplit(uint256[] memory split, uint256 numArtists) internal pure {
        if (split.length != numArtists + 2) revert InvalidSplitArrayLength();
        uint256 sum = 0;
        for (uint i = 0; i < split.length; i++) {
            sum += split[i];
        }
        if (sum != 100 * 10000) revert InvalidSplitSum();
    }

    /// @notice Validates that the total tickets across all tiers match the total capacity of the show.
    /// @param ticketTiers Array of ticket tiers for the show.
    /// @param totalCapacity Total capacity of the show.
    function validateTotalTicketsAcrossTiers(ShowTypes.TicketTier[] memory ticketTiers, uint256 totalCapacity) internal pure {
        uint256 totalTicketsAcrossTiers = 0;
        for (uint i = 0; i < ticketTiers.length; i++) {
            totalTicketsAcrossTiers += ticketTiers[i].ticketsAvailable;
        }
        if (totalTicketsAcrossTiers != totalCapacity) revert TicketCapacityMismatch();
    }
}
