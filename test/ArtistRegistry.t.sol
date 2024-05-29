// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { ReferralModule } from "../src/registry/referral/ReferralModule.sol";
import { ArtistRegistry } from "../src/registry/artist/ArtistRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ArtistRegistryTest is Test {
    ReferralModule referralModule;
    ArtistRegistry artistRegistry;
    address SELLOUT_PROTOCOL_WALLET = address(1);
    address NOMINEE = address(2);

    function setUp() external {
        // Deploy ReferralModule through a proxy
        bytes memory initDataReferral = abi.encodeWithSelector(ReferralModule.initialize.selector, SELLOUT_PROTOCOL_WALLET);
        ERC1967Proxy proxyReferral = new ERC1967Proxy(address(new ReferralModule()), initDataReferral);
        referralModule = ReferralModule(address(proxyReferral));

        // Deploy ArtistRegistry through a proxy
        bytes memory initDataArtistRegistry = abi.encodeWithSelector(ArtistRegistry.initialize.selector, SELLOUT_PROTOCOL_WALLET, address(referralModule));
        ERC1967Proxy proxyArtistRegistry = new ERC1967Proxy(address(new ArtistRegistry()), initDataArtistRegistry);
        artistRegistry = ArtistRegistry(address(proxyArtistRegistry));

        // Set permission for the ArtistRegistry to decrement referral credits
        vm.prank(SELLOUT_PROTOCOL_WALLET);
        referralModule.setCreditControlPermission(address(proxyArtistRegistry), true);

        // Adding some referral credits for testing
        vm.prank(address(proxyArtistRegistry));
        referralModule.incrementReferralCredits(address(this), 10, 10, 10);
    }

    function testArtistNominationAndAcceptance() public {
        // Assume this contract has referral credits to nominate artists
        artistRegistry.nominate(NOMINEE);

        // Accept the nomination from the nominated artist's perspective
        vm.prank(NOMINEE);
        artistRegistry.acceptNomination("Sellout Artist", "The Greatest Artist");

        // Verify the artist's registration
        (,, address wallet) = artistRegistry.getArtist(NOMINEE);
        assertEq(wallet, NOMINEE, "The artist's wallet address should match the nominated address.");
    }

    function testArtistUpdate() public {
        // Setup: Nominate and accept an artist to update
        testArtistNominationAndAcceptance();

        // New name and biography for the artist
        string memory newName = "Updated Artist Name";
        string memory newBio = "Updated Artist Bio";
        address newAddr = address(3);

        // Update the artist's information
        vm.prank(NOMINEE);
        artistRegistry.updateArtist(1, newName, newBio, newAddr);

        // Verify the update was successful
        (string memory name, string memory bio, address addr) = artistRegistry.getArtist(NOMINEE);
        assertEq(name, newName, "Artist name was not updated correctly.");
        assertEq(bio, newBio, "Artist bio was not updated correctly.");
        assertEq(addr, newAddr, "Artist address was not updated correctly.");
    }

    function testArtistDeregistration() public {
        // Setup: Nominate and accept an artist to deregister
        testArtistNominationAndAcceptance();

        // Deregister the artist
        vm.prank(NOMINEE);
        artistRegistry.deregisterArtist(1);

        // Attempt to fetch deregistered artist info, check for default or empty values
        (string memory name, string memory bio, address wallet) = artistRegistry.getArtist(NOMINEE);
        assertEq(wallet, address(0), "Artist wallet should be default address.");
        assertEq(name, "", "Artist name should be empty.");
        assertEq(bio, "", "Artist bio should be empty.");
    }
}
