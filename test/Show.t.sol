pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../src/show/Show.sol";
import "../src/show/types/ShowTypes.sol";
import "../src/venue/types/VenueTypes.sol";
import "../src/factory/SellOutFactory.sol";

contract TestShow is Test {
    Show showInstance;
    Ticket ticketInstance;

    function setUp() public {
        SellOutFactory factory = new SellOutFactory();

        showInstance = Show(factory.showInstance());
        ticketInstance = Ticket(factory.ticketInstance());
    }

    function testProposeShowWithValidParameters() public {
        string memory name = "Sample Show";
        string memory description = "A great show!";
        address[] memory artists = new address[](1);
        artists[0] = address(0x1234);
        VenueTypes.Venue memory venue = VenueTypes.Venue({
            name: "Venue Name",
            coordinates: VenueTypes.Coordinates({lat: 100, lon: 80}),
            totalCapacity: 5000,
            wallet: address(0x5678)
        });
        uint8 radius = 80;
        uint8 sellOutThreshold = 80;
        uint256 totalCapacity = 1000;
        ShowTypes.TicketPrice memory ticketPrice = ShowTypes.TicketPrice({minPrice: 10, maxPrice: 100});
        uint256[] memory split = new uint256[](3);
        split[0] = 40; // organizer
        split[1] = 40; // artists
        split[2] = 20; // venue

        bytes32 showId = showInstance.proposeShow(name, description, artists, venue.coordinates, radius, sellOutThreshold, totalCapacity, ticketPrice, split);

        // Validate the result
        (string memory returnedName, , , , , , , , , ) = showInstance.getShowById(showId);
        assertEq(returnedName, name, "Show name does not match");
    }

    function testShowExpiry() public {
        string memory name = "Expired Show";
        string memory description = "A show that has expired!";
        address[] memory artists = new address[](1);
        artists[0] = address(0x1234);
        VenueTypes.Venue memory venue = VenueTypes.Venue({
            name: "Venue Name",
            coordinates: VenueTypes.Coordinates({lat: 80, lon: 100}),
            wallet: address(0x5678),
            totalCapacity: 500
        });

        uint8 radius = 80;
        uint8 sellOutThreshold = 80;
        uint256 totalCapacity = 1000;
        ShowTypes.TicketPrice memory ticketPrice = ShowTypes.TicketPrice({minPrice: 10, maxPrice: 100});
        uint256[] memory split = new uint256[](3);
        split[0] = 40;
        split[1] = 40;
        split[2] = 20;

        bytes32 showId = showInstance.proposeShow(name, description, artists, venue.coordinates, radius, sellOutThreshold, totalCapacity, ticketPrice, split);

        // Simulate the passage of time by increasing the block timestamp
        vm.warp(block.timestamp + 31 days);

        // Simulate the expiry check
//        ticketInstance.checkAndUpdateExpiry(showId);

        // Validate that the show status is "Expired"
        Show.Status status = showInstance.getShowStatus(showId);
        assertEq(uint(status), uint(ShowTypes.Status.Expired));
    }

}


