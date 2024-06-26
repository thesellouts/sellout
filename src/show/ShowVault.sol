// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import { ShowTypes } from "./types/ShowTypes.sol";
import { IShowVault } from "./IShowVault.sol";
import { IShow } from "./IShow.sol";
import { ShowVaultStorage } from "./storage/ShowVaultStorage.sol";

/*

    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@, ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@                         @@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@               .@@@                @@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      (@@@@@@@@@@@@@
    @@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@
    @@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@
    @@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@
    @@@@@@@@@     ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@
    @@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@
    @@@@@@@@     @@@@@@@@@@@@@@@/ @@@@@@@@@@@@@@@@@@@@@ #@@@@@@@@@@@@@@@     @@@@@@@
    @@@@@@@@     @@@@@@@@@@            @@@@@@@@@@@            @@@@@@@@@@     @@@@@@@
    @@@@@@@@     @@@@@@@@        @       @@@@@@@       @        @@@@@@@@     @@@@@@@
    @@@@@@@@     @@@@@@@@     @@@@@@@     @@@@@     @@@@@@@     @@@@@@@@     @@@@@@@
    @@@@@@@@@     @@@@@@@     @@@@@@@     @@@@@     @@@@@@@     @@@@@@@     @@@@@@@@
    @@@@@@@@@     .@@@@@@                @@@@@@@                @@@@@@      @@@@@@@@
    @@@@@@@@@@      @@@@@@@            @@@@@@@@@@@            @@@@@@@      @@@@@@@@@
    @@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@
    @@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@
    @@@@@@@@@@@@@@(      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      &@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@       @@@@@@@@@@@ @@@@@@@@@ @@@@@@@@@@@       @@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@         @@@@@     @@@@@     @@@@@        .@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@     @@@@@     @@@@@     @@@@@     @@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@     @@@@@     @@@@@     @@@@@     @@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@                                 @@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


    @title  SELLOUT VAULT
    @author taayyohh
    @notice Manages and secures all financial transactions for shows, including handling deposits, refunds,
    and payouts related to ticket sales and event organization.
*/

contract ShowVault is Initializable, IShowVault, ShowVaultStorage, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    /// @notice Restricts function calls to the show contract only.
    modifier onlyShowContract() {
        require(msg.sender == showContract, "Unauthorized: caller is not the Show contract");
        _;
    }

    /// @notice Restricts function calls to either the show contract or the box office contract.
    modifier onlyShowOrBoxOfficeContract() {
        require(msg.sender == showContract || msg.sender == boxOfficeContract, "Unauthorized: caller is not the Show or Box contract");
        _;
    }

    /// @notice Restricts function calls to either the ticket or venue contract.
    modifier onlyVenueOrTicketContract(bytes32 showId) {
        require(
            msg.sender == showInstance.getShowToTicketProxy(showId) ||
            msg.sender == showInstance.getShowToVenueProxy(showId),
            "Unauthorized: caller is not the Ticket or Venue contract"
        );
        _;
    }

    /// @notice Initializes the contract with the Show contract and the Sellout Protocol Wallet
    /// @param _showContract The address of the Show contract
    /// @param _selloutProtocolWallet The address of the Sellout Protocol Wallet
    function initialize(address _showContract, address _selloutProtocolWallet) public initializer {
        __Ownable_init(_selloutProtocolWallet);
        __ReentrancyGuard_init();
        showContract = _showContract;
        showInstance = IShow(_showContract);
        THE_STEWARD = _selloutProtocolWallet;
    }

    /// @notice Allows the contract owner to upgrade the contract to a new implementation
    /// @param newImplementation The address of the new contract implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Deposits ether into the vault for a specified show
    /// @param showId The identifier of the show
    function depositToVault(bytes32 showId) external payable onlyVenueOrTicketContract(showId) {
        showVault[showId] += msg.value;
    }

    /// @notice Deposits ERC20 tokens into the vault for a specified show
    /// @param showId The identifier of the show
    /// @param amount The amount of tokens to deposit
    /// @param paymentToken The ERC20 token address
    /// @param tokenRecipient The recipient of the tokens
    function depositToVaultERC20(bytes32 showId, uint256 amount, address paymentToken, address tokenRecipient) external onlyVenueOrTicketContract(showId) {
        require(paymentToken != address(0), "Invalid payment token address");
        require(showPaymentTokens[showId] == paymentToken, "!t");

        ERC20Upgradeable token = ERC20Upgradeable(paymentToken);
        require(token.allowance(tokenRecipient, address(this)) >= amount, "Insufficient allowance");
        token.transferFrom(tokenRecipient, address(this), amount);
        showTokenVault[showId][paymentToken] += amount;
    }

    /// @notice Allows a user to withdraw their refund for a specific show
    /// @param showId The identifier of the show
    /// @param paymentToken The payment token address (address(0) for ETH)
    /// @param payee The address of the payee
    function withdrawRefund(bytes32 showId, address paymentToken, address payee) external onlyShowContract nonReentrant {
        uint256 amount = paymentToken == address(0) ? pendingRefunds[showId][payee] : pendingTokenRefunds[showId][paymentToken][payee];
        require(amount > 0, "No refund available");

        if (paymentToken == address(0)) {
            pendingRefunds[showId][payee] = 0;
            (bool sent, ) = payable(payee).call{value: amount}("");
            require(sent, "Failed to send Ether");
        } else {
            pendingTokenRefunds[showId][paymentToken][payee] = 0;
            ERC20Upgradeable token = ERC20Upgradeable(paymentToken);
            require(token.transfer(payee, amount), "Failed to send ERC20");
        }
    }

    /// @notice Clears the vault for a specific show, resetting stored values to zero
    /// @param showId The identifier of the show
    /// @param paymentToken The payment token address (address(0) for ETH)
    function clearVault(bytes32 showId, address paymentToken) external onlyShowContract {
        if(paymentToken == address(0)) {
            showVault[showId] = 0;
        } else {
            showTokenVault[showId][paymentToken] = 0;
        }
    }

    /// @notice Calculates the total amount available for payout for a show
    /// @param showId The identifier of the show
    /// @param paymentToken The payment token address (address(0) for ETH)
    /// @return The total amount available for payout
    function calculateTotalPayoutAmount(bytes32 showId, address paymentToken) external view returns (uint256) {
        if (paymentToken == address(0)) {
            return showVault[showId];
        } else {
            return showTokenVault[showId][paymentToken];
        }
    }

    /// @notice Processes a refund adjustment in the financial records of a show
    /// @param showId The identifier of the show
    /// @param refundAmount The amount to refund
    /// @param paymentToken The payment token address (address(0) for ETH)
    /// @param recipient The recipient of the refund
    function processRefund(bytes32 showId, uint256 refundAmount, address paymentToken, address recipient) external onlyShowOrBoxOfficeContract() {
        if (paymentToken == address(0)) {
            require(showVault[showId] >= refundAmount, "Insufficient funds");
            showVault[showId] -= refundAmount;
            pendingRefunds[showId][recipient] += refundAmount;
        } else {
            require(showTokenVault[showId][paymentToken] >= refundAmount, "Insufficient token funds");
            showTokenVault[showId][paymentToken] -= refundAmount;
            pendingTokenRefunds[showId][paymentToken][recipient] += refundAmount;
        }
    }

    /// @notice Distributes the total available payout among participants of a show based on predefined splits.
    /// Initially, a "steward" fee (4%) goes to the protocol wallet to support maintenance and growth.
    /// A "garden" fee (1%) goes to the DAO treasury, symbolizing seeding for future decentralization.
    /// Over time, the intention is to shift all fees towards the "garden", fully sustaining the ecosystem.
    /// @param showId The identifier of the show.
    /// @param recipients The addresses of the recipients.
    /// @param splits The percentage splits for each recipient.
    /// @param totalAmount The total payout amount.
    /// @param paymentToken The payment token address (address(0) for ETH).
    function distributeShares(
        bytes32 showId,
        address[] memory recipients,
        uint256[] memory splits,
        uint256 totalAmount,
        address paymentToken
    ) external onlyShowContract {
        uint256 stewardFee = (totalAmount * 4) / 100; // 4% steward fee
        uint256 gardenFee = (totalAmount * 1) / 100; // 1% garden fee
        uint256 remainingAmount = totalAmount - stewardFee - gardenFee;

        // Pay the steward fee to the protocol wallet
        addPayout(showId, THE_STEWARD, stewardFee, paymentToken);

        // Pay the garden fee to the DAO treasury
        addPayout(showId, THE_GARDEN, gardenFee, paymentToken);

        // Distribute the remaining amount among the recipients
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 share = (remainingAmount * splits[i]) / 100;
            addPayout(showId, recipients[i], share, paymentToken);
        }
    }

    /// @dev Adds a payout amount to the ledger, marking it pending for withdrawal
    /// @param showId The identifier of the show
    /// @param recipient The address of the recipient who will receive the payout
    /// @param amount The amount of the payout
    /// @param paymentToken The token address used for the payout (address(0) for ETH)
    function addPayout(bytes32 showId, address recipient, uint256 amount, address paymentToken) private {
        if(paymentToken == address(0)) {
            pendingPayouts[showId][recipient] += amount;
        } else {
            pendingTokenPayouts[showId][paymentToken][recipient] += amount;
        }
    }

    /// @notice Allows the organizer or artist to withdraw funds after a show has been completed
    /// @param showId The identifier of the show
    /// @param paymentToken The payment token address (address(0) for ETH)
    /// @param payee The recipient of the payout
    function payout(bytes32 showId, address paymentToken, address payee) public onlyShowContract {
        if (paymentToken == address(0)) {
            payoutETH(showId, payee);
        } else {
            payoutERC20(showId, paymentToken, payee);
        }
    }

    /// @notice Handles Ethereum payouts
    /// @param showId The identifier of the show
    function payoutETH(bytes32 showId, address payee) private {
        uint256 amount = pendingPayouts[showId][payee];
        require(amount > 0, "!$");
        pendingPayouts[showId][payee] = 0;

        (bool sent, ) = payable(payee).call{value: amount}("");
        require(sent, "!->");
        emit Withdrawal(showId, payee, amount, address(0));
    }

    // @notice Handles ERC20 token payouts
    /// @param showId The identifier of the show
    /// @param paymentToken The ERC20 token used for the payout
    function payoutERC20(bytes32 showId, address paymentToken, address payee) private {
        uint256 amount = pendingTokenPayouts[showId][paymentToken][payee];
        require(amount > 0, "!$");
        pendingTokenPayouts[showId][paymentToken][payee] = 0;

        ERC20Upgradeable token = ERC20Upgradeable(paymentToken);
        require(token.balanceOf(address(this)) >= amount, "!$");
        require(token.transfer(payee, amount), "!->");
        emit Withdrawal(showId, payee, amount, paymentToken);
    }

    /// @notice Gets the payment token for a specific show
    /// @param showId The unique identifier of the show
    /// @return The payment token address
    function getShowPaymentToken(bytes32 showId) public view returns (address) {
        return showPaymentTokens[showId];
    }

    /// @notice Sets the payment token for a specific show
    /// @param showId The unique identifier of the show
    /// @param token The payment token address
    function setShowPaymentToken(bytes32 showId, address token) external onlyShowContract {
        showPaymentTokens[showId] = token;
    }

    /// @notice Sets the Box Office contract address.
    /// @param _boxOfficeContract The address of the Box Office contract.
    function setContractAddresses(address _boxOfficeContract) external {
        require(address(boxOfficeContract) == address(0), "Box Office Contract already set");

        boxOfficeContract = _boxOfficeContract;
    }

    /// @notice Updates the address of the DAO treasury (the Garden)
    /// @dev This function can only be called by the protocol owner. It updates the address that holds DAO funds.
    /// @param _theGarden The new address for the DAO treasury
    function setDAOTreasuryAddress(address _theGarden) external onlyOwner {
        require(_theGarden != address(0), "Invalid address: cannot be zero address");
        THE_GARDEN = _theGarden;
        emit DAOTreasuryAddressUpdated(_theGarden);
    }
}
