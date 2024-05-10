// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
//
//import "forge-std/Test.sol";
//import "../src/Show.sol";
//import "../src/VenueProposals.sol";
//
//contract VenueProposalsTest is Test {
//    Show public showContract;
//    VenueProposals public venueProposalsContract;
//
//    function setUp() public {
//        showContract = new Show();
//        venueProposalsContract = new VenueProposals(address(showContract));
//    }
//
//    function testSubmitProposal() public {
//        // Deploy and set up a show
//        address[] memory artists = new address[](2);
//        artists[0] = address(0x1234567890123456789012345678901234567890);
//        artists[1] = address(0x0987654321098765432109876543210987654321);
//
//        // Deploy and set up a show using the Show contract
//        Show show = new Show(
//            msg.sender,
//            "40.730610,-73.935242",
//            artists,
//            1000,
//            0.5 ether,
//            2 ether,
//            80
//        );
//
//        // Submit a proposal using the VenueProposals contract
//        venueProposalsContract.submitProposal(address(show), "Venue Name", "40.730610,-73.935242", new uint256[](0), {value: 1 ether});
//
//        // Perform assertions
//        // ... Your assertions here ...
//    }
//
//    // You can write similar test functions for other interactions with VenueProposals contract
//
//    // ... other test functions ...
//}
