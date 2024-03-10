// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { OrganizerRegistry } from "../src/registry/organizer/OrganizerRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployOrganizerRegistry is Script {
    function run() external {
        vm.startBroadcast();

        // Fetch the SELLOUT_PROTOCOL_WALLET and REFERRAL_MODULE_ADDRESS from environment variables
        address selloutProtocolWallet = vm.envAddress("SELLOUT_PROTOCOL_WALLET");
        address referralModuleAddress = vm.envAddress("REFERRAL_MODULE_ADDRESS");

        // Deploy the OrganizerRegistry implementation contract
        OrganizerRegistry organizerRegistryImpl = new OrganizerRegistry();

        // Encode the initializer function call with the referralModuleAddress
        bytes memory initData = abi.encodeWithSelector(OrganizerRegistry.initialize.selector, selloutProtocolWallet, referralModuleAddress);

        // Deploy the ERC1967Proxy pointing to the OrganizerRegistry implementation
        ERC1967Proxy proxyOrganizerRegistry = new ERC1967Proxy(address(organizerRegistryImpl), initData);

        // Log the deployed proxy address
        console.log("OrganizerRegistry deployed at", address(proxyOrganizerRegistry));

        vm.stopBroadcast();
    }
}
