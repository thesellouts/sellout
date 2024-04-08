// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { TicketFactory } from "../src/ticket/TicketFactory.sol";
import { Ticket } from "../src/ticket/Ticket.sol";

contract DeployTicketFactory is Script {
    function run() external {
        vm.startBroadcast();

        address showAddress = vm.envAddress("SHOW_ADDRESS");

        // Deploy the Ticket implementation
        Ticket ticketImplementation = new Ticket();
        console.log("TicketImplementation deployed at", address(ticketImplementation));

        // Deploy the TicketFactory implementation
        TicketFactory ticketFactoryImpl = new TicketFactory();
        console.log("TicketFactory implementation deployed at", address(ticketFactoryImpl));

        // Prepare the initializer function call for TicketFactory
        // Assuming `initialize` takes ticketImplementation address and a version string as arguments
        string memory initialVersion = "1.0.0";
        bytes memory initData = abi.encodeWithSignature("initialize(address,string,address)", address(ticketImplementation), initialVersion, showAddress);

        // Deploy the ERC1967 Proxy for TicketFactory
        ERC1967Proxy proxy = new ERC1967Proxy(address(ticketFactoryImpl), initData);
        console.log("TicketFactory deployed at", address(proxy));

        vm.stopBroadcast();
    }
}
