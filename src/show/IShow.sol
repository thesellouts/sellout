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
        uint256 indexed showId,
        address indexed organizer,
        string name,
        address[] artists,
        string description,
        Venue venue,
        TicketPrice ticketPrice,
        uint256 sellOutThreshold
    );

    event ShowDeactivated(uint256 indexed showId, address indexed executor);

    event StatusUpdated(uint256 indexed showId, Status status);


    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///


    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    function isOrganizer(address user, uint256 showId) external view returns (bool);
    function isArtist(address user, uint256 showId) external view returns (bool);

    function proposeShow(
        string calldata name,
        string calldata description,
        address[] calldata artists,
        ShowTypes.Venue memory venue,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        ShowTypes.TicketPrice memory ticketPrice
    ) external returns (uint256);

//    function deactivateShow(uint256 showId) internal;
    function cancelShow(uint256 showId) external;
    function completeShow(uint256 showId) external;

    function getTicketPrice(uint256 showId) external view returns (ShowTypes.TicketPrice memory);
    function getTotalCapacity(uint256 showId) external view returns (uint256);
    function getSellOutThreshold(uint256 showId) external view returns (uint256);

    function getShowDetails(uint256 showId) external view returns (
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

    function getShowStatus(uint256 showId) external view returns (ShowTypes.Status);
    function updateStatus(uint256 showId, ShowTypes.Status status) external;

}
