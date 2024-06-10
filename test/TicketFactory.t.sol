// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ticket/TicketFactory.sol";
import "../src/ticket/Ticket.sol";
import "forge-std/console.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TicketFactoryTest is Test {
    TicketFactory ticketFactory;
    Ticket ticketImplementation;
    address boxOfficeAddress = address(1);
    address unauthorizedAddress = address(2);

    function setUp() external {
        // Deploy Ticket implementation
        ticketImplementation = new Ticket();

        // Initialize TicketFactory with Ticket implementation
        bytes memory initDataTicketFactory = abi.encodeWithSelector(
            TicketFactory.initialize.selector,
            address(ticketImplementation),
            "v1.0"
        );
        ERC1967Proxy proxyTicketFactory = new ERC1967Proxy(address(new TicketFactory()), initDataTicketFactory);
        ticketFactory = TicketFactory(address(proxyTicketFactory));

        // Set the BoxOffice address
        vm.prank(address(this));  // Ensure the caller is the owner
        ticketFactory.setContractAddresses(boxOfficeAddress);
    }

    function testInitialization() public {
        assertEq(ticketFactory.version(), "v1.0", "Incorrect version on initialization.");
        assertEq(address(ticketFactory.ticketImplementation()), address(ticketImplementation), "Ticket implementation address not set correctly.");
    }

    function testCreateTicketProxy() public {
        // Only boxOfficeAddress can create a ticket proxy, simulate boxOfficeAddress calling the function
        vm.prank(boxOfficeAddress);

        address ticketProxyAddress = ticketFactory.createTicketProxy(
            address(this)  // initialOwner
        );

        // Check that the proxy address is not zero
        assertTrue(ticketProxyAddress != address(0), "Ticket proxy creation failed.");
        // Check if the proxy has been pushed to the deployedTickets array
        address[] memory deployedTickets = ticketFactory.getDeployedTickets();
        assertEq(deployedTickets[deployedTickets.length - 1], ticketProxyAddress, "Ticket proxy not recorded correctly.");
    }

    function testUnauthorizedTicketProxyCreation() public {
        vm.expectRevert("Caller is not the BoxOffice contract");
        vm.prank(unauthorizedAddress);
        ticketFactory.createTicketProxy(unauthorizedAddress);
    }

    function testVersionManagement() public {
        // Update version by the owner
        string memory newVersion = "v1.1";
        vm.prank(address(this));
        ticketFactory.setVersion(newVersion);

        // Check the version update
        assertEq(ticketFactory.version(), newVersion, "Version not updated correctly.");
    }

    function testUpdateTicketImplementation() public {
        // Deploy a new Ticket implementation
        Ticket newTicketImplementation = new Ticket();

        // Update implementation by the owner
        vm.prank(address(this));
        ticketFactory.updateTicketImplementation(address(newTicketImplementation));

        // Check the implementation update
        assertEq(address(ticketFactory.ticketImplementation()), address(newTicketImplementation), "Ticket implementation not updated correctly.");
    }

//    function testUpgradeExistingProxy() public {
//        // Step 1: Deploy and initialize a proxy as before
//        vm.prank(boxOfficeAddress);
//        address ticketProxyAddress = ticketFactory.createTicketProxy(address(this));
//
//        // Log the proxy address for debugging
//        console.log("Ticket Proxy Address:", ticketProxyAddress);
//
//        // Step 2: Deploy a new Ticket implementation
//        Ticket newTicketImplementation = new Ticket();
//        vm.prank(address(this));
//        newTicketImplementation.initialize(address(this), "NewVersion");
//
//        // Log the new implementation address for debugging
//        console.log("New Ticket Implementation Address:", address(newTicketImplementation));
//
////        // Step 3: Upgrade the existing proxy to the new implementation
////        // Using call to invoke the upgradeTo function directly on the proxy
////        vm.prank(address(this));
////        (bool success,) = ticketProxyAddress.call(abi.encodeWithSignature("upgradeTo(address)", address(newTicketImplementation)));
////        require(success, "Proxy upgrade failed");
//
//        // Step 4: Verify the upgrade
//        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
//        address currentImplementation = address(uint160(uint256(vm.load(ticketProxyAddress, slot))));
//        assertEq(currentImplementation, address(newTicketImplementation), "Proxy does not reflect updated implementation.");
//
//        // Optional: Logs for debugging
//        console.log("Current Implementation in Proxy:", currentImplementation);
//    }
}
