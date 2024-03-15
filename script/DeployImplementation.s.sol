// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/show/Show.sol";

contract DeployImplementation is Script {
    function run() external {
        vm.startBroadcast();

        Show newShow = new Show();
        console.log("NewShowImplementation deployed at", address(newShow));

        vm.stopBroadcast();
    }
}
