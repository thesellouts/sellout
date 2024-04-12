// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IVenue.sol"; // Ensure you have an IVenue interface that includes the initialize method with proper parameters

/// @title VenueFactory
/// @dev Implements a factory for creating upgradeable venue proxies.
contract VenueFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    /// @notice Address of the venue implementation contract.
    address public venueImplementation;

    /// @notice Array of addresses for all deployed ticket proxies.
    address[] public deployedVenues;

    /// @notice Version of the ticket factory.
    string public version;

    // Store the Show contract address for access control
    address public showAddress;

    /// @notice Emitted when a new venue proxy is created.
    event VenueProxyCreated(address indexed venueProxy);

    function initialize(address _venueImplementation, string memory _version, address _showAddress) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        venueImplementation = _venueImplementation;
        version = _version;
        showAddress = _showAddress;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier onlyShowContract() {
        require(msg.sender == showAddress, "Caller is not the Show contract");
        _;
    }

    /// @notice Creates a new venue proxy and initializes it with the specified parameters.
    /// @param initialOwner The owner of the new venue proxy.
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
    ) public onlyShowContract returns (address) {
        address clone = Clones.clone(venueImplementation);
        IVenue(clone).initialize(
            initialOwner,
            proposalPeriodDuration,
            proposalDateExtension,
            proposalDateMinimumFuture,
            proposalPeriodExtensionThreshold
        );
        emit VenueProxyCreated(clone);
        return clone;
    }

    /// @notice Sets a new version for the venue factory.
    /// @param _version New version to set.
    function setVersion(string memory _version) public onlyOwner {
        version = _version;
    }


    /// @notice Returns the list of deployed venue proxies.
    /// @return An array of addresses of the deployed venue proxies.
    function getDeployedVenues() public view returns (address[] memory) {
        return deployedVenues;
    }

    /// @notice Updates the venue implementation contract address.
    /// @param newImplementation The new venue implementation address to set.
    function updateVenueImplementation(address newImplementation) public onlyOwner {
        venueImplementation = newImplementation;
    }
}
