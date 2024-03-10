// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Show } from "../src/show/Show.sol";

contract DeployShow is Script {
    function run() external {
        vm.startBroadcast();

        address selloutProtocolWallet = vm.envAddress("SELLOUT_PROTOCOL_WALLET");

        // Deploy Show Implementation
        Show showImpl = new Show();
        // Prepare initializer function call
        bytes memory initData = abi.encodeWithSignature("initialize(address)", selloutProtocolWallet);
        // Deploy Proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(showImpl), initData);

        vm.stopBroadcast();
        console.log("Show deployed at", address(proxy));
    }
}
