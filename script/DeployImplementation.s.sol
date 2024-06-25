// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/venue/VenueFactory.sol";

contract DeployImplementation is Script {
    function run() external {
        vm.startBroadcast();

        VenueFactory newVenueFactory = new VenueFactory();
        console.log("NewVenueFactoryImplementation deployed at", address(newVenueFactory));

        vm.stopBroadcast();
    }
}
