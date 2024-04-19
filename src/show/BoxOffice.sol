// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { IBoxOffice } from "./IBoxOffice.sol";
import { BoxOfficeStorage } from "./storage/BoxOfficeStorage.sol";

import { ITicket } from "../ticket/ITicket.sol";
import { ITicketFactory } from "../ticket/ITicketFactory.sol";

import { IShow } from '../show/IShow.sol';
import { IShowVault } from '../show/IShowVault.sol';

import { ShowTypes } from '../show/types/ShowTypes.sol';



/**
 * @title BoxOffice
 * @dev Manages ticket sales, ticket validations, and ticket-related data for shows,
 *      acting as part of a decentralized event management platform.
 */
contract BoxOffice is IBoxOffice, BoxOfficeStorage, Initializable, UUPSUpgradeable, OwnableUpgradeable {
    modifier onlyShowContract() {
        require(msg.sender == address(showContractInstance), "Unauthorized: caller is not the Show contract");
        _;
    }

    /// @dev Ensures that only the ticket proxy associated with a given show can call certain functions.
    modifier onlyTicketProxy(bytes32 showId) {
        require(msg.sender == showContractInstance.getShowToTicketProxy(showId), "!tPxy");
        _;
    }

    /// @notice Initializes the BoxOffice contract with required addresses.
    /// @param _selloutProtocolWallet Address of the Sellout Protocol Wallet (owner).
    /// @param _showContract Address of the Show contract.
    /// @param _ticketFactory Address of the Ticket Factory contract.
    /// @param _showVault Address of the Show Vault contract.
    function initialize(
        address _selloutProtocolWallet,
        address _showContract,
        address _ticketFactory,
        address _showVault
    ) public initializer {
        __Ownable_init(_selloutProtocolWallet);
        __UUPSUpgradeable_init();
        showContractInstance = IShow(_showContract);
        ticketFactoryInstance = ITicketFactory(_ticketFactory);
        showVaultInstance = IShowVault(_showVault);
    }

    /// @notice Allows only the owner to upgrade the contract implementation.
    /// @param newImplementation The address of the new contract implementation.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Creates and initializes a ticket proxy for a given show.
    /// @param showId Unique identifier for the show.
    /// @param protocol The address of the protocol proposing the show.
    function createAndInitializeTicketProxy(bytes32 showId, address protocol) external onlyShowContract {
        address ticketProxyAddress = ticketFactoryInstance.createTicketProxy(protocol);
        ITicket(ticketProxyAddress).setShowContractAddresses(address(showContractInstance), address(this), address(showVaultInstance));
        showContractInstance.setShowToTicketProxy(showId, ticketProxyAddress);
    }

    /// @notice Gets the total number of tickets sold for a specific show.
    /// @param showId Unique identifier for the show.
    /// @return Number of tickets sold.
    function getTotalTicketsSold(bytes32 showId) external view returns (uint256) {
        return totalTicketsSold[showId];
    }

    /// @notice Sets the total number of tickets sold for a specific show.
    /// @param showId Unique identifier for the show.
    /// @param amount Total number of tickets sold.
    function setTotalTicketsSold(bytes32 showId, uint256 amount) external onlyTicketProxy(showId) {
        totalTicketsSold[showId] = amount;
    }

    /// @notice Sets the price paid for a specific ticket of a show.
    /// @param showId Unique identifier for the show.
    /// @param ticketId Unique identifier of the ticket within the show.
    /// @param price Price paid for the ticket.
    function setTicketPricePaid(bytes32 showId, uint256 ticketId, uint256 price) external onlyTicketProxy(showId) {
        ticketPricePaid[showId][ticketId] = price;
    }

    /// @notice Retrieves the price paid for a specific ticket of a show.
    /// @param showId Unique identifier for the show.
    /// @param ticketId Unique identifier of the ticket within the show.
    /// @return Price paid for the ticket.
    function getTicketPricePaid(bytes32 showId, uint256 ticketId) external view returns (uint256) {
        return ticketPricePaid[showId][ticketId];
    }

    /// @notice Updates total tickets sold and potentially the show status after a ticket refund.
    /// @param showId Unique identifier for the show.
    /// @param ticketId ID of the ticket being refunded.
    /// @param refundAmount Amount to be refunded.
    /// @param paymentToken Payment token address; address(0) for ETH.
    //. @param ticketOwner address of the owner requesting a refund
    function updateTicketsSoldAndShowStatusAfterRefund(
        bytes32 showId,
        uint256 ticketId,
        uint256 refundAmount,
        address paymentToken,
        address ticketOwner
    ) external onlyShowContract {
        address ticketProxyAddress = showContractInstance.getShowToTicketProxy(showId);
        require(ticketProxyAddress != address(0), "!pxy"); // Ensure the ticket proxy is valid

        totalTicketsSold[showId]--;
        showVaultInstance.processRefund(showId, refundAmount, paymentToken,ticketOwner);

        ITicket(ticketProxyAddress).burnTokens(ticketId, 1, ticketOwner);
        delete ticketPricePaid[showId][ticketId];
        removeTokenIdFromWallet(showId, ticketOwner, ticketId);
    }

    /// @notice Checks if a given tokenId exists in the wallet's list of tokenIds for a specific show.
    /// @param showId The unique identifier of the show.
    /// @param wallet The address of the wallet to check for token ownership.
    /// @param tokenId The unique identifier of the token to check.
    /// @return True if the tokenId exists in the wallet's list of tokens for the specified show, false otherwise.
    function isTokenOwner(bytes32 showId, address wallet, uint256 tokenId) external view returns (bool) {
        uint256[] memory ticketIds =  walletToShowToTokenIds[showId][wallet];
        for (uint256 i = 0; i < ticketIds.length; i++) {
            if (ticketIds[i] == tokenId) {
                return true;
            }
        }
        return false;
    }

    /// @notice Retrieves the token IDs associated with a specific show for a given wallet
    /// @param showId Unique identifier for the show
    /// @param wallet Address of the wallet for which token IDs are being retrieved
    /// @return An array of token IDs associated with the show for the specified wallet
    function getWalletTokenIds(bytes32 showId, address wallet) external view returns (uint256[] memory) {
        return walletToShowToTokenIds[showId][wallet];
    }

    // @notice Adds a token ID to a user's wallet for a specific show.
    // @param showId The unique identifier of the show.
    // @param wallet The address of the user's wallet.
    // @param tokenId The unique identifier of the token.
    // @dev This function can only be called by the external contracts
    function addTokenIdToWallet(bytes32 showId, address wallet, uint256 tokenId) external onlyTicketProxy(showId) {
        walletToShowToTokenIds[showId][wallet].push(tokenId);
    }

    // @notice Removes a specific ticket ID for a given wallet and show.
    // @param showId The unique identifier of the show.
    // @param wallet The address of the wallet owning the ticket.
    // @param ticketId The ID of the ticket to be removed.
    // @dev This function can only be called by the external contracts
    function removeTokenIdFromWallet(bytes32 showId, address wallet, uint256 tokenId) public  {
        require(msg.sender == showContractInstance.getShowToTicketProxy(showId) || msg.sender == address(this), "BOT");
        uint256[] storage ticketIds = walletToShowToTokenIds[showId][wallet];
        for (uint256 i = 0; i < ticketIds.length; i++) {
            if (ticketIds[i] == tokenId) {
                ticketIds[i] = ticketIds[ticketIds.length - 1];
                ticketIds.pop();
                break;
            }
        }
    }
}
