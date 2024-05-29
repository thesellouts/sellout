// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import { ReferralModule } from "../src/registry/referral/ReferralModule.sol";
import { ReferralTypes } from "../src/registry/referral/types/ReferralTypes.sol";  // Ensure this path is correct

contract ReferralModuleTest is Test {
    ReferralModule referralModule;
    address SELLOUT_PROTOCOL_WALLET = address(1);
    address authorizedAddress = address(0x123);
    address referrer = address(0x456);

    function setUp() public {
        referralModule = new ReferralModule();
        vm.startPrank(SELLOUT_PROTOCOL_WALLET);
        referralModule.initialize(SELLOUT_PROTOCOL_WALLET);
        referralModule.setCreditControlPermission(authorizedAddress, true);
        vm.stopPrank();
    }

    function testInitialize() public {
        assertEq(referralModule.owner(), SELLOUT_PROTOCOL_WALLET, "Owner should be the sellout protocol wallet");
    }

    function testSetCreditControlPermission() public {
        bool currentPermission = referralModule.isCreditor(authorizedAddress);
        assertTrue(currentPermission, "Authorized address should have permission initially.");

        vm.prank(SELLOUT_PROTOCOL_WALLET);
        referralModule.setCreditControlPermission(authorizedAddress, false);

        currentPermission = referralModule.isCreditor(authorizedAddress);
        assertFalse(currentPermission, "Authorized address should have permission revoked.");
    }

    function testFailSetCreditControlPermissionByNonOwner() public {
        vm.startPrank(address(0xABC));
        vm.expectRevert("Ownable: caller is not the owner");
        referralModule.setCreditControlPermission(authorizedAddress, false);
        vm.stopPrank();
    }

    function testIncrementReferralCredits() public {
        vm.prank(authorizedAddress);
        referralModule.incrementReferralCredits(referrer, 10, 5, 3);
        ReferralTypes.ReferralCredits memory credits = referralModule.getReferralCredits(referrer);

        assertEq(credits.artist, 10, "Artist credits should match");
        assertEq(credits.organizer, 5, "Organizer credits should match");
        assertEq(credits.venue, 3, "Venue credits should match");
    }

    function testFailIncrementReferralCreditsByNonAuthorized() public {
        vm.prank(address(0xDEF));
        referralModule.incrementReferralCredits(referrer, 10, 5, 3);
        vm.expectRevert(bytes("Unauthorized"));
    }

    function testDecrementReferralCredits() public {
        vm.startPrank(authorizedAddress);
        referralModule.incrementReferralCredits(referrer, 10, 5, 3);
        referralModule.decrementReferralCredits(referrer, 5, 3, 2);
        vm.stopPrank();

        ReferralTypes.ReferralCredits memory credits = referralModule.getReferralCredits(referrer);
        assertEq(credits.artist, 5, "Artist credits should match after decrement");
        assertEq(credits.organizer, 2, "Organizer credits should match after decrement");
        assertEq(credits.venue, 1, "Venue credits should match after decrement");
    }

    function testFailDecrementReferralCreditsBeyondAvailable() public {
        vm.prank(authorizedAddress);
        referralModule.incrementReferralCredits(referrer, 10, 5, 3);
        vm.expectRevert(bytes("Insufficient credits"));
        referralModule.decrementReferralCredits(referrer, 20, 10, 5);
    }

    function testFailDecrementReferralCreditsByNonAuthorized() public {
        vm.prank(address(0xDEF));
        referralModule.decrementReferralCredits(referrer, 10, 5, 3);
        vm.expectRevert(bytes("Unauthorized"));
    }
}
