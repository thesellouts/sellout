// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Show.sol";

contract ShowTest is Test {
    Show public show;

    function setUp() public {
        address organizer = address(this); // Using the test contract as the organizer
        string memory location = "40.730610,-73.935242"; // Example location
        address[] memory artists = new address[](2);
        artists[0] = address(0x1234567890123456789012345678901234567890); // Example artist addresses
        artists[1] = address(0x0987654321098765432109876543210987654321);
        uint256 totalCapacity = 1000;
        uint256 minTicketPrice = 1 ether;
        uint256 maxTicketPrice = 2 ether;
        uint256 sellOutThreshold = 80;

        show = new Show(
            organizer,
            location,
            artists,
            totalCapacity,
            minTicketPrice,
            maxTicketPrice,
            sellOutThreshold
        );
    }

    function testProposeShow() public {
        address[] memory artists = new address[](2);
        artists[0] = address(0x1234567890123456789012345678901234567890); // Example artist addresses
        artists[1] = address(0x0987654321098765432109876543210987654321);

        show.proposeShow("40.730610,-73.935242", artists, 500, 0.5 ether, 1.5 ether, 70);
        assertEq(uint256(show.status()), uint256(Show.Status.Proposed));
        assertEq(show.totalCapacity(), 500);
    }

    function testSetVenue() public {
        // Test setting the venue
        show.setVenue("Madison Square Garden", "40.750504,-73.993439");
        (string memory venueName, ) = show.venue();
        assertEq(venueName, "Madison Square Garden");
    }

    function testUpdateStatus() public {
        // Test updating the show status
        show.updateStatus(Show.Status.SoldOut);
        assertEq(uint(show.status()), uint(Show.Status.SoldOut));
    }

    function testInvalidTicketPriceRange() public {
        address[] memory artists = new address[](2);
        artists[0] = address(0x1234567890123456789012345678901234567890); // Example artist addresses
        artists[1] = address(0x0987654321098765432109876543210987654321);

        // Attempt to propose a show with max ticket price less than min ticket price
        try show.proposeShow("40.730610,-73.935242", artists, 500, 1.5 ether, 0.5 ether, 70) {
            // This line should not be reached, as the function call should revert
            fail("Should have reverted due to invalid ticket price range");
        } catch Error(string memory reason) {
            assertEq(reason, "Max ticket price must be greater or equal to min ticket price");
        }
    }

    function testInvalidSellOutThreshold() public {
        address[] memory artists = new address[](2);
        artists[0] = address(0x1234567890123456789012345678901234567890); // Example artist addresses
        artists[1] = address(0x0987654321098765432109876543210987654321);

        // Attempt to propose a show with sell-out threshold greater than 100
        try show.proposeShow("40.730610,-73.935242", artists, 500, 0.5 ether, 1.5 ether, 101) {
            // This line should not be reached, as the function call should revert
            fail("Should have reverted due to invalid sell-out threshold");
        } catch Error(string memory reason) {
            assertEq(reason, "Sell-out threshold must be between 0 and 100");
        }
    }

}
