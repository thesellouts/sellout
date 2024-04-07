// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Venue } from "../src/venue/Venue.sol";

contract DeployVenue is Script {
    function run() external {
        vm.startBroadcast();

        address selloutProtocolWallet = vm.envAddress("SELLOUT_PROTOCOL_WALLET");
        address showAddress = vm.envAddress("SHOW_ADDRESS");

        // Deploy Venue Implementation
        Venue venueImpl = new Venue();
        // Prepare initializer function call
        bytes memory initData = abi.encodeWithSignature("initialize(address,address)", selloutProtocolWallet, showAddress);
        // Deploy Proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(venueImpl), initData);

        vm.stopBroadcast();
        console.log("Venue deployed at", address(proxy));
    }
}
