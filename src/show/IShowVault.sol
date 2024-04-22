// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IShowVault {
    /// @notice Emitted upon a successful Ether withdrawal from the show's funds.
    /// @param showId The unique identifier of the show.
    /// @param recipient The address of the recipient who received the funds.
    /// @param amount The amount of funds withdrawn.
    event Withdrawal(bytes32 indexed showId, address indexed recipient, uint256 amount, address paymentToken);

    /// @notice Deposits Ether into the vault for a specific show.
    /// @param showId Unique identifier of the show to receive the deposit.
    function depositToVault(bytes32 showId) external payable;

    /// @notice Deposits specified ERC20 tokens into the vault for a specific show.
    /// @param showId Unique identifier of the show to receive the deposit.
    /// @param amount Amount of ERC20 tokens to deposit.
    /// @param paymentToken Contract address of the ERC20 token.
    /// @param tokenRecipient Address which provides the tokens.
    function depositToVaultERC20(bytes32 showId, uint256 amount, address paymentToken, address tokenRecipient) external;

    /// @notice Allows a user to withdraw their refund for a show, in either Ether or an ERC20 token.
    /// @param showId Unique identifier of the show from which the refund will be withdrawn.
    /// @param paymentToken Contract address of the ERC20 token, or address(0) for Ether.
    function withdrawRefund(bytes32 showId, address paymentToken) external;

    /// @notice Clears all stored value in the vault for a specific show.
    /// @param showId Unique identifier of the show for which to clear the vault.
    /// @param paymentToken Contract address of the ERC20 token, or address(0) for Ether.
    function clearVault(bytes32 showId, address paymentToken) external;

    /// @notice Calculates the total payout amount available for a show, distinguishing between ETH and ERC20 payments.
    /// @param showId Unique identifier of the show.
    /// @param paymentToken Contract address of the ERC20 token, or address(0) for Ether.
    /// @return The total amount available for payout.
    function calculateTotalPayoutAmount(bytes32 showId, address paymentToken) external view returns (uint256);

    /// @notice Processes a refund adjustment in the financial state of the show vault.
    /// @param showId Unique identifier of the show.
    /// @param refundAmount Amount to be refunded.
    /// @param paymentToken Contract address of the ERC20 token, or address(0) for Ether.
    /// @param recipient Address of the recipient receiving the refund.
    function processRefund(bytes32 showId, uint256 refundAmount, address paymentToken, address recipient) external;

    /// @notice Distributes shares of the show's total amount among specified recipients.
    /// @param showId Unique identifier of the show.
    /// @param recipients Array of addresses representing the recipients of the funds.
    /// @param splits Array of percentages detailing how the total amount is to be split among recipients.
    /// @param totalAmount Total amount to be distributed.
    /// @param paymentToken Contract address of the ERC20 token, or address(0) for Ether.
    function distributeShares(bytes32 showId, address[] calldata recipients, uint256[] calldata splits, uint256 totalAmount, address paymentToken) external;

    /// @notice Allows the organizer or artist to withdraw funds after a show has been completed.
    /// @param showId Unique identifier of the show.
    /// @param paymentToken Contract address of the ERC20 token, or address(0) for Ether.
    /// @param payee Recipient wallet address
    function payout(bytes32 showId, address paymentToken, address payee) external;

    /// @notice Sets the payment token for a specific show
    /// @param showId The unique identifier of the show
    /// @param token The payment token address
    function setShowPaymentToken(bytes32 showId, address token) external;

    /// @notice Gets the payment token for a specific show
    /// @param showId The unique identifier of the show
    /// @return The payment token address
    function getShowPaymentToken(bytes32 showId) external view returns (address);

    // @dev Sets the addresses for the Show contract and the Venue Registry.
    // @param boxOfficeAddress The address of the BoxOffice contract.
    function setContractAddresses(address boxOfficeAddress) external;
}
