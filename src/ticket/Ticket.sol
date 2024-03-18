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
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";


/**
 * @title SellOut Ticket
 * @notice Implements ticket sales for shows using the ERC1155 standard. Supporting arbitrary ticket tiers.
 * @dev Extends ERC1155 for ticket tokenization.
 */
contract Ticket is Initializable, ITicket, TicketStorage, ERC1155Upgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, OwnableUpgradeable {

    /**
     * @notice Initializes the contract with the Show contract address and metadata URI.
     * @param initialOwner The address of the initial contract owner.
     * @param _showContractAddress The address of the Show contract.
     */
    function initialize(address initialOwner, address _showContractAddress) public initializer {
        __ERC1155_init("https://metadata.sellouts.app/ticket/{id}.json");
        __ReentrancyGuard_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        showInstance = IShow(_showContractAddress);
        defaultURI = "https://metadata.sellouts.app/ticket/";
    }

    /**
     * @dev Ensures that only the Show contract can call the modified function.
     */
    modifier onlyShowContract() {
        require(msg.sender == address(showInstance), "Only the Show contract can call this function");
        _;
    }

    /**
     * @dev Allows contract upgrades by the contract owner only.
     * @param newImplementation The address of the new contract implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Purchases tickets for a specified show and tier.
     * @param showId Identifier of the show.
     * @param tierIndex Index of the ticket tier.
     * @param amount Number of tickets to purchase.
     */
    function purchaseTickets(bytes32 showId, uint256 tierIndex, uint256 amount) public payable nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        ShowTypes.Status showStatus = showInstance.getShowStatus(showId);
        require(showStatus == ShowTypes.Status.Proposed, "Show is not available for ticket purchase");

        uint256[] memory ownedTokenIds = showInstance.getWalletTokenIds(showId, msg.sender);
        require(ownedTokenIds.length + amount <= MAX_TICKETS_PER_WALLET, "Exceeds maximum tickets per wallet");

        (, uint256 pricePerTicket, uint256 ticketsAvailable) = showInstance.getTicketTierInfo(showId, tierIndex);
        require(ticketsAvailable >= amount, "Not enough tickets available in this tier");
        require(msg.value == pricePerTicket * amount, "Incorrect payment amount");

        showInstance.depositToVault{value: msg.value}(showId);

        // Mint tickets in batch for efficiency
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            ids[i] = ++lastTicketNumberForShow[showId];
            amounts[i] = 1;
            ticketIdToTierIndex[ids[i]] = tierIndex; // Associate each ticket ID with its tier index
            showInstance.addTokenIdToWallet(showId, msg.sender, ids[i]);
            showInstance.setTicketPricePaid(showId, ids[i], pricePerTicket);
            showInstance.setTicketOwnership(showId, msg.sender, ids[i], true);
        }
        _mintBatch(msg.sender, ids, amounts, "");

        showInstance.consumeTicketTier(showId, tierIndex, amount);
        showInstance.updateStatusIfSoldOut(showId);
        showInstance.setTotalTicketsSold(showId, amount);

        emit TicketPurchased(msg.sender, showId, ids[amount-1], amount, tierIndex);
    }

    /**
     * @notice Retrieves the price paid for a specific ticket and its tier index.
     * @param showId The unique identifier of the show.
     * @param ticketId The unique identifier of the ticket.
     * @return price The price paid for the ticket.
     * @return tierIndex The index of the ticket tier.
     */
    function getTicketPricePaidAndTierIndex(bytes32 showId, uint256 ticketId) public view returns (uint256 price, uint256 tierIndex) {
        require(ticketIdToTierIndex[ticketId] != 0, "Ticket or tier index does not exist");
        uint256 _price = showInstance.getTicketPricePaid(showId, ticketId);
        uint256 _tierIndex = ticketIdToTierIndex[ticketId];
        return (_price, _tierIndex);
    }


    /**
     * @notice Burns a specified amount of tokens, removing them from circulation.
     * @param tokenId Identifier of the token to be burned.
     * @param amount Amount of tokens to be burned.
     * @param owner Owner of the tokens.
     */
    function burnTokens(uint256 tokenId, uint256 amount, address owner) public onlyShowContract {
        _burn(owner, tokenId, amount);
    }

    /**
     * @notice Sets the default URI for tickets related to a specific show.
     * @param newDefaultURI The new default URI for tickets.
     * @param showId Identifier of the show.
     */
    function setDefaultURI(string memory newDefaultURI, bytes32 showId) public {
        require(msg.sender == showInstance.getOrganizer(showId), "Caller is not the organizer");
        defaultURI = newDefaultURI;
    }

    /**
     * @notice Sets the URI for a specific token ID.
     * @param showId Identifier of the show.
     * @param tokenId Identifier of the token.
     * @param newURI The new URI for the token.
     */
    function setTokenURI(bytes32 showId, uint256 tokenId, string memory newURI) public {
        require(msg.sender == showInstance.getOrganizer(showId), "Caller is not the organizer of this show");
        tokenURIs[tokenId] = newURI;
        emit URI(newURI, tokenId);
    }

    /**
     * @notice Retrieves the URI for a specific token ID.
     * @param tokenId Identifier of the token.
     * @return The URI of the specified token.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory _tokenURI = tokenURIs[tokenId];
        return bytes(_tokenURI).length > 0 ? _tokenURI : string(abi.encodePacked(defaultURI, Strings.toString(tokenId), ".json"));
    }
}
