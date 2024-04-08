// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ticket/Ticket.sol";

contract DeployImplementation is Script {
    function run() external {
        vm.startBroadcast();

        Ticket newTicket = new Ticket();
        console.log("NewTicketImplementation deployed at", address(newTicket));

        vm.stopBroadcast();
    }
}
