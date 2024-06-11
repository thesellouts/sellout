// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/venue/Venue.sol";

contract DeployImplementation is Script {
    function run() external {
        vm.startBroadcast();

        Venue newVenue = new Venue();
        console.log("NewVenueImplementation deployed at", address(newVenue));

        vm.stopBroadcast();
    }
}
