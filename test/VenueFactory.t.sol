// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/venue/VenueFactory.sol";
import "../src/venue/Venue.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract VenueFactoryTest is Test {
    VenueFactory venueFactory;
    Venue venueImplementation;
    address showAddress = address(1);
    address unauthorizedAddress = address(2);

    function setUp() external {
        // Deploy Venue implementation
        venueImplementation = new Venue();

        // Initialize VenueFactory with Venue implementation
        bytes memory initDataVenueFactory = abi.encodeWithSelector(
            VenueFactory.initialize.selector,
            address(venueImplementation),
            "v1.0",
            showAddress
        );
        ERC1967Proxy proxyVenueFactory = new ERC1967Proxy(address(new VenueFactory()), initDataVenueFactory);
        venueFactory = VenueFactory(address(proxyVenueFactory));
    }

    function testInitialization() public {
        assertEq(venueFactory.version(), "v1.0", "Incorrect version on initialization.");
        assertEq(address(venueFactory.venueImplementation()), address(venueImplementation), "Venue implementation address not set correctly.");
    }

    function testCreateVenueProxy() public {
        // Only showAddress can create a venue proxy, simulate showAddress calling the function
        vm.prank(showAddress);

        address venueProxyAddress = venueFactory.createVenueProxy(
            address(this), // initialOwner
            3600,          // proposalPeriodDuration
            600,           // proposalDateExtension
            3600,          // proposalDateMinimumFuture
            300            // proposalPeriodExtensionThreshold
        );

        // Check that the proxy address is not zero
        assertTrue(venueProxyAddress != address(0), "Venue proxy creation failed.");
    }

    function testUnauthorizedVenueProxyCreation() public {
        vm.expectRevert("Caller is not the Show contract");
        vm.prank(unauthorizedAddress);
        venueFactory.createVenueProxy(
            unauthorizedAddress, // initialOwner
            3600,                // proposalPeriodDuration
            600,                 // proposalDateExtension
            3600,                // proposalDateMinimumFuture
            300                  // proposalPeriodExtensionThreshold
        );
    }

    function testVersionManagement() public {
        // Update version by the owner
        string memory newVersion = "v1.1";
        vm.prank(address(this));
        venueFactory.setVersion(newVersion);

        // Check the version update
        assertEq(venueFactory.version(), newVersion, "Version not updated correctly.");
    }

    function testUpdateVenueImplementation() public {
        // Deploy a new Venue implementation
        Venue newVenueImplementation = new Venue();

        // Update implementation by the owner
        vm.prank(address(this));
        venueFactory.updateVenueImplementation(address(newVenueImplementation));

        // Check the implementation update
        assertEq(address(venueFactory.venueImplementation()), address(newVenueImplementation), "Venue implementation not updated correctly.");
    }


}
