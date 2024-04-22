// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/show/ShowVault.sol";

contract DeployImplementation is Script {
    function run() external {
        vm.startBroadcast();

        ShowVault newShowVault = new ShowVault();
        console.log("NewShowVaultImplementation deployed at", address(newShowVault));

        vm.stopBroadcast();
    }
}
