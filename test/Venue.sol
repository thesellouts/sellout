// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/venue/Venue.sol";
import "../src/registry/venue/IVenueRegistry.sol";
import "../src/show/IShow.sol";
import "../src/show/IShowVault.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { VenueRegistryTypes } from "../src/registry/venue/types/VenueRegistryTypes.sol";
import { ShowTypes } from "../src/show/types/ShowTypes.sol";

contract VenueTest is Test {
    Venue venue;
    address initialOwner = address(1);

    function setUp() external {
        // Deploy the Venue contract through a proxy
        bytes memory initData = abi.encodeWithSelector(
            Venue.initialize.selector,
            initialOwner,
            3600,   // proposalPeriodDuration
            600,    // proposalDateExtension
            3600,   // proposalDateMinimumFuture
            300     // proposalPeriodExtensionThreshold
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(new Venue()), initData);
        venue = Venue(address(proxy));
    }

    function testInitialization() public {
        assertEq(venue.proposalPeriodDuration(), 3600, "Incorrect proposal period duration.");
        assertEq(venue.proposalDateExtension(), 600, "Incorrect proposal date extension.");
        assertEq(venue.proposalDateMinimumFuture(), 3600, "Incorrect proposal date minimum future.");
        assertEq(venue.proposalPeriodExtensionThreshold(), 300, "Incorrect proposal period extension threshold.");
    }
}
