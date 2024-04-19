// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IShow } from '../IShow.sol';


contract ShowVaultStorage {
    // Address of the Show contract that can interact with the vault
    address public showContract;

    // Address of the Box Office contract that can interact with the vault
    address public boxOfficeContract;

    IShow public showInstance;

    // Mapping from showId to its accumulated ether balance
    mapping(bytes32 => uint256) public showVault;

    // Mapping from showId and token address to its accumulated ERC20 token balance
    mapping(bytes32 => mapping(address => uint256)) public showTokenVault;

    // Mapping from showId to wallet to pending refunds
    mapping(bytes32 => mapping(address => uint256)) public pendingRefunds;

    // Mapping from showId and token address to wallet to pending token refunds
    mapping(bytes32 => mapping(address => mapping(address => uint256))) public pendingTokenRefunds;

    // Mapping to track pending payouts for each show and address
    mapping(bytes32 => mapping(address => uint256)) public pendingPayouts;

    // Mapping to track pending payouts for each show and address
    mapping(bytes32 => mapping(address => mapping(address => uint256))) public pendingTokenPayouts;

    // Mapping to track the payment token for each show
    mapping(bytes32 => address) public showPaymentTokens;
}
