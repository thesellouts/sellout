// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ITicketFactory Interface
/// @notice Interface for the TicketFactory contract.
interface ITicketFactory {
    /// @notice Sets the address of the BoxOffice contract that will interact with this TicketFactory.
    /// @param boxOfficeAddress The address of the BoxOffice contract.
    function setContractAddresses(address boxOfficeAddress) external;

    /**
     * @notice Creates a new ticket proxy instance for a specific owner and returns its address.
     * @param initialOwner The address that will own the newly created ticket proxy.
     * @return The address of the newly created ticket proxy.
     */
    function createTicketProxy(address initialOwner) external returns (address);

    /**
     * @notice Sets a new version for the ticket factory.
     * @param _version New version to set.
     */
    function setVersion(string memory _version) external;

    /**
     * @notice Returns the list of deployed ticket proxies.
     * @return An array of addresses of the deployed ticket proxies.
     */
    function getDeployedTickets() external view returns (address[] memory);

    /**
     * @notice Updates the ticket implementation contract address.
     * @param newImplementation New ticket implementation address to set.
     */
    function updateTicketImplementation(address newImplementation) external;
}
