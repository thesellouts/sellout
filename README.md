## Overview 
The Sellout Protocol is a decentralized platform designed to streamline the creation, ticketing, and management of shows, leveraging blockchain technology to ensure transparency, security, and efficiency. This document outlines the protocol's architecture, contract interactions, and the lifecycle of a show from proposal to payout.

### Contract Architecture
The Sellout Protocol comprises several smart contracts that interact with each other to facilitate the creation and management of shows:

- **ReferralModule**: Manages referral credits and permissions for artists, organizers, and venues.
- **ArtistRegistry**: Registers artists and manages their information.
- **OrganizerRegistry**: Registers organizers and manages their information.
- **VenueRegistry**: Registers venues and manages their information.
- **Show**: Manages individual shows, including proposals, ticketing, and payouts.
- **Ticket**: Handles ticket issuance, transfers, and redemptions for shows.
- **Venue**: Manages venue-specific information and booking for shows.


### Contract Overview
```
+----------------+     +-------------------+     +------------------+
|                |     |                   |     |                  |
| ReferralModule |<----+ ArtistRegistry   |<----+                  |
|                |     |                   |     |                  |
+--------^-------+     +-------------------+     |                  |
         |                                       |                  |
         |                                       |    Show          |
+--------+-------+     +-------------------+     |                  |
|                |     |                   |     |                  |
| VenueRegistry  |<----+ OrganizerRegistry |<----+                  |
|                |     |                   |     +------------------+
+----------------+     +-------------------+                |
                                                          +--v---------+
                                                          |            |
                                                          |  Ticket    |
                                                          |            |
                                                          +--^---------+
                                                             |
                       +-------------------+                 |
                       |                   |<----------------+
                       |     Venue         |
                       |                   |
                       +-------------------+

```

## Sellout Protocol: Show Lifecycle and Financial Dynamics
The Sellout Protocol reimagines the live event booking and management process, prioritizing transparency, artist and organizer empowerment, and dynamic audience engagement. This section outlines the granular steps involved in the lifecycle of a show, with a special focus on financial arrangements and automated payouts.

### 1. Show Proposal
   An organizer proposes a show by calling the proposeShow function in the Show contract. Key details include:

- **Artists:** Line-up for the show.
- **Ticket Price Structure:** Minimum and maximum ticket prices.
- **Payout Splits:** Predetermined splits for the organizer, artists, and venue.
- **Sellout Threshold:** A defined percentage of total capacity, triggering venue bidding.

```
function proposeShow(
    string memory name,
    string memory description,
    address[] memory artists,
    VenueTypes.Coordinates memory coordinates,
    uint256 radius,
    uint8 sellOutThreshold,
    uint256 totalCapacity,
    ShowTypes.TicketPrice memory ticketPrice,
    uint256[] memory split
) external returns (bytes32 showId);
```

### 2. Ticket Sales and Refunds
Tickets are sold through the Ticket contract. Until the sellout threshold is reached, ticket holders can refund their tickets, ensuring a dynamic engagement with the show's demand.

### 3. Reaching the Sellout Threshold
Once ticket sales hit the sellout threshold:

- The show's demand has been proven, increasing its market value.
- Venues start bidding or offering bribes to host the show, leveraging the Venue contract.

### 4. Financial Arrangements and Venue Selection
The organizer, in collaboration with artists, selects the venue offering the best deal, based on:

- **Financial Offers:** Higher payouts or bribes from venues.
- **Facilities and Perks:** Quality of venue services and additional benefits.

### 5. Automated Payouts Post-Show
After the show, the Show contract automatically distributes funds according to the pre-set splits:

```
// Example of payout function that would be called after the show 
function completeShow(bytes32 showId) external;
```
- **Protocol Fee:** A small percentage is allocated to the Sellout Protocol as a platform fee.
- **Payouts:** The remaining funds are split between the organizer, artists, and venue as previously agreed.
### Benefits of the Sellout Protocol
- **Empowerment:** Artists and organizers have more control and bargaining power.
- **Transparency:** Financial arrangements are transparent and enforced through smart contracts.
- **Flexibility:** Ticket refund options up until the sellout threshold maintain audience engagement.
- **Automation:** Payouts are automatically executed, reducing manual processing and errors.
