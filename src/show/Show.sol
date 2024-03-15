// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IShow } from "./IShow.sol";
import { ShowStorage, ShowTypes } from "./storage/ShowStorage.sol";

import { Ticket } from "../ticket/Ticket.sol";
import { ReferralModule } from "../registry/referral/ReferralModule.sol";
import { VenueTypes } from "../venue/storage/VenueStorage.sol";
import { IArtistRegistry } from "../registry/artist/IArtistRegistry.sol";
import { IOrganizerRegistry } from "../registry/organizer/IOrganizerRegistry.sol";
import { IVenueRegistry } from "../registry/venue/IVenueRegistry.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";


/// @title Sellout Show
/// @author taayyohh
/// @notice Manages show proposals, statuses, and fund distribution
contract Show is Initializable, IShow, ShowStorage, ReentrancyGuardUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
    address public ticketContract;
    address public venueContract;
    address public referralContract;

    address public artistRegistryContract;
    address public organizerRegistryContract;
    address public venueRegistryContract;

    Ticket public ticketInstance;
    ReferralModule public referralInstance;
    IArtistRegistry public artistRegistryInstance;
    IOrganizerRegistry public organizerRegistryInstance;
    IVenueRegistry public venueRegistryInstance;
    bool private areContractsSet = false;

    address public SELLOUT_PROTOCOL_WALLET;

    function initialize(address _selloutProtocolWallet) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init(_selloutProtocolWallet);
        SELLOUT_PROTOCOL_WALLET = _selloutProtocolWallet;
    }

    // Modifiers
    modifier onlyOrganizerOrArtist(bytes32 showId) {
        require(isOrganizer(msg.sender, showId) || isArtist(msg.sender, showId), "Not authorized");
        _;
    }
    modifier onlyTicketContract() {
        require(msg.sender == ticketContract, "Only the Ticket contract can call this function");
        _;
    }
    modifier onlyVenueContract() {
        require(msg.sender == venueContract, "Only the Ticket contract can call this function");
        _;
    }
    modifier onlyTicketOrVenue() {
        require(
            msg.sender == venueContract ||
            msg.sender == ticketContract ||
            msg.sender == address(this),
            "Only the Venue, Ticket contract, or this contract can call this function"
        );
        _;
    }
    modifier isExpired(bytes32 showId) {
        require(shows[showId].status != Status.Expired, "Show has expired");
        _;
    }

    /// @notice Sets the Ticket, Venue, and Registry contract addresses
    /// @param _ticketContract Address of the Ticket contract
    /// @param _venueContract Address of the Venue contract
    /// @param _referralContract Address of the ReferralModule contract
    /// @param _artistRegistryContract Address of the ArtistRegistry contract
    /// @param _organizerRegistryContract Address of the OrganizerRegistry contract
    /// @param _venueRegistryContract Address of the VenueRegistry contract
    function setProtocolAddresses(
        address _ticketContract,
        address _venueContract,
        address _referralContract,
        address _artistRegistryContract,
        address _organizerRegistryContract,
        address _venueRegistryContract
    ) public {
        require(!areContractsSet, "Protocol addresses already set");

        // Set core protocol contracts
        ticketContract = _ticketContract;
        venueContract = _venueContract;

        // set contract instances
        ticketInstance = Ticket(_ticketContract);
        referralInstance = ReferralModule(_referralContract);
        artistRegistryInstance = IArtistRegistry(_artistRegistryContract);
        organizerRegistryInstance = IOrganizerRegistry(_organizerRegistryContract);
        venueRegistryInstance = IVenueRegistry(_venueRegistryContract);

        areContractsSet = true;
    }

    /// @notice Deposits Ether into the vault for a specific show
    /// @param showId Unique identifier for the show
    function depositToVault(bytes32 showId) external payable onlyTicketOrVenue {
        showVault[showId] += msg.value;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


    function isOrganizerRegistered(address organizer) internal view returns (bool) {
        (, , address wallet) = organizerRegistryInstance.getOrganizer(organizer);
        return wallet == organizer;
    }

    function isArtistRegistered(address artist) internal view returns (bool) {
        (, , address wallet) = artistRegistryInstance.getArtist(artist);
        return wallet == artist;
    }


    /// @notice Creates a show proposal between one or more artists
    /// @param name Name of the show
    /// @param description Description of the show
    /// @param artists Array of artist addresses
    /// @param coordinates desired location of show
    /// @param radius of desired show
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
        uint256[] memory split // organizer, artists[], venue
    ) external returns (bytes32 showId) {
        // Validation checks
        require(bytes(name).length > 0, "Name is required");
        require(radius > 0, "Venue radius must be greater than 0");
        require(totalCapacity > 0, "Total capacity must be greater than 0");
        require(artists.length > 0, "At least one artist required");
        require(ticketPrice.maxPrice >= ticketPrice.minPrice, "Max ticket price must be greater or equal to min ticket price");
        require(sellOutThreshold >= 50 && sellOutThreshold <= 100, "Sell-out threshold must be between 50 and 100");
        require(coordinates.lat >= -90 * 10**6 && coordinates.lat <= 90 * 10**6, "Invalid latitude");
        require(coordinates.lon >= -180 * 10**6 && coordinates.lon <= 180 * 10**6, "Invalid longitude");
        require(areContractsSet, "Contract addresses must be set");

        require(isOrganizerRegistered(msg.sender), "Organizer must be registered");

        for (uint256 i = 0; i < artists.length; i++) {
            require(isArtistRegistered(artists[i]), "All artists must be registered");
        }

        validateSplit(split, artists.length);

        // Create a proposal ID by hashing the relevant parameters
        //TODO: add revert if showId exists
        showId = keccak256(abi.encodePacked(msg.sender, artists, coordinates.lat, coordinates.lon, radius, sellOutThreshold, totalCapacity));
        uint256 expiry = block.timestamp + 30 days;


        // Construct the venue with the coordinates
        VenueTypes.Venue memory venue = VenueTypes.Venue({
            name: "",
            coordinates: coordinates,
            totalCapacity: totalCapacity,
            wallet: address(0)
        });

        // Create the show proposal
        shows[showId] = Show({
            showId: showId,
            name: name,
            description: description,
            artists: artists,
            organizer: msg.sender,
            radius: radius,
            venue: venue,
            ticketPrice: ticketPrice,
            sellOutThreshold: sellOutThreshold,
            totalCapacity: totalCapacity,
            status: Status.Proposed,
            isActive: true,
            split: split,
            expiry: expiry,
            showDate: 0
        });

        // Map artists to the show
        for (uint i = 0; i < artists.length; i++) {
            isArtistMapping[showId][artists[i]] = true;
        }

        activeShowCount++;

        emit ShowProposed(showId, msg.sender, name, artists, description, ticketPrice, sellOutThreshold, split);

        return showId;
    }


    /// @notice Updates the expiry time of a show
    /// @param showId Unique identifier for the show
    /// @param expiry New expiry time for the show
    function updateExpiry(bytes32 showId, uint256 expiry) external onlyTicketContract {
        require(shows[showId].status == Status.Proposed, "Show must be in Proposed status");
        shows[showId].expiry = expiry;
        emit ExpiryUpdated(showId, expiry);
    }

    /// @notice Checks and updates the expiry status of a show
    /// @param showId Unique identifier for the show
    function checkAndUpdateExpiry(bytes32 showId) public onlyTicketContract {
        Show storage show = shows[showId];
        if (block.timestamp >= show.expiry && show.status != Status.Expired) {
            show.status = Status.Expired;
            activeShowCount--;
            emit ShowExpired(showId);
        }
    }



    // @notice Checks if the total tickets sold for a show has reached or exceeded the sell-out threshold.
    // @param showId The unique identifier for the show
    function checkAndUpdateShowStatus(bytes32 showId) public onlyTicketOrVenue {
        Show storage show = shows[showId];
        uint256 soldTickets = getTotalTicketsSold(showId);
        if (soldTickets >= show.totalCapacity * show.sellOutThreshold / 100 && show.status == Status.Proposed) {
            updateStatus(showId, Status.SoldOut);
        }
    }

    /// @notice Updates the status of a show
    /// @param showId Unique identifier for the show
    /// @param _status New status for the show
    function updateStatus(bytes32 showId, Status _status) internal {
        shows[showId].status = _status;
        emit StatusUpdated(showId, _status);
    }

    /// @notice Updates the venue information for a specific show.
    /// @param showId Unique identifier for the show.
    /// @param newVenue New venue information to be set.
    function updateVenue(bytes32 showId, VenueTypes.Venue memory newVenue) external onlyVenueContract {
        // Retrieve the show using the showId
        Show storage show = shows[showId];

        // Update the venue information
        show.venue = newVenue;

        // Optionally, you could emit an event to log the change
        emit VenueUpdated(showId, newVenue);
    }

    /// @notice Cancels a sold-out show
    /// @param showId Unique identifier for the show
    function cancelShow(bytes32 showId) public onlyOrganizerOrArtist(showId) {
        Show storage show = shows[showId];
        require(show.status == Status.SoldOut || show.status == Status.Accepted || show.status == Status.Upcoming, "Show must be Pending");
        show.status = Status.Cancelled;
        //TODO: if show is cancelled refunds must be available
        //TODO:: maybe consider safegaurds here, x percent need to cancel
    }

    /// @notice Completes a show and distributes funds
    /// @param showId Unique identifier for the show
    function completeShow(bytes32 showId) public onlyTicketContract {
        Show storage show = shows[showId];
        require(show.status == Status.Accepted, "Show must be Accepted");

        uint256 totalAmount = showVault[showId];
        require(totalAmount > 0, "No funds to distribute");

        uint256[] memory split = show.split;

        // Calculate protocol's share (1%)
        uint256 protocolShare = totalAmount / 100;
        pendingWithdrawals[showId][SELLOUT_PROTOCOL_WALLET] = protocolShare;

        // Reduce totalAmount by protocol's share
        totalAmount -= protocolShare;

        // Calculate organizer's share
        uint256 organizerShare = totalAmount * split[0] / 100;
        pendingWithdrawals[showId][show.organizer] = organizerShare;

        // Calculate artists' shares
        for (uint i = 0; i < show.artists.length; i++) {
            uint256 artistShare = totalAmount * split[i + 1] / 100;
            pendingWithdrawals[showId][show.artists[i]] = artistShare;
        }

        // Calculate venue's share
        uint256 venueShare = totalAmount * split[split.length - 1] / 100;
        pendingWithdrawals[showId][show.venue.wallet] = venueShare;

        showVault[showId] = 0;

        // Update the status
        show.status = Status.Completed;

        // Increment referral credits for the participants of the show
        // Assuming you have a referralModule instance correctly set up in the contract
        // Each participant gets 1 credit to register one organizer, artist, and venue respectively.
        referralInstance.incrementReferralCredits(show.organizer, 1, 1, 1);
        for (uint i = 0; i < show.artists.length; i++) {
            referralInstance.incrementReferralCredits(show.artists[i], 1, 1, 1);
        }
        referralInstance.incrementReferralCredits(show.venue.wallet, 1, 1, 1);

        // Emit event for show completion
        emit StatusUpdated(showId, Status.Completed);
    }


    /// @notice Allows the organizer or artist to withdraw funds after a show has been completed.
    /// @param showId The unique identifier of the show.
    function payout(bytes32 showId) public onlyOrganizerOrArtist(showId) {
        Show storage show = shows[showId];
        require(show.status == Status.Completed, "Show must be Completed");
        require(block.timestamp == show.showDate + 2 days, "Show cool down has not ended");

        uint256 amount = pendingWithdrawals[showId][msg.sender];
        require(amount > 0, "No funds to withdraw");

        // Ensure the recipient can't re-entrantly call this function
        pendingWithdrawals[showId][msg.sender] = 0;

        payable(msg.sender).transfer(amount);
        emit Withdrawal(showId, msg.sender, amount);
    }


    /// @notice Allows a ticket owner to refund a specific ticket for a show.
    /// @dev This function now also checks if the show's status should be updated from 'SoldOut' to 'Proposed'
    /// if the total tickets sold falls below the sellout threshold after the refund.
    /// @param showId The unique identifier of the show.
    /// @param ticketId The ID of the ticket to be refunded.
    function refundTicket(bytes32 showId, uint256 ticketId) public {
        require(shows[showId].status == Status.Proposed || shows[showId].status == Status.Cancelled || shows[showId].status == Status.Expired, "Funds are locked or show is sold out");
        require(isTicketOwner(msg.sender, showId, ticketId), "User does not own the ticket for this show");
        uint256 refundAmount = getTicketPricePaid(showId, ticketId);
        require(refundAmount > 0, "Ticket not purchased");

        // Update total tickets sold and potentially the show status
        updateTicketsSoldAndShowStatusAfterRefund(showId, ticketId, refundAmount);

        // Refund logic
        payable(msg.sender).transfer(refundAmount);
        emit TicketRefunded(msg.sender, showId, refundAmount);
    }

    /// @dev Updates total tickets sold and potentially the show status after a ticket refund.
    /// @param showId The unique identifier of the show.
    /// @param ticketId The ID of the ticket being refunded.
    /// @param refundAmount The amount to be refunded.
    function updateTicketsSoldAndShowStatusAfterRefund(bytes32 showId, uint256 ticketId, uint256 refundAmount) internal {
        Show storage show = shows[showId];

        // Decrease total tickets sold
        totalTicketsSold[showId]--;

        // Update the show vault and pending withdrawals
        showVault[showId] -= refundAmount;
        pendingWithdrawals[showId][msg.sender] += refundAmount;

        // Update show status if needed
        uint256 soldTickets = totalTicketsSold[showId];
        uint256 sellOutThresholdTickets = (show.totalCapacity * show.sellOutThreshold) / 100;
        if (soldTickets < sellOutThresholdTickets && show.status == Status.SoldOut) {
            show.status = Status.Proposed;
            emit StatusUpdated(showId, Status.Proposed);
        }

        // Perform cleanup for the refunded ticket
        delete ticketPricePaid[showId][ticketId];
        removeTicketId(showId, msg.sender, ticketId);
        ticketInstance.burnTokens(ticketId, 1, msg.sender);
    }

    // * @notice Removes a specific ticket ID for a given wallet and show.
    // * @param showId The unique identifier of the show.
    // * @param wallet The address of the wallet owning the ticket.
    // * @param ticketId The ID of the ticket to be removed.
    // *
    function removeTicketId(bytes32 showId, address wallet, uint256 ticketId) internal {
        uint256[] storage ticketIds = walletToShowToTokenIds[showId][wallet];
        for (uint256 i = 0; i < ticketIds.length; i++) {
            if (ticketIds[i] == ticketId) {
                ticketIds[i] = ticketIds[ticketIds.length - 1];
                ticketIds.pop();
                break;
            }
        }
    }

    /// @notice Retrieves the refund amount owed to a specific address for a given show.
    /// @param showId The unique identifier of the show.
    /// @param user The address of the user.
    /// @return amountOwed The amount of refund owed to the user for the specified show.
    function getPendingRefund(bytes32 showId, address user) public view returns (uint256 amountOwed) {
        return pendingWithdrawals[showId][user];
    }


    /// @notice Check if an address owns a ticket for a specific show
    /// @param owner The address to check
    /// @param showId The ID of the show
    /// @return true if the address owns a ticket for the show, false otherwise
    function isTicketOwner(address owner, bytes32 showId, uint256 ticketId) public view returns (bool) {
        uint256[] memory ticketIds = walletToShowToTokenIds[showId][owner];
        for (uint256 i = 0; i < ticketIds.length; i++) {
            if (ticketIds[i] == ticketId) {
                return true;
            }
        }
        return false;
    }

    /// @notice Checks if a wallet owns at least one ticket for a specific show
    /// @param wallet The address to check for ticket ownership.
    /// @param showId The unique identifier of the show.
    /// @return ownsTicket A boolean indicating whether the wallet owns at least one ticket to the show.
    function hasTicket(address wallet, bytes32 showId) public view returns (bool ownsTicket) {
        return walletToShowToTokenIds[showId][wallet].length > 0;
    }


    // @notice Allows a user to withdraw their refund for a show.
    // @param showId The unique identifier of the show.
    function withdrawRefund(bytes32 showId) public nonReentrant {
        Show storage show = shows[showId];

        // Check if the show is in an appropriate status for refunds
        require(
            show.status == Status.Refunded ||
            show.status == Status.Expired ||
            show.status == Status.Cancelled ||
            show.status == Status.Proposed,
            "Refunds are not available for this show status"
        );

        uint256 amount = pendingWithdrawals[showId][msg.sender];
        require(amount > 0, "No funds to withdraw");
        require(address(this).balance >= amount, "Insufficient funds in the contract");

        // Ensure the refund amount is set to 0 before transferring
        pendingWithdrawals[showId][msg.sender] = 0;

        payable(msg.sender).transfer(amount);
        emit RefundWithdrawn(msg.sender, showId, amount);
    }


    // @notice Sets the price paid for a specific ticket of a show.
    // @param showId The unique identifier of the show.
    // @param ticketId The unique identifier of the ticket within the show.
    // @param price The price paid for the ticket.
    // @dev This function can only be called by the ticket contract (as indicated by the onlyTicketContract modifier).
    function setTicketPricePaid(bytes32 showId, uint256 ticketId, uint256 price) external onlyTicketContract {
        ticketPricePaid[showId][ticketId] = price;
    }

    // @notice Sets the price paid for a specific ticket of a show.
    // @param showId The unique identifier of the show.
    // @param ticketId The unique identifier of the ticket within the show.
    // @param price The price paid for the ticket.
    // @dev This function can only be called by the ticket contract (as indicated by the onlyTicketContract modifier).
    function setTotalTicketsSold(bytes32 showId, uint256 amount) external onlyTicketContract {
        totalTicketsSold[showId] = totalTicketsSold[showId] + amount;
    }


    // @notice Adds a token ID to a user's wallet for a specific show.
    // @param showId The unique identifier of the show.
    // @param wallet The address of the user's wallet.
    // @param tokenId The unique identifier of the token.
    // @dev This function can only be called by the ticket contract (as indicated by the onlyTicketContract modifier).
    function addTokenIdToWallet(bytes32 showId, address wallet, uint256 tokenId) external onlyTicketContract {
        walletToShowToTokenIds[showId][wallet].push(tokenId);
    }


    /// @notice Retrieves the details of a show
    /// @param showId Unique identifier for the show
    /// @return name Name of the show
    /// @return description Description of the show
    /// @return organizer Organizer's address
    /// @return artists Array of artist addresses
    /// @return venue Venue details
    /// @return ticketPrice Ticket price details
    /// @return sellOutThreshold Sell-out threshold percentage
    /// @return totalCapacity Total capacity of the show
    /// @return status Status of the show
    /// @return isActive Whether the show is active
    function getShowById(bytes32 showId) public view returns (
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
    ) {
        Show storage show = shows[showId];

        return (
            show.name,
            show.description,
            show.organizer,
            show.artists,
            show.venue,
            show.ticketPrice,
            show.sellOutThreshold,
            show.totalCapacity,
            show.status,
            show.isActive
        );
    }

    /// @notice Retrieves the sell-out threshold of a show
    /// @param showId Unique identifier for the show
    /// @return Sell-out threshold percentage of the show
    function getSellOutThreshold(bytes32 showId) public view returns (uint256) {
        return shows[showId].sellOutThreshold;
    }

    /// @notice Retrieves the status of a show
    /// @param showId Unique identifier for the show
    /// @return Status of the show
    function getShowStatus(bytes32 showId) public view returns (Status) {
        return shows[showId].status;
    }

    /// @notice Retrieves the ticket price details of a show
    /// @param showId Unique identifier for the show
    /// @return TicketPrice structure containing min and max price
    function getTicketPrice(bytes32 showId) public view returns (TicketPrice memory) {
        return shows[showId].ticketPrice;
    }

    /// @notice Retrieves the total capacity of a show
    /// @param showId Unique identifier for the show
    /// @return Total capacity of the show
    function getTotalCapacity(bytes32 showId) public view returns (uint256) {
        return shows[showId].totalCapacity;
    }


    /// @notice Retrieves the status of a show
    /// @param showId Unique identifier for the show
    /// @return total tickets sold
    function getTotalTicketsSold(bytes32 showId) public view returns (uint256) {
        return totalTicketsSold[showId];
    }

    /// @notice Retrieves the token IDs associated with a specific show for a given wallet
    /// @param showId Unique identifier for the show
    /// @param wallet Address of the wallet for which token IDs are being retrieved
    /// @return An array of token IDs associated with the show for the specified wallet
    function getWalletTokenIds(bytes32 showId, address wallet) public view returns (uint256[] memory) {
        return walletToShowToTokenIds[showId][wallet];
    }

    /// @notice Returns the total number of voters for a specific show, including artists and the organizer.
    /// @param showId Unique identifier for the show.
    /// @return Total number of voters (artists + organizer).
    function getNumberOfVoters(bytes32 showId) public view returns (uint256) {
        uint256 numberOfArtists = shows[showId].artists.length;

        // Adding 1 for the organizer
        return numberOfArtists + 1;
    }

    // @notice Retrieves the price paid for a specific ticket of a show.
    // @param showId The unique identifier of the show.
    // @param ticketId The unique identifier of the ticket within the show.
    // @return The price paid for the specified ticket.
    function getTicketPricePaid(bytes32 showId, uint256 ticketId) public view returns (uint256) {
        return ticketPricePaid[showId][ticketId];
    }

    /// @notice Checks if the given user is an organizer of the specified show.
    /// @param user Address of the user to check
    /// @param showId Unique identifier for the show
    /// @return true if the user is an organizer, false otherwise
    function isOrganizer(address user, bytes32 showId) public view returns (bool) {
        return shows[showId].organizer == user;
    }

    /// @notice Checks if the given user is an artist in the specified show.
    /// @param user Address of the user to check
    /// @param showId Unique identifier for the show
    /// @return true if the user is an artist, false otherwise
    function isArtist(address user, bytes32 showId) public view returns (bool) {
        return isArtistMapping[showId][user];
    }

    /// @notice Validates the split percentages between organizer, artists, and venue
    /// @param split Array representing the percentage split
    /// @param numArtists Number of artists in the show
    function validateSplit(uint256[] memory split, uint256 numArtists) internal pure {
        require(split.length == numArtists + 2, "Split array must have a length equal to the number of artists plus 2");

        uint256 sum = 0;
        for (uint i = 0; i < split.length; i++) {
            sum += split[i];
        }
        require(sum == 100, "Split percentages must sum to 100");
    }

    function getOrganizer(bytes32 showId) public view returns (address) {
        return shows[showId].organizer;
    }
}
