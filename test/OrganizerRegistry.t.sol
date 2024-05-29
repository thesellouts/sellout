// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { ReferralModule } from "../src/registry/referral/ReferralModule.sol";
import { OrganizerRegistry } from "../src/registry/organizer/OrganizerRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract OrganizerRegistryTest is Test {
    ReferralModule referralModule;
    OrganizerRegistry organizerRegistry;
    address SELLOUT_PROTOCOL_WALLET = address(1);
    address NOMINEE = address(2);

    function setUp() external {
        // Deploy ReferralModule through a proxy
        bytes memory initDataReferral = abi.encodeWithSelector(ReferralModule.initialize.selector, SELLOUT_PROTOCOL_WALLET);
        ERC1967Proxy proxyReferral = new ERC1967Proxy(address(new ReferralModule()), initDataReferral);
        referralModule = ReferralModule(address(proxyReferral));

        // Deploy OrganizerRegistry through a proxy
        bytes memory initDataOrganizerRegistry = abi.encodeWithSelector(OrganizerRegistry.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(referralModule));
        ERC1967Proxy proxyOrganizerRegistry = new ERC1967Proxy(address(new OrganizerRegistry()), initDataOrganizerRegistry);
        organizerRegistry = OrganizerRegistry(address(proxyOrganizerRegistry));

        // Set permission for the OrganizerRegistry to decrement referral credits
        vm.prank(SELLOUT_PROTOCOL_WALLET);
        referralModule.setCreditControlPermission(address(proxyOrganizerRegistry), true);

        // Adding some referral credits for testing
        vm.prank(address(proxyOrganizerRegistry));
        referralModule.incrementReferralCredits(address(this), 0, 10, 0); // Adding organizer credits for simplicity
    }

    function testOrganizerNominationAndAcceptance() public {
        // Assume this contract has referral credits to nominate organizers
        organizerRegistry.nominate(NOMINEE); // Nominate a new organizer

        // Accept the nomination from the nominated organizer's perspective
        vm.prank(NOMINEE);
        organizerRegistry.acceptNomination("Sellout Organizer", "The best organizer");

        // Verify the organizer's registration
        (,, address wallet) = organizerRegistry.getOrganizer(NOMINEE);
        assertEq(wallet, NOMINEE, "The organizer's wallet address should match the nominated address.");
    }

    function testOrganizerUpdate() public {
        // Setup: Nominate and accept an organizer to update
        testOrganizerNominationAndAcceptance();

        // New name and biography for the organizer
        string memory newName = "Updated Organizer Name";
        string memory newBio = "Updated Organizer Bio";
        address newAddr = address(3);

        // Update the organizer's information
        vm.prank(NOMINEE);
        organizerRegistry.updateOrganizer(1, newName, newBio, newAddr); // Assuming ID 1 for simplicity, adjust as needed

        // Verify the update was successful
        (string memory name, string memory bio, address wallet) = organizerRegistry.getOrganizer(NOMINEE);
        assertEq(name, newName, "Organizer name was not updated correctly.");
        assertEq(bio, newBio, "Organizer bio was not updated correctly.");
        assertEq(wallet, newAddr, "Organizer wallet was not updated correctly.");
    }

    function testOrganizerDeregistration() public {
        // Setup: Nominate and accept an organizer to deregister
        testOrganizerNominationAndAcceptance();

        // Deregister the organizer
        vm.prank(NOMINEE);
        organizerRegistry.deregisterOrganizer(1); // Assuming ID 1 for simplicity, adjust as needed

        // Attempt to fetch deregistered organizer info, check for default or empty values
        (string memory name, string memory bio, address wallet) = organizerRegistry.getOrganizer(NOMINEE);
        assertEq(wallet, address(0), "Organizer wallet should be default address.");
        assertEq(name, "", "Organizer name should be empty.");
        assertEq(bio, "", "Organizer bio should be empty.");
    }

    function testFailRegisterDuplicateOrganizer() public {
        // Nominate and accept an organizer
        testOrganizerNominationAndAcceptance();

        // Attempt to nominate the same organizer again
        vm.expectRevert("Organizer already registered");
        organizerRegistry.nominate(NOMINEE);
    }

    function testMultipleOrganizerRegistrations() public {
        address organizer2 = address(0xABC);
        address organizer3 = address(0xDEF);

        // Nominate multiple new organizers
        organizerRegistry.nominate(NOMINEE);
        organizerRegistry.nominate(organizer2);
        organizerRegistry.nominate(organizer3);

        // Accept nominations
        vm.prank(NOMINEE);
        organizerRegistry.acceptNomination("First Organizer", "The first one");
        vm.prank(organizer2);
        organizerRegistry.acceptNomination("Second Organizer", "The second one");
        vm.prank(organizer3);
        organizerRegistry.acceptNomination("Third Organizer", "The third one");

        // Check all are registered
        assertTrue(organizerRegistry.isOrganizerRegistered(NOMINEE), "First organizer should be registered");
        assertTrue(organizerRegistry.isOrganizerRegistered(organizer2), "Second organizer should be registered");
        assertTrue(organizerRegistry.isOrganizerRegistered(organizer3), "Third organizer should be registered");
    }

}
