// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../types/TicketTypes.sol";

/// @title TicketStorage
/// @author taayyohh
/// @notice Show Storage contract
contract TicketStorage is TicketTypes {
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIdCounter;

    string internal _baseTokenURI;

    mapping(uint256 => bytes32) public ticketToShow;
    mapping(bytes32 => uint256) public totalTicketsSold;
    mapping(uint256 => uint256) public ticketPricePaid; // Mapping to store the ticket price paid for each ticket
    mapping(address => mapping(bytes32 => bool)) public ticketOwnership;


    function getNextTokenId() internal returns (uint256) {
        _tokenIdCounter.increment();
        return _tokenIdCounter.current();
    }
}
