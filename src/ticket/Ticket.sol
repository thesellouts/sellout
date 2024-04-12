// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ITicket } from "./ITicket.sol";
import { TicketStorage } from "./storage/TicketStorage.sol";
import { IShow } from "../show/IShow.sol";
import { ShowTypes } from "../show/types/ShowTypes.sol";

import { Strings } from "@openzeppelin-contracts/utils/Strings.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import { ERC20Upgradeable } from  "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
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


    // @title SELLOUT TICKET
    // @author taayyohh
    // @notice Implements ticket sales for shows using the ERC1155 standard. Supporting arbitrary ticket tiers.
    // @dev Extends ERC1155 for ticket tokenization.
*/


contract Ticket is Initializable, ITicket, TicketStorage, ERC1155Upgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 private ticketIdCounter = 1;

    // @notice Initializes the contract with the Show contract address and metadata URI.
    // @param initialOwner The address of the initial contract owner.
    function initialize(address initialOwner, string memory _version) public initializer {
        __ERC1155_init("https://metadata.sellouts.app/show/{id}.json");
        __ReentrancyGuard_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        version = _version;
        defaultURI = "https://metadata.sellouts.app/show/";
    }

    // @dev Ensures that only the Show contract can call the modified function.
    modifier onlyShowContract() {
        require(msg.sender == address(showInstance), "Only the Show contract can call this function");
        _;
    }

     // @dev Allows contract upgrades by the contract owner only.
     // @param newImplementation The address of the new contract implementation.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // @notice Purchases tickets, processing payment, minting tickets, and finalizing the purchase.
    // @dev Breaks down the purchase process into smaller internal functions to manage stack depth.
    // @param showId Identifier of the show.
    // @param tierIndex Index of the ticket tier.
    // @param amount Number of tickets to purchase.
    // @param paymentToken Address of the ERC20 token the show is priced in.
    function purchaseTickets(bytes32 showId, uint256 tierIndex, uint256 amount, address paymentToken) public payable nonReentrant {
        validatePurchase(showId, tierIndex, amount);
        PurchaseData memory data = preparePurchaseData(showId, tierIndex, amount);

        bool purchaseSuccessful = executePurchase(showId, tierIndex, amount, data, paymentToken);
        require(purchaseSuccessful, "Purchase failed");

        // Finalize the purchase only after confirming success
        finalizePurchase(showId, tierIndex, amount);
    }

    // @dev Validates the parameters for a ticket purchase request.
    // @param showId Unique identifier for the show for which tickets are being purchased.
    // @param tierIndex Index of the ticket tier within the show from which tickets are being purchased.
    // @param amount The number of tickets the user wishes to purchase.
    function validatePurchase(bytes32 showId, uint256 tierIndex, uint256 amount) private view {
        ShowTypes.Status showStatus = showInstance.getShowStatus(showId);
        require(
            showStatus == ShowTypes.Status.Proposed || showStatus == ShowTypes.Status.Accepted,
            "Show not available for purchase"
        );
        require(amount > 0, "Amount must be greater than 0");

        (, , uint256 ticketsAvailable) = showInstance.getTicketTierInfo(showId, tierIndex);
        require(ticketsAvailable >= amount, "Not enough tickets available");

        uint256[] memory ownedTokenIds = showInstance.getWalletTokenIds(showId, msg.sender);
        require(ownedTokenIds.length + amount <= MAX_TICKETS_PER_WALLET, "Max tickets exceeded");
    }

    // @dev Prepares the purchase data for a ticket purchase request.
    // @param showId Unique identifier for the show for which tickets are being purchased.
    // @param tierIndex Index of the ticket tier within the show from which tickets are being purchased.
    // @param amount The number of tickets the user wishes to purchase.
    // @return data A `PurchaseData` struct containing the calculated purchase data, including price per ticket, tickets available, and total payment required.
    function preparePurchaseData(bytes32 showId, uint256 tierIndex, uint256 amount) private view returns (PurchaseData memory data) {
        uint256 pricePerTicket;
        uint256 ticketsAvailable;
        (, pricePerTicket, ticketsAvailable) = showInstance.getTicketTierInfo(showId, tierIndex);

        uint256 totalPayment = pricePerTicket * amount;
        return PurchaseData({
            pricePerTicket: pricePerTicket,
            ticketsAvailable: ticketsAvailable,
            totalPayment: totalPayment,
            tokenId: 0 // This will be set later
        });
    }

     // @dev Executes the ticket purchase process: processes payment, mints tickets, and returns success status.
     // @param showId The unique identifier for the show.
     // @param tierIndex The index of the ticket tier.
     // @param amount The number of tickets to purchase.
     // @param data Struct containing purchase data.
     // @param paymentToken The address of the ERC20 token used for payment (address(0) for ETH).
     // @return success Indicates whether the purchase was successful.
    function executePurchase(bytes32 showId, uint256 tierIndex, uint256 amount, PurchaseData memory data, address paymentToken) private returns (bool) {
        if (!processPayment(showId, data.totalPayment, paymentToken)) {
            return false; // Payment processing failed
        }

        bool mintingSuccess = true;
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = ticketIdCounter++;
            if (!mintTicket(tokenId, tierIndex, showId, msg.sender, data.pricePerTicket)) {
                mintingSuccess = false; // Minting failed
                break;
            }

            emit TicketPurchased(msg.sender, showId, tierIndex, tokenId, 1, paymentToken);
        }

        return mintingSuccess;
    }

    // @dev Processes the payment for the ticket purchase. Supports both ETH and ERC20 payments.
    // ETH payments require the sent value to match the total payment amount.
    // ERC20 payments require an allowance and do not require sending ETH with the transaction.
    // @param showId The unique identifier for the show.
    // @param totalPayment The total payment amount required.
    // @param paymentToken The address of the ERC20 token used for payment (address(0) for ETH).
    function processPayment(bytes32 showId, uint256 totalPayment, address paymentToken) private returns (bool) {
        if (paymentToken == address(0)) {
            require(msg.value == totalPayment, "Incorrect ETH amount");
            showInstance.depositToVault{value: msg.value}(showId);
            return true;
        } else {
            require(msg.value == 0, "Do not send ETH with ERC20 payment");
            showInstance.depositToVaultERC20(showId, totalPayment, paymentToken, msg.sender);
            return true;
        }
    }

     // @dev Mints a ticket for a buyer. Associates the ticket with a show, tier, and sets the price paid.
     // @param tokenId The unique identifier for the ticket.
     // @param tierIndex The index of the ticket tier.
     // @param showId The unique identifier for the show.
     // @param buyer The address of the ticket buyer.
     // @param pricePerTicket The price paid per ticket.
    function mintTicket(uint256 tokenId, uint256 tierIndex, bytes32 showId, address buyer, uint256 pricePerTicket) private returns (bool) {
        _mint(buyer, tokenId, 1, "");
        ticketIdToTierIndex[tokenId] = tierIndex;
        tokenIdToShowId[tokenId] = showId;
        showInstance.addTokenIdToWallet(showId, buyer, tokenId);
        showInstance.setTicketPricePaid(showId, tokenId, pricePerTicket);
        return true;
    }

    // @dev Finalizes the ticket purchase process after payment and minting. Updates total tickets sold and checks if the show is sold out.
    // @param showId The unique identifier for the show.
    // @param tierIndex The index of the ticket tier for which tickets were purchased.
    // @param amount The number of tickets purchased.
    function finalizePurchase(bytes32 showId, uint256 tierIndex, uint256 amount) private {
        showInstance.setTotalTicketsSold(showId, amount);
        showInstance.consumeTicketTier(showId, tierIndex, amount);
        showInstance.updateStatusIfSoldOut(showId);
    }

     // @notice Retrieves the price paid for a specific ticket and its tier index.
     // @param showId The unique identifier of the show.
     // @param ticketId The unique identifier of the ticket.
     // @return price The price paid for the ticket.
     // @return tierIndex The index of the ticket tier.
    function getTicketPricePaidAndTierIndex(bytes32 showId, uint256 ticketId) public view returns (uint256 price, uint256 tierIndex) {
        uint256 _price = showInstance.getTicketPricePaid(showId, ticketId);
        uint256 _tierIndex = ticketIdToTierIndex[ticketId];
        return (_price, _tierIndex);
    }

    // @notice Burns a specified amount of tokens, removing them from circulation.
    // @param tokenId Identifier of the token to be burned.
    // @param amount Amount of tokens to be burned.
    // @param owner Owner of the tokens.
    function burnTokens(uint256 tokenId, uint256 amount, address owner) public onlyShowContract {
        _burn(owner, tokenId, amount);
    }

    // @notice Sets the default URI for tickets related to a specific show.
    // @param newDefaultURI The new default URI for tickets.
    // @param showId Identifier of the show.
    function setDefaultURIForShow(bytes32 showId, string memory newDefaultURI) public {
        require(msg.sender == showInstance.getOrganizer(showId), "Caller is not the organizer");
        showDefaultURIs[showId] = newDefaultURI;
    }

    // @notice Sets the URI for a specific token ID.
    // @param showId Identifier of the show.
    // @param tokenId Identifier of the token.
    // @param newURI The new URI for the token.
    function setTokenURI(bytes32 showId, uint256 tokenId, string memory newURI) public {
        require(msg.sender == showInstance.getOrganizer(showId), "Caller is not the organizer of this show");
        tokenURIs[tokenId] = newURI;
        emit URI(newURI, tokenId);
    }

     // @dev Sets the address of the Show contract. This function allows the Ticket contract
     // @param _showContractAddress The address of the Show contract to be linked with this Ticket contract.
    function setShowContractAddress(address _showContractAddress) external {
        // Ensure that the Show contract address is not already set.
        require(address(showInstance) == address(0), "Show contract address is already set");

        showInstance = IShow(_showContractAddress);
    }

    // @notice Retrieves the URI for a specific token ID, incorporating showId into the URI path.
    // @param tokenId Identifier of the token for which to retrieve the URI.
    // @return The URI of the specified token, either a custom set URI or a constructed one
    //        that includes the showId and tokenId in the path.
    function uri(uint256 tokenId) public view override returns (string memory) {
        // Check if a custom URI has been set for the token
        string memory customTokenURI = tokenURIs[tokenId];
        if (bytes(customTokenURI).length > 0) {
            return customTokenURI;
        }

        // Retrieve the associated showId for the token
        bytes32 showId = tokenIdToShowId[tokenId];
        require(showId != bytes32(0), "Token does not exist.");

        // Convert the showId from bytes32 to a hexadecimal string
        string memory showIdHexString = bytes32ToHexString(showId);

        // Construct the metadata URI using the showId and tokenId
        string memory baseURI = bytes(showDefaultURIs[showId]).length > 0 ? showDefaultURIs[showId] : defaultURI;
        return string(abi.encodePacked(baseURI, "0x", showIdHexString, "/", Strings.toString(tokenId), ".json"));
    }

     // @dev Safely transfers `amount` of token `id` from `from` to `to`.
     // @param from The address sending the token.
     // @param to The address receiving the token.
     // @param id The ID of the token being transferred.
     // @param amount The amount of tokens to be transferred.
     // @param data Additional data with no specified format, sent in call to `_mint`, `_burn`, or `_transfer`.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        // Custom logic before transfer
        bytes32 showId = tokenIdToShowId[id];
        if (from != address(0)) {
            showInstance.removeTokenIdFromWallet(showId, from, id);
        }
        if (to != address(0)) {
            showInstance.addTokenIdToWallet(showId, to, id);
        }

        // Call the base contract transfer method
        super.safeTransferFrom(from, to, id, amount, data);
    }

     // @dev Safely transfers multiple types of tokens from `from` to `to`.
     // This override includes custom logic to update token ownership mapping in the Show contract.
     // It calls the base ERC1155 safeBatchTransferFrom to handle the transfer following the ERC1155 standard.
     // @param from The address sending the tokens.
     // @param to The address receiving the tokens.
     // @param ids An array of token IDs being transferred.
     // @param amounts An array of the amounts of each token ID being transferred.
     // @param data Additional data with no specified format, sent in call to `_mint`, `_burn`, or `_transfer`.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        // Custom logic before batch transfer
        for (uint256 i = 0; i < ids.length; i++) {
            bytes32 showId = tokenIdToShowId[ids[i]];
            if (from != address(0)) {
                showInstance.removeTokenIdFromWallet(showId, from, ids[i]);
            }
            if (to != address(0)) {
                showInstance.addTokenIdToWallet(showId, to, ids[i]);
            }
        }

        // Call the base contract batch transfer method
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

     // @dev Converts a bytes32 value to a hexadecimal string.
     // This function is used to convert binary data, like Ethereum addresses or hashes,
     // into a human-readable hexadecimal string format.
     // @param _bytes32 The bytes32 value to convert.
     // @return The hexadecimal string representation of the input value.
    function bytes32ToHexString(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64); // Each byte is represented by 2 hex characters

        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(_bytes32[i] >> 4)];
            str[1+i*2] = alphabet[uint8(_bytes32[i] & 0x0f)];
        }

        return string(str);
    }
}
