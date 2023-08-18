// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../show/Show.sol";
import "../show/types/ShowTypes.sol";
import "./storage/TicketStorage.sol";
import "./types/TicketTypes.sol";


/// @title ITicket
/// @author taayyohh
/// @notice The external Ticket events, errors and functions
interface ITicket is TicketTypes {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    event TicketPurchased(address indexed buyer, uint256 showId, uint256 ticketId, uint256 fanStatus);
    event TicketRefunded(address indexed owner, uint256 showId, uint256 ticketId);


    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///


    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///
    function purchaseTicket(uint256 showId) external payable;
    function refundTicket(uint256 ticketId) external;
    function totalCapacityOfShow(uint256 showId) external view returns (uint256);
}
