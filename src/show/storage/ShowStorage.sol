// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ShowTypes } from "../types/ShowTypes.sol";
import { ReferralModule } from "../../registry/referral/ReferralModule.sol";
import { Ticket } from "../../ticket/Ticket.sol";
import { IArtistRegistry } from "../../registry/artist/IArtistRegistry.sol";
import { IOrganizerRegistry } from "../../registry/organizer/IOrganizerRegistry.sol";
import { IVenueRegistry } from "../../registry/venue/IVenueRegistry.sol";

/// @title ShowStorageV1
/// @author taayyohh
/// @notice This contract provides storage for show-related data, including ticket mapping, total tickets sold, show details, and more.

contract ShowStorage is ShowTypes {
    address public ticketContract;
    address public venueContract;
    address public referralContract;

    address public artistRegistryContract;
    address public organizerRegistryContract;
    address public venueRegistryContract;

    Ticket public ticketInstance;
    ReferralModule public referralInstance;
    IArtistRegistry public artistRegistryInstance;
    IOrganizerRegistry public organizerRegistryInstance;
    IVenueRegistry public venueRegistryInstance;
    bool internal areContractsSet = false;

    address public SELLOUT_PROTOCOL_WALLET;

    // Base URI for tokens
    string internal _baseTokenURI;

    // Counter for the total number of active shows
    uint256 public activeShowCount;

    // Mapping to store show details by show ID
    mapping(bytes32 => Show) public shows;

    // Mapping to track whether a given address is an artist for a specific show
    mapping(bytes32 => mapping(address => bool)) public isArtistMapping;

    // Mapping to track the Ether balance for each show
    mapping(bytes32 => uint256) public showVault;

    // Mapping from show ID to ERC20 token address to amount of tokens
    mapping(bytes32 => mapping(address => uint256)) public showTokenVault;

    // Mapping to track pending refunds for each show and address
    mapping(bytes32 => mapping(address => uint256)) public pendingRefunds;

    // Mapping to track pending refunds for each show and address
    mapping(bytes32 => mapping(address => mapping(address => uint256))) public pendingTokenRefunds;

    // Mapping to track pending payouts for each show and address
    mapping(bytes32 => mapping(address => uint256)) public pendingPayouts;

    // Mapping to track pending payouts for each show and address
    mapping(bytes32 => mapping(address => mapping(address => uint256))) public pendingTokenPayouts;

    // Mapping to track the total number of tickets sold for each show ID
    mapping(bytes32 => uint256) public totalTicketsSold;

    // Mapping to store the ticket price paid for each ticket ID
    mapping(bytes32 => mapping(uint256 => uint256)) public ticketPricePaid;

    // Mapping to associate wallet addresses with show IDs and token IDs
    mapping(bytes32 => mapping(address => uint256[])) public walletToShowToTokenIds;

    // Mapping to track the payment token for each show
    mapping(bytes32 => address) public showPaymentToken;

    mapping(bytes32 => mapping(address => mapping(uint256 => bool))) internal ticketOwnership;
}
