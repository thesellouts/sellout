// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ITicket.sol";
import "./storage/TicketStorage.sol";
import "../show/Show.sol";

/// @title SellOut
/// @author taayyohh
/// @notice SellOut
contract Ticket is ITicket, TicketStorage, ERC721Enumerable, ERC721URIStorage, ReentrancyGuard {
    Show public showInstance;


    constructor(address _showContractAddress) ERC721("SellOuts", "SELLOUT") {
        showInstance = Show(_showContractAddress);
    }

    function setBaseURI(string memory baseURI) external {
        _baseTokenURI = baseURI;
    }

    function purchaseTicket(uint256 showId) public payable nonReentrant {
        require(totalTicketsSold[showId] < totalCapacityOfShow(showId), "Sold out");

        uint256 fanStatus = determineFanStatus(showId);
        Show.TicketPrice memory ticketPrice = showInstance.getTicketPrice(showId);

        uint256 calculatedTicketPrice = calculateTicketPrice(fanStatus, ticketPrice.minPrice, ticketPrice.maxPrice);

        require(msg.value == calculatedTicketPrice, "Incorrect payment amount");

        string memory generatedTokenURI = generateTokenURI(fanStatus);
        uint256 tokenId = _mintNFT(msg.sender, generatedTokenURI);

        ticketToShow[tokenId] = showId;
        totalTicketsSold[showId]++;

        if (totalTicketsSold[showId] == totalCapacityOfShow(showId)) {
            showInstance.updateStatus(showId, ShowTypes.Status.SoldOut);
        }

        emit TicketPurchased(msg.sender, showId, tokenId, fanStatus);
    }

    function refundTicket(uint256 ticketId) public nonReentrant {
        require(ownerOf(ticketId) == msg.sender, "You don't own this ticket");

        uint256 showId = ticketToShow[ticketId];
        uint256 fanStatus = determineFanStatus(showId);
        Show.TicketPrice memory ticketPrice = showInstance.getTicketPrice(showId);

        uint256 refundAmount = calculateRefundAmount(fanStatus, ticketPrice.minPrice, ticketPrice.maxPrice);

        payable(msg.sender).transfer(refundAmount);

        totalTicketsSold[showId]--;

        if (totalTicketsSold[showId] <= showInstance.getSellOutThreshold(showId)) {
            showInstance.updateStatus(showId, ShowTypes.Status.Proposed);
        }

        _burn(ticketId);

        emit TicketRefunded(msg.sender, showId, ticketId);
    }

    function calculateRefundAmount(uint256 fanStatus, uint256 minTicketPrice, uint256 maxTicketPrice) internal pure returns (uint256) {
        require(fanStatus >= 0 && fanStatus <= 10, "Invalid fan status");
        require(maxTicketPrice >= minTicketPrice, "Max ticket price must be greater or equal to min ticket price");

        uint256 ticketPrice = calculateTicketPrice(fanStatus, minTicketPrice, maxTicketPrice);
        uint256 refundAmount = ticketPrice;

        return refundAmount;
    }

    function calculateTicketPrice(uint256 fanStatus, uint256 minPrice, uint256 maxPrice) internal pure returns (uint256) {
        require(fanStatus >= 0 && fanStatus <= 10, "Invalid fan status");
        require(maxPrice >= minPrice, "Max price must be greater or equal to min price");

        if (fanStatus == 1) {
            return minPrice;
        } else {
            uint256 priceRange = maxPrice - minPrice;
            uint256 incrementalStep = priceRange / 9;
            return minPrice + (incrementalStep * (fanStatus - 1));
        }
    }

    function determineFanStatus(uint256 showId) internal view returns (uint256) {
        uint256 totalCapacity;
        uint256 totalTicketsSoldForShow = totalTicketsSold[showId];
        ShowTypes.Status status;

        (,,,,,,,totalCapacity,status,) = showInstance.getShowDetails(showId);

        require(status != ShowTypes.Status.Accepted && status != ShowTypes.Status.Refunded, "Show is not refundable");

        uint256 percentageSold = (totalTicketsSoldForShow * 100) / totalCapacity;
        uint256 fanStatus = ceilDiv(percentageSold, 10);

        if (fanStatus > 10) {
            fanStatus = 10;
        }

        return fanStatus;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }

    function generateTokenURI(uint256 fanStatus) internal pure returns (string memory) {
        string memory baseURI = "https://your-base-uri.com/";
        return string(abi.encodePacked(baseURI, "fanStatus/", Strings.toString(fanStatus)));
    }

    function _mintNFT(address to, string memory generatedTokenURI) internal returns (uint256) {
        uint256 tokenId = getNextTokenId();
        _mint(to, tokenId);
        _setTokenURI(tokenId, generatedTokenURI);
        return tokenId;
    }
    function totalCapacityOfShow(uint256 showId) public view returns (uint256) {
        return showInstance.getTotalCapacity(showId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override(ERC721, ERC721Enumerable) {
        // Call parent contracts' _beforeTokenTransfer implementations
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Add your custom logic here
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
