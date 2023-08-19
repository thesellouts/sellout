pragma solidity 0.8.16;

import "../show/Show.sol";
import "../ticket/Ticket.sol";
import "../venue/Venue.sol";

contract SellOutFactory {
    Show public showInstance;
    Ticket public ticketInstance;
    Venue public venueInstance;

    function deployContracts() public {
        // Deploy the Show contract
        showInstance = new Show();

        // Deploy the Ticket contract, passing the Show contract's address
        ticketInstance = new Ticket(address(showInstance));

        // Deploy the Venue contract, passing the Show contract's address
        venueInstance = new Venue(address(showInstance), address(ticketInstance));

        // Set the Ticket and Venue contract's addresses in the Show contract
        showInstance.setTicketAndVenueContractAddresses(address(ticketInstance), address(venueInstance));
    }
}
