// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import { ITicketFactory } from '../../ticket/ITicketFactory.sol';
import { IShow } from '../IShow.sol';
import { IShowVault } from '../IShowVault.sol';

contract BoxOfficeStorage {
    IShow public showContractInstance;
    ITicketFactory public ticketFactoryInstance;
    IShowVault public showVaultInstance;

    mapping(bytes32 => uint256) public totalTicketsSold;

    mapping(bytes32 => mapping(uint256 => uint256)) public ticketPricePaid;

    // Mapping to associate wallet addresses with show IDs and token IDs
    mapping(bytes32 => mapping(address => uint256[])) public walletToShowToTokenIds;
}
