// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Show {
    // State variables
    address public organizer;
    string public location; // lat,long,radius
    address[] public artists;
    Venue public venue;
    uint256 public totalCapacity;
    TicketPrice public ticketPrice;
    uint256 public sellOutThreshold; // in percentage
    Status public status;

    // Events
    event ShowProposed(
        address indexed organizer,
        string location,
        uint256 totalCapacity,
        uint256 minTicketPrice,
        uint256 maxTicketPrice,
        uint256 sellOutThreshold
    );
    event VenueSet(string name, string latLong);
    event StatusUpdated(Status status);

    // Venue struct
    struct Venue {
        string name;
        string latLong; // latitude, longitude
    }

    // Ticket price struct
    struct TicketPrice {
        uint256 minPrice; // in wei
        uint256 maxPrice; // in wei
    }

    // Show status enum
    enum Status {
        Proposed,
        SoldOut,
        Completed,
        Refunded
    }

    // Constructor
    constructor(
        address _organizer,
        string memory _location,
        address[] memory _artists,
        uint256 _totalCapacity,
        uint256 _minTicketPrice,
        uint256 _maxTicketPrice,
        uint256 _sellOutThreshold
    ) {
        organizer = _organizer;
        location = _location;
        artists = _artists;
        totalCapacity = _totalCapacity;
        ticketPrice = TicketPrice(_minTicketPrice, _maxTicketPrice);
        sellOutThreshold = _sellOutThreshold;
        status = Status.Proposed;
    }

    // Modifier to restrict access to the organizer
    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only the organizer can perform this action");
        _;
    }

    // Function to propose a new show
    function proposeShow(
        string memory _location,
        address[] memory _artists,
        uint256 _totalCapacity,
        uint256 _minTicketPrice,
        uint256 _maxTicketPrice,
        uint256 _sellOutThreshold
    ) public {
        require(_maxTicketPrice >= _minTicketPrice, "Max ticket price must be greater or equal to min ticket price");
        require(_sellOutThreshold >= 0 && _sellOutThreshold <= 100, "Sell-out threshold must be between 0 and 100");

        organizer = msg.sender;
        location = _location;
        artists = _artists;
        totalCapacity = _totalCapacity;
        ticketPrice = TicketPrice(_minTicketPrice, _maxTicketPrice);
        sellOutThreshold = _sellOutThreshold;
        status = Status.Proposed;

        emit ShowProposed(
            organizer,
            location,
            totalCapacity,
            ticketPrice.minPrice,
            ticketPrice.maxPrice,
            sellOutThreshold
        );
    }

    // Function to set the venue details
    function setVenue(string memory _name, string memory _latLong) public onlyOrganizer {
        venue = Venue(_name, _latLong);
        emit VenueSet(_name, _latLong);
    }

    // Function to update the show status
    function updateStatus(Status _status) public onlyOrganizer {
        status = _status;
        emit StatusUpdated(_status);
    }

    // Function to get all show details
    function getShowDetails()
    public
    view
    returns (
        address _organizer,
        string memory _location,
        address[] memory _artists,
        Venue memory _venue,
        uint256 _totalCapacity,
        TicketPrice memory _ticketPrice,
        uint256 _sellOutThreshold,
        Status _status
    )
    {
        return (
            organizer,
            location,
            artists,
            venue,
            totalCapacity,
            ticketPrice,
            sellOutThreshold,
            status
        );
    }

    // Additional functions, modifiers, and events to be added as needed
}
