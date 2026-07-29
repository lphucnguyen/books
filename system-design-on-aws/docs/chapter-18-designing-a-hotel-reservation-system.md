# Chapter 18: Designing a Hotel Reservation System

We love to travel and often use online hotel reservation systems such as Booking.com, agoda, and Airbnb to book our stays in advance. In this chapter, we’ll dive deep into the underlying design of reservation systems for hotel rooms (or any other type of place to stay—we’ll use the term _property_ here). The reservation system should show listed properties in a particular area and allow users to book rooms for a specific period of time. When designing such systems, consider that there are a lot of edge cases the system should adhere to, such as how to handle double payments and the fact that the same room should not be bookable by multiple people for the same time frame. We’ll work on figuring out all such scenarios and finalizing the overall system architecture.

We’ll start the discussion with requirement clarifications and our expectations for the system, close on the design by breaking the overall booking system into multiple subsystems, and then conclude the discussion by identifying AWS services useful for deploying this type of system on the AWS cloud.

## CHAPTER 18 Designing a Hotel Reservation System: System Requirements

The most important requirement is quite simple: allow customers to book a room for their future stays. We’ll start with a few clarifications:

- The system is responsible for onboarding a single hotel chain or any property • onto the system to list the rooms. The system allows properties to onboard and add the rooms with amenities.

- We need to determine who will accept the payments from the users. Does the • system accept the payments on the property owners’ behalf, or will users directly pay at the property? This is an important requirement to consider because if users directly pay to the property owner, the system doesn’t have to take into


account the payment lifecycle. But this can detract from the experience for property owners since the customers can book rooms and never show up. To ensure that both users and owners are happy, the system leaves it to owners to decide the mode of payment and any other policies specific to the property.

- Will the system offer any recommendations for visiting nearby attractions near • the booked property? No—this feature would definitely be a value-add for the users (along with other features, such as a trip planner), but we’ll skip it and keep the scope limited. The system can have external integrations that offer this service.

- The property may have been listed on multiple reservations systems, so we need • to determine how the system ensures that availability is updated if it is booked on another system. This can either be automated in some way in which another system sends the updates to our system or the property owner will need to update the property. It is difficult to integrate given all the different reservation platforms (not to mention that the platforms might not support the integration), so we’ll rely on owners to update the property status. We’ll discuss one edge case of double bookings in this scenario while working on the design.

- We also need to consider dynamic pricing: can the room prices vary based • on booking rate, occasion, or any other factor? The architecture should give independence to the owners to determine a fixed price and manage it on their own or leave the decision to the booking system by providing maximum and minimum room prices. We won’t go deep into ML algorithms, but we’ll discuss a general strategy for supporting dynamic pricing in the system.

We’ll finalize the functional and nonfunctional requirements of the system next based on these clarifications.

### Functional and Nonfunctional Requirements

The system has two types of users: property owners and customers who book these properties for a certain period of time.

The functional requirements the system should support in the context of property owners are:

- Onboard them to the system with personal details, payment settlement details, • and so forth

- List one or more of their properties with details like number and type of rooms, • pricing structure, images of the property, and additional benefits

- Update the details, such as available number of rooms, price, and images •

- View the status of current and past bookings, user reviews, earnings, and the like •


For the users booking a property, the functional requirements are:

- Search for properties in a geographical location for a particular checkin and • checkout date-range selection. There can be additional filters for search, such as the property rating (e.g., four stars, five stars), whether pets are allowed, the cancellation policy, and whether breakfast is included.

- Book a room and pay for the room (if that is the property’s policy—properties • will also have the option to have the user pay at the property with a minimal deposit).

- Update the booking. Possible updates can include selecting new dates, adding • more rooms, updating checkin and checkout timing, making a payment, adding room service, and booking spa treatments.

- View current and past bookings. •

- Cancel the booking. The payment details on this will depend on the property. Are • free cancellations allowed? Or will the user be charged some amount? How are refunds handled?

- Add reviews after the stay. The system restricts the users to add reviews only after • the stay is completed at the booked property.

The following NFRs should be ensured by the system:

- The system should overall have high availability and reliability. •

- There is strong consistency for bookings and payments. A booking state should • be reflected on all reservation systems in the same status.

- The search system should present the list of properties with very low latency. •

- The system is responsible only for property reservations, but it should not be • limited in any way from supporting other types of reservations, such as flights and rental cars. The system should be extensible and should not require major redesign to support these requirements.

- Fault tolerance in the system ensures that double bookings or payments are • primarily avoided and are handled gracefully if they do occur.

System scale is another important factor when making design decisions. We’ll work with the scale numbers approximated in the next section.

### System Scale

Like the functional requirements, the system scale can be divided into two parts: the number of properties listed on the system and the number of users searching for properties and booking them. Note that the numbers used in this section are based on


assumptions, not on any concrete data source. We recommend studying your use case to come up with the initial numbers, and later you can plan for scale.

The assumptions we made for determining scale are as follows:

Number of properties = 10 million worldwide

Average number of properties per location = 500

Average number of rooms per property = 100

Total rooms worldwide = 10 million × 100 = 1 billion

Average stay at a property = 2 days

The scale for searching properties on the platform can be completely different from stays that are actually booked—let’s use these estimates for the design:

Search rate = 20 million/day = 250 requests/second

Active users on platform = 100 million

Actual bookings = 10% of searches = 2 million/day = 25 requests/second

We can also calculate approximate storage requirements, which might add value when selecting the data store for the architecture. The system maintains user information, property information, and bookings information:

Storage space for room details {room ID, type, facilities, minimum rate, maximum rate, dimensions} = 500 bytes

Storage space for property details {property ID, address, number of rooms, facilities} = 500 bytes

Average 50 reviews per property and 500 bytes per review {review content, stars, user ID} = 50 × 500 Bytes = 25 KB

Total storage space per property = 500 bytes + 100 × 500 bytes + 25 KB = 75 KB

Storage space for all properties = 10 million × 75 KB ~ 715 GB

Storage space for property media (images and videos) with an average 10 images per property of 1 KB each = 10 KB × 10 million ~ 100 GB

Property media data storage is relatively less since the rate at which properties are added is much lower than the number of bookings per day. We’ll calculate the booking storage requirements next:


Storage space per one booking {guest details, booking details, total amount} = 1 KB

Total storage space = 1 KB × 2 million = 2 GB/day = 730 GB/year

With all this in mind, let’s start designing the architecture of the reservation system.

## Starting with the Design

The property reservation system is similar to the web crawler and search engine system we discussed in Chapter 15. Property owners listing their properties are like web crawlers gathering data from websites. In both these cases, the system stores this data, which is made available to the users for searching later. Therefore, we know that property data from property owners should be stored in such a way that the search is faster on top of data, and we’ll leverage the inverted index data structure to facilitate the search.

Before we look more into the storage part of our use case, let’s break the system into three high-level parts, shown in Figure 18-1: onboarding of properties, searching for properties, and booking a property.

![](../images/system_design_on_aws_page_0491_0.png)

_Figure 18-1. High-level view of the property reservation system_

### Property Onboarding Architecture

The simplest requirement of the onboarding system is to collect data from the property owners and store it in such a fashion that searching on top of this data is fast. This can be broken down into steps in a workflow-like system with each step taking certain kinds of inputs, as shown in Figure 18-2.


![](../images/system_design_on_aws_page_0492_1.png)

_Figure 18-2. Property onboarding state machine_

We skipped some of the states to keep the state machine small, such as adding property restrictions, price details, images, and the like. The state machine can be implemented with workflow engines like AWS Step Functions.

The choice of database to store the property details is another key decision we need to make. The data definitely has relational properties: properties are listed for a city, a property contains rooms, and bookings are created for these rooms. So we can explore the idea of using relational databases here. The relations could be a property table that is associated with tables like property address, property rooms, property reviews, and property facilities. The property rooms can be further associated with room facilities and room prices. This is just a suggested schema for Day 0 architecture, and details like pricing and reviews can be maintained by a completely independent system as the system scales.

An additional benefit we get from RDBMS is strong ACID support, but this might require extra effort to implement data-partitioning techniques as the data grows. The system requires strongly consistent support for available rooms on a property to ensure that bookings are confirmed only for available rooms. On the subject of partitioning, if the system has separate databases for properties and bookings, the required storage space is not that large, and it can be managed via Amazon Aurora distributed storage.

For Aurora, the storage space for a cluster could scale up to 128 TB (for all PostgreSQL versions and versions 2, 2.09, 3, and higher for MySQL) and 64 TB (for lower engine versions), which is quite a high storage space number. We’ll also be discussing Aurora with limitless storage in “Scaling to Millions and Beyond” on page 493.


In case partitioning is needed, one technique could be dividing the data based on property IDs, and the routing layer in front can figure out exactly where the data resides. We recommend not fully normalizing the data in tables and avoiding complex join operations. This can help optimize query performance (at the cost of storing duplicate data among the tables), and even if the joins are used, the query should be written in a way that joins are applied after data filtering. It is much like query expression versus filter expression on DynamoDB tables data. The filter expression is applied after the data is collected, so it doesn’t help if the final data retrieved is a large set or small set—the time taken is the same.

Let’s think more about whether we should use solutions like DynamoDB, which can improve scalability and performance by avoiding joins, parallel querying, and out-of-the-box horizontal scaling. The partition key is the property ID, and we can define multiple sort keys to store different attributes associated with a property, as shown in Table 18-1.

_Table 18-1. Sort keys for storing property details in Amazon DynamoDB_

**Sort key** **Comments** PY The main property object with other details like address, facilities, and so on.

PY#IMG#{imageId} Image details of property images. This can just maintain the Amazon S3 link where the image is stored. Similar sort keys can be created to support different media types.

PY#R#PY#R#{roomId} This uniquely identifies a room object.

PY#R#{roomType} This contains different room properties based on room type.

PY#R#{roomType}#{imageId} Image details based on room type.

You can keep other details as necessary per your requirements, such as food menus, a history of updates to property details, and so on. We can conclude that both RDBMS and DynamoDB are feasible solutions for storing and accessing the property information. One of the sort keys from Table 18-1 is PY#R#{roomType}#{imageId}: the image ID represents a location identifier where the image is being stored, such as an Amazon S3 URL (we discussed Amazon S3 in Chapter 10).

Once the property details are stored in a database, we need a system to offer a search feature on this data. Let’s discuss the architecture of the property search next.

### Property Search Architecture

The key parameter for any search query is location. Once a user selects a location, the system should be able to present a list of properties in that location. The user can apply more filters to refine the results, such as type of property, whether pets are allowed, or if breakfast is included. The database we created in the previous section is not directly helpful for offering the search capability unless we create different GSIs (in the case of DynamoDB or RDBMS indexes) to support all of the filter


query patterns efficiently. The GSI approach can become complex as more and more filters are introduced into the search criteria. A better solution is to leverage search solutions like Elasticsearch or Amazon OpenSearch.

The architectures of these solutions that we explored in Chapter 15 can be useful for serving our property-booking-search use case here. Apart from offering search over fixed search parameters, Elasticsearch can power search queries with fuzzy text. The data from the properties database can be published to the queue as CDC events and then converted into Elasticsearch-compatible schema and persisted, as shown in Figure 18-3.

![](../images/system_design_on_aws_page_0494_2.png)

_Figure 18-3. Data persistence in Elasticsearch from the database via CDC_

The system might also require combining data from two data stores because we need the capability of strong consistency for availability of rooms on a property, and this information is stored in a strongly consistent database. The search can be broken down into two steps:

1. Retrieve properties from the Elasticsearch cluster based on the search criteria. 1.

2. Check these properties against their availability from a strongly consistent data‐2.

base.

There is also a possibility that the search is facilitated by multiple teams and is hosted on separate Elasticsearch clusters or any other database solution. This makes a perfect use case for using GraphQL federations—refer to Chapter 6 for more information on GraphQL and to Chapter 12 for AWS AppSync (a managed GraphQL federation service). The search service can be an independent wrapper that talks to different services and gathers the properties’ data based on customer filters.

Yet another solution is having the application run filters on data in memory instead of using too many indexes on a database or Elasticsearch. This means the application retrieves the data for a location from the database and then runs additional filters on top of this data. This is not a recommended approach in this scenario but can be considered in similar scenarios with less data retrieved on the wire. The number of properties for a particular location could be huge and can become a bottleneck.


We described usage of a strongly consistent database for checking the room availability. We can take a different approach that serves results from an eventually consistent database, making queries much faster, while checking for room availability in a strongly consistent database in parallel but not waiting for these results to merge. Results are merged later in the frontend application if room availability is not the same in both data stores.

There are trade-offs in any approach that we take here; another approach could be waiting for results from the strongly consistent database only if the room availability is minimal (for example, if there are only two rooms left); otherwise, serve the results from only the eventually consistent database.

The room availability check is to ensure that rooms are booked only if they are available. Organizations take different approaches to solve this problem. One completely different approach taken here is to allow overbooking of rooms based on analysis of past room cancellations at a particular property. This helps simplify the problem scope and ensure that rooms are never vacant.

Let’s dig a little bit more into Elasticsearch’s underlying architecture (in addition to what we discussed in Chapter 15) and strategies to come up with the Elasticsearch configuration.

**Elasticsearch configuration and scaling**

As you know, scalability is an important aspect of the system requirements. In Chapter 15, we discussed multiple approaches to scale read and write independently; those approaches apply here as well. In this chapter, let’s focus specifically on scalability of Elasticsearch clusters to support increasing reads and writes and a hot nodes issue (a few of the nodes handle all the read/write requests, and the rest of them sit idle). You can change the Elasticsearch shard configurations later, but that requires reindexing of data, which is a costly operation on a system running in production. The shard size should be average (not too small and not too large); the general recommendation is to keep the shard size between 10 GB and 30 GB with critical search latency use cases and between 30 GB and 50 GB for write-heavy workloads such as log analytics.

We often assume that sharding is done to solve the problem of storage. _Sharding_ is more of a general term referring to breaking the workloads into multiple resources to solve a bottleneck or combination of bottlenecks from storage, compute, network, performance, and reliability.


A smaller shard leads to the creation of smaller segments, and too many smaller segments add to the management overhead for hardware resources. Smaller shards offer room for more concurrent queries but can also lead to a lot of queries being queued up at a shard level for increasing traffic. In short, a smaller set of large shards is better than a larger number of smaller shards. Similarly, a very large shard should be avoided to reduce the data-rebalancing overhead on node failures.

For use cases with requirements for data deletion (such as storing logs in a time-based fashion), we recommend deleting the indexes and not the documents. The indexes are removed from the disk as soon as they are deleted, but this is not the case with documents. The documents are marked for soft delete (causing deleted documents to consume resources as well) and are actually deleted on the segment merge. This is similar to the tombstones problem in Cassandra discussed in Chapter 3.

Coming back to the number of shards that should be configured for an Elasticsearch cluster index, the shard size depends on the actual data size and the expected growth, so first let’s figure out the storage requirements, and then we’ll move to the number of shards. The total storage space depends on the size of the source data, number of replicas, indexing overhead, operating system reserved space, and service maintenance overhead:

- We should configure a minimum of one replica to prevent data loss. The replicas • will also help improve search query performance. Each replica contains the full copy of an index, and we’ll keep two replicas to start in our system architecture.

- The data is stored in a specific data structure format, and in general, the total size • of the source data and index is 110% of the source data.

- The operating system reserves 5% of space for its own processes. •

- The OpenSearch service (or Elasticsearch service) reserves space for different • operations, such as segment merges, logs, and so on. This is 20% of the storage space for each instance (up to 20 GB) in the case of the OpenSearch service.

We can estimate required storage based on these inputs:

Minimum storage requirement

= Source data × 1 + number of replicas × 1 + indexing overhead

1 −Linux reserved space × 1 −OpenSearch Service overhead Minimum storage requirement = Source data × 1 + number of replicas × 1 . 45 Storage for our system = 715 GB × 1 + 2 × 1 . 45 = 3 . 1 TB


Similarly, the formula to calculate the approximate number of shards is:

Number of shards = (Source data + room to grow) × (1 + indexing overhead) / Desired shard size

Number of shards for our system with 2x growth = (715 GB + 715 GB) × 1.1 / 30 = 53

Space required by each shard with current storage requirement = 715 × 1.1 / 53 ~ 15 GB

If you notice here, the shard size falls into the recommended size of 10−30 GB for critical search latency use cases. Referring to the calculation, we can also identify the type of instance that should be used in the cluster setup. Follow an iterative approach for figuring out the instance types and monitoring the metrics to come up with the best possible configuration.

Horizontal scaling (adding new data nodes) of Elasticsearch will not help with query performance if the shard size is too large because the data partitions where data is written or queried are still large. We can employ application layer logic in these scenarios by creating new indexes (once the index size exceeds a threshold value), which keeps the shard size within the limit even with growing data. Further, an index alias can be created to point to all of these indexes and aggregate the search results.

We mentioned GraphQL federation at the start of this section. Let’s elaborate more on how it fits into the reservation system architecture for the property search use case.

**GraphQL federation for search**

The response to any search request by customers should be a list of properties with each property associated with additional information, such as property details, rating, price for the selected date range (the property might have different types of rooms available, and the system can reflect the pricing for the most popular room types), and property tags (such as free breakfast or pets allowed). All of this information is collected from different systems and then shown collectively on the web UI as in Figure 18-4.


![](../images/system_design_on_aws_page_0498_3.png)

_Figure 18-4. Property search architecture using GraphQL federation_

The definitions of _resolvers_ and _schema registry_ match what we discussed in “AWS AppSync” on page 326 in Chapter 12. Booking.com systems leverage Apollo as their GraphQL federation solution, and the schema is fetched from different resolvers every 10 seconds by default. To remove complete dependency from Apollo servers and reduce frequent schema fetches, the schema is cached, and the cache is updated upon new schema build webhook events from Apollo.

A _webhook_ is a callback sent from a source system to a destination system to facilitate event-driven communication among multiple systems. For example, as soon as the customer booking is completed, the backend system posts an HTTP payload to the frontend system endpoint, and the same is reflected to the customer on the web UI.

We described search functionality on the basis of a location keyword in the Elasticsearch cluster. For example, if a user searches for “Goa,” then the search results should include properties from Goa, a state in India. Similarly, if a user searches for “Jaipur,” then the search results should include properties from Jaipur, a city in India. The search keyword can be anything from the location data, such as locality, town, city, state, and country.

Other features offered by booking systems are to search for properties by enabling your current location and to look for points of interest near the booked property. This can be solved by a concept called _Geohash_.


**Exploring points of interests**

Geohash is helpful for encoding latitudes and longitudes into an alphanumeric string. Assume the world has a large two-dimensional grid. Geohash is created by recursively dividing it into smaller grids, as shown in Figure 18-5.

_Figure 18-5. Geohash representation_

The length of the Geohash determines the precision of any location: a longer string means more precision because the grid is divided multiple times and represents a smaller subsection of the entire world. The shared prefix in Geohashes represents proximity of two locations, so they can be used to efficiently figure out the closest locations to a searched location. To get the surrounding places, we can remove one last character from the Geohash to get a grid that is one level higher and use the prefix to figure out the surrounding places.

The world is not uniform, and some places are more densely populated than others. Our algorithm should take this into consideration and can divide the grids into smaller levels so that they contain a smaller number of locations (for example, divide the grid further if it has more than two hundred locations). It doesn’t really make sense to divide the grid containing the ocean because there will be no locations of interest, whereas it would be very helpful in densely populated New York City.

Another way of representing location is using trees. The most popular implementation is quadtree (Booking.com leverages quadtree to implement its points-of-interest feature), which works on a similar concept as Geohash. A particular grid is constantly divided into four subparts until the area has the desired number of places. One method of figuring out nearby places is to keep pointers to parent nodes; we can go one level up and get all the child nodes that are in the surrounding area. Another way is to maintain the links between the child nodes via data structures, such as a doubly linked list.

Redis offers a geospatial feature that allows users to store the location coordinates and then query for nearby locations in a given radius.


The system additionally caches the search results to improve the query performance. The results can be cached in solutions like Redis, and media content (e.g., property images) can be cached in CDN solutions like Amazon CloudFront.

In the next section, we’ll discuss the architecture details of property booking.

### Property Booking Architecture

The next step after property search is actually booking rooms at the selected property from the search results. A simplistic view of a booking flow is shown in Figure 18-6. The payment system and booking flow go through different states, which we’ll discuss in detail now.

![](../images/system_design_on_aws_page_0500_4.png)

_Figure 18-6. Property booking state machine_

The booking transitions from one state to another and is needed to determine the current state of the booking. Figure 18-7 shows a minimal state diagram to represent different states and transitions between them for end-to-end booking flow. The booking state machine is initiated when the user moves to the BookProperty state from Figure 18-6. Note that the payment states will be managed separately by the payment system and are independent from the booking system.


![](../images/system_design_on_aws_page_0501_5.png)

_Figure 18-7. Booking states_

The transition from PENDING_CONFIRMATION to CONFIRMED states can vary from property to property in the sense that some properties require payment confirmation before confirming the booking. Let’s now talk about storing the booking information in a data store.

**Data store selection**

The booking system creates a booking as shown in Figure 18-6 and stores this information in a data store. We explored relational databases like Amazon Aurora and Amazon DynamoDB for the property onboarding architecture, and we’ll do the same for our booking architecture.

A key consideration here is that customers are mostly interested in current ongoing bookings and rarely look for past bookings. A general design decision in these kinds of scenarios could be maintaining two data stores: one for recent data with consistent reads and the other for past historical data. Gojek has a similar implementation: active bookings are stored in PostgreSQL, and the data is partitioned weekly with the help of the PostgreSQL partitions feature, as shown in the following code snippet:

```
CREATE TABLE bookings (
    booking_number PRIMARY KEY,
    customer_id,
    booking_details,
    created_at_timestamp,
    start_date,
    end_date,
    booking_status,
    payment_id
) PARTITION BY RANGE(created_at_timestamp)
```

The older partitions are archived with the help of a scheduler job, and this architecture serves 120,000 requests per minute.

A point to note here is that room bookings can be created well in advance and don’t really directly compare to Gojek’s architecture, where bookings are mostly done in the present. So can we really take inspiration from this architecture? This design


decision can help with real-time bookings, such as a cab-booking service, but not so much in our use case. However, we can still explore the idea of two data stores. The system should persist the older bookings if they are removed from the active database, and we can use a similar approach as diagrammed in Figure 18-3. Instead of keeping just the active bookings, we can make the archival time a little longer (such as one year) and ensure that the data is removed completely after one year from the main database.

Much like the case of the Elasticsearch indexes that we’ve discussed, we recommend handling deletion of data partition-wise. The data is soft deleted in the case of PostgreSQL, and regular vacuum processes are required to actually clean the data from the disk, hampering the performance of the database. If we use Amazon DynamoDB as the main data store, the TTL feature can be leveraged to automatically clear out the data after a fixed timestamp.

To finalize on the data store selection, we need a strongly consistent database to ensure the correct status of bookings at all times. In “System Scale” on page 467, we calculated 2 million bookings per day (25 RPS) and storage space as 730 GB per year. This storage requirement can be easily supported by vertical scaling of the Amazon Aurora database and doesn’t present any bottleneck, so we’ll design the solution with Aurora as the database.

Amazon DynamoDB can also support strongly consistent behavior, but this is limited to primary key attributes and the LSI. We should be clear on query patterns beforehand to avoid any issues at a later point: unknown query patterns can add to the cost as well as eventual consistency behavior (with GSIs) in the future.

In addition to the bookings table (shared in the previous code snippet), the database will have tables like booking_history (to store the status transitions of particular bookings, which is helpful for auditing purposes), booking_payments, and so on.

A very common and intriguing question that comes to mind is what happens if there is only a single room left and multiple users are trying to book that same room at exactly the same time? Let’s discuss this in the next section.

**Handling concurrent bookings**

There are different ways to handle the double-booking scenario, but first let’s understand if there actually is a need to handle this. The systems definitely need help from the property owners (or systems) to resolve ambiguity on bookings because even if the concurrency is handled well in our system, it can occur that the same property is booked on multiple booking platforms. A key point to note is that we can always


overbook the rooms based on certain criteria, such as past cancellations. Also, as evident from Figure 18-6, the room is confirmed only after a confirmation is received from the property owner, so we don’t require any special handling there.

Although we don’t require specific handling for our use case, we’ll discuss a few ways that systems handle multiple concurrent requests (for example, multiple users trying to book the same seat for a movie ticket or trying to book the same room at the same property). The idea is to use locks to block the seat or room for a certain time interval, which allows the user to finish the booking. If the user doesn’t complete the booking within the fixed time, then it is made available again for other users.

A _lock_ is a technique used in software engineering to gain access to a resource for a specific time frame so that nobody else accesses it for that particular time.

Booking rooms consists of two steps: check the availability of the room (read operation) and book the room (update the availability of the room to false). The lock can be acquired at either of these steps; acquiring the lock at the read step is called _pessimistic locking,_ and acquiring it at the update step is called _optimistic locking_. We can use these two types of concurrency techniques to gain access to a room for a particular property:

_Pessimistic concurrency technique_ Pessimistic locking requires acquiring a lock at read, and the lock is only released after the operation is completed. Until the lock is acquired, other requests wait for it, which can obviously cause a bottleneck if the number of requests waiting is too large.

_Optimistic concurrency technique_ Optimistic locking allows multiple user requests to read and update the data simultaneously. In case of any conflict on the update operation, the data is not committed, and the user is notified accordingly. This can be implemented by enabling versioning on the data: the version number is incremented on every update, and the most recent update should have a higher version number than the previous update. Amazon DynamoDB offers different mechanisms to support optimistic concurrency, and DynamoDBVersionAttribute annotation is one of the ways to implement it.

Returning to the earlier idea of booking a movie ticket and holding the seat for the time being, the lock can be introduced by keeping an entry in the database (e.g., `HOLD_FOR_ID`) against the user ID, and the time field `HOLD_START_AT_TIME` keeps the timestamp value (e.g., 20 minutes). Once the timestamp value is breached, the hold is


canceled. This can be easily implemented with Redis as the backend data store with the following steps:

1. The user finalizes the seat (or room) and proceeds to payment. The system stores 1.

an entry against the seat entity with an expiration (or TTL). The system uses Redis `SET` with `EX` (set with expiration seconds) and `NX` (set if not present) options to store the key ‘`seat_{theatreId}_{showId}_{seatId}`’. There can be more identifiers depending on the data storage pattern.

2. If the user completes the payment, the key is removed from Redis using the 2.

`DEL` operation. If the key is not deleted, Redis removes it automatically after the configured expiration time.

This implementation works well with a single Redis instance, but addition and deletion become tricky with Redis clusters (or any other distributed system solution). Redis recommends the Redlock algorithm for proper implementation in distributed environments. Additionally, we recommend using open source Redis libraries like Jedis or Lettuce for easier integration.

The system also supports booking cancellations. For this, the system updates the booking status, notifies the property owner, and initiates the payment refund if the customer was charged earlier. Further, the system should adhere to idempotent behavior and solve the problem of the same room being booked twice by the same user (or the user being charged twice for the same room). We’ll discuss this in more detail in the next section along with processing booking payments.

**Payment processing architecture**

Different payment solutions are used in different countries, and there can be different compliance regulations for each country. For example, PayPal is heavily used in the US, while Unified Payments Interface (UPI) is quite popular in India but not in other countries. The payment system’s core responsibility is to allow customers to pay via their preferred payment option and record the payment (pay-in system). The payment system is also responsible for reconciling the payments from third-party payment gateway solutions, such as Razorpay or PayPal, and making those payments to the property owners (pay-out system) after taking out the booking commission. The core payment system stays the same for both pay-in and pay-out, and `debitFrom` and `CreditTo` attributes are associated with payment changes.

The system should adhere to these additional requirements:

- For a single stay, the booking can be modified by the user, such as increasing the • number of days or adding property benefits like lunch and dinner.

- The payment options can increase over time, and they can vary from one loca‐• tion to another.


- It goes without saying (but we’re going to say it) that customers should be • charged only once for a smooth payment experience.

The high-level view of the system to manage the end-to-end payment lifecycle is shown in Figure 18-8.

![](../images/system_design_on_aws_page_0505_6.png)

_Figure 18-8. Booking payment system architecture_

Here are the components of the architecture:

_Booking orchestration_ Performs all the booking-related work. Once the user details and property details are gathered, the payment orchestration system (referred to as _order manage‐_ _ment_) takes care of the entire cycle of pay-in and pay-out.

_Pricing system_ Responsible for derivation of prices for the rooms.

_Billing system_ Generates invoices.

_Order management_ The reason for the extra order management layer is to support the system requirement of booking modifications. A single order can consist of multiple


payments associated with one booking. The order construct also simplifies the pay-out system by tying it to the same order booking system that payment was received against.

_Wallet service_ Manages the wallet provided to the customers. The wallet can include the rewards earned by customers on bookings, any refunds that are transferred to the wallet, or a custom amount added to the wallet from any payment method. The wallet could be helpful if the payment methods are not working so that the booking can be processed by deducting the amount from the wallet.

_PayIn service_ Responsible for customer payments: from customer to booking system or from booking system to customer (in the case of refunds). The customer can pay with an internal wallet or gift card managed by the wallet service or via other payment solutions, such as debit cards facilitated by external payment gateways. A single payment can be a combination of a wallet and external payment gateway as well.

_PayOut service_ Handles the logic of settling the payments with property owners. This system deducts the booking platform commission and transfers the rest to the property owner’s account.

_Reconciliation system_ For any payment system, there is a requirement of an additional reconciliation system, ensuring that the debits and credits for all payments are balanced, no discrepancy is created, and transaction integrity is maintained throughout the payment lifecycle (and will flag a discrepancy if it arises). The reconciliation system operates based on inputs from internal and external systems, such as callbacks from internal and external payment systems, settlement reports from banking partners, payment status inquiry APIs, and the like.

All the payments processed via the payment system go through a set of states and eventually reach a terminal state, such as SUCCESS, FAILURE, REFUND, or CANCELED. The intermediate payments state could be PAYMENT_CREATED, PROCESSING, and so on. The database also stores the responses from external payment gateways in case of payment failures to provide proper insights to the users for why the payment processing failed. Ensuring consistent and idempotent behavior is important for transactional systems, so let’s dig a little deeper into this.

Idempotent behavior ensures that the response of the API is the same irrespective of the time at which it is invoked, and it avoids any double payments (i.e., the customer is charged twice or the property host is paid twice). We recommend ensuring idempotency by maintaining a unique idempotency identifier; Airbnb leverages its own custom-built Orpheus general-purpose idempotency library for guaranteeing


idempotent APIs. Here is a summary of the Airbnb payments architecture, which we can take inspiration from:

- Every client request includes an idempotency key, which helps with uniquely • determining duplicate requests. For Amazon DynamoDB transactional requests, we can leverage the clientToken feature. The clientToken is valid for a 10-minute time window and ensures idempotent behavior for the same requests.

- Each payment is divided into three sections: pre-RPC, RPC, and post-RPC. • Pre-RPC is a payment initiation call, and a transaction is recorded in the database with intent. The RPC step is actual processing of the payment and includes the call to an external payment partner to process the payment. The final post-RPC step includes handling the response or callbacks from external partners and recording them in the database. The key consideration here is separating database and external network calls; the database calls are made only in the first and final steps, and external network calls are made only in the RPC step. A simple implementation is shown in Figure 18-9.

- The exceptions are categorized as retryable and nonretryable for the clients • to determine if the request can be retried. There is also a retryable window configured at the Orpheus end for each request to avoid a blast of retries to the system from clients.

- The requests are handled only by the primary instance of the database, which is • sharded by the idempotency key to support the scale.

As shown in the diagram in Figure 18-9, the responsibility of identifier generation can fall on either the client or the payment processing system. For example, the payment acknowledgment ID can be generated by the payment system and sent to an external partner, or the identifier is sent in response to a process payment call. We recommend generating the identifier at the client side if there is a single payment call as the identifier is helpful for inquiring about the payment status or reconciling the payment via received callbacks. The drawback of this approach could be external clients responsible for generating a primary payment attribute; that’s where dividing the processing into two steps—pre-RPC and RPC—is helpful.

Room prices generally vary depending on the availability, time of booking, and many other factors. We’ll not go into too much depth, but let’s gather some general ideas for how dynamic pricing components can be added into the system.


![](../images/system_design_on_aws_page_0508_7.png)

_Figure 18-9. Payment processing in three steps: pre-RPC, RPC, and post-RPC_

**Dynamic pricing in the system**

Booking platforms in general don’t keep a static price. The price is adjusted based on multiple factors, such as location, date-range selection, the number of days of the stay, and the popularity of the property. The booking and search systems continuously publish the consumer data via event streams for the pricing system to consume and run ML inferences to come up with prices. The pricing system database is continuously updated in the background based on the ML inferences and custom price (or price range) shared by the property owners. Figure 18-10 shows a reference architecture for the dynamic pricing system.

We’ve used Amazon S3 to store raw data received from different sources (booking, search, and external sources). Amazon SageMaker Feature Store is another service that can be used as a repository to store all the pricing features.

The pricing system has two independent scaling layers, and we can plan to deploy these layers separately or in the same system depending on the workload served by the system. The first is completely asynchronous and responsible for consuming the events and updating the pricing structure, and the second is the read layer for different systems to get the most recent price of a property.


![](../images/system_design_on_aws_page_0509_8.png)

_Figure 18-10. Dynamic pricing system_

Given that the price can continuously update in the system, the booking system should ensure that a price is locked for a user for a fixed period of time (e.g., 10 minutes). This avoids the bad customer experience of the price updating once the user proceeds to pay for the booking. Another point to note here is that the price shown to multiple users for the same property at the same time can be different and depends on the pricing structure followed by the business.

There are multiple subsystems inside the property booking system, and we should focus some attention on the way they communicate. Does all communication happen synchronously, or can we leverage message queues in some of them? For interaction between the payments system and booking system, it makes sense to include a combination of both. This is because the payment system in itself can take time for payment processing, so the booking system should just initiate a payment request and then receive an acknowledgment that payment has begun. The payments system publishes the payment status lifecycle, and the booking system can depend on that to figure out the latest status of the payment.


Queues help decouple two systems and make the rate of publishing and consuming events independent. However, the system should not work with an assumption that queue size can grow infinitely and that any number of messages can be published without consumption (or that the rate of publishing versus consumption varies by a large ratio). This is often solved either by reducing the rate of publishing (referred to as _back pressure_) or by having the queue drop messages based on certain criteria (e.g., messages older than a day are deleted).

As the booking system consumes the events from the payment system (or any other system following this communication paradigm in the architecture), there is a possibility of out-of-order events, events being missed, and duplicate events. Now either it is guaranteed by the queue system that none of these issues will happen or it should be handled by the event-consuming system. Apache Kafka supports exactly-once semantics and event ordering on a single partition (or group IDs in Amazon SQS). This can also be handled in the booking system as follows:

- The system checks for the most recent status from the database before updating • the status.

- There is a possibility that the system receives a terminal status before an inter‐• mediate status. In this case, the system should discard the events if a payment has already reached terminal state.

- The system has a built-in inquiry mechanism to call the payment system to check • for the most recent payment system. This makes the booking system independent and works even if some of the events are missed in the payment callbacks.

We have discussed multiple components in the property booking architecture. Users create a booking, make the payment, and spend their time at the property. The next step is user reviews. The booking system notifies users to ask about their experience at the property and they leave a review, which we’ll discuss in the next section.

### Property Reviews Architecture

Reviews are associated with a property and a user. The system can ask some predefined questions about the stay (How would you rate the staff? Is it a good value for the price? How was the food?) and allow for generic feedback notes. Generally, the booking systems also implement ML algorithms to determine the type of experience based on the feedback note and improve other user search criteria by running multiple analytics pipelines.

Like the search system, the reviews system is very read heavy. Customers search for properties, look for reviews, and then decide whether to book a specific property. The read traffic is proportional to search system traffic, whereas write traffic is


proportional to property-booking traffic (we can assume 10% of users who book a property actually provide a review of their stay). Here are some search criteria that a review system should support:

- Get all the reviews of the property. •

- Get reviews of the property based on any provided text filter, such as reviews • associated with food, bathrooms, or room size or reviews for a specific time range.

In essence, we require text search for the user reviews as well as some of the supported features. Elasticsearch (or Amazon OpenSearch) is suitable for such use cases, and we can leverage the same to support the read use cases. But what about the write traffic on the system? A review is stored against a user and a property, and only one review is allowed per user per stay against a particular property. We’re fine with eventual consistency on the reviews data for fetching the reviews, but there should definitely be a strongly consistent behavior from a single-user perspective to make sure there’s one review per user.

Let’s take an example of an Amazon DynamoDB schema to support the write use case, which serves as a source of truth for review data:

Partition key = {propertyId}

Sort key = {userId}

The data is always queried from the Elasticsearch cluster, and we don’t have to worry about hot keys concerning too many reviews associated with a single property. However, the queries should always be paginated to get a fixed number of results from DynamoDB, Elasticsearch, or any other data store used in a particular architecture. The simplistic architecture of property reviews shown in Figure 18-11 is as follows:

_Reviews system_ Allows users to add a review for their stay on a property. The database layer of the system streams this review to be used by the read layer. The reviews are also consumed by the analytics pipeline to figure out the popularity of the property; this can also be the input for the pricing system to decide the price based on reviews.

_Reviews system read layer_ Retrieves reviews for any property per the filters provided by the users from the Elasticsearch cluster.


![](../images/system_design_on_aws_page_0512_9.png)

_Figure 18-11. Reviews system high-level architecture_

With all the details we gathered about the overall booking system, let’s determine which AWS technologies to leverage for launching the system on the AWS cloud.

## Launching the System on AWS

As with the discussion of the system design, we’ll break the system into subparts and design the deployment view of the systems in Day 0 and Day N architectures. Horizontal scaling comes out of the box for the nonrelational databases, and users don’t really have to worry about it. For relational databases, users will need to tweak the application code and manage the horizontal scaling on their end. We’ll discuss the Aurora Limitless database architecture as part of this section to explore how customers can offload the management overhead and let AWS manage the horizontal scaling of relational databases. Let’s start the discussion with the Day 0 architecture of the overall booking system.

### Day 0 Architecture

We’ll take inspiration from the AWS tech blog and break the design into multiple components for cleaner architecture diagrams, starting with the property onboarding system. The system architecture uses Amazon API Gateway to expose all the create and update APIs, and the authentication is managed by Amazon Cognito user pools. Amazon Route 53 provides a unique domain for users to interact with, which internally resolves to the API Gateway endpoint. AWS Lambda is used as the backend for managing all the property configurations, and it further interacts with three data stores: two Amazon S3 buckets and one Amazon DynamoDB table. The first S3


bucket is used to store any media content, such as property and room images, and the second S3 bucket is used for publishing all of the configurations in static format.

Any newly published configurations to S3 with respect to properties (addition or removal) and their pricing are consumed by the search system to facilitate property search by the users. DynamoDB stores the property information based on the schema we discussed in “Property Onboarding Architecture” on page 469. The architecture is shown in Figure 18-12.

![](../images/system_design_on_aws_page_0513_10.png)

_Figure 18-12. Property onboarding architecture on AWS_

Room availability is continuously updated by the property owners and in the booking system. A key consideration to note is whether we can utilize DynamoDB streams to publish data to the pricing and search systems. We can, definitely, but the data is modeled in different ways to support multiple search use cases, and it is not the best idea to consume all the modeled data by the different systems. A single static config can be consumed by these systems and modeled per their requirements, which makes the overall architecture simple to operate.

The second subsystem is a search system allowing users to look for properties along with their prices and available rooms at a particular location. Users don’t have to be logged in to search for a property, so authentication is optional. In case users are logged in, this information can be used to show more recommendations in the future. Additionally, the system can integrate with Amazon Location Service to offer capabilities like maps and points of interest. The properties are reflected in the search results based on the combination of two sets of databases: in the first, the property should be in the vicinity of the user-searched location using the Geohash database and should incorporate search filters using Elasticsearch, and the second maintains the availability of rooms at the property. The system also emits events for


property searches for the properties having the most interest in a date range, and the pricing system can adjust the pricing of the properties accordingly. The high-level architecture of the property search system is shown in Figure 18-13.

![](../images/system_design_on_aws_page_0514_11.png)

_Figure 18-13. Property search architecture on AWS_

The next system is a booking system allowing users to book a selected property from the search results. The booking system essentially books an available room, informs the property owner to take confirmation, processes the payment if needed, and finally marks the booking status per the response from the property owner. The architecture of the booking system is shown in Figure 18-14.


![](../images/system_design_on_aws_page_0515_12.png)

_Figure 18-14. Property booking architecture on AWS_

We have heavily used AWS serverless technologies in all the architectures described in this section. Let’s further evaluate these different systems when scaling to a huge number of customers.

### Scaling to Millions and Beyond

Using serverless solutions doesn’t directly mean that they don’t scale, but they can add to the cost as the traffic increases. The cost of AWS services is justified because customers don’t have any operations management overhead. We’ll start by looking at Amazon Aurora to figure out if it can meet increasing storage requirements. Per the storage-requirements calculations, the systems should be good to handle the required load since Aurora’s storage capacity is 128 TB (up to 64 TB for older engine versions). Aurora shared storage scales in 10 GB segments up to 128 TB, and on top of this storage, we can introduce multiple read replicas (up to 15) and vertically scale the writer instance to handle increasing load, as shown in Figure 18-15.


![](../images/system_design_on_aws_page_0516_13.png)

_Figure 18-15. Scaling in an Amazon Aurora cluster_

Beyond 128 TB in customer-managed Aurora clusters, the sharding on storage should be implemented by the customer. This can also be handed over to AWS using Aurora Serverless as compute, which offers Aurora Limitless Database capability. This feature is helpful for managing millions of write transactions per second and petabytes of data with no sharding overhead on the customer’s plate.

We compared Amazon RDS and Aurora in Chapter 10 to some extent. Some additional operational challenges in RDS can be solved by migrating to Aurora. Some of these challenges include RDS taking around a day to create and restore read replicas for big clusters and needing to warm up the disk layer of RDS. These challenges are solved by offering an independent distributed storage layer in Aurora clusters.

Now, let’s talk a little bit about the architecture of Aurora Limitless Database—the key distinction here is scaling the writes both vertically and horizontally. The user talks to a single writer endpoint, which internally communicates with multiple distributed transaction routers. These routers are responsible for ensuring the consistency and isolation properties of the database, scaling vertically to an extent, and then scaling horizontally to manage the load. The transaction routers store the metadata about the table schema and mapping tables key ranges to further figure out the shards where data should be kept.


There can be three types of tables on Aurora Limitless Database: sharded, standard, and reference. Standard tables are the default tables created in nonsharded Aurora clusters. The sharded tables are partitioned via hash-based partitioning by taking the hash of the shard key to 64 bits, and the ranges of 64 bit space are assigned to the shards. The reference tables can be the small tables for any use cases that don’t share the shard key and are kept on each and every shard. All the related tables are colocated on the same shard to ensure minimum latency on data join operations. The data access shards store the sharded key space and the reference tables. These shards are also responsible for performing local transaction logic (global transaction logic across the shards is handled by transaction routers), local planning, and query execution.

The data access shards are further backed by Aurora’s distributed storage layer to ensure data durability and high availability, as shown in Figure 18-16.

![](../images/system_design_on_aws_page_0517_14.png)

_Figure 18-16. Amazon Aurora Limitless Database architecture_


Aurora internally divides the shards further into slices (colocated data is present on the same slices). This makes relocation tasks easy on horizontal scaling and offers intrashard parallelism capability to improve query performances. This is quite similar to data division into virtual nodes in a physical node’s consistent hashing ring, which we discussed in Chapter 3.

Aurora automatically takes care of high availability and durability by replicating the data across the AZs. For the transaction routers layer, any transaction router that goes down is automatically replaced by another one, and the requests can be handled by other instances. For the data access shards layers, the shards store the data, so there is downtime associated if any of these shards goes down. Aurora provides compute redundancy configuration as 0, 1, and 2 to replicate the shards across the AZs: 0 means there is no replication across the AZs, and 2 means a shard is replicated across two AZs.

The relational databases offer ACID properties out of the box for a single-instance deployment, but for a distributed environment, this support should be managed in the custom application logic. This is offered by the Aurora Limitless Database out of the box. Let’s understand how transactions work in a distributed setup of nodes acting as shards. There can be two scenarios for executing multiple queries in a single transaction: all the queries access the same shard, or they access different shards. The same shard query is committed via one-phase commit, and two-phase commit is used for multishard transactions.

Time synchronization is another problem for multishard transactions, but this is solved using Amazon EC2’s time-sync service and Aurora’s custom implementation of bounded clocks. A SQL statement is sent to a transaction router and then is forwarded to different data access shards, but the time of delivery could be different, causing a time-sync issue on transaction commits. This can become a problem while restoring the data from snapshots (as a single data snapshot is created combining multiple shards) because of inconsistent data. The EC2 time-sync service offers three entries of time: current approximate time, earliest possible time, and latest possible time. The time is always within the earliest and latest possible time range, so the shards agree on one time (with microsecond precision), which has been passed by all of them.

We discussed all these details regarding Aurora Limitless Database to give us an idea of the extra work required for implementing the sharding on our own, adhering to basic relational database features. For the compute part in various architectures, we used AWS Lambda heavily in the Day 0 architecture of different systems. AWS Lambda can be used at scale or replaced by other compute options based on the comparisons we did in Chapters 10 and 14. The choices of database and compute always boil down to determining how each technology fits into your specific use case.


We often use Amazon API Gateway with AWS Lambda and then switch to ELBs with Amazon EC2 or container services. We covered the general idea of these services in Chapter 9, discussing their differences and similarities. Unless you’re looking for specific API Gateway features, we recommend choosing ELB over API Gateway for application deployment.

Let’s move to our Day N architecture next.

### Day N Architecture

Let’s think about which things we want to change in the Day 0 architecture if it has to be scaled to millions of users. In “Starting with the Design” on page 469, we discussed multiple components and breaking down the entire system into subcomponents. We also covered sharding mechanisms with Amazon Aurora in the previous section. We pretty much divided the system responsibility into subsystems in the Day 0 architecture, though we preferred most of the serverless offerings of AWS.

We also looked at multiple examples in previous chapters for moving from AWS Lambda to Amazon EC2 or Amazon EKS to support the Day N architecture. Note that we’re not saying that serverless solutions don’t scale or that they are too costly in all the scenarios. For example, Amazon DynamoDB works well at a huge scale and has predictable costs for defined query patterns. Along similar lines, Amazon Aurora Limitless Database is designed to support large-scale sharded databases, so it would be incorrect to say that we should manage infrastructure as scale grows. We recommend carefully evaluating your design choices and finalizing a choice with the least pain points.

Our architecture will also need a notification system to update customers about what’s happening with their bookings. We used a combination of Amazon SNS and Amazon SES to send notifications to customers in the Day 0 architecture (refer to Figure 18-14). This can be further extended to integrate more notification channels, such as WhatsApp, mobile phone push notifications, and so on. Additionally, this system is used for marketing campaigns and sends different kinds of notifications to users. To implement all these features, an independent component in the system architecture can be included to take care of notification delivery and management. We can choose to club the same set of services (e.g., pay-in and pay-out microservices in the payments architecture) on the same EKS cluster, which should save some costs there. Reiterating from the previous chapters, it’s not necessary to make the components independent if you don’t foresee a need for that.

All the applications in the property reservation architecture are accessible via the frontend service. The frontend system is an application responsible for handling the user traffic for various operations and redirecting it to a specific application, such as user authentication, property onboarding, property search, booking, reviews, and so on.


A simplistic view of the booking system is shown in Figure 18-17 with all the different components discussed in previous sections.

![](../images/system_design_on_aws_page_0520_15.png)

_Figure 18-17. Property reservation system Day N architecture_

In the architecture, we included all the services in a single AWS account for diagram clarity. We can also divide the AWS accounts based on business verticals, which will require additional networking infrastructure configurations for cross-account communication.

## Conclusion

Implementation of any system end to end involves handling a lot of internal use cases, and you should limit the scope of the problem statement to close in on the discussion. We tried to take a similar approach with all the architectures in this part of the book: identifying the scope and then going into depth on it.

In this chapter, we identified a few of the systems in the overall booking architecture and figured out the design and the AWS services that would be beneficial for launching the application. We decided that both Amazon DynamoDB and Amazon Aurora can be useful in our property onboarding system design. This is an important


takeaway: it often happens that multiple services will meet your requirements. We recommend evaluating your options primarily on three factors if this happens: your previous expertise on any service, the operational overhead, and the cost you’re paying to AWS for service usage.

Remember, on Day 0, we make a lot of assumptions, but we learn over time by observing the system’s behavior in production. With these observations in mind, we should reevaluate whether the system should be broken into more subparts for scaling for the system’s and the team’s operations.

One of the requirements in a booking system could be offering a communications channel between property owners and the customers after a booking. This allows customers to directly interact with hosts for any special requests. In the next chapter, we’ll introduce you to the design of such chat applications and how they operate at high scale.


