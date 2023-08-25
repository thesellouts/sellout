// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./types/ShowTypes.sol";
import "../venue/types/VenueTypes.sol";

/// @title IShow
/// @author taayyohh
/// @notice Interface for the Show contract, defining the main events, errors, and functions.
interface IShow is ShowTypes {

    /// @notice Event emitted when the status of a show is updated.
    /// @param showId Unique identifier for the show
    /// @param status New status for the show
    event StatusUpdated(bytes32 indexed showId, Status status);

    /// @notice Event emitted when a new show is proposed.
    /// @param showId Unique identifier for the show
    /// @param organizer Address of the organizer
    /// @param name Name of the show
    /// @param artists Array of artist addresses
    /// @param description Description of the show
    /// @param ticketPrice Ticket price details
    /// @param sellOutThreshold Sell-out threshold percentage
    /// @param split Array representing the percentage split between organizer, artists, and venue
    event ShowProposed(
        bytes32 indexed showId,
        address indexed organizer,
        string name,
        address[] artists,
        string description,
        TicketPrice ticketPrice,
        uint256 sellOutThreshold,
        uint256[] split
    );

    // Add other events from the Show contract
    event ExpiryUpdated(bytes32 indexed showId, uint256 expiry);
    event VenueUpdated(bytes32 indexed showId, VenueTypes.Venue newVenue);
    event TicketRefunded(address indexed user, bytes32 indexed showId, uint256 refundAmount);
    event RefundWithdrawn(address indexed user, bytes32 indexed showId, uint256 amount);
    event ShowExpired(bytes32 indexed showId);
    event Withdrawal(bytes32 indexed showId, address indexed recipient, uint256 amount);

    // Functions from the Show contract
    function setTicketAndVenueContractAddresses(address _ticketContract, address _venueContract) external;
    function depositToVault(bytes32 showId) external payable;
    function proposeShow(
        string memory name,
        string memory description,
        address[] memory artists,
        VenueTypes.Venue memory venue,
        uint8 sellOutThreshold,
        uint256 totalCapacity,
        TicketPrice memory ticketPrice,
        uint256[] memory split
    ) external returns (bytes32 showId);
    function updateExpiry(bytes32 showId, uint256 expiry) external;
    function cancelShow(bytes32 showId) external;
    function completeShow(bytes32 showId) external;
    function payout(bytes32 showId) external;
    function updateStatus(bytes32 showId, Status _status) external;
    function refundTicket(bytes32 showId) external;
    function setVenue(bytes32 showId, VenueTypes.Venue memory newVenue) external;
    function checkAndUpdateExpiry(bytes32 showId) external;
    function setTicketPricePaid(bytes32 showId, uint256 ticketId, uint256 price) external;
    function incrementTotalTicketsSold(bytes32 showId) external;
    function setTicketOwnership(address user, bytes32 showId, bool owns) external;
    function addTokenIdToWallet(bytes32 showId, address wallet, uint256 tokenId) external;
}
