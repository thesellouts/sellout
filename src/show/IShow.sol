// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ShowTypes } from "./types/ShowTypes.sol";
import { VenueTypes } from "../venue/storage/VenueStorage.sol";

/// @title IShow Interface
/// @notice Interface for the Show contract detailing functionalities with events and external functions for show management.
interface IShow is ShowTypes {
    /// Events

    /// @notice Emitted when the expiry of a show is updated.
    /// @param showId The unique identifier of the show.
    /// @param expiry The new expiry time for the show in UNIX timestamp.
    event ExpiryUpdated(bytes32 indexed showId, uint256 expiry);

    /// @notice Emitted when a user successfully withdraws their refund for a ticket.
    /// @param user The address of the user withdrawing the refund.
    /// @param showId The unique identifier of the show.
    /// @param amount The amount of the refund.
    event RefundWithdrawn(address indexed user, bytes32 indexed showId, uint256 amount);

    /// @notice Emitted when a show is marked as expired.
    /// @param showId The unique identifier of the show.
    event ShowExpired(bytes32 indexed showId);

    /// @notice Emitted when tickets from a specific tier are consumed
    /// @param showId ID of the show
    /// @param tierIndex Index of the ticket tier
    /// @param amount Number of tickets consumed
    event TicketTierConsumed(bytes32 indexed showId, uint256 indexed tierIndex, uint256 amount);

     // @notice Event emitted when ERC20 tokens are deposited into a show's vault.
     // @param showId The unique identifier of the show receiving the deposit.
     // @param tokenAddress The address of the ERC20 token being deposited.
     // @param depositor The address of the account making the deposit.
     // @param amount The amount of ERC20 tokens deposited.
    event ERC20Deposited(bytes32 indexed showId, address indexed tokenAddress, address indexed depositor, uint256 amount);


    /// @notice Emitted upon the proposal of a new show.
    /// @param showId The unique identifier of the proposed show.
    /// @param organizer The address of the organizer proposing the show.
    /// @param name The name of the proposed show.
    /// @param artists An array of addresses representing the artists involved in the show.
    /// @param description A description of the proposed show.
    /// @param sellOutThreshold The percentage threshold for considering the show sold out.
    /// @param split An array representing the revenue split between the organizer, artists, and venue.
    /// @param currencyAddress The total ticket capacity for the show.
    event ShowProposed(
        bytes32 indexed showId,
        address indexed organizer,
        string name,
        address[] artists,
        string description,
        uint256 sellOutThreshold,
        uint256[] split,
        address currencyAddress
    );

    /// @notice Emitted when the status of a show is updated.
    /// @param showId The unique identifier of the show.
    /// @param status The new status of the show.
    event StatusUpdated(bytes32 indexed showId, Status status);

    /// @notice Emitted when a ticket is refunded.
    /// @param user The address of the user receiving the refund.
    /// @param showId The unique identifier of the show for which the ticket was refunded.
    /// @param refundAmount The amount refunded to the user.
    event TicketRefunded(address indexed user, bytes32 indexed showId, uint256 refundAmount);

    /// @notice Emitted when the venue details of a show are updated.
    /// @param showId The unique identifier of the show.
    /// @param newVenue The new venue details of the show.
    event VenueUpdated(bytes32 indexed showId, VenueTypes.Venue newVenue);

    /// @notice Emitted upon a successful withdrawal from the show's funds.
    /// @param showId The unique identifier of the show.
    /// @param recipient The address of the recipient who received the funds.
    /// @param amount The amount of funds withdrawn.
    /// @param paymentToken erc20 the ticket was priced in.
    event Withdrawal(bytes32 indexed showId, address indexed recipient, uint256 amount, address paymentToken);

    // Functions

    /// @notice Adds a token ID to a user's wallet for a specific show, signifying ticket ownership.
    /// @param showId The unique identifier of the show.
    /// @param wallet The wallet address to which the ticket ID will be added.
    /// @param tokenId The unique identifier of the ticket being added to the wallet.
    function addTokenIdToWallet(bytes32 showId, address wallet, uint256 tokenId) external;

    /// @notice Cancels a show based on its unique identifier.
    /// @param showId The unique identifier of the show to be cancelled.
    function cancelShow(bytes32 showId) external;

    /// @notice Marks a show as completed, which may trigger fund distributions and other end-of-show processes.
    /// @param showId The unique identifier of the show to be marked as completed.
    function completeShow(bytes32 showId) external;

    /// @notice Consumes a specified number of tickets from a ticket tier for a given show.
    /// @dev This function should only be callable by authorized contracts, such as the Ticket contract.
    /// @param showId The unique identifier of the show.
    /// @param tierIndex The index of the ticket tier from which tickets are to be consumed.
    /// @param amount The number of tickets to consume from the specified tier.
    function consumeTicketTier(bytes32 showId, uint256 tierIndex, uint256 amount) external;

    /// @notice Allows the deposit of funds into a show's vault, contributing towards the show's financial pool.
    /// @param showId The unique identifier of the show for which the funds are being deposited.
    function depositToVault(bytes32 showId) external payable;

    /// @notice Deposits specified ERC20 tokens into the vault for a specific show.
    /// @dev Requires approval for the contract to transfer tokens on behalf of the sender.
    /// @param showId Unique identifier for the show.
    /// @param amount Amount of ERC20 tokens to deposit.
    /// @param paymentToken Address of the ERC20 token to deposit.
    /// @param ticketRecipient Address of the ticket recipient.
    function depositToVaultERC20(bytes32 showId, uint256 amount, address paymentToken, address ticketRecipient) external;

    /// @notice Retrieves the number of voters for a specific show, including both artists and the organizer.
    /// @param showId The unique identifier of the show.
    /// @return The total number of voters associated with the show.
    function getNumberOfVoters(bytes32 showId) external view returns (uint256);

    /// @notice Retrieves the organizer's address for a given show.
    /// @param showId The unique identifier of the show.
    /// @return The address of the show's organizer.
    function getOrganizer(bytes32 showId) external view returns (address);

    /// @notice Retrieves detailed information about a show by its unique identifier.
    /// @param showId The unique identifier of the show.
    /// @return name The name of the show.
    /// @return description A description of the show.
    /// @return organizer The address of the show's organizer.
    /// @return artists An array of addresses representing the artists involved in the show.
    /// @return venue Detailed venue information for the show.
    /// @return ticketTiers An array of ticket tiers, including pricing and availability for each tier.
    /// @return sellOutThreshold The sell-out threshold for the show, expressed as a percentage.
    /// @return totalCapacity The total capacity of tickets for the show.
    /// @return status The current status of the show.
    /// @return isActive A boolean indicating whether the show is active.
    /// @return currencyAddress The address of the currency the show is Priced in
    function getShowById(bytes32 showId) external view returns (
        string memory name,
        string memory description,
        address organizer,
        address[] memory artists,
        VenueTypes.Venue memory venue,
        ShowTypes.TicketTier[] memory ticketTiers,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        Status status,
        bool isActive,
        address currencyAddress
    );

    /// @notice Retrieves the current status of a show based on its unique identifier.
    /// @param showId The unique identifier of the show.
    /// @return The current status of the show.
    function getShowStatus(bytes32 showId) external view returns (Status);

    /// @notice Retrieves the price paid for a specific ticket of a show.
    /// @param showId The unique identifier of the show.
    /// @param ticketId The unique identifier of the ticket.
    /// @return The price paid for the ticket.
    function getTicketPricePaid(bytes32 showId, uint256 ticketId) external view returns (uint256);

    /// @notice Retrieves information about a specific ticket tier within a show.
    /// @param showId The unique identifier of the show.
    /// @param tierIndex The index of the ticket tier within the show.
    /// @return name The name of the ticket tier.
    /// @return price The price of tickets within this tier.
    /// @return ticketsAvailable The number of tickets available for sale in this tier.
    function getTicketTierInfo(bytes32 showId, uint256 tierIndex) external view returns (string memory name, uint256 price, uint256 ticketsAvailable);

    /// @notice Retrieves the total number of tickets sold for a specific show.
    /// @param showId The unique identifier of the show.
    /// @return The total number of tickets sold.
    function getTotalTicketsSold(bytes32 showId) external view returns (uint256);

    /// @notice Retrieves the token IDs associated with a specific show for a given wallet.
    /// @param showId The unique identifier of the show.
    /// @param wallet The address of the wallet.
    /// @return An array of token IDs associated with the show for the specified wallet.
    function getWalletTokenIds(bytes32 showId, address wallet) external view returns (uint256[] memory);

    /// @notice Checks if a wallet owns at least one ticket for a specific show.
    /// @param wallet The address of the wallet to check.
    /// @param showId The unique identifier of the show.
    /// @return ownsTicket A boolean indicating whether the wallet owns at least one ticket for the show.
    function hasTicket(address wallet, bytes32 showId) external view returns (bool ownsTicket);

    /// @notice Checks if the specified user is an artist in the given show.
    /// @param user The address of the user to check.
    /// @param showId The unique identifier of the show.
    /// @return A boolean indicating whether the user is an artist in the show.
    function isArtist(address user, bytes32 showId) external view returns (bool);

    /// @notice Checks if the specified user is the organizer of the given show.
    /// @param user The address of the user to check.
    /// @param showId The unique identifier of the show.
    /// @return A boolean indicating whether the user is the organizer of the show.
    function isOrganizer(address user, bytes32 showId) external view returns (bool);

    /// @notice Checks if the specified owner owns a ticket for the given show.
    /// @param owner The address of the potential ticket owner.
    /// @param showId The unique identifier of the show.
    /// @param ticketId The unique identifier of the ticket.
    /// @return A boolean indicating whether the owner has the ticket for the show.
    function isTicketOwner(address owner, bytes32 showId, uint256 ticketId) external view returns (bool);

    /// @notice Initiates a payout of funds from a show's vault to the specified showId.
    /// @param showId The unique identifier of the show for which the payout is being requested.
    function payout(bytes32 showId) external;

    /// @notice Proposes a new show with detailed configuration encapsulated within a `ShowProposal` struct.
    /// @param proposal A `ShowProposal` struct containing all the necessary details for proposing a new show, including
    /// name, description, artist addresses, venue coordinates, radius, sell-out threshold, total capacity, ticket tiers,
    /// revenue split configuration, and the currency address for ticket sales.
    /// @dev This function initiates the creation of a show by validating the input parameters encapsulated in the proposal,
    /// then creates a new show based on these parameters. It is the entry point for organizers to propose new shows to the platform.
    /// The function requires that the caller is a registered organizer and that the artists included in the proposal are registered artists.
    /// @return showId The unique identifier for the newly proposed show, generated based on the proposal details.
    function proposeShow(ShowProposal memory proposal) external returns (bytes32 showId);

    /// @notice Allows a ticket owner to request a refund for a specific ticket of a show, under certain conditions.
    /// @param showId The unique identifier of the show for which the refund is requested.
    /// @param ticketId The unique identifier of the ticket being refunded.
    function refundTicket(bytes32 showId, uint256 ticketId) external;

    /// @notice Sets the protocol addresses for Ticket, Venue, Referral, Artist Registry, Organizer Registry, and Venue Registry contracts.
    /// @param _ticketContract The address of the Ticket contract.
    /// @param _venueContract The address of the Venue contract.
    /// @param _referralContract The address of the ReferralModule contract.
    /// @param _artistRegistry The address of the ArtistRegistry contract.
    /// @param _organizerRegistry The address of the OrganizerRegistry contract.
    /// @param _venueRegistry The address of the VenueRegistry contract.
    function setProtocolAddresses(
        address _ticketContract,
        address _venueContract,
        address _referralContract,
        address _artistRegistry,
        address _organizerRegistry,
        address _venueRegistry
    ) external;

    /// @notice Sets the price paid for a specific ticket of a show.
    /// @param showId The unique identifier of the show.
    /// @param ticketId The unique identifier of the ticket.
    /// @param price The price paid for the ticket.
    function setTicketPricePaid(bytes32 showId, uint256 ticketId, uint256 price) external;

    /// @notice Sets the ownership status of a ticket for a specific show.
    /// @dev This function should only be callable by the Ticket contract or other authorized contracts.
    /// @param showId The unique identifier of the show.
    /// @param owner The address of the ticket owner.
    /// @param ticketId The unique identifier of the ticket.
    /// @param isOwned A boolean indicating the ownership status to be set.
    function setTicketOwnership(bytes32 showId, address owner, uint256 ticketId, bool isOwned) external;

    /// @notice Sets the total number of tickets sold for a specific show.
    /// @param showId The unique identifier of the show.
    /// @param amount The amount to be added to the total tickets sold count.
    function setTotalTicketsSold(bytes32 showId, uint256 amount) external;

    /// @notice Updates the status of a show, potentially triggered by ticket sales reaching the sell-out threshold or other criteria.
    /// @param showId The unique identifier of the show.
    /// @param status The new status to be assigned to the show.
    function updateStatus(bytes32 showId, Status status) external;

    /// @notice Checks and updates the status of a show to 'SoldOut' if ticket sales meet or exceed the sell-out threshold.
    /// @param showId The unique identifier of the show to be evaluated.
    function updateStatusIfSoldOut(bytes32 showId) external;

    /// @notice Updates the venue details for a specific show.
    /// @param showId The unique identifier of the show.
    /// @param newVenue The new venue details to be applied to the show.
    function updateShowVenue(bytes32 showId, VenueTypes.Venue memory newVenue) external;

    /// @notice Updates the date for an accepted show.
    /// @dev Only callable by the Venue contract for shows in the Accepted status.
    /// @param showId The unique identifier of the show whose date is to be updated.
    /// @param newDate The new date (timestamp) for the show.
    function updateShowDate(bytes32 showId, uint256 newDate) external;

    /// @notice Allows a user to withdraw their refund for a previously refunded ticket.
    /// @param showId The unique identifier of the show for which the refund is being withdrawn.
    function withdrawRefund(bytes32 showId) external;
}
