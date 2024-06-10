//// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
//
//import "forge-std/Test.sol";
//import "../src/show/ShowVault.sol";
//import "../src/show/Show.sol";
//
//contract ShowVaultTest is Test {
//    ShowVault public showVault;
//    Show public show;
//    address user = address(0x123);
//    address paymentToken = address(0); // For ETH
//    bytes32 showId = keccak256(abi.encodePacked("exampleShow"));
//    address boxOfficeContract = address(0x456); // Mock Box Office contract address
//    address protocolWallet = address(this); // Mock protocol wallet
//
//    function setUp() public {
//        // Deploy Show contract
//        show = new Show();
//        // Deploy ShowVault contract
//        showVault = new ShowVault();
//
//        // Initialize ShowVault with Show contract address and a protocol wallet
//        showVault.initialize(address(show), protocolWallet);
//
//        // Set the Box Office contract address
//        showVault.setContractAddresses(boxOfficeContract);
//
//        // Initialize the Show contract
//        show.initialize(protocolWallet);
//
//        // Set the ShowVault in the Show contract
//        show.setProtocolAddresses(
//            address(0), // ticketFactory
//            address(0), // venueFactory
//            address(0), // referralContract
//            address(0), // artistRegistry
//            address(0), // organizerRegistry
//            address(0), // venueRegistry
//            address(showVault), // showVault
//            boxOfficeContract // boxOffice
//        );
//
//        // Fund the user with some ETH
//        vm.deal(user, 1 ether); // Fund the user with some ETH
//
//        // Mock deposit to the ShowVault from an EOA
//        vm.prank(user);
//        (bool sent, ) = address(showVault).call{value: 0.01 ether}("");
//        require(sent, "Failed to send Ether");
//
//        // Ensure ShowVault has sufficient funds
//        uint256 vaultBalance = address(showVault).balance;
//        require(vaultBalance >= 0.01 ether, "Vault has insufficient funds");
//
//        // Call processRefund from an authorized contract
//        vm.prank(address(show));
//        showVault.processRefund(showId, 0.005 ether, paymentToken, user);
//    }
//
//    function testWithdrawRefund() public {
//        // User calls withdrawRefund on the Show contract
//        vm.prank(user); // Mock the user as the caller
//        show.withdrawRefund(showId);
//
//        // Check that the refund was processed correctly
//        uint256 refundAmount = showVault.pendingRefunds(showId, user);
//        assertEq(refundAmount, 0); // Ensure the refund amount is zero after withdrawal
//        // Check the user's balance to ensure they received the refund
//        uint256 userBalance = user.balance;
//        assertEq(userBalance, 1.005 ether);
//    }
//}
