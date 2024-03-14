// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ShowTypes } from "./types/ShowTypes.sol";
import { VenueTypes } from "../venue/storage/VenueStorage.sol";

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

    /// @notice Event emitted when the expiry of a show is updated.
    /// @param showId Unique identifier for the show
    /// @param expiry New expiry time for the show
    event ExpiryUpdated(bytes32 indexed showId, uint256 expiry);

    /// @notice Event emitted when the venue of a show is updated.
    /// @param showId Unique identifier for the show
    /// @param newVenue New venue details for the show
    event VenueUpdated(bytes32 indexed showId, VenueTypes.Venue newVenue);

    /// @notice Event emitted when a ticket is refunded.
    /// @param user Address of the user who received the refund
    /// @param showId Unique identifier for the show
    /// @param refundAmount Amount refunded to the user
    event TicketRefunded(address indexed user, bytes32 indexed showId, uint256 refundAmount);


    /// @notice Event emitted when a refund is withdrawn.
    /// @param user Address of the user who withdrew the refund
    /// @param showId Unique identifier for the show
    /// @param amount Amount withdrawn by the user
    event RefundWithdrawn(address indexed user, bytes32 indexed showId, uint256 amount);

    /// @notice Event emitted when a show expires.
    /// @param showId Unique identifier for the show
    event ShowExpired(bytes32 indexed showId);

    /// @notice Event emitted when a withdrawal is made from the show's funds.
    /// @param showId Unique identifier for the show
    /// @param recipient Address of the recipient who received the funds
    /// @param amount Amount withdrawn
    event Withdrawal(bytes32 indexed showId, address indexed recipient, uint256 amount);

    /// @notice Sets the addresses for the Ticket and Venue contracts.
    /// @param _ticketContract Address of the Ticket contract
    /// @param _venueContract Address of the Venue contract
    /// @param _referralContract Address of the ReferralModule contract
    /// @param _artistRegistry Address of the ArtistRegistry contract
    /// @param _organizerRegistry Address of the OrganizerRegistry contract
    /// @param _venueRegistry Address of the VenueRegistry contract
    function setProtocolAddresses(
        address _ticketContract,
        address _venueContract,
        address _referralContract,
        address _artistRegistry,
        address _organizerRegistry,
        address _venueRegistry
    ) external;


    /// @notice Allows users to deposit funds to a show's vault.
    /// @param showId Unique identifier for the show
    function depositToVault(bytes32 showId) external payable;

    /**
   * @notice Checks if a wallet owns at least one ticket for a specific show.
     * @param wallet The address to check for ticket ownership.
     * @param showId The unique identifier of the show.
     * @return ownsTicket A boolean indicating whether the wallet owns at least one ticket to the show.
     */
    function hasTicket(address wallet, bytes32 showId) external view returns (bool ownsTicket);

    /// @notice Proposes a new show.
    /// @param name Name of the show
    /// @param description Description of the show
    /// @param artists Array of artist addresses
    /// @param coordinates Desired location of show
    /// @param radius Radius of desired show
    /// @param sellOutThreshold Sell-out threshold percentage
    /// @param totalCapacity Total capacity of the show
    /// @param ticketPrice Ticket price details
    /// @param split Array representing the percentage split between organizer, artists, and venue
    /// @return showId Unique identifier for the proposed show
    function proposeShow(
        string memory name,
        string memory description,
        address[] memory artists,
        VenueTypes.Coordinates memory coordinates,
        uint256 radius,
        uint8 sellOutThreshold,
        uint256 totalCapacity,
        TicketPrice memory ticketPrice,
        uint256[] memory split
    ) external returns (bytes32 showId);

    /// @notice Updates the expiry time of a show.
    /// @param showId Unique identifier for the show
    /// @param expiry New expiry time for the show
    function updateExpiry(bytes32 showId, uint256 expiry) external;

    /// @notice Updates the venue details of a show.
    /// @param showId Unique identifier for the show
    /// @param newVenue New venue details for the show
    function updateVenue(bytes32 showId, VenueTypes.Venue memory newVenue) external;

    /// @notice Cancels a show.
    /// @param showId Unique identifier for the show
    function cancelShow(bytes32 showId) external;

    /// @notice Marks a show as completed.
    /// @param showId Unique identifier for the show
    function completeShow(bytes32 showId) external;

    /// @notice Payouts the funds from a show's vault.
    /// @param showId Unique identifier for the show
    function payout(bytes32 showId) external;

    /// @notice Allows a ticket owner to refund a specific ticket for a show that is either Proposed, Cancelled, or Expired.
    /// @param showId The unique identifier of the show.
    /// @param ticketId The ID of the ticket to be refunded.
    function refundTicket(bytes32 showId, uint256 ticketId) external;

    /// @notice Withdraws a refund.
    /// @param showId Unique identifier for the show
    function withdrawRefund(bytes32 showId) external;

    /// @notice Checks and updates the expiry of a show.
    /// @param showId Unique identifier for the show
    function checkAndUpdateExpiry(bytes32 showId) external;

    /// @notice Sets the price paid for a ticket.
    /// @param showId Unique identifier for the show
    /// @param ticketId Unique identifier for the ticket
    /// @param price Price paid for the ticket
    function setTicketPricePaid(bytes32 showId, uint256 ticketId, uint256 price) external;

    /// @notice Sets the total tickets sold for a specific show.
    /// @param showId The unique identifier of the show.
    /// @param amount The amount to add to the total tickets sold.
    function setTotalTicketsSold(bytes32 showId, uint256 amount) external;

    /// @notice Adds a token ID to a wallet for a specific show.
    /// @param showId Unique identifier for the show
    /// @param wallet Address of the wallet
    /// @param tokenId Token ID to be added
    function addTokenIdToWallet(bytes32 showId, address wallet, uint256 tokenId) external;

    /// @notice Retrieves details of a show by its ID.
    /// @param showId Unique identifier for the show
    /// @return name Name of the show
    /// @return description Description of the show
    /// @return organizer Address of the organizer
    /// @return artists Array of artist addresses
    /// @return venue Venue details
    /// @return ticketPrice Ticket price details
    /// @return sellOutThreshold Sell-out threshold percentage
    /// @return totalCapacity Total capacity of the show
    /// @return status Status of the show
    /// @return isActive Whether the show is active or not
    function getShowById(bytes32 showId) external view returns (
        string memory name,
        string memory description,
        address organizer,
        address[] memory artists,
        VenueTypes.Venue memory venue,
        TicketPrice memory ticketPrice,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        Status status,
        bool isActive
    );

    /// @notice Retrieves the sell-out threshold of a show.
    /// @param showId Unique identifier for the show
    /// @return Sell-out threshold percentage of the show
    function getSellOutThreshold(bytes32 showId) external view returns (uint256);

    /// @notice Retrieves the status of a show.
    /// @param showId Unique identifier for the show
    /// @return Status of the show
    function getShowStatus(bytes32 showId) external view returns (Status);

    /**
      * @notice Retrieves the organizer's address for a given show ID.
     * @param showId The unique identifier for the show.
     * @return The address of the organizer of the show.
     */
    function getOrganizer(bytes32 showId) external view returns (address);


        /// @notice Retrieves the ticket price details of a show.
    /// @param showId Unique identifier for the show
    /// @return Ticket price details
    function getTicketPrice(bytes32 showId) external view returns (TicketPrice memory);

    /// @notice Retrieves the total capacity of a show.
    /// @param showId Unique identifier for the show
    /// @return Total capacity of the show
    function getTotalCapacity(bytes32 showId) external view returns (uint256);

    /// @notice Retrieves the total tickets sold for a show.
    /// @param showId Unique identifier for the show
    /// @return Total tickets sold for the show
    function getTotalTicketsSold(bytes32 showId) external view returns (uint256);

    /// @notice Retrieves the token IDs associated with a specific show for a given wallet.
    /// @param showId Unique identifier for the show
    /// @param wallet Address of the wallet
    /// @return Array of token IDs associated with the show for the specified wallet
    function getWalletTokenIds(bytes32 showId, address wallet) external view returns (uint256[] memory);

    /// @notice Returns the total number of voters for a specific show, including artists and the organizer.
    /// @param showId Unique identifier for the show
    /// @return Total number of voters (artists + organizer)
    function getNumberOfVoters(bytes32 showId) external view returns (uint256);

    /// @notice Retrieves the price paid for a specific ticket of a show.
    /// @param showId Unique identifier for the show
    /// @param ticketId Unique identifier for the ticket
    /// @return Price paid for the specified ticket
    function getTicketPricePaid(bytes32 showId, uint256 ticketId) external view returns (uint256);

    /// @notice Checks if the given user is an organizer of the specified show.
    /// @param user Address of the user to check
    /// @param showId Unique identifier for the show
    /// @return true if the user is an organizer, false otherwise
    function isOrganizer(address user, bytes32 showId) external view returns (bool);

    /// @notice Checks if the given user is an artist in the specified show.
    /// @param user Address of the user to check
    /// @param showId Unique identifier for the show
    /// @return true if the user is an artist, false otherwise
    function isArtist(address user, bytes32 showId) external view returns (bool);

    /// @notice Checks if an address owns a ticket for a specific show.
    /// @param owner Address to check
    /// @param showId Unique identifier for the show
    /// @return true if the address owns a ticket for the show, false otherwise
    function isTicketOwner(address owner, bytes32 showId, uint256 ticketId) external view returns (bool);

    /**
    * @notice Retrieves the refund amount owed to a specific address for a given show.
     * @param showId The unique identifier of the show.
     * @param user The address of the user.
     * @return amountOwed The amount of refund owed to the user for the specified show.
     */
    function getPendingRefund(bytes32 showId, address user) external view returns (uint256 amountOwed);

    /**
    * @notice Checks and updates the show status based on ticket sales and sell-out threshold.
     * @param showId The unique identifier for the show to check and update the status of.
     */
    function checkAndUpdateShowStatus(bytes32 showId) external;
}
