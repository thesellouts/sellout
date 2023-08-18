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
    modifier onlyOrganizerOrArtist(uint256 showId) {
        require(isOrganizer(msg.sender, showId) || isArtist(msg.sender, showId), "Not authorized");
        _;
    }

    function isOrganizer(address user, uint256 showId) public view returns (bool) {
        return shows[showId].organizer == user;
    }

    function isArtist(address user, uint256 showId) public view returns (bool) {
        for (uint i = 0; i < shows[showId].artists.length; i++) {
            if (shows[showId].artists[i] == user) {
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
        uint256 sellOutThreshold, // Percentage (0-100)
        uint256 totalCapacity, // Total capacity of the show
        TicketPrice memory ticketPrice
    ) public returns (uint256) {
        require(totalCapacity > 0, "Total capacity must be greater than 0");
        require(artists.length > 0, "At least one artist required");
        require(ticketPrice.maxPrice >= ticketPrice.minPrice, "Max ticket price must be greater or equal to min ticket price");
        require(sellOutThreshold >= 0 && sellOutThreshold <= 100, "Sell-out threshold must be between 0 and 100");

        shows[showCount] = Show({
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


        emit ShowProposed(showCount, msg.sender, name, artists, description, venue, ticketPrice, sellOutThreshold);

        return showCount++;
    }

    function deactivateShow(uint256 showId) internal onlyOrganizerOrArtist(showId) {
        shows[showId].isActive = false;
        emit ShowDeactivated(showId, msg.sender);
    }

    function cancelShow(uint256 showId) public onlyOrganizerOrArtist(showId) {
        Show storage show = shows[showId];
        require(show.status == Status.SoldOut, "Show must be SoldOut");

        show.status = Status.Cancelled;
    }

    function completeShow(uint256 showId) public onlyOrganizerOrArtist(showId) {
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

    function getTicketPrice(uint256 _showId) public view returns (TicketPrice memory) {
        return shows[_showId].ticketPrice;
    }

    function getTotalCapacity(uint256 showId) public view returns (uint256) {
        return shows[showId].totalCapacity;
    }

    function getSellOutThreshold(uint256 showId) public view returns (uint256) {
        return shows[showId].sellOutThreshold;
    }

    function getShowDetails(uint256 showId) public view returns (
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
        Show storage show = shows[showId];
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

    function getShowStatus(uint256 showId) public view returns (Status) {
        return shows[showId].status;
    }

    function updateStatus(uint256 showId, Status _status) public onlyOrganizerOrArtist(showId) {
        require(shows[showId].status == Status.Proposed, "Show must be in Proposed status");
        shows[showId].status = _status;
        emit StatusUpdated(showId, _status);
    }
}
