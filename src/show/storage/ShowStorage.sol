// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../types/ShowTypes.sol";


/// @title ShowStorageV1
/// @author taayyohh
/// @notice Show Storage contract
contract ShowStorage is ShowTypes {
    string internal _baseTokenURI;

    mapping(uint256 => uint256) public ticketToShow;
    mapping(uint256 => uint256) public totalTicketsSold;
    mapping(uint256 => Show) public shows;

    uint256 public showCount;

    address constant SELLOUT_PROTOCOL_WALLET = 0x1234567890123456789012345678901234567890;
}

