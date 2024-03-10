// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { ReferralModule } from "../src/registry/referral/ReferralModule.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployReferralModule is Script {
    function run() external {
        // Start the broadcast mode to send transactions
        vm.startBroadcast();

        // Fetch the SELLOUT_PROTOCOL_WALLET from environment variable
        address selloutProtocolWallet = vm.envAddress("SELLOUT_PROTOCOL_WALLET");

        // Deploy the ReferralModule implementation contract
        ReferralModule referralModuleImpl = new ReferralModule();

        // Encode the initializer function call
        bytes memory initData = abi.encodeWithSelector(ReferralModule.initialize.selector, selloutProtocolWallet);

        // Deploy the ERC1967Proxy pointing to the ReferralModule implementation
        ERC1967Proxy proxyReferralModule = new ERC1967Proxy(address(referralModuleImpl), initData);

        // Log the deployed proxy address
        console.log("ReferralModule deployed at", address(proxyReferralModule));

        // Stop the broadcast mode
        vm.stopBroadcast();
    }
}
