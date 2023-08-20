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

    /// @notice Event emitted when a show is deactivated.
    /// @param showId Unique identifier for the show
    /// @param sender Address of the sender who deactivated the show
    event ShowDeactivated(
        bytes32 indexed showId,
        address indexed sender
    );

    /// @notice Event emitted when the expiry date of a show is updated.
    /// @param showId Unique identifier for the show
    /// @param newExpiry New expiry time for the show
    event ExpiryUpdated(bytes32 indexed showId, uint256 newExpiry);

    /// @notice Event emitted when a show has expired.
    /// @param showId Unique identifier for the show
    event ShowExpired(bytes32 indexed showId);

    /// @notice Event emitted when the venue of a show is updated.
    /// @param showId Unique identifier for the show
    /// @param newVenue New venue information to be set
    event VenueUpdated(bytes32 indexed showId, VenueTypes.Venue newVenue);

    /// @notice Event emitted when a withdrawal is made from the show's funds.
    /// @param showId Unique identifier for the show
    /// @param recipient Address of the recipient
    /// @param amount Amount withdrawn
    event Withdrawal(bytes32 indexed showId, address indexed recipient, uint256 amount);


    /// @notice Checks if the given user is an organizer of the specified show.
    function isOrganizer(address user, bytes32 showId) external view returns (bool);

    /// @notice Checks if the given user is an artist in the specified show.
    function isArtist(address user, bytes32 showId) external view returns (bool);

    /// @notice Allows a user to propose a new show.
    function proposeShow(
        string calldata name,
        string calldata description,
        address[] calldata artists,
        VenueTypes.Venue memory venue,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        ShowTypes.TicketPrice memory ticketPrice,
        uint256[] memory split
    ) external returns (bytes32);

    /// @notice Allows an organizer to cancel a show.
    function cancelShow(bytes32 showId) external;

    /// @notice Completes a show and distributes funds.
    function completeShow(bytes32 showId) external;

    /// @notice Retrieves details of a show by its ID.
    function getShowById(bytes32 showId) external view returns (
        string memory name,
        string memory description,
        address organizer,
        address[] memory artists,
        VenueTypes.Venue memory venue,
        ShowTypes.TicketPrice memory ticketPrice,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        ShowTypes.Status status,
        bool isActive
    );

    /// @notice Retrieves the ticket price for a specific show.
    function getTicketPrice(bytes32 showId) external view returns (ShowTypes.TicketPrice memory);

    /// @notice Retrieves the total capacity for a specific show.
    function getTotalCapacity(bytes32 showId) external view returns (uint256);

    /// @notice Retrieves the sell-out threshold for a specific show.
    function getSellOutThreshold(bytes32 showId) external view returns (uint256);

    /// @notice Retrieves the status of a specific show.
    function getShowStatus(bytes32 showId) external view returns (ShowTypes.Status);

    /// @notice Updates the status of a specific show.
    /// @param showId Unique identifier for the show
    /// @param status New status for the show
    function updateStatus(bytes32 showId, ShowTypes.Status status) external;


    /// @notice Sets the Ticket and Venue contract addresses
    /// @param _ticketContract Address of the Ticket contract
    /// @param _venueContract Address of the Venue contract
    function setTicketAndVenueContractAddresses(address _ticketContract, address _venueContract) external;

    /// @notice Deposits Ether into the vault for a specific show
    /// @param showId Unique identifier for the show
    function depositToVault(bytes32 showId) external payable;

    /// @notice Allows a user to withdraw their share of the funds for a specific show
    /// @param showId Unique identifier for the show
    function withdraw(bytes32 showId) external;

    /// @notice Returns the total number of voters for a specific show, including artists and the organizer
    /// @param showId Unique identifier for the show
    /// @return Total number of voters (artists + organizer)
    function getNumberOfVoters(bytes32 showId) external view returns (uint256);

    /// @notice Updates the venue information for a specific show
    /// @param showId Unique identifier for the show
    /// @param newVenue New venue information to be set
    function setVenue(bytes32 showId, VenueTypes.Venue memory newVenue) external;

    /// @notice Checks and updates the expiry status of a show
    /// @param showId Unique identifier for the show
    function checkAndUpdateExpiry(bytes32 showId) external;
}
