// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC721Enumerable, ERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ITicket } from "./ITicket.sol";
import { TicketStorage } from "./storage/TicketStorage.sol";
import { Show } from "../show/Show.sol";
import { ShowTypes } from "../show/types/ShowTypes.sol";

/// @title SellOut
/// @author taayyohh
/// @notice A contract for managing ticket sales for shows
contract Ticket is ITicket, TicketStorage, ERC721Enumerable, ERC721URIStorage, ReentrancyGuard {
    Show public showInstance;

    /// @notice Constructor to initialize the contract with the Show contract address
    /// @param _showContractAddress The address of the Show contract
    constructor(address _showContractAddress) ERC721("The SellOuts", "SELLOUT") {
        showInstance = Show(_showContractAddress);
    }

    /// @notice Modifier to ensure only the Show contract can call certain functions
    modifier onlyShowContract() {
        require(msg.sender == address(showInstance), "Only the Show contract can call this function");
        _;
    }

    // Modifier to restrict access to SELLOUT_PROTOCOL_WALLET only
//    modifier onlySelloutProtocolWallet() {
//        require(msg.sender == SELLOUT_PROTOCOL_WALLET, "Not authorized");
//        _;
//    }

    /// @notice Purchase a ticket for a specific show
    /// @param showId The ID of the show
    function purchaseTicket(bytes32 showId) public payable nonReentrant {
        require(showInstance.getShowStatus(showId) == ShowTypes.Status.Proposed, "Show is not available for ticket purchase");
        require(showInstance.getTotalTicketsSold(showId) < showInstance.getTotalCapacity(showId), "Sold out");
        require(showInstance.getWalletTokenIds(showId, msg.sender).length < MAX_TICKETS_PER_WALLET, "Max tickets reached");

        showInstance.checkAndUpdateExpiry(showId);

        require(showInstance.getShowStatus(showId) != ShowTypes.Status.Expired, "Show has expired");

        uint256 fanStatus = determineFanStatus(showId);
        ShowTypes.TicketPrice memory ticketPrice = showInstance.getTicketPrice(showId);

        uint256 calculatedTicketPrice = calculateTicketPrice(fanStatus, ticketPrice.minPrice, ticketPrice.maxPrice);

        require(msg.value == calculatedTicketPrice, "Incorrect payment amount");
        showInstance.depositToVault{value: msg.value}(showId);

        string memory generatedTokenURI = generateTokenURI(fanStatus);
        uint256 tokenId = _mintNFT(msg.sender, generatedTokenURI);

        showInstance.addTokenIdToWallet(showId, msg.sender, tokenId);
        showInstance.setTicketPricePaid(showId, tokenId, msg.value);
        showInstance.setTicketOwnership(msg.sender, showId, true);
        showInstance.updateExpiry(showId, block.timestamp + 30 days);

        uint256 proposalThresholdValue = (showInstance.getTotalCapacity(showId) * showInstance.getSellOutThreshold(showId)) / 100;

        // Check if the total tickets sold is greater than or equal to the proposal threshold
        if (showInstance.getTotalTicketsSold(showId) >= proposalThresholdValue) {
            showInstance.updateStatus(showId, ShowTypes.Status.SoldOut);
        }

        emit TicketPurchased(msg.sender, showId, tokenId, fanStatus);
    }

    /// @notice Internal function to mint a new NFT
    /// @param to The address to mint the NFT to
    /// @param generatedTokenURI The URI of the token
    /// @return tokenId The ID of the minted token
    function _mintNFT(address to, string memory generatedTokenURI) internal returns (uint256) {
        uint256 tokenId = getNextTokenId();
        _mint(to, tokenId);
        _setTokenURI(tokenId, generatedTokenURI);
        return tokenId;
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

    /// @notice Determine the fan status based on the percentage of tickets sold
    /// @param showId The ID of the show
    /// @return The fan status (1-10)
    function determineFanStatus(bytes32 showId) internal view returns (uint256) {
        uint256 totalCapacity = showInstance.getTotalCapacity(showId);
        uint256 totalTicketsSoldForShow = showInstance.getTotalTicketsSold(showId);
        uint256 percentageSold = (totalTicketsSoldForShow * 100) / totalCapacity;

        // Calculate the fan status, ensuring it's at least 1
        uint256 fanStatus = (percentageSold + 10 - 1) / 10;

        // Ensure the fan status is at least 1
        if (fanStatus < 1) {
            fanStatus = 1;
        }

        return fanStatus;
    }


    /// @notice Overridden function from ERC721 set the base URI for the NFT metadata
    /// @param baseURI The base URI string
    function setBaseURI(string memory baseURI) external {
        _baseTokenURI = baseURI;
    }

    /// @notice Generate the token URI based on fan status
    /// @param fanStatus The fan status (1-10)
    /// @return The generated token URI
    ///TODO: make this more generative
    function generateTokenURI(uint256 fanStatus) internal pure returns (string memory) {
        string memory baseURI = "https://sellout.lucid.haus/";
        return string(abi.encodePacked(baseURI, "pfp/", Strings.toString(fanStatus)));
    }

    /// @notice Burns a specific token, removing it from circulation
    /// @param tokenId The ID of the token to be burned
    function burnToken(uint256 tokenId) public onlyShowContract {
        _burn(tokenId);
    }


    /// @notice Overridden function from ERC721 to handle token URI
    /// @param tokenId The ID of the token
    /// @return The URI of the token
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage,ITicket) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    }

    /// @notice Overridden function from ERC721 to handle token transfer
    /// @param from The address transferring the token
    /// @param to The address receiving the token
    /// @param tokenId The ID of the token
    /// @param batchSize The batch size for the transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /// @notice Overridden function from ERC721Enumerable and ERC721URIStorage to support specific interfaces
    /// @param interfaceId The ID of the interface
    /// @return true if the interface is supported, false otherwise
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Overridden function from ERC721 and ERC721URIStorage to handle token burning
    /// @param tokenId The ID of the token to burn
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) onlyShowContract {
        super._burn(tokenId);
    }
}
