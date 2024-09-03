// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/registry/venue/VenueRegistry.sol";

contract DeployImplementation is Script {
    function run() external {
        vm.startBroadcast();

        VenueRegistry newVenueRegistry = new VenueRegistry();
        console.log("NewVenueRegistryImplementation deployed at", address(newVenueRegistry));

        vm.stopBroadcast();
    }
}
