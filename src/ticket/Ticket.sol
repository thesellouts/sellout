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


/**
 * @title SellOut Ticket
 * @author taayyohh
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
     * @param paymentToken Address of the erc20 token the show is priced in.
     */
    function purchaseTickets(bytes32 showId, uint256 tierIndex, uint256 amount, address paymentToken) public payable nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        ShowTypes.Status showStatus = showInstance.getShowStatus(showId);
        require(showStatus == ShowTypes.Status.Proposed, "Show is not available for ticket purchase");
        uint256[] memory ownedTokenIds = showInstance.getWalletTokenIds(showId, msg.sender);
        require(ownedTokenIds.length + amount <= MAX_TICKETS_PER_WALLET, "Exceeds maximum tickets per wallet");
        (, uint256 pricePerTicket, uint256 ticketsAvailable) = showInstance.getTicketTierInfo(showId, tierIndex);
        require(ticketsAvailable >= amount, "Not enough tickets available in this tier");
        uint256 totalPayment = pricePerTicket * amount;
        if (paymentToken == address(0)) {
            require(msg.value == totalPayment, "Incorrect payment amount");
            showInstance.depositToVault{value: msg.value}(showId);
        } else {
            require(msg.value == 0, "ERC20 purchases should not send ETH");
            showInstance.depositToVaultERC20(showId, totalPayment, paymentToken, msg.sender);
        }
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = uint256(keccak256(abi.encode(showId, tierIndex, lastTicketNumberForShow[showId] + 1 + i)));
            _mint(msg.sender, tokenId, 1, "");

            ticketIdToTierIndex[tokenId] = tierIndex;
            tokenIdToShowId[tokenId] = showId;

            showInstance.setTicketOwnership(showId, msg.sender, tokenId, true);
            showInstance.addTokenIdToWallet(showId, msg.sender, tokenId);
            showInstance.setTicketPricePaid(showId, tokenId, pricePerTicket);
        }
        lastTicketNumberForShow[showId] += amount;
        showInstance.consumeTicketTier(showId, tierIndex, amount);
        showInstance.setTotalTicketsSold(showId, amount);
        showInstance.updateStatusIfSoldOut(showId);

        emit TicketPurchased(msg.sender, showId, tierIndex, amount, paymentToken);
    }


    /**
     * @notice Retrieves the price paid for a specific ticket and its tier index.
     * @param showId The unique identifier of the show.
     * @param ticketId The unique identifier of the ticket.
     * @return price The price paid for the ticket.
     * @return tierIndex The index of the ticket tier.
     */
    function getTicketPricePaidAndTierIndex(bytes32 showId, uint256 ticketId) public view returns (uint256 price, uint256 tierIndex) {
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
  * @notice Retrieves the URI for a specific token ID, incorporating showId into the URI path.
 * This function overrides the default `uri` method from the ERC1155 standard to provide
 * custom token URIs that include the show identifier (showId) as part of the URI path.
 * If a custom token URI has been set, it returns that URI; otherwise, it constructs a URI
 * that includes the showId and tokenId. The showId is encoded as a hexadecimal string.
 *
 * @param tokenId Identifier of the token for which to retrieve the URI.
 * @return The URI of the specified token, either a custom set URI or a constructed one
 *         that includes the showId and tokenId in the path.
 */
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
        string memory baseURI = "https://metadata.sellouts.app/show/";
        return string(abi.encodePacked(baseURI, showIdHexString, "/", Strings.toString(tokenId), ".json"));
    }

    /**
     * @dev Converts a bytes32 value to a hexadecimal string.
     * This function is used to convert binary data, like Ethereum addresses or hashes,
     * into a human-readable hexadecimal string format.
     *
     * @param _bytes32 The bytes32 value to convert.
     * @return The hexadecimal string representation of the input value.
     */
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
