// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IShow.sol";
import "./storage/ShowStorage.sol";
//import "./types/ShowTypes.sol"; // Add this import statement


contract Show is IShow, ShowStorage {

    ///                                                          ///
    ///                          MODIFIERS                       ///
    ///                                                          ///
    /// @notice Reverts if caller is not an authorized minter
    modifier onlyOrganizerOrArtist(bytes32 showId) {
        require(isOrganizer(msg.sender, showId) || isArtist(msg.sender, showId), "Not authorized");
        _;
    }

    function isOrganizer(address user, bytes32 showId) public view returns (bool) {
        return shows[showId].organizer == user; // Updated
    }

    function isArtist(address user, bytes32 showId) public view returns (bool) {
        for (uint i = 0; i < shows[showId].artists.length; i++) { // Updated
            if (shows[showId].artists[i] == user) { // Updated
                return true;
            }
        }
        return false;
    }


    ///                                                          ///
    ///                        PROPOSE SHOW                      ///
    ///                                                          ///
    /// @notice Creates a show proposal between one or more artists
    function proposeShow(
        string memory name,
        string memory description,
        address[] memory artists,
        Venue memory venue,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        TicketPrice memory ticketPrice
    ) public returns (bytes32 showId) {
        require(totalCapacity > 0, "Total capacity must be greater than 0");
        require(artists.length > 0, "At least one artist required");
        require(ticketPrice.maxPrice >= ticketPrice.minPrice, "Max ticket price must be greater or equal to min ticket price");
        require(sellOutThreshold >= 0 && sellOutThreshold <= 100, "Sell-out threshold must be between 0 and 100");

        // Create a proposal ID by hashing the relevant parameters
        showId = keccak256(abi.encodePacked(msg.sender, name, description, artists, sellOutThreshold, totalCapacity));

        shows[showId] = Show({
            showId : showId,
            name: name,
            description: description,
            artists: artists,
            organizer: msg.sender,
            venue: venue,
            ticketPrice: ticketPrice,
            sellOutThreshold: sellOutThreshold,
            totalCapacity: totalCapacity,
            status: Status.Proposed,
            isActive: true
        });

        emit ShowProposed(showId, msg.sender, name, artists, description, ticketPrice, sellOutThreshold);

        return showId;
    }

    function deactivateShow(bytes32 showId) internal onlyOrganizerOrArtist(showId) {
        shows[showId].isActive = false;
        emit ShowDeactivated(showId, msg.sender);
    }

    function cancelShow(bytes32 showId) public onlyOrganizerOrArtist(showId) {
        Show storage show = shows[showId];
        require(show.status == Status.SoldOut, "Show must be SoldOut");

        show.status = Status.Cancelled;
    }

    function completeShow(bytes32 showId) public onlyOrganizerOrArtist(showId) {
        Show storage show = shows[showId];
        require(show.status == Status.Accepted, "Show must be Accepted");

        uint256 totalAmount = address(this).balance;

        // Distribute among artists
//        for (uint256 i = 0; i < show.artists.length; i++) {
//            payable(show.artists[i].addr).transfer(totalAmount * show.artists[i].share / 100);
//        }
//
//        // Transfer to the organizer
//        payable(show.organizer).transfer(totalAmount * show.organizerShare / 100);
//
//        // Transfer to the protocol wallet
        payable(SELLOUT_PROTOCOL_WALLET).transfer(totalAmount / 100);

        // Update the status
        show.status = Status.Completed;
    }

    function getTicketPrice(bytes32 showId) public view returns (TicketPrice memory) {
        return shows[showId].ticketPrice;
    }

    function getTotalCapacity(bytes32 showId) public view returns (uint256) {
        return shows[showId].totalCapacity; // Updated
    }

    function getSellOutThreshold(bytes32 showId) public view returns (uint256) {
        return shows[showId].sellOutThreshold; // Updated
    }

    function getShowDetails(bytes32 showId) public view returns (
        string memory name,
        string memory description,
        address organizer,
        address[] memory artists,
        Venue memory venue,
        TicketPrice memory ticketPrice,
        uint256 sellOutThreshold,
        uint256 totalCapacity,
        Status status,
        bool isActive
    ) {
        Show storage show = shows[showId]; // Updated
        return (
            show.name,
            show.description,
            show.organizer,
            show.artists,
            show.venue,
            show.ticketPrice,
            show.sellOutThreshold,
            show.totalCapacity,
            show.status,
            show.isActive
        );
    }

    function getShowStatus(bytes32 showId) public view returns (Status) {
        return shows[showId].status; // Updated
    }

    function updateStatus(bytes32 showId, Status _status) public onlyOrganizerOrArtist(showId) {
        require(shows[showId].status == Status.Proposed, "Show must be in Proposed status"); // Updated
        shows[showId].status = _status; // Updated
        emit StatusUpdated(showId, _status);
    }
}
