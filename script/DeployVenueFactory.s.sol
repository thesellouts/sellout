// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { VenueFactory } from "../src/venue/VenueFactory.sol";
import { Venue } from "../src/venue/Venue.sol";

contract DeployVenueFactory is Script {
    function run() external {
        vm.startBroadcast();

        address showAddress = vm.envAddress("SHOW_ADDRESS");

        // Deploy the Venue implementation
        Venue venueImplementation = new Venue();
        console.log("VenueImplementation deployed at", address(venueImplementation));

        // Deploy the VenueFactory implementation
        VenueFactory venueFactoryImpl = new VenueFactory();
        console.log("VenueFactory implementation deployed at", address(venueFactoryImpl));

        // Prepare the initializer function call for VenueFactory
        // Assuming `initialize` takes venueImplementation address and a version string as arguments
        string memory initialVersion = "1.0.0";
        bytes memory initData = abi.encodeWithSignature("initialize(address,string,address)", address(venueImplementation), initialVersion, showAddress);

        // Deploy the ERC1967 Proxy for VenueFactory
        ERC1967Proxy proxy = new ERC1967Proxy(address(venueFactoryImpl), initData);
        console.log("VenueFactory deployed at", address(proxy));

        vm.stopBroadcast();
    }
}
