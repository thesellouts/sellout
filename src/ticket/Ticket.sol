// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ITicket.sol";
import "./storage/TicketStorage.sol";
import "../show/Show.sol";
import "../show/types/ShowTypes.sol";

/// @title SellOut Ticket
/// @author taayyohh
/// @notice A contract for managing ticket sales for shows using the ERC1155 standard
contract Ticket is ITicket, TicketStorage, ERC1155, ReentrancyGuard {
    Show public showInstance;

    // Mapping from token ID to its URI
    mapping(uint256 => string) private tokenURIs;

    // Default URI
    string private defaultURI;

    /// @notice Constructor to initialize the contract with the Show contract address
    /// @param _showContractAddress The address of the Show contract
    constructor(address _showContractAddress) ERC1155("https://sellout.onchain.haus/") {
        showInstance = Show(_showContractAddress);
        defaultURI = "https://sellout.onchain.haus/"; // Set the default URI
    }

    /// @notice Modifier to ensure only the Show contract can call certain functions
    modifier onlyShowContract() {
        require(msg.sender == address(showInstance), "Only the Show contract can call this function");
        _;
    }

    /// @notice Purchase multiple tickets for a specific show
    /// @param showId The ID of the show
    /// @param amount The amount of tickets to purchase
    function purchaseTickets(bytes32 showId, uint256 amount) public payable nonReentrant {
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
        uint256 tokenId = uint256(keccak256(abi.encodePacked(showId, fanStatus, ticketsPurchasedCount[showId][msg.sender])));
        _mint(msg.sender, tokenId, amount, ""); // Minting the specified amount of tickets

        showInstance.addTokenIdToWallet(showId, msg.sender, tokenId);
        showInstance.setTicketPricePaid(showId, tokenId, msg.value);
        showInstance.setTicketOwnership(msg.sender, showId, true);
        showInstance.updateExpiry(showId, block.timestamp + 30 days);

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

    /// @notice Determine the fan status based on the percentage of tickets sold
    /// @param showId The ID of the show
    /// @return The fan status (1-10)
    function determineFanStatus(bytes32 showId) internal view returns (uint256) {
        uint256 totalCapacity = showInstance.getTotalCapacity(showId);
        uint256 totalTicketsSoldForShow = showInstance.getTotalTicketsSold(showId);
        uint256 percentageSold = (totalTicketsSoldForShow * 100) / totalCapacity;

        // Calculate the fan status, ensuring it's at least 1
        uint256 fanStatus = (percentageSold + 9) / 10;
        return fanStatus > 0 ? fanStatus : 1; // Ensure the fan status is at least 1
    }

    /// @notice Sets the URI for a given token ID
    /// @param showId The ID of the show for which to set the URI
    /// @param tokenId The token ID for which to set the URI
    /// @param newURI The new URI to set
    function setTokenURI(bytes32 showId, uint256 tokenId, string memory newURI) public {
        require(msg.sender == showInstance.getOrganizer(showId), "Caller is not the organizer of this show");
        tokenURIs[tokenId] = newURI;
        emit URI(newURI, tokenId);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory _tokenURI = tokenURIs[tokenId];
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI; // Specific URI for this token
        } else {
            return string(abi.encodePacked(defaultURI, Strings.toString(tokenId), ".json")); // Default URI
        }
    }

    // Function to set the default URI for tickets, restricted to the organizer of a specific show
    function setDefaultURI(string memory newDefaultURI, bytes32 showId) public {
        require(showInstance.isOrganizer(msg.sender, showId), "Caller is not the organizer");
        defaultURI = newDefaultURI;
    }


    /// @notice Retrieves the organizer address for a specific show
    /// @param showId The unique identifier of the show
    /// @return The address of the organizer of the show
    function getOrganizer(bytes32 showId) public view returns (address) {
        return showInstance.getOrganizer(showId);
    }
}
