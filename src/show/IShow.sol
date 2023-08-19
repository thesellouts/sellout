// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./types/ShowTypes.sol";


/// @title IShow
/// @author taayyohh
/// @notice The external Show events, errors and functions
interface IShow is ShowTypes {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///
    event ShowProposed(
        bytes32 showId,
        address indexed organizer,
        string name,
        address[] artists,
        string description,
        TicketPrice ticketPrice,
        uint256 sellOutThreshold
    );

    event ShowDeactivated(bytes32 showId, address indexed executor);

    event StatusUpdated(bytes32 showId, Status status);

    function isOrganizer(address user, bytes32 showId) external view returns (bool);
    function isArtist(address user, bytes32 showId) external view returns (bool);

    function proposeShow(
        string calldata name,
        string calldata description,
        address[] calldata artists,
        ShowTypes.Venue memory venue,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        ShowTypes.TicketPrice memory ticketPrice
    ) external returns (bytes32);

//    function deactivateShow(bytes32 showId) internal;
    function cancelShow(bytes32 showId) external;
    function completeShow(bytes32 showId) external;

    function getTicketPrice(bytes32 showId) external view returns (ShowTypes.TicketPrice memory);
    function getTotalCapacity(bytes32 showId) external view returns (uint256);
    function getSellOutThreshold(bytes32 showId) external view returns (uint256);

    function getShowDetails(bytes32 showId) external view returns (
        string memory name,
        string memory description,
        address organizer,
        address[] memory artists,
        ShowTypes.Venue memory venue,
        ShowTypes.TicketPrice memory ticketPrice,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        ShowTypes.Status status,
        bool isActive
    );

    function getShowStatus(bytes32 showId) external view returns (ShowTypes.Status);
    function updateStatus(bytes32 showId, ShowTypes.Status status) external;

}
