//// SPDX-License-Identifier: UNLICENSED
//pragma solidity ^0.8.13;
//
//import "forge-std/Test.sol";
//import "../src/Show.sol";
//import "../src/SellOut.sol";
//
//contract SellOutTest is Test {
//    Show public showContract;
//    SellOut public sellOutContract;
//    uint256 public lastShowId; // To track the last created show ID
//
//    function setUp() public {
//        showContract = new Show();
//        sellOutContract = new SellOut(address(showContract));
//    }
//
//    function createShow() internal returns (uint256) {
//        address[] memory artists = new address[](2);
//        artists[0] = address(0x1234567890123456789012345678901234567890);
//        artists[1] = address(0x0987654321098765432109876543210987654321);
//
//        // Create a show using the Show contract
//        uint256 showId = showContract.proposeShow(
//            "40.730610,-73.935242",
//            artists,
//            1000,
//            0.5 ether,
//            2 ether,
//            80
//        );
//
//        return showId;
//    }
//
//    function testPurchaseTicket() public {
//        // Create a show
//        uint256 showId = createShow();
//
//        // Purchase a ticket using the SellOut contract
//        sellOutContract.purchaseTicket{value: 0.5 ether}(showId);
//
//        // Perform assertions
//        // ... Your assertions here ...
//    }
//
//    // You can write similar test functions for other interactions with SellOut contract
//
//    // ... other test functions ...
//}
