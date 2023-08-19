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

    event StatusUpdated(bytes32 showId, Status status);


    event ShowProposed(
        bytes32 indexed showId,
        address indexed organizer,
        string name,
        address[] artists,
        string description,
        TicketPrice ticketPrice,
        uint256 sellOutThreshold,
        uint256[] split
    );

    event ShowDeactivated(
        bytes32 indexed showId,
        address indexed sender
    );

    event ExpiryUpdated(bytes32 indexed showId, uint256 newExpiry);
    event ShowExpired(bytes32 indexed showId);





    function isOrganizer(address user, bytes32 showId) external view returns (bool);
    function isArtist(address user, bytes32 showId) external view returns (bool);

    function proposeShow(
        string calldata name,
        string calldata description,
        address[] calldata artists,
        ShowTypes.Venue memory venue,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        ShowTypes.TicketPrice memory ticketPrice,
        uint256[] memory split
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
    function checkAndUpdateExpiry(bytes32 showId) external;

}
