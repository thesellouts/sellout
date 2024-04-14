// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { BoxOffice } from "../src/show/BoxOffice.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployBoxOffice is Script {
    function run() external {
        vm.startBroadcast();

        // Fetch necessary addresses from environment variables
        address selloutProtocolWallet = vm.envAddress("SELLOUT_PROTOCOL_WALLET");
        address showContract = vm.envAddress("SHOW_ADDRESS");
        address ticketFactory = vm.envAddress("TICKET_FACTORY_ADDRESS");
        address showVault = vm.envAddress("SHOW_VAULT_ADDRESS");

        // Deploy the BoxOffice implementation
        BoxOffice boxOfficeImpl = new BoxOffice();
        console.log("BoxOffice implementation deployed at", address(boxOfficeImpl));

        // Prepare the initializer function call for BoxOffice
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,address,address)",
            selloutProtocolWallet,
            showContract,
            ticketFactory,
            showVault
        );

        // Deploy the ERC1967 Proxy for BoxOffice
        ERC1967Proxy proxy = new ERC1967Proxy(address(boxOfficeImpl), initData);
        console.log("BoxOffice deployed at", address(proxy));

        vm.stopBroadcast();
    }
}
