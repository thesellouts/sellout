// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ticket/TicketFactory.sol";

contract DeployImplementation is Script {
    function run() external {
        vm.startBroadcast();

        TicketFactory newTicketFactory = new TicketFactory();
        console.log("NewTicketFactoryImplementation deployed at", address(newTicketFactory));

        vm.stopBroadcast();
    }
}
