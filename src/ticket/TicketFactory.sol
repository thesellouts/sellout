// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Clones } from "@openzeppelin-contracts/proxy/Clones.sol";
import { ITicket } from "./ITicket.sol";

/// @title TicketFactory
/// @dev Implements a factory for creating upgradeable ticket proxies.
contract TicketFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    /// @notice Address of the ticket implementation contract.
    address public ticketImplementation;

    /// @notice Array of addresses for all deployed ticket proxies.
    address[] public deployedTickets;

    /// @notice Version of the ticket factory.
    string public version;

    // Address of the BoxOffice contract
    address public boxOfficeAddress;

    /// @notice Emitted when a new ticket proxy is created.
    event TicketProxyCreated(address indexed ticketProxy);

    /// @notice Initializes the ticket factory with a ticket implementation address and a version.
    /// @param _ticketImplementation Address of the ticket implementation.
    /// @param _version Version of the ticket factory.
    function initialize(address _ticketImplementation, string memory _version) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        ticketImplementation = _ticketImplementation;
        version = _version;
    }

    /// @dev Authorizes contract upgrades to the owner only.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Restricts function calls to the BoxOffice contract only.
    modifier onlyBoxOffice() {
        require(msg.sender == boxOfficeAddress, "Caller is not the BoxOffice contract");
        _;
    }

    /// @notice Creates a new ticket proxy for a given owner and adds it to the deployed tickets list.
    /// @param initialOwner Address of the initial owner of the ticket proxy.
    /// @return The address of the newly created ticket proxy.
    function createTicketProxy(address initialOwner) public onlyBoxOffice returns (address) {
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
    function updateTicketImplementation(address newImplementation) external onlyOwner {
        ticketImplementation = newImplementation;
    }

    /// @notice Sets the BoxOffice address, can only be called once by the owner.
    /// @param _boxOfficeAddress The address of the BoxOffice contract.
    function setContractAddresses(address _boxOfficeAddress) external {
        require(boxOfficeAddress == address(0), "BoxOffice address already set");
        boxOfficeAddress = _boxOfficeAddress;
    }
}
