// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Clones } from "@openzeppelin-contracts/proxy/Clones.sol";
import "./ITicket.sol";

/// @title TicketFactory
/// @dev Implements a factory for creating upgradeable ticket proxies.
contract TicketFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    /// @notice Address of the ticket implementation contract.
    address public ticketImplementation;

    /// @notice Array of addresses for all deployed ticket proxies.
    address[] public deployedTickets;

    /// @notice Version of the ticket factory.
    string public version;

    // Address of the Show contract
    address public showAddress;

    /// @notice Emitted when a new ticket proxy is created.
    event TicketProxyCreated(address indexed ticketProxy);

    /// @notice Initializes the ticket factory with a ticket implementation address and a version.
    /// @param _ticketImplementation Address of the ticket implementation.
    /// @param _version Version of the ticket factory.
    /// @param _showAddress Address of show contract
    function initialize(address _ticketImplementation, string memory _version, address _showAddress) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        ticketImplementation = _ticketImplementation;
        version = _version;
        showAddress = _showAddress;
    }

    /// @dev Authorizes contract upgrades to the owner only.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier onlyShowContract() {
        require(msg.sender == showAddress, "Caller is not the Show contract");
        _;
    }

    /// @notice Creates a new ticket proxy for a given owner and adds it to the deployed tickets list.
    /// @param initialOwner Address of the initial owner of the ticket proxy.
    /// @return The address of the newly created ticket proxy.
    function createTicketProxy(address initialOwner) public onlyShowContract returns (address) {
        address clone = Clones.clone(ticketImplementation);
        ITicket(clone).initialize(initialOwner, version);
        deployedTickets.push(clone);
        emit TicketProxyCreated(clone);
        return clone;
    }


    /// @notice Sets a new version for the ticket factory.
    /// @param _version New version to set.
    function setVersion(string memory _version) public onlyOwner {
        version = _version;
    }

    /// @notice Returns the list of deployed ticket proxies.
    /// @return An array of addresses of the deployed ticket proxies.
    function getDeployedTickets() public view returns (address[] memory) {
        return deployedTickets;
    }

    /// @notice Updates the ticket implementation contract address.
    /// @param newImplementation New ticket implementation address to set.
    function updateTicketImplementation(address newImplementation) public onlyOwner {
        ticketImplementation = newImplementation;
    }
}
