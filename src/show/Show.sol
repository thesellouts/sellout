// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IShow } from "./IShow.sol";
import { ShowStorage, ShowTypes } from "./storage/ShowStorage.sol";

import { ITicket } from "../ticket/ITicket.sol";
import { ITicketFactory } from "../ticket/ITicketFactory.sol";

import { ReferralModule } from "../registry/referral/ReferralModule.sol";
import { VenueTypes } from "../venue/storage/VenueStorage.sol";
import { IArtistRegistry } from "../registry/artist/IArtistRegistry.sol";
import { IOrganizerRegistry } from "../registry/organizer/IOrganizerRegistry.sol";
import { IVenueRegistry } from "../registry/venue/IVenueRegistry.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { ERC20Upgradeable } from  "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


/// @title Sellout Show
/// @author taayyohh
/// @notice Manages show proposals, statuses, and fund distribution
contract Show is Initializable, IShow, ShowStorage, ReentrancyGuardUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
    function initialize(address _selloutProtocolWallet) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init(_selloutProtocolWallet);
        SELLOUT_PROTOCOL_WALLET = _selloutProtocolWallet;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // Modifiers
    modifier onlyOrganizerOrArtist(bytes32 showId) {
        require(isOrganizer(msg.sender, showId) || isArtist(msg.sender, showId), "Not authorized");
        _;
    }
    modifier onlyTicketContract(bytes32 showId) {
        require(msg.sender == showToTicketProxy[showId], "Caller is not the ticket proxy for this show");
        _;
    }
    modifier onlyTicketOrShowContract(bytes32 showId) {
        require(msg.sender == showToTicketProxy[showId] ||  msg.sender == address(this), "Caller is not the ticket proxy for this show");
        _;
    }
    modifier onlyVenueContract() {
        require(msg.sender == venueContract, "Only the Ticket contract can call this function");
        _;
    }
    modifier onlyTicketOrVenue(bytes32 showId) {
        require(
            msg.sender == venueContract ||
            msg.sender == showToTicketProxy[showId] ||
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
    /// @param _ticketFactory Address of the Ticket Factory contract
    /// @param _venueContract Address of the Venue contract
    /// @param _referralContract Address of the ReferralModule contract
    /// @param _artistRegistryContract Address of the ArtistRegistry contract
    /// @param _organizerRegistryContract Address of the OrganizerRegistry contract
    /// @param _venueRegistryContract Address of the VenueRegistry contract
    function setProtocolAddresses(
        address _ticketFactory,
        address _venueContract,
        address _referralContract,
        address _artistRegistryContract,
        address _organizerRegistryContract,
        address _venueRegistryContract
    ) public {
        require(!areContractsSet, "cannot reset");

        venueContract = _venueContract;

        ticketFactoryInstance = ITicketFactory(_ticketFactory);
        referralInstance = ReferralModule(_referralContract);
        artistRegistryInstance = IArtistRegistry(_artistRegistryContract);
        organizerRegistryInstance = IOrganizerRegistry(_organizerRegistryContract);
        venueRegistryInstance = IVenueRegistry(_venueRegistryContract);

        areContractsSet = true;
    }

    // @dev Creates a new show entry in the contract storage based on a validated show proposal.
    // @param proposal A struct containing all necessary details for creating a new show, assumed to be validated.
    // @return showId The unique identifier of the newly created show, generated based on proposal details.
    function createShow(ShowProposal memory proposal) private returns (bytes32 showId) {
        // Generating a unique identifier for the show based on proposal details
        showId = keccak256(abi.encode(
            proposal.name,
            proposal.description,
            proposal.artists,
            proposal.coordinates.lat,
            proposal.coordinates.lon,
            proposal.radius,
            proposal.sellOutThreshold,
            proposal.totalCapacity,
            proposal.currencyAddress,
            block.timestamp // Consider including block.timestamp for uniqueness
        ));

        // Creating a new show entry in the mapping with the showId
        Show storage newShow = shows[showId];
        newShow.name = proposal.name;
        newShow.description = proposal.description;
        newShow.organizer = msg.sender; // Assuming the msg.sender is the organizer
        newShow.artists = proposal.artists;
        newShow.venue = VenueTypes.Venue({
            name: "",
            coordinates: proposal.coordinates,
            totalCapacity: proposal.totalCapacity,
            wallet: address(0), // Default value, update as needed
            venueId: bytes32(0) // Default value, update as needed
        });
        newShow.radius = proposal.radius;
        newShow.sellOutThreshold = proposal.sellOutThreshold;
        newShow.totalCapacity = proposal.totalCapacity;
        newShow.status = Status.Proposed;
        newShow.isActive = true;
        newShow.split = proposal.split;
        newShow.expiry = block.timestamp + 30 days;
        newShow.showDate = 0; // Default value, update as needed
        newShow.currencyAddress = proposal.currencyAddress;
        showPaymentToken[showId] = proposal.currencyAddress;

        // Adding ticket tiers
        for (uint256 i = 0; i < proposal.ticketTiers.length; i++) {
            newShow.ticketTiers.push(proposal.ticketTiers[i]);
        }

        // Setting artist mappings
        for (uint256 i = 0; i < proposal.artists.length; i++) {
            isArtistMapping[showId][proposal.artists[i]] = true;
        }

        activeShowCount++; // Incrementing the count of active shows

        // Emitting an event to signal that a new show has been proposed
        emit ShowProposed(
            showId,
            msg.sender,
            proposal.name,
            proposal.artists,
            proposal.description,
            proposal.sellOutThreshold,
            proposal.split,
            proposal.currencyAddress
        );

        return showId;
    }

    // @dev Creates and initializes a ticket proxy for a given show.
    // @param showId The unique identifier for the show.
    // @param organizer The address of the organizer proposing the show.
    function createAndInitializeTicketProxy(bytes32 showId, address organizer) private {
        address ticketProxyAddress = ticketFactoryInstance.createTicketProxy(organizer);
        ITicket(ticketProxyAddress).setShowContractAddress(address(this));
        showToTicketProxy[showId] = ticketProxyAddress;
    }


    // @notice Proposes a new show with detailed information.
    // @dev This function creates a new show proposal based on the provided ShowProposal struct.
    // @param proposal A struct containing all necessary details for proposing a new show.
    // @return showId The unique identifier for the proposed show, generated based on proposal details.
    function proposeShow(ShowProposal memory proposal) external returns (bytes32 showId) {
        validateShowProposal(proposal);
        showId = createShow(proposal);
        createAndInitializeTicketProxy(showId, msg.sender);
        return showId;
    }


    /// @notice Deposits Ether into the vault for a specific show
    /// @param showId Unique identifier for the show
    function depositToVault(bytes32 showId) external payable onlyTicketOrVenue(showId) {
        showVault[showId] += msg.value;
    }

    /// @notice Deposits specified ERC20 tokens into the vault for a specific show.
    /// @dev Requires approval for the contract to transfer tokens on behalf of the sender.
    /// @param showId Unique identifier for the show.
    /// @param amount Amount of ERC20 tokens to deposit.
    /// @param tokenRecipient Address of the ticker recipient.
    /// @dev This function should be called to deposit ERC20 tokens for a show, ensuring the token is approved for transfer
    function depositToVaultERC20(bytes32 showId, uint256 amount, address paymentToken, address tokenRecipient) external onlyTicketOrVenue(showId) {
        require(paymentToken != address(0), "requires ERC20");
        require(showPaymentToken[showId] == paymentToken, "incorrect ERC20");

        ERC20Upgradeable token = ERC20Upgradeable(paymentToken);

        require(token.allowance(tokenRecipient, address(this)) >= amount, "insufficient allowance");
        token.transferFrom(tokenRecipient, address(this), amount);

        // Update the ERC20 token balance for the show
        showTokenVault[showId][paymentToken] += amount;

        emit ERC20Deposited(showId, paymentToken, msg.sender, amount);
    }


    /// @notice Consumes tickets from a specified tier for a given show.
    /// @param showId The identifier of the show.
    /// @param tierIndex The index of the ticket tier.
    /// @param amount The number of tickets to consume.
    /// @dev This modifies the state of ticket availability, should only be called by ticket or venue contracts
    function consumeTicketTier(bytes32 showId, uint256 tierIndex, uint256 amount) external onlyTicketOrVenue(showId) {
        Show storage show = shows[showId];
        require(tierIndex < show.ticketTiers.length, "invalid tier");

        ShowTypes.TicketTier storage tier = show.ticketTiers[tierIndex];
        require(tier.ticketsAvailable >= amount, "tier sold out");

        tier.ticketsAvailable -= amount;

        emit TicketTierConsumed(showId, tierIndex, amount);
    }

    /// @notice Updates the status of a show.
    /// @param showId Unique identifier for the show.
    /// @param _status New status for the show.
    /// @dev Can only be called by ticket or venue contracts, impacts show flow and state significantly.
    function updateStatus(bytes32 showId, Status _status) public onlyTicketOrVenue(showId) {
        shows[showId].status = _status;
        emit StatusUpdated(showId, _status);
    }

    /// @notice Checks if the total tickets sold for a show has reached or exceeded the sell-out threshold.
    /// @param showId The unique identifier for the show.
    /// @dev Used to automatically update a show's status to SoldOut if applicable, callable only by ticket or venue contracts.
    function updateStatusIfSoldOut(bytes32 showId) external onlyTicketOrVenue(showId) {
        Show storage show = shows[showId];
        uint256 soldTickets = getTotalTicketsSold(showId);
        if (soldTickets * 100 >= show.totalCapacity * show.sellOutThreshold) {
            updateStatus(showId, Status.SoldOut);
        }
    }

    /// @notice Cancels a sold-out show
    /// @param showId Unique identifier for the show
    function cancelShow(bytes32 showId) public onlyOrganizerOrArtist(showId) {
        Show storage show = shows[showId];
        require(show.status == Status.SoldOut || show.status == Status.Accepted || show.status == Status.Upcoming, "invalid status");
        show.status = Status.Cancelled;
        activeShowCount--;
    }

    // @notice Completes a show and distributes funds
    // @param showId Unique identifier for the show
    function completeShow(bytes32 showId) public onlyOrganizerOrArtist(showId) {
        Show storage show = shows[showId];
        require(show.status == Status.Upcoming, "invalid status");
        require(block.timestamp >= show.showDate + 30 minutes, "cooldown period");

        address paymentToken = showPaymentToken[showId];
        uint256 totalAmount = calculateTotalPayoutAmount(showId);
        require(totalAmount > 0, "no funds");

        DistributionData memory data = DistributionData({
            showId: showId,
            totalAmount: totalAmount,
            paymentToken: paymentToken,
            split: show.split
        });
        distributeShares(show, data);

        clearVault(showId, paymentToken);
        markShowAsCompleted(showId);
    }

    /// @dev Clears the vault for a specific show, setting the stored value to 0.
    /// This function handles both ETH and ERC20 token vaults based on the payment token address.
    /// @param showId The unique identifier of the show.
    /// @param paymentToken The address of the payment token. If set to address(0), it indicates ETH.
    function clearVault(bytes32 showId, address paymentToken) private {
        if(paymentToken == address(0)) {
            showVault[showId] = 0;
        } else {
            showTokenVault[showId][paymentToken] = 0;
        }
    }

    // @dev Marks a show as completed and updates relevant state variables.
    // @param showId The unique identifier of the show to mark as completed.
    function markShowAsCompleted(bytes32 showId) private {
        Show storage show = shows[showId];
        require(show.status != Status.Completed, "already complete");

        // Update the show's status to Completed.
        show.status = Status.Completed;

        require(activeShowCount > 0, "no active shows");
        activeShowCount--;

        // Emit an event to log the status update.
        emit StatusUpdated(showId, Status.Completed);
    }

    /// @dev Checks if a show is upcoming based on its status and the current timestamp.
    /// @param showId The unique identifier of the show to check.
    /// @return bool True if the show is marked as Upcoming and the current time is past the show date.
    function isShowUpcoming(bytes32 showId) private view returns (bool) {
        Show storage show = shows[showId];
        return show.status == Status.Upcoming && block.timestamp >= show.showDate + 30 minutes;
    }

    /// @dev Calculates the total payout amount available for a show, distinguishing between ETH and ERC20 payments.
    /// @param showId The unique identifier of the show.
    /// @return uint256 The total amount available for payout.
    function calculateTotalPayoutAmount(bytes32 showId) private view returns (uint256) {
        address paymentToken = showPaymentToken[showId];
        if (paymentToken == address(0)) {
            return showVault[showId];
        } else {
            return showTokenVault[showId][paymentToken];
        }
    }

    /// @dev Distributes shares of the show's total amount among the organizer, artists, and the venue.
    /// @param show Reference to the show struct containing show details.
    /// @param data Struct containing distribution data such as showId, totalAmount, paymentToken, and splits.
    function distributeShares(Show storage show, DistributionData memory data) private {
        // Combine organizer, artists, and venue into a single array for processing.
        address[] memory recipients = new address[](show.artists.length + 2);
        recipients[0] = show.organizer; // Organizer's share
        for (uint256 i = 0; i < show.artists.length; i++) {
            recipients[i + 1] = show.artists[i]; // Artists' shares
        }
        recipients[recipients.length - 1] = show.venue.wallet; // Venue's share

        // Call the new function with combined recipients and splits
        calculateAndDistributeShare(data.showId, recipients, data.split, data.totalAmount, data.paymentToken);
    }

    // @dev Calculates and distributes the share of the total amount for each recipient.
    /// @param showId The unique identifier of the show.
    /// @param recipients An array of addresses for recipients.
    /// @param splits An array of percentages defining how the total amount is split among recipients.
    /// @param totalAmount The total amount to be distributed.
    /// @param paymentToken The token in which payments are made. If address(0), it refers to ETH.
    function calculateAndDistributeShare(
        bytes32 showId,
        address[] memory recipients,
        uint256[] memory splits,
        uint256 totalAmount,
        address paymentToken
    ) private {
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 share = totalAmount * splits[i] / 100;
            addPayout(showId, recipients[i], share, paymentToken);
        }
    }

    /// @dev Adds a payout amount to the pending payouts or token payouts based on the payment token.
    /// @param showId The unique identifier of the show.
    /// @param recipient The recipient of the payout.
    /// @param amount The amount to be added to the payout.
    /// @param paymentToken The payment token address. If address(0), it indicates ETH.
    function addPayout(bytes32 showId, address recipient, uint256 amount, address paymentToken) private {
        if(paymentToken == address(0)) {
            pendingPayouts[showId][recipient] += amount;
        } else {
            pendingTokenPayouts[showId][paymentToken][recipient] += amount;
        }
    }

    /// @notice Allows a ticket owner to refund a specific ticket for a show.
    /// @dev This function also checks if the show's status should be updated from 'SoldOut' to 'Proposed'
    /// @param showId The unique identifier of the show.
    /// @param ticketId The ID of the ticket to be refunded.
    function refundTicket(bytes32 showId, uint256 ticketId) public {
        address ticketProxyAddress = showToTicketProxy[showId];
        require(ticketProxyAddress != address(0), "no ticket proxy");
        require(shows[showId].status == Status.Proposed || shows[showId].status == Status.Cancelled || shows[showId].status == Status.Expired, "locked funds due to the status of the show");

        ITicket ticketProxy = ITicket(ticketProxyAddress);
        require(isTicketOwner(msg.sender, showId, ticketId), "not ticket owner");

        (uint256 refundAmount, uint256 tierIndex) = ticketProxy.getTicketPricePaidAndTierIndex(showId, ticketId);
        require(refundAmount > 0, "no refunded tickets");

        // Retrieve the payment token used for this show
        address paymentToken = showPaymentToken[showId];

        // Increment the available tickets for the tier
        shows[showId].ticketTiers[tierIndex].ticketsAvailable++;

        // Update total tickets sold and potentially the show status, now passing the paymentToken
        updateTicketsSoldAndShowStatusAfterRefund(showId, ticketId, refundAmount, paymentToken);

        // Emit refund event
        emit TicketRefunded(msg.sender, showId, refundAmount);
    }


    /// @dev Updates total tickets sold and potentially the show status after a ticket refund.
    /// @param showId The unique identifier of the show.
    /// @param ticketId The ID of the ticket being refunded.
    /// @param refundAmount The amount to be refunded.
    /// @param paymentToken The payment token address; address(0) for ETH.
    function updateTicketsSoldAndShowStatusAfterRefund(bytes32 showId, uint256 ticketId, uint256 refundAmount, address paymentToken) internal {
        Show storage show = shows[showId];

        // Decrease total tickets sold
        totalTicketsSold[showId]--;

        // Update the show vault and pending withdrawals depending on the payment type
        if (paymentToken == address(0)) {
            // For ETH payments, manage the ETH balance
            showVault[showId] -= refundAmount;
            pendingRefunds[showId][msg.sender] += refundAmount;
        } else {
            // For ERC20 payments, manage the token balance
            showTokenVault[showId][paymentToken] -= refundAmount;
            pendingTokenRefunds[showId][paymentToken][msg.sender] += refundAmount;
        }

        // Update show status if needed
        uint256 soldTickets = totalTicketsSold[showId];
        uint256 sellOutThresholdTickets = (show.totalCapacity * show.sellOutThreshold) / 100;
        if (soldTickets < sellOutThresholdTickets && show.status == Status.SoldOut) {
            show.status = Status.Proposed;
            emit StatusUpdated(showId, Status.Proposed);
        }

        // Perform cleanup for the refunded ticket
        address ticketProxyAddress = showToTicketProxy[showId];
        require(ticketProxyAddress != address(0), "no ticket proxy");
        ITicket(ticketProxyAddress).burnTokens(ticketId, 1, msg.sender);

        // Cleanup internal tracking of the ticket ownership.
        delete ticketPricePaid[showId][ticketId];
        removeTokenIdFromWallet(showId, msg.sender, ticketId);
    }


    /// @notice Allows the organizer or artist to withdraw funds after a show has been completed.
    /// @param showId The unique identifier of the show.
    function payout(bytes32 showId) public onlyOrganizerOrArtist(showId) {
        Show storage show = shows[showId];
        require(show.status == Status.Completed, "invalid status");
        require(block.timestamp >= show.showDate + 5 minutes, "cooldown");

        address paymentToken = showPaymentToken[showId];
        uint256 amount;

        // Determine the amount to be paid out, based on whether it's ETH or an ERC20 token.
        if (paymentToken == address(0)) {
            amount = pendingPayouts[showId][msg.sender];
            require(amount > 0, "No funds");
            pendingPayouts[showId][msg.sender] = 0; // Reset before payout to prevent reentrancy
        } else {
            amount = pendingTokenPayouts[showId][paymentToken][msg.sender];
            require(amount > 0, "No tokens");
            pendingTokenPayouts[showId][paymentToken][msg.sender] = 0; // Reset before payout
        }

        // Perform the payout.
        if (paymentToken == address(0)) {
            (bool sent, ) = payable(msg.sender).call{value: amount}("");
            require(sent, "Failed to send");
        } else {
            ERC20Upgradeable token = ERC20Upgradeable(paymentToken);
            require(token.balanceOf(address(this)) >= amount, "Insufficient balance");
            require(token.transfer(msg.sender, amount), "transfer failed");
        }

        emit Withdrawal(showId, msg.sender, amount, paymentToken);
    }

    // @notice Allows a user to withdraw their refund for a show.
    // @param showId The unique identifier of the show.
    function withdrawRefund(bytes32 showId) public nonReentrant {
        Show storage show = shows[showId];

        require(
            show.status == Status.Refunded ||
            show.status == Status.Expired ||
            show.status == Status.Cancelled ||
            show.status == Status.Proposed,
            "Refunds are not available for this show status"
        );

        address paymentToken = showPaymentToken[showId];
        uint256 amount;

        if (paymentToken == address(0)) {
            amount = pendingRefunds[showId][msg.sender];
        } else {
            amount = pendingTokenRefunds[showId][paymentToken][msg.sender];
        }

        require(amount > 0, "No funds to withdraw");

        if (paymentToken == address(0)) {
            pendingRefunds[showId][msg.sender] = 0; // Reset before transfer to prevent reentrancy
            (bool sent, ) = payable(msg.sender).call{value: amount}("");
            require(sent, "Failed to send ETH");
        } else {
            pendingTokenRefunds[showId][paymentToken][msg.sender] = 0; // Reset before transfer
            ERC20Upgradeable token = ERC20Upgradeable(paymentToken);
            require(token.balanceOf(address(this)) >= amount, "Insufficient token");
            require(token.transfer(msg.sender, amount), "Transfer failed");
        }

        emit RefundWithdrawn(msg.sender, showId, amount);
    }

    /// @notice Updates the venue information for a specific show.
    /// @dev This function should only be callable by authorized contracts, such as the Venue contract.
    /// @param showId The unique identifier of the show to update.
    /// @param newVenue The new venue information to be set for the show.
    function updateShowVenue(bytes32 showId, VenueTypes.Venue calldata newVenue) external onlyVenueContract {
        require(shows[showId].status == Status.Proposed || shows[showId].status == Status.Accepted, "Invalid status");
        shows[showId].venue = newVenue;
        emit VenueUpdated(showId, newVenue);
    }

    /// @notice Updates the date for an accepted show.
    /// @dev This function can only be called by the Venue contract for shows in the Accepted status.
    /// @param showId The unique identifier of the show whose date is to be updated.
    /// @param newDate The new date (timestamp) for the show.
    function updateShowDate(bytes32 showId, uint256 newDate) external onlyVenueContract {
        require(shows[showId].status == Status.Accepted, "Show must be accepted");
        shows[showId].showDate = newDate;
    }

    // @notice Adds a token ID to a user's wallet for a specific show.
    // @param showId The unique identifier of the show.
    // @param wallet The address of the user's wallet.
    // @param tokenId The unique identifier of the token.
    // @dev This function can only be called by the ticket contract
    function addTokenIdToWallet(bytes32 showId, address wallet, uint256 tokenId) external onlyTicketContract(showId) {
        walletToShowToTokenIds[showId][wallet].push(tokenId);
    }

    // @notice Removes a specific ticket ID for a given wallet and show.
    // @param showId The unique identifier of the show.
    // @param wallet The address of the wallet owning the ticket.
    // @param ticketId The ID of the ticket to be removed.
    function removeTokenIdFromWallet(bytes32 showId, address wallet, uint256 tokenId) public onlyTicketOrShowContract(showId) {
        uint256[] storage ticketIds = walletToShowToTokenIds[showId][wallet];
        for (uint256 i = 0; i < ticketIds.length; i++) {
            if (ticketIds[i] == tokenId) {
                ticketIds[i] = ticketIds[ticketIds.length - 1];
                ticketIds.pop();
                break;
            }
        }
    }

    /// @notice Retrieves the details of a show, including ticket tiers.
    /// @param showId Unique identifier for the show
    /// @return name Name of the show
    /// @return description Description of the show
    /// @return organizer Organizer's address
    /// @return artists Array of artist addresses
    /// @return venue Venue details
    /// @return ticketTiers Array of ticket tiers, including name, price, and tickets available for each tier
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
        TicketTier[] memory ticketTiers,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        Status status,
        bool isActive,
        address currencyAddress
    ) {
        Show storage show = shows[showId];
        ticketTiers = new TicketTier[](show.ticketTiers.length);
        for(uint i = 0; i < show.ticketTiers.length; i++) {
            ticketTiers[i] = show.ticketTiers[i];
        }

        return (
            show.name,
            show.description,
            show.organizer,
            show.artists,
            show.venue,
            ticketTiers,
            show.sellOutThreshold,
            show.totalCapacity,
            show.status,
            show.isActive,
            show.currencyAddress
        );
    }

    /// @notice Retrieves the status of a show
    /// @param showId Unique identifier for the show
    /// @return Status of the show
    function getShowStatus(bytes32 showId) public view returns (ShowTypes.Status) {
        Show memory show = shows[showId];
        if (block.timestamp > show.expiry && show.status != ShowTypes.Status.Expired) {
            return ShowTypes.Status.Expired;
        } else {
            return show.status;
        }
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

    /// @notice Returns the total number of unique voters for a specific show, including artists and the organizer.
    /// @param showId Unique identifier for the show.
    /// @return Total number of unique voters (artists + organizer).
    function getNumberOfVoters(bytes32 showId) public view returns (uint256) {
        Show storage show = shows[showId];
        uint256 numberOfUniqueVoters = 1; // Start with 1 for the organizer

        // Iterate over artists to count unique voters
        for (uint256 i = 0; i < show.artists.length; i++) {
            if (show.artists[i] != show.organizer) {
                numberOfUniqueVoters++;
            }
        }

        return numberOfUniqueVoters;
    }

    // @notice Retrieves the price paid for a specific ticket of a show.
    // @param showId The unique identifier of the show.
    // @param ticketId The unique identifier of the ticket within the show.
    // @return The price paid for the specified ticket.
    function getTicketPricePaid(bytes32 showId, uint256 ticketId) public view returns (uint256) {
        return ticketPricePaid[showId][ticketId];
    }

    /// @notice Retrieves information about a specific ticket tier for a show.
    /// @param showId The unique identifier for the show.
    /// @param tierIndex The index of the ticket tier within the show's ticketTiers array.
    /// @return name The name of the ticket tier.
    /// @return price The price of tickets within the tier.
    /// @return ticketsAvailable The number of tickets available for sale in this tier.
    function getTicketTierInfo(bytes32 showId, uint256 tierIndex) public view returns (string memory name, uint256 price, uint256 ticketsAvailable) {
        require(tierIndex < shows[showId].ticketTiers.length, "Invalid tier");

        TicketTier storage tier = shows[showId].ticketTiers[tierIndex];
        return (tier.name, tier.price, tier.ticketsAvailable);
    }


    function getOrganizer(bytes32 showId) public view returns (address) {
        return shows[showId].organizer;
    }

    /// @notice Checks if a wallet owns at least one ticket for a specific show
    /// @param wallet The address to check for ticket ownership.
    /// @param showId The unique identifier of the show.
    /// @return ownsTicket A boolean indicating whether the wallet owns at least one ticket to the show.
    function hasTicket(address wallet, bytes32 showId) public view returns (bool ownsTicket) {
        return walletToShowToTokenIds[showId][wallet].length > 0;
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

    /// @notice Check if an address owns a ticket for a specific show
    /// @param owner The address to check
    /// @param showId The ID of the show
    /// @param ticketId The ID of the ticket
    /// @return true if the address owns a ticket for the show, false otherwise
    function isTicketOwner(address owner, bytes32 showId, uint256 ticketId) public view returns (bool) {
        return ticketOwnership[showId][owner][ticketId];
    }

    /// @notice Sets ticket ownership status for a specific ticket of a show.
    /// @param showId The ID of the show.
    /// @param owner The address of the ticket owner.
    /// @param ticketId The ID of the ticket.
    /// @param isOwned The ownership status to set.
    function setTicketOwnership(bytes32 showId, address owner, uint256 ticketId, bool isOwned) public onlyTicketContract(showId) {
        ticketOwnership[showId][owner][ticketId] = isOwned;
    }

    // @notice Sets the price paid for a specific ticket of a show.
    // @param showId The unique identifier of the show.
    // @param ticketId The unique identifier of the ticket within the show.
    // @param price The price paid for the ticket.
    // @dev This function can only be called by the ticket contract
    function setTicketPricePaid(bytes32 showId, uint256 ticketId, uint256 price) external onlyTicketContract(showId) {
        ticketPricePaid[showId][ticketId] = price;
    }

    // @notice Sets the price paid for a specific ticket of a show.
    // @param showId The unique identifier of the show.
    // @param ticketId The unique identifier of the ticket within the show.
    // @param price The price paid for the ticket.
    // @dev This function can only be called by the ticket contract
    function setTotalTicketsSold(bytes32 showId, uint256 amount) external onlyTicketContract(showId) {
        totalTicketsSold[showId] = totalTicketsSold[showId] + amount;
    }

    // @dev Validates the input parameters contained within the ShowProposal struct.
    // @param proposal The ShowProposal struct containing the details to be validated.
    function validateShowProposal(ShowProposal memory proposal) private pure {
        require(bytes(proposal.name).length > 0, "Name required");
        require(proposal.radius > 0, "radius required");
        require(bytes(proposal.description).length > 0 && bytes(proposal.description).length <= 1000, "description required < 1000");
        require(proposal.totalCapacity > 0, "capacity > 0");
        require(proposal.artists.length > 0, "At least one artist required");
        require(proposal.sellOutThreshold >= 50 && proposal.sellOutThreshold <= 100, "sellout threshold > 50%");
        require(proposal.coordinates.lat >= -90 * 10**6 && proposal.coordinates.lat <= 90 * 10**6, "invalid lat");
        require(proposal.coordinates.lon >= -180 * 10**6 && proposal.coordinates.lon <= 180 * 10**6, "Invalid long");
        validateSplit(proposal.split, proposal.artists.length);
        // Ensure ticketTiers and currencyAddress are also validated as needed
    }

    /// @notice Validates the split percentages between organizer, artists, and venue
    /// @param split Array representing the percentage split
    /// @param numArtists Number of artists in the show
    function validateSplit(uint256[] memory split, uint256 numArtists) internal pure {
        require(split.length == numArtists + 2, "split must equal artists plus 2 (organizer and venue)");

        uint256 sum = 0;
        for (uint i = 0; i < split.length; i++) {
            sum += split[i];
        }
        require(sum == 100, "split must sum 100");
    }

    /// @notice Validates that the total tickets across all tiers match the total capacity of the show
    /// @param ticketTiers Array of ticket tiers for the show
    /// @param totalCapacity Total capacity of the show
    function validateTotalTicketsAcrossTiers(ShowTypes.TicketTier[] memory ticketTiers, uint256 totalCapacity) internal pure {
        uint256 totalTicketsAcrossTiers = 0;
        for (uint i = 0; i < ticketTiers.length; i++) {
            totalTicketsAcrossTiers += ticketTiers[i].ticketsAvailable;
        }
        require(totalTicketsAcrossTiers == totalCapacity, "total tickets must equal total capacity");
    }
}
