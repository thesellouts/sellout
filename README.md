


SellOut Protocol

+------------------+     
|                  |     
|   Deployment     |     
|   & Setup        |     
|                  |     
+--------|---------+     
         |              
         |              
         v             
+------------------+     +------------------+     
|                  |     |                  |     
|  SellOutFactory  |---->|      Show       |
| (Deploy & Link)  |     | (Interacts with |     
+------------------+     |  ShowStorage)   |     
                         +--------|--------+     
                                  |             
                                  |             
                                  v             
                        +------------------+     +------------------+    
                        |                  |     |                  |    
                        |   ShowStorage    |     |  ReferralModule  |    
                        |                  |     |                  |    
                        +------------------+     +------------------+    
                                                                      
+------------------+     +------------------+     +------------------+
|                  |     |                  |     |                  |
|  ArtistRegistry  |     | OrganizerRegistry|     |   VenueRegistry  |
|                  |     |                  |     |                  |
+------------------+     +------------------+     +------------------+

+------------------+     +------------------+     
|                  |     |                  |     
|      Ticket      |     |      Venue       |     
|                  |     |                  |     
+--------|---------+     +--------|---------+     
         |                    |              
         |                    |              
         |                    |              
         |                    |              
         |                    |              
         |                    |              
         |                    |              
         |                    |              
         +--------------------+--------------------+
                                  |              
                                  |              
                                  |              
                                  v              
                        +--------------------------+
                        |                          |
                        |   proposeShow()          |
                        +--------------------------+
                        |                          |
                        |----updateStatus()-------->
                        |       (to "Proposed")    |
                        |                          |
           +------------|    checkAndUpdateExpiry()|
           |            |                          |<- - - - - - - - - - - - +
           |            |                          |                        |
           |            |<---updateStatus()--------+                        |
           |            |       (if threshold met, to "SoldOut")           |
           |            |                          |                        |
           |            |                          |                        |
           |            |                          |                        |
           |            |                          |                        |
+-------------------+   |                          |                        |
|      Ticket       |   |                          |                        |
+-------------------+   |                          |                        |
|  purchaseTickets()|---+                          |                        |
|  (update to       |   |                          |                        |
|  SoldOut if       |   |                          |                        |
|  threshold met)   |   |                          |                        |
+-------------------+   |                          |                        |
                        |                          |                        |
                        |                          |                        |
                        |<---updateStatus()--------+                        |
                        |       (to "Accepted")    |                        |
                        |                          |                        |
                        |                          |                        |
+-------------------+   |                          |                        |
|      Venue        |   |                          |                        |
| (and IVenue       |   |                          |                        |
|  Interface)       |   |                          |                        |
+-------------------+   |                          |                        |
|  submitProposal() |---+                          |                        |
+-------------------+   |                          |                        |
| ticketHolderVenue |---+                          |                        |
|  Vote()           |   |                          |                        |
+-------------------+   |                          |                        |
|  vote()           |---+                          |                        |
+-------------------+   |                          |                        |
|  voteForDate()    |---+                          |                        |
+-------------------+   |                          |                        |
                        |                          |                        |
                        |                          |                        |
                        |<---completeShow()--------+                        |
                        |                          |                        |
                        |                          |                        |
                        |                          |                        |
                        |                          |                        |
                        |                          |                        |
           +------------|    refundTicket()        |                        |
           |            |                          |                        |
           |            +--------------------------+                        |
           |                                                                  |
           |            +--------------------------+                        |
           +------------|    withdrawRefund()      |                        |
                        +--------------------------+                        

Interacting with the Registry:

1. Artist Onboarding:
   + ArtistRegistry
     - registerArtist(): Artists register themselves, providing name, bio, and other details.

2. Organizer Onboarding:
   + OrganizerRegistry
     - registerOrganizer(): Organizers register themselves, providing name, bio, and other details.

3. Venue Onboarding:
   + VenueRegistry
     - registerVenue(): Venues register themselves, providing name, location, capacity, and other details.

Note:
   - Referral credits can be earned or spent in the registration process, hence the interaction with ReferralModule.
   - ReferralModule also provides functionality for incentivizing the ecosystem growth through referrals.

Lifecycle Notes:
   - All interactions with the registry are typically done at the onset, as part of setting up profiles for artists, organizers, and venues.
   - These registrations are important as they directly impact the proposing, voting, and execution of shows.
