// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

interface IProxy {
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}

contract DeployTicketProxy is Script {
    function run() external {
        vm.startBroadcast();

        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        address newImplementationAddress = vm.envAddress("NEW_IMPLEMENTATION_ADDRESS");

        // If there's no need to call a function in the new implementation post-upgrade, data would be empty
        bytes memory data = ""; // Or encode the function call if needed

        IProxy(proxyAddress).upgradeToAndCall(newImplementationAddress, data);

        console.log("Show proxy upgraded to new implementation at", newImplementationAddress);

        vm.stopBroadcast();
    }
}
