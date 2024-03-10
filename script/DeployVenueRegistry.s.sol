// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { VenueRegistry } from "../src/registry/venue/VenueRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployVenueRegistry is Script {
    function run() external {
        vm.startBroadcast();

        // Fetch the SELLOUT_PROTOCOL_WALLET and REFERRAL_MODULE_ADDRESS from environment variables
        address selloutProtocolWallet = vm.envAddress("SELLOUT_PROTOCOL_WALLET");
        address referralModuleAddress = vm.envAddress("REFERRAL_MODULE_ADDRESS");

        // Deploy the VenueRegistry implementation contract
        VenueRegistry venueRegistryImpl = new VenueRegistry();

        // Encode the initializer function call with the referralModuleAddress
        bytes memory initData = abi.encodeWithSelector(VenueRegistry.initialize.selector, selloutProtocolWallet, referralModuleAddress);

        // Deploy the ERC1967Proxy pointing to the VenueRegistry implementation
        ERC1967Proxy proxyVenueRegistry = new ERC1967Proxy(address(venueRegistryImpl), initData);

        // Log the deployed proxy address
        console.log("VenueRegistry deployed at", address(proxyVenueRegistry));

        vm.stopBroadcast();
    }
}
