// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../src/ticket/Ticket.sol";
import "../src/show/Show.sol";
import "../src/show/types/ShowTypes.sol";
import "../src/venue/Venue.sol";
import "../src/factory/SellOutFactory.sol";

contract TestTicket is Test {
    Ticket ticketInstance;
    Show showInstance;
    Venue venueInstance;

    function setUp() public {
        SellOutFactory factory = new SellOutFactory();

        showInstance = Show(factory.showInstance());
        ticketInstance = Ticket(factory.ticketInstance());
        venueInstance = Venue(factory.venueInstance());
    }

    function testPurchaseTicket() public {
        // Set up the show
        string memory name = "Live Concert";
        string memory description = "An amazing live concert!";
        address[] memory artists = new address[](1);

        artists[0] = address(0x1234);
        VenueTypes.Venue memory venue = VenueTypes.Venue({
            name: "Concert Hall",
            coordinates: VenueTypes.Coordinates({lat: 100, lon: 80}),
            totalCapacity: 5000,
            wallet: address(0x5678)
        });
        uint8 radius = 80;
        uint8 sellOutThreshold = 80;
        uint256 totalCapacity = 1000;
        ShowTypes.TicketPrice memory ticketPrice = ShowTypes.TicketPrice({minPrice: 10, maxPrice: 100});
        uint256[] memory split = new uint256[](3);
        split[0] = 10; // organizer
        split[1] = 70; // artists
        split[2] = 20; // venue

        bytes32 showId = showInstance.proposeShow(name, description, artists, venue.coordinates, radius, sellOutThreshold, totalCapacity, ticketPrice, split);

        // Purchase a ticket
        uint256 calculatedTicketPrice = 10; // Assuming fan status 1
        ticketInstance.purchaseTickets{value: calculatedTicketPrice}(showId, 1);

        // Validate the result
        uint256 totalTicketsSoldForShow = showInstance.totalTicketsSold(showId);
        assertEq(totalTicketsSoldForShow, 1, "Ticket purchase failed");
    }

    function testRefundTicket() public {
        // Set up the show
        string memory name = "Live Concert";
        string memory description = "An amazing live concert!";
        address[] memory artists = new address[](1);

        artists[0] = address(0x1234);
        VenueTypes.Venue memory venue = VenueTypes.Venue({
            name: "Concert Hall",
            coordinates: VenueTypes.Coordinates({lat: 100, lon: 80}),
            totalCapacity: 5000,
            wallet: address(0x5678)
        });
        uint8 radius = 80;
        uint8 sellOutThreshold = 80;
        uint256 totalCapacity = 1000;
        ShowTypes.TicketPrice memory ticketPrice = ShowTypes.TicketPrice({minPrice: 10, maxPrice: 100});
        uint256[] memory split = new uint256[](3);
        split[0] = 10; // organizer
        split[1] = 70; // artists
        split[2] = 20; // venue

        bytes32 showId = showInstance.proposeShow(name, description, artists, venue.coordinates, radius, sellOutThreshold, totalCapacity, ticketPrice, split);
        uint256 calculatedTicketPrice = 10; // Assuming fan status 1
        ticketInstance.purchaseTickets{value: calculatedTicketPrice}(showId, 1);

        // Get the ticket ID for the purchased ticket
        uint256 ticketId = 1;

        // Get the initial balance of the user
        uint256 initialBalance = showInstance.pendingWithdrawals(showId, msg.sender);

        // Refund the ticket
        showInstance.refundTicket(showId, ticketId);

        // Validate the refund amount
        uint256 refundAmount = showInstance.getTicketPricePaid(showId, ticketId);
        uint256 expectedBalance = initialBalance + refundAmount;
        assertEq(showInstance.pendingWithdrawals(showId, msg.sender), expectedBalance, "Refund amount incorrect");

        // Withdraw the refund
        showInstance.withdrawRefund(showId);

       // Validate the withdrawal
        assertEq(showInstance.pendingWithdrawals(showId, msg.sender), 0, "Withdrawal failed");
//        assertEq(address(msg.sender).balance, expectedBalance, "Balance incorrect after withdrawal");
    }


}
