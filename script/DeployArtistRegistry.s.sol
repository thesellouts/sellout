// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { ArtistRegistry } from "../src/registry/artist/ArtistRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployArtistRegistry is Script {
    function run() external {
        // Start the broadcast mode to send transactions
        vm.startBroadcast();

        // Fetch the SELLOUT_PROTOCOL_WALLET and REFERRAL_MODULE_ADDRESS from environment variables
        address selloutProtocolWallet = vm.envAddress("SELLOUT_PROTOCOL_WALLET");
        address referralModuleAddress = vm.envAddress("REFERRAL_MODULE_ADDRESS");

        // Deploy the ArtistRegistry implementation contract
        ArtistRegistry artistRegistryImpl = new ArtistRegistry();

        // Encode the initializer function call with the referralModuleAddress
        bytes memory initData = abi.encodeWithSelector(ArtistRegistry.initialize.selector, selloutProtocolWallet, referralModuleAddress);

        // Deploy the ERC1967Proxy pointing to the ArtistRegistry implementation
        ERC1967Proxy proxyArtistRegistry = new ERC1967Proxy(address(artistRegistryImpl), initData);

        // Log the deployed proxy address
        console.log("ArtistRegistry deployed at", address(proxyArtistRegistry));

        // Stop the broadcast mode
        vm.stopBroadcast();
    }
}
