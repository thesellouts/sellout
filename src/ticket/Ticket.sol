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

/// @title SellOut Ticket
/// @author taayyohh
/// @notice A contract for managing ticket sales for shows using the ERC1155 standard
contract Ticket is Initializable, ITicket, TicketStorage, ERC1155Upgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
    IShow public showInstance;

    // Mapping from token ID to its URI
    mapping(uint256 => string) private tokenURIs;

    // Default URI
    string private defaultURI;

    /// @notice Constructor to initialize the contract with the Show contract address
    /// @param _showContractAddress The address of the Show contract
    function initialize(address initialOwner, address _showContractAddress) public initializer {
        __ERC1155_init("https://metadata.sellouts.app/ticket/{id}.json");
        __ReentrancyGuard_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        showInstance = IShow(_showContractAddress);
        defaultURI = "https://metadata.sellouts.app/ticket/";
    }


    /// @notice Modifier to ensure only the Show contract can call certain functions
    modifier onlyShowContract() {
        require(msg.sender == address(showInstance), "Only the Show contract can call this function");
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


    /// @notice Purchase multiple tickets for a specific show
    /// @param showId The ID of the show
    /// @param amount The amount of tickets to purchase
    function purchaseTickets(bytes32 showId, uint256 amount) public payable nonReentrant {
        uint256 totalPreviouslyPurchased = ticketsPurchasedCount[showId][msg.sender];
        uint256 totalTicketsSold = showInstance.getTotalTicketsSold(showId);

        require(totalPreviouslyPurchased + amount <= MAX_TICKETS_PER_WALLET, "Exceeds maximum tickets per wallet");

        require(showInstance.getShowStatus(showId) == ShowTypes.Status.Proposed, "Show is not available for ticket purchase");
        require(showInstance.getTotalTicketsSold(showId) + amount <= showInstance.getTotalCapacity(showId), "Not enough tickets available");

        uint256 fanStatus = determineFanStatus(showId);
        ShowTypes.TicketPrice memory ticketPrice = showInstance.getTicketPrice(showId);

        uint256 calculatedTicketPrice = calculateTicketPrice(fanStatus, ticketPrice.minPrice, ticketPrice.maxPrice) * amount;

        require(msg.value == calculatedTicketPrice, "Incorrect payment amount");
        showInstance.depositToVault{value: msg.value}(showId);

        // Increment the purchase counter for this user for this show
        ticketsPurchasedCount[showId][msg.sender] += amount;

        // Unique token for each show, fan status, and purchase count
        uint256 tokenId = uint256(keccak256(abi.encodePacked(showId, msg.sender, totalTicketsSold, amount)));
        _mint(msg.sender, tokenId, amount, "");

        showInstance.addTokenIdToWallet(showId, msg.sender, tokenId);
        showInstance.setTicketPricePaid(showId, tokenId, msg.value);
        showInstance.setTicketOwnership(msg.sender, showId, true);
        showInstance.updateExpiry(showId, block.timestamp + 30 days);
        showInstance.setTotalTicketsSold(showId, amount);

        emit TicketPurchased(msg.sender, showId, tokenId, amount, fanStatus);
    }

    /// @notice Burns a specific amount of tokens, removing them from circulation
    /// @param tokenId The ID of the token type to be burned
    /// @param amount The amount of tokens to be burned
    function burnTokens(uint256 tokenId, uint256 amount) public onlyShowContract {
        _burn(msg.sender, tokenId, amount);
    }

    /// @notice Calculate the ticket price based on fan status
    /// @param fanStatus The fan status (1-10)
    /// @param minPrice The minimum price of the ticket
    /// @param maxPrice The maximum price of the ticket
    /// @return The calculated ticket price
    function calculateTicketPrice(uint256 fanStatus, uint256 minPrice, uint256 maxPrice) internal pure returns (uint256) {
        require(fanStatus >= 1 && fanStatus <= 10, "Invalid fan status");
        require(maxPrice >= minPrice, "Max price must be greater or equal to min price");

        if (fanStatus == 1 || maxPrice == minPrice) {
            return minPrice;
        } else {
            uint256 priceRange = maxPrice - minPrice;
            uint256 incrementalStep = priceRange / 9;
            return minPrice + (incrementalStep * (fanStatus - 1));
        }
    }

     // @notice Determines a fan's status based on the percentage of tickets sold.
     // @dev Used internally to calculate dynamic ticket pricing.
     // @param showId The unique identifier of the show.
     // @return The fan status, a number between 1 and 10.
    function determineFanStatus(bytes32 showId) internal view returns (uint256) {
        uint256 totalCapacity = showInstance.getTotalCapacity(showId);
        uint256 totalTicketsSoldForShow = showInstance.getTotalTicketsSold(showId);
        uint256 percentageSold = (totalTicketsSoldForShow * 100) / totalCapacity;

        // Calculate the fan status, ensuring it's at least 1
        uint256 fanStatus = (percentageSold + 9) / 10;
        return fanStatus > 0 ? fanStatus : 1; // Ensure the fan status is at least 1
    }

    // @notice Sets the URI for a specific token ID.
    // @dev Can only be called by the organizer of the show related to the token.
    // @param showId The unique identifier of the show.
    // @param tokenId The token ID for which to set the URI.
    // @param newURI The new URI for the token.
    function setTokenURI(bytes32 showId, uint256 tokenId, string memory newURI) public {
        require(msg.sender == showInstance.getOrganizer(showId), "Caller is not the organizer of this show");
        tokenURIs[tokenId] = newURI;
        emit URI(newURI, tokenId);
    }

    // @notice Retrieves the URI for a specific token ID.
    // @param tokenId The token ID for which to retrieve the URI.
    // @return The URI of the specified token.
    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory _tokenURI = tokenURIs[tokenId];
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI; // Specific URI for this token
        } else {
            return string(abi.encodePacked(defaultURI, Strings.toString(tokenId), ".json")); // Default URI
        }
    }

    // @notice Sets the default URI for tickets related to a specific show.
    // @dev Can only be set by the organizer of the show.
    // @param newDefaultURI The new default URI for tickets.
    // @param showId The unique identifier of the show.
    function setDefaultURI(string memory newDefaultURI, bytes32 showId) public {
        require(showInstance.isOrganizer(msg.sender, showId), "Caller is not the organizer");
        defaultURI = newDefaultURI;
    }
}
