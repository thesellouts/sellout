// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IShow } from '../IShow.sol';

contract ShowVaultStorage {
    /// @notice Address of the Sellout multisig that can interact with the vault
    address public SELLOUT_PROTOCOL_WALLET;

    /// @notice Address of the Show contract that can interact with the vault
    address public showContract;

    /// @notice Address of the Box Office contract that can interact with the vault
    address public boxOfficeContract;

    /// @notice Interface instance of the IShow contract
    IShow public showInstance;

    /// @notice Mapping from showId to its accumulated ether balance
    /// @dev Stores the total amount of Ether collected for each show
    mapping(bytes32 => uint256) public showVault;

    /// @notice Mapping from showId and token address to its accumulated ERC20 token balance
    /// @dev Stores the total amount of each ERC20 token type collected for each show
    mapping(bytes32 => mapping(address => uint256)) public showTokenVault;

    /// @notice Mapping from showId to wallet addresses to pending refunds in Ether
    /// @dev Tracks the amount of Ether to be refunded to each wallet for each show
    mapping(bytes32 => mapping(address => uint256)) public pendingRefunds;

    /// @notice Mapping from showId and token address to wallet addresses to pending token refunds
    /// @dev Tracks the amount of each ERC20 token to be refunded to each wallet for each show
    mapping(bytes32 => mapping(address => mapping(address => uint256))) public pendingTokenRefunds;

    /// @notice Mapping to track pending payouts in Ether for each show and wallet address
    /// @dev Tracks the Ether amounts pending payout to each wallet for each show
    mapping(bytes32 => mapping(address => uint256)) public pendingPayouts;

    /// @notice Mapping to track pending payouts in ERC20 tokens for each show and wallet address
    /// @dev Tracks the token amounts pending payout to each wallet for each show
    mapping(bytes32 => mapping(address => mapping(address => uint256))) public pendingTokenPayouts;

    /// @notice Mapping to track the payment token for each show
    /// @dev Stores the address of the ERC20 payment token used for transactions in each show
    mapping(bytes32 => address) public showPaymentTokens;
}
