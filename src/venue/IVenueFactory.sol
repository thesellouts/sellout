// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IVenueFactory Interface
/// @notice Interface for the VenueFactory contract.
interface IVenueFactory {
    /// @notice Creates a new venue proxy instance with initial parameters and returns its address.
    /// @param initialOwner The address that will own the newly created venue proxy.
    /// @param proposalPeriodDuration Duration of the proposal period.
    /// @param proposalDateExtension Extension duration for proposal dates.
    /// @param proposalDateMinimumFuture The minimum future date for a proposal.
    /// @param proposalPeriodExtensionThreshold Threshold for extending the proposal period.
    /// @return The address of the newly created venue proxy.
    function createVenueProxy(
        address initialOwner,
        uint256 proposalPeriodDuration,
        uint256 proposalDateExtension,
        uint256 proposalDateMinimumFuture,
        uint256 proposalPeriodExtensionThreshold
    ) external returns (address);

    /// @notice Sets a new version for the venue factory.
    /// @param _version New version to set.
    function setVersion(string memory _version) external;

    /// @notice Returns the list of deployed venue proxies.
    /// @return An array of addresses of the deployed venue proxies.
    function getDeployedVenues() external view returns (address[] memory);

    /// @notice Updates the venue implementation contract address.
    /// @param newImplementation New venue implementation address to set.
    function updateVenueImplementation(address newImplementation) external;
}
