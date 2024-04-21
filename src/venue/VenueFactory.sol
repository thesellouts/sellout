// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Clones } from "@openzeppelin-contracts/proxy/Clones.sol";
import { IVenue } from "./IVenue.sol";

/*

    @title  VenueFactory
    @author taayyohh
    @dev Implements a factory for creating upgradeable venue proxies using the clone pattern.

*/

contract VenueFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    /// @notice Address of the venue implementation contract.
    /// @dev This is the master copy used for creating clone proxies.
    address public venueImplementation;

    /// @notice Current version of the VenueFactory.
    /// @dev Used to track changes and upgrades in the factory functionality.
    string public version;

    /// @notice Address of the Show contract, used for access control.
    /// @dev Only this address can invoke certain functions.
    address public showAddress;

    /// @notice Emitted when a new venue proxy is created.
    /// @param venueProxy Address of the newly created venue proxy.
    event VenueProxyCreated(address indexed venueProxy);

    /// @notice Initializes the VenueFactory contract.
    /// @param _venueImplementation Address of the venue implementation contract.
    /// @param _version Initial version string for the factory.
    /// @param _showAddress Address of the Show contract for access control.
    function initialize(address _venueImplementation, string memory _version, address _showAddress) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        venueImplementation = _venueImplementation;
        version = _version;
        showAddress = _showAddress;
    }

    /// @dev Overrides the UUPSUpgradeable function to restrict upgrade capability to the owner only.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Modifier to restrict function calls to the Show contract only.
    modifier onlyShowContract() {
        require(msg.sender == showAddress, "Caller is not the Show contract");
        _;
    }

    /// @notice Creates and initializes a new venue proxy with specified parameters.
    /// @param initialOwner The owner of the new venue proxy.
    /// @param proposalPeriodDuration Duration of the proposal period in seconds.
    /// @param proposalDateExtension Extension duration for proposal dates in seconds.
    /// @param proposalDateMinimumFuture Minimum future time in seconds for a proposal to be valid.
    /// @param proposalPeriodExtensionThreshold Threshold in seconds for extending the proposal period.
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

    /// @notice Sets a new version string for the VenueFactory.
    /// @param _version The new version string to be set.
    function setVersion(string memory _version) public onlyOwner {
        version = _version;
    }

    /// @notice Updates the address of the venue implementation contract.
    /// @param newImplementation The new venue implementation address to be set.
    function updateVenueImplementation(address newImplementation) public onlyOwner {
        venueImplementation = newImplementation;
    }
}
