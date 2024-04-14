// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { ShowVault } from "../src/show/ShowVault.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployShowVault is Script {
    function run(address _showContract, address _selloutProtocolWallet) external {
        vm.startBroadcast();

        // Deploy the ShowVault implementation
        ShowVault showVaultImpl = new ShowVault();
        console.log("ShowVault implementation deployed at", address(showVaultImpl));

        // Prepare the initializer function call for ShowVault
        bytes memory initData = abi.encodeWithSignature("initialize(address,address)", _showContract, _selloutProtocolWallet);

        // Deploy the ERC1967 Proxy for ShowVault
        ERC1967Proxy proxy = new ERC1967Proxy(address(showVaultImpl), initData);
        console.log("ShowVault deployed at", address(proxy));

        vm.stopBroadcast();
    }
}
