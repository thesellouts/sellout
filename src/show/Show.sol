// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IShow } from "./IShow.sol";
import { ShowStorage, ShowTypes } from "./storage/ShowStorage.sol";
import { IShowVault } from "./IShowVault.sol";
import { ShowValidations } from "./ShowValidations.sol";

import { ITicket } from "../ticket/ITicket.sol";
import { ITicketFactory } from "../ticket/ITicketFactory.sol";

import { IVenue } from "../venue/IVenue.sol";
import { IVenueFactory } from "../venue/IVenueFactory.sol";
import { VenueTypes } from "../venue/types/VenueTypes.sol";

import { ReferralModule } from "../registry/referral/ReferralModule.sol";
import { IArtistRegistry } from "../registry/artist/IArtistRegistry.sol";
import { IOrganizerRegistry } from "../registry/organizer/IOrganizerRegistry.sol";
import { IVenueRegistry } from "../registry/venue/IVenueRegistry.sol";
import { VenueRegistryTypes } from "../registry/venue/types/VenueRegistryTypes.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/*

    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@, ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@                         @@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@               .@@@                @@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      (@@@@@@@@@@@@@
    @@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@
    @@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@
    @@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@
    @@@@@@@@@     ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@
    @@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@
    @@@@@@@@     @@@@@@@@@@@@@@@/ @@@@@@@@@@@@@@@@@@@@@ #@@@@@@@@@@@@@@@     @@@@@@@
    @@@@@@@@     @@@@@@@@@@            @@@@@@@@@@@            @@@@@@@@@@     @@@@@@@
    @@@@@@@@     @@@@@@@@        @       @@@@@@@       @        @@@@@@@@     @@@@@@@
    @@@@@@@@     @@@@@@@@     @@@@@@@     @@@@@     @@@@@@@     @@@@@@@@     @@@@@@@
    @@@@@@@@@     @@@@@@@     @@@@@@@     @@@@@     @@@@@@@     @@@@@@@     @@@@@@@@
    @@@@@@@@@     .@@@@@@                @@@@@@@                @@@@@@      @@@@@@@@
    @@@@@@@@@@      @@@@@@@            @@@@@@@@@@@            @@@@@@@      @@@@@@@@@
    @@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@
    @@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@
    @@@@@@@@@@@@@@(      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      &@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@       @@@@@@@@@@@ @@@@@@@@@ @@@@@@@@@@@       @@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@         @@@@@     @@@@@     @@@@@        .@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@     @@@@@     @@@@@     @@@@@     @@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@     @@@@@     @@@@@     @@@@@     @@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@                                 @@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


    @title  SELLOUT SHOW
    @author taayyohh
    @notice Sellout your dream show.
*/


contract Show is Initializable, IShow, ShowStorage, ReentrancyGuardUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
    function initialize(address _selloutProtocolWallet) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init(_selloutProtocolWallet);
        SELLOUT_PROTOCOL_WALLET = _selloutProtocolWallet;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier onlyOrganizerOrArtist(bytes32 showId) {
        require(isOrganizer(msg.sender, showId) || isArtist(msg.sender, showId), "OA");
        _;
    }

    modifier onlyTicketContract(bytes32 showId) {
        require(msg.sender == showToTicketProxy[showId], "T");
        _;
    }

    modifier onlyVenueContract(bytes32 showId) {
        require(msg.sender == showToVenueProxy[showId], "V");
        _;
    }

    modifier onlyTicketOrVenue(bytes32 showId) {
        require(
            msg.sender == showToVenueProxy[showId] ||
            msg.sender == showToTicketProxy[showId] ||
            msg.sender == address(this),
            "TV"
        );
        _;
    }

    /// @notice Sets the Ticket, Venue, Registry, and ShowVault contract addresses
    /// @param _ticketFactory Address of the Ticket Factory contract
    /// @param _venueFactory Address of the Venue Factory contract
    /// @param _referralContract Address of the ReferralModule contract
    /// @param _artistRegistryContract Address of the ArtistRegistry contract
    /// @param _organizerRegistryContract Address of the OrganizerRegistry contract
    /// @param _venueRegistryContract Address of the Venue Registry contract
    /// @param _showVault Address of the ShowVault contract
    function setProtocolAddresses(
        address _ticketFactory,
        address _venueFactory,
        address _referralContract,
        address _artistRegistryContract,
        address _organizerRegistryContract,
        address _venueRegistryContract,
        address _showVault
    ) external {
        require(!setContracts, "!!");

        venueFactoryInstance = IVenueFactory(_venueFactory);
        ticketFactoryInstance = ITicketFactory(_ticketFactory);
        referralInstance = ReferralModule(_referralContract);
        artistRegistryInstance = IArtistRegistry(_artistRegistryContract);
        organizerRegistryInstance = IOrganizerRegistry(_organizerRegistryContract);
        venueRegistryInstance = IVenueRegistry(_venueRegistryContract);
        showVaultInstance = IShowVault(_showVault);

        setContracts = true;
    }

    // @notice Proposes a new show with detailed information.
    // @dev This function creates a new show proposal based on the provided ShowProposal struct.
    // @param proposal A struct containing all necessary details for proposing a new show.
    // @return showId The unique identifier for the proposed show, generated based on proposal details.
    function proposeShow(ShowProposal memory proposal) external returns (bytes32 showId) {
        require(organizerRegistryInstance.isOrganizerRegistered(msg.sender), "!rO");
        for(uint i = 0; i < proposal.artists.length; i++) {
            require(artistRegistryInstance.isArtistRegistered(proposal.artists[i]), "!rA");
        }
        ShowValidations.validateShowProposal(proposal);
        showId = createShow(proposal);
        createAndInitializeTicketProxy(showId, SELLOUT_PROTOCOL_WALLET);
        createAndInitializeVenueProxy(
            showId,
            SELLOUT_PROTOCOL_WALLET,
            proposal.venueProposalParams.proposalPeriodDuration,
            proposal.venueProposalParams.proposalDateExtension,
            proposal.venueProposalParams.proposalDateMinimumFuture,
            proposal.venueProposalParams.proposalPeriodExtensionThreshold
        );
        return showId;
    }

    // @dev Creates a new show entry in the contract storage based on a validated show proposal.
    // @param proposal A struct containing all necessary details for creating a new show, assumed to be validated.
    // @return showId The unique identifier of the newly created show, generated based on proposal details.
    function createShow(ShowProposal memory proposal) private returns (bytes32 showId) {
        // Generating a unique identifier for the show based on proposal details
        showId = keccak256(abi.encode(
            proposal.name,
            proposal.artists,
            proposal.coordinates.latitude,
            proposal.coordinates.longitude,
            proposal.radius,
            proposal.sellOutThreshold,
            proposal.totalCapacity,
            proposal.currencyAddress,
            msg.sender
        ));

        // Creating a new show entry in the mapping with the showId
        Show storage show = shows[showId];
        show.name = proposal.name;
        show.description = proposal.description;
        show.organizer = msg.sender;
        show.artists = proposal.artists;
        show.venue = VenueRegistryTypes.VenueInfo({
            name: "",
            bio: "",
            wallet: address(0),
            venueId: 0,
            coordinates: proposal.coordinates,
            totalCapacity: proposal.totalCapacity,
            streetAddress: ""
        });
        show.radius = proposal.radius;
        show.sellOutThreshold = proposal.sellOutThreshold;
        show.totalCapacity = proposal.totalCapacity;
        show.status = Status.Proposed;
        show.split = proposal.split;
        show.expiry = block.timestamp + 30 days;
        show.showDate = 0;
        show.currencyAddress = proposal.currencyAddress;
        showPaymentToken[showId] = proposal.currencyAddress;

        // Adding ticket tiers
        for (uint256 i = 0; i < proposal.ticketTiers.length; i++) {
            show.ticketTiers.push(proposal.ticketTiers[i]);
        }

        // Setting artist mappings
        for (uint256 i = 0; i < proposal.artists.length; i++) {
            isArtistMapping[showId][proposal.artists[i]] = true;
        }

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
    // @param protocol The address of the protocol proposing the show.
    function createAndInitializeTicketProxy(bytes32 showId, address protocol) private {
        address ticketProxyAddress = ticketFactoryInstance.createTicketProxy(protocol);
        ITicket(ticketProxyAddress).setShowContractAddress(address(this));
        showToTicketProxy[showId] = ticketProxyAddress;
    }

    /// @dev Creates and initializes a venue proxy for a given show with specific proposal parameters.
    /// @param showId The unique identifier for the show for which the venue proxy is being created.
    /// @param protocol The address of the protocol (or initial owner) to whom the new venue proxy will belong.
    /// @param proposalPeriodDuration The duration (in seconds) for the proposal period for venue proposals.
    /// @param proposalDateExtension The duration (in seconds) by which a proposal date can be extended.
    /// @param proposalDateMinimumFuture The minimum future date (in seconds from now) for a proposal date.
    /// @param proposalPeriodExtensionThreshold The threshold (in seconds before the proposal period ends)
    /// for when the proposal period can be extended.
    /// @notice This function creates a venue proxy tailored to the specific requirements of a show
    function createAndInitializeVenueProxy(
        bytes32 showId,
        address protocol,
        uint256 proposalPeriodDuration,
        uint256 proposalDateExtension,
        uint256 proposalDateMinimumFuture,
        uint256 proposalPeriodExtensionThreshold
    ) private {
        address venueProxyAddress = venueFactoryInstance.createVenueProxy(
            protocol,
            proposalPeriodDuration,
            proposalDateExtension,
            proposalDateMinimumFuture,
            proposalPeriodExtensionThreshold
        );
        IVenue(venueProxyAddress).setShowAndVenueRegistryAddresses(address(this), address(venueRegistryInstance));
        showToVenueProxy[showId] = venueProxyAddress;
    }

    /// @notice Deposits Ether into the vault for a specific show
    /// @param showId Unique identifier for the show
    function depositToVault(bytes32 showId) external payable onlyTicketOrVenue(showId) {
        showVaultInstance.depositToVault{value: msg.value}(showId);
    }

    /// @notice Deposits specified ERC20 tokens into the vault for a specific show.
    /// @dev Requires approval for the contract to transfer tokens on behalf of the sender.
    /// @param showId Unique identifier for the show.
    /// @param amount Amount of ERC20 tokens to deposit.
    /// @param paymentToken Address of the ERC20 token.
    /// @param tokenRecipient Address of the token sender who approved the transfer.
    /// @dev This function should be called to deposit ERC20 tokens for a show, ensuring the token is approved for transfer
    function depositToVaultERC20(bytes32 showId, uint256 amount, address paymentToken, address tokenRecipient) external onlyTicketOrVenue(showId) {
        require(paymentToken != address(0), "!t");
        require(showPaymentToken[showId] == paymentToken, "!t");

        showVaultInstance.depositToVaultERC20(showId, amount, paymentToken, tokenRecipient);
    }

    /// @notice Consumes tickets from a specified tier for a given show.
    /// @param showId The identifier of the show.
    /// @param tierIndex The index of the ticket tier.
    /// @param amount The number of tickets to consume.
    /// @dev This modifies the state of ticket availability, should only be called by ticket or venue contracts
    function consumeTicketTier(bytes32 showId, uint256 tierIndex, uint256 amount) external onlyTicketOrVenue(showId) {
        Show storage show = shows[showId];
        require(tierIndex < show.ticketTiers.length, "!");

        ShowTypes.TicketTier storage tier = show.ticketTiers[tierIndex];
        require(tier.ticketsAvailable >= amount, "0 tix");

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
    function cancelShow(bytes32 showId) external onlyOrganizerOrArtist(showId) {
        Show storage show = shows[showId];
        require(show.status == Status.SoldOut || show.status == Status.Accepted || show.status == Status.Upcoming, "!s");
        show.status = Status.Cancelled;
    }

    // @notice Completes a show and distributes funds
    // @param showId Unique identifier for the show
    function completeShow(bytes32 showId) external onlyOrganizerOrArtist(showId) {
        Show storage show = shows[showId];
        require(show.status == Status.Upcoming, "!s");
        require(block.timestamp >= show.showDate + 2 days, "!s");

        address paymentToken = showPaymentToken[showId];
        uint256 totalAmount = showVaultInstance.calculateTotalPayoutAmount(showId, paymentToken);
        if (totalAmount == 0) {
            return;
        }

        uint256 numParticipants = show.artists.length + 2;
        address[] memory recipients = new address[](numParticipants);
        uint256[] memory splits = new uint256[](show.split.length);

        recipients[0] = show.organizer;
        for (uint256 i = 0; i < show.artists.length; i++) {
            recipients[i + 1] = show.artists[i];
        }
        recipients[numParticipants - 1] = show.venue.wallet;
        splits = show.split;

        showVaultInstance.distributeShares(showId, recipients, splits, totalAmount, paymentToken);
        showVaultInstance.clearVault(showId, paymentToken);

        show.status = Status.Completed;
        emit StatusUpdated(showId, Status.Completed);
    }

    /// @notice Allows a ticket owner to refund a specific ticket for a show.
    /// @dev This function also checks if the show's status should be updated from 'SoldOut' to 'Proposed'
    /// @param showId The unique identifier of the show.
    /// @param tokenId The ID of the ticket to be refunded.
    function refundTicket(bytes32 showId, uint256 tokenId) external {
        address ticketProxyAddress = showToTicketProxy[showId];
        require(ticketProxyAddress != address(0), "!pxy");
        require(shows[showId].status == Status.Proposed || shows[showId].status == Status.Cancelled || shows[showId].status == Status.Expired, "!=s");

        ITicket ticketProxy = ITicket(ticketProxyAddress);
        require(isTokenOwner(showId, msg.sender, tokenId), "!t");

        (uint256 refundAmount, uint256 tierIndex) = ticketProxy.getTicketPricePaidAndTierIndex(showId, tokenId);
        require(refundAmount > 0, "!$");

        // Retrieve the payment token used for this show
        address paymentToken = showPaymentToken[showId];

        // Increment the available tickets for the tier
        shows[showId].ticketTiers[tierIndex].ticketsAvailable++;

        // Update total tickets sold and potentially the show status, now passing the paymentToken
        updateTicketsSoldAndShowStatusAfterRefund(showId, tokenId, refundAmount, paymentToken);

        // Emit refund event
        emit TicketRefunded(msg.sender, showId, refundAmount);
    }

    /// @notice Refunds the bribe if the venue was not accepted for the show.
    /// @param showId The unique identifier of the show.
    /// @param venueId The identifier of the venue submitting the proposal.
    /// @param proposalIndex Index of the proposal submitted by the venue.
    function refundBribe(bytes32 showId, uint256 venueId, uint256 proposalIndex) external {
        Show storage show = shows[showId];
        require(show.status != Status.Completed, "!c");
        require(show.venue.venueId != venueId, "!s");

        IVenue venueContract = IVenue(showToVenueProxy[showId]);
        uint256 proposalsCount = venueContract.getProposalsCount(showId);
        require(proposalsCount > proposalIndex, "!i");

        VenueTypes.Proposal memory proposal = venueContract.getProposal(showId, proposalIndex);
        require(proposal.venue.venueId == venueId, "!v");
        require(proposal.proposer == msg.sender, "!pr");
        require(proposal.bribe > 0, "!$");

        venueContract.resetBribe(showId, proposalIndex);
        showVaultInstance.processRefund(showId, proposal.bribe, proposal.paymentToken, msg.sender);

        emit BribeRefunded(showId, venueId, msg.sender, proposal.bribe, proposal.paymentToken);
    }

    /// @notice Allows the organizer or artist to withdraw funds after a show has been completed.
    /// @param showId The unique identifier of the show.
    function payout(bytes32 showId) public onlyOrganizerOrArtist(showId) {
        ShowTypes.Show storage show = shows[showId];

        require(show.status == Status.Completed, "!s");
        require(block.timestamp >= show.showDate + 2 days, "!cl");

        address paymentToken = showPaymentToken[showId];
        showVaultInstance.payout(showId, paymentToken);
    }

    /// @notice Allows a user to withdraw their refund for a show.
    /// @param showId The unique identifier of the show.
    function withdrawRefund(bytes32 showId) public nonReentrant {
        ShowTypes.Show storage show = shows[showId];

        require(
            show.status == Status.Refunded ||
            show.status == Status.Expired ||
            show.status == Status.Cancelled ||
            show.status == Status.Proposed,
            "!s"
        );

        showVaultInstance.withdrawRefund(showId, showPaymentToken[showId]);
    }

    /// @dev Updates total tickets sold and potentially the show status after a ticket refund.
    /// @param showId The unique identifier of the show.
    /// @param ticketId The ID of the ticket being refunded.
    /// @param refundAmount The amount to be refunded.
    /// @param paymentToken The payment token address; address(0) for ETH.
    function updateTicketsSoldAndShowStatusAfterRefund(bytes32 showId, uint256 ticketId, uint256 refundAmount, address paymentToken) internal {
        // Verify that the ticket proxy is valid before making any state changes
        address ticketProxyAddress = showToTicketProxy[showId];
        require(ticketProxyAddress != address(0), "!pxy");

        // Decrease total tickets sold
        totalTicketsSold[showId]--;

        // Call ShowVault to manage financials
        showVaultInstance.processRefund(showId, refundAmount, paymentToken, msg.sender);

        // Burn the ticket token
        ITicket(ticketProxyAddress).burnTokens(ticketId, 1, msg.sender);

        // Cleanup ticket price paid data
        delete ticketPricePaid[showId][ticketId];

        // Remove token ID from the wallet
        _removeTokenIdFromWallet(showId, msg.sender, ticketId);
    }


    /// @notice Updates the venue information for a specific show.
    /// @dev This function should only be callable by authorized contracts, such as the Venue contract.
    /// @param showId The unique identifier of the show to update.
    /// @param newVenue The new venue information to be set for the show.
    function updateShowVenue(bytes32 showId, VenueRegistryTypes.VenueInfo calldata newVenue) external onlyVenueContract(showId) {
        require(shows[showId].status == Status.Proposed || shows[showId].status == Status.Accepted, "s"); // invalid status
        shows[showId].venue = newVenue;
        emit VenueUpdated(showId, newVenue);
    }

    /// @notice Updates the date for an accepted show.
    /// @dev This function can only be called by the Venue contract for shows in the Accepted status.
    /// @param showId The unique identifier of the show whose date is to be updated.
    /// @param newDate The new date (timestamp) for the show.
    function updateShowDate(bytes32 showId, uint256 newDate) external onlyVenueContract(showId) {
        require(shows[showId].status == Status.Accepted, "!s"); // show must be accepted
        shows[showId].showDate = newDate;
    }

    // @notice Adds a token ID to a user's wallet for a specific show.
    // @param showId The unique identifier of the show.
    // @param wallet The address of the user's wallet.
    // @param tokenId The unique identifier of the token.
    // @dev This function can only be called by the ticket contract
    function _addTokenIdToWallet(bytes32 showId, address wallet, uint256 tokenId) internal {
        walletToShowToTokenIds[showId][wallet].push(tokenId);
    }

    // @notice Removes a specific ticket ID for a given wallet and show.
    // @param showId The unique identifier of the show.
    // @param wallet The address of the wallet owning the ticket.
    // @param ticketId The ID of the ticket to be removed.
    function _removeTokenIdFromWallet(bytes32 showId, address wallet, uint256 tokenId) internal {
        uint256[] storage ticketIds = walletToShowToTokenIds[showId][wallet];
        for (uint256 i = 0; i < ticketIds.length; i++) {
            if (ticketIds[i] == tokenId) {
                ticketIds[i] = ticketIds[ticketIds.length - 1];
                ticketIds.pop();
                break;
            }
        }
    }

    // @notice Adds a token ID to a user's wallet for a specific show.
    // @param showId The unique identifier of the show.
    // @param wallet The address of the user's wallet.
    // @param tokenId The unique identifier of the token.
    // @dev This function can only be called by the external contracts
    function addTokenIdToWallet(bytes32 showId, address wallet, uint256 tokenId) external onlyTicketContract(showId) {
        _addTokenIdToWallet(showId, wallet, tokenId);
    }

    // @notice Removes a specific ticket ID for a given wallet and show.
    // @param showId The unique identifier of the show.
    // @param wallet The address of the wallet owning the ticket.
    // @param ticketId The ID of the ticket to be removed.
    // @dev This function can only be called by the external contracts
    function removeTokenIdFromWallet(bytes32 showId, address wallet, uint256 tokenId) external onlyTicketContract(showId) {
        _removeTokenIdFromWallet(showId, wallet, tokenId);
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
    function getShowById(bytes32 showId) public view returns (
        string memory name,
        string memory description,
        address organizer,
        address[] memory artists,
        VenueRegistryTypes.VenueInfo memory venue,
        TicketTier[] memory ticketTiers,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        Status status,
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
        require(tierIndex < shows[showId].ticketTiers.length, "t"); // invalid tier

        TicketTier storage tier = shows[showId].ticketTiers[tierIndex];
        return (tier.name, tier.price, tier.ticketsAvailable);
    }

    /// @notice Retrieves wallet address of an organizer for a given show
    /// @param showId The unique identifier for the show.
    /// @return wallet The wallet address of the organizer.
    function getOrganizer(bytes32 showId) public view returns (address) {
        return shows[showId].organizer;
    }

    /// @notice Checks if the given user is an artist in the specified show.
    /// @param user Address of the user to check
    /// @param showId Unique identifier for the show
    /// @return true if the user is an artist, false otherwise
    function isArtist(address user, bytes32 showId) public view returns (bool) {
        return isArtistMapping[showId][user];
    }

    /// @notice Checks if the given user is an organizer of the specified show.
    /// @param user Address of the user to check
    /// @param showId Unique identifier for the show
    /// @return true if the user is an organizer, false otherwise
    function isOrganizer(address user, bytes32 showId) public view returns (bool) {
        return shows[showId].organizer == user;
    }

    /// @dev Checks if a given tokenId exists in the wallet's list of tokenIds for a specific show.
    /// @param showId The unique identifier of the show.
    /// @param wallet The address of the wallet to check for token ownership.
    /// @param tokenId The unique identifier of the token to check.
    /// @return bool Returns true if the tokenId exists in the wallet's list of tokens for the specified show, false otherwise.
    function isTokenOwner(bytes32 showId, address wallet, uint256 tokenId) private view returns (bool) {
        uint256[] storage ticketIds = walletToShowToTokenIds[showId][wallet];
        for (uint256 i = 0; i < ticketIds.length; i++) {
            if (ticketIds[i] == tokenId) {
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

    /// @notice Allows ticket holders to vote for an emergency refund
    /// @param showId The unique identifier of the show
    function voteForEmergencyRefund(bytes32 showId) external {
        require(hasTicket(msg.sender, showId), "no tix");
        require(shows[showId].status == Status.Completed, "!s");
        require(!hasVotedForEmergencyRefund[showId][msg.sender], "!!v");

        hasVotedForEmergencyRefund[showId][msg.sender] = true;
        votesForEmergencyRefund[showId] += 1;

        if (isEmergencyRefundThresholdReached(showId)) {
            cancelShowForEmergencyRefund(showId);
        }
    }

    /// @notice Checks if the vote threshold for an emergency refund has been reached
    /// @param showId The unique identifier of the show
    /// @return bool Whether the threshold has been reached
    function isEmergencyRefundThresholdReached(bytes32 showId) internal view returns (bool) {
        uint256 totalVotes = votesForEmergencyRefund[showId];
        uint256 totalTicketsSoldForShow = getTotalTicketsSold(showId);

        return totalVotes >= (totalTicketsSoldForShow * 66 / 100);
    }

    /// @notice Cancels the show and enables refunds due to reaching the emergency refund vote threshold
    /// @param showId The unique identifier of the show
    function cancelShowForEmergencyRefund(bytes32 showId) internal {
        shows[showId].status = Status.Cancelled;
        emit ShowCancelled(showId, "Emergency Refund");
    }
}
