pragma solidity 0.8.16;

import "../show/Show.sol";
import "../ticket/Ticket.sol";
import "../venue/Venue.sol";

contract SellOutFactory {
    Show public showInstance;
    Ticket public ticketInstance;
    Venue public venueInstance;

    // State variable to store the Sellout Protocol Wallet address
    address public SELLOUT_PROTOCOL_WALLET;

    constructor() {
        // Set the Sellout Protocol Wallet address to the deployer's address
        SELLOUT_PROTOCOL_WALLET = msg.sender;

        // Deploy the Show contract, passing the Sellout Protocol Wallet address
        showInstance = new Show(SELLOUT_PROTOCOL_WALLET);

        // Deploy the Ticket contract, passing the Show contract's address
        ticketInstance = new Ticket(address(showInstance));

        // Deploy the Venue contract, passing the Show contract's address
        venueInstance = new Venue(address(showInstance), address(ticketInstance));

        // Set the Ticket and Venue contract's addresses in the Show contract
        showInstance.setTicketAndVenueContractAddresses(address(ticketInstance), address(venueInstance));
    }
}
