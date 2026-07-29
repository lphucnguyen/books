# Chapter 17: Designing an Online Game Leaderboard

Online gaming has surged in popularity over the past decade, becoming a global phenomenon that connects millions of players across the world. Games like _Fortnite_, _League of Legends_, _Dota_, and _Call of Duty _have not only provided entertainment but also fostered competitive communities where players continuously strive to improve their skills. A central feature that amplifies this competitive spirit is the _leaderboard_: a system that ranks players based on their performance.

Leaderboards serve as a tangible measure of achievement, motivating players to climb the ranks and outperform their peers. They enhance player engagement by offering clear goals and fostering a sense of community and rivalry. However, behind the simple interface of a leaderboard lies a complex system that must efficiently handle real-time data processing, massive user bases, and the demand for instantaneous updates.

In this chapter, we will delve into the design and architecture of an online game leaderboard system. We’ll focus on building a scalable, efficient, real-time ranking system using AWS services. Starting with the foundational requirements, we’ll explore how to architect a solution that can grow from supporting a few thousand players to millions worldwide. By building the solution from first principles, we’ll create a Day 0 architecture suitable for a startup. Finally, we’ll explore strategies to scale the system to handle millions of users, addressing potential bottlenecks and leveraging AWS services effectively. By the end of this chapter, you’ll have a comprehensive understanding of how to design a robust online game leaderboard system on AWS that is capable of delivering a seamless, engaging experience to players around the globe.


## CHAPTER 17 Designing an Online Game Leaderboard: System Requirements

The requirements center on enhancing player engagement and fostering a competitive community within an online multiplayer game. The leaderboard system is integral to this goal, serving not only as a measure of individual achievement but also as a social platform where players can compare their performance against friends and rivals globally. Let’s look at the functional and nonfunctional requirements of our game leaderboard system.

### Functional and Nonfunctional Requirements

In modern gaming, the most important functional requirement is that the leaderboards are updated in real time, reflecting players’ achievements as they happen. This immediacy is crucial; it heightens the competitive atmosphere and motivates players to continue playing to improve their rankings.

From a business perspective, the leaderboard system supports several critical objectives:

_Player retention_ By providing immediate and accurate feedback on performance, the leaderboard incentivizes players to continue engaging with the game to improve their rankings.

_Community building_ Leaderboards foster a sense of community and healthy rivalry, encouraging players to interact and compete with one another.

_Monetization opportunities_ The leaderboard can be tied to in-game rewards, achievements, or special events, providing additional incentives for players to engage with the game and potentially spend on in-game purchases.

_Data insights_ The leaderboard system can offer valuable analytics on player behavior and performance trends, informing future game development and marketing strategies.

Leaderboards are not just a feature but a fundamental component that can make or break the gaming experience. In games like the _Battle Royale_ titles or massively multiplayer online role-playing games (MMORPGs), leaderboards can be global, regional, or even segmented by specific in-game events or seasons. The system must handle the following critical tasks to meet these expectations:

_Real-time score processing_ As players achieve milestones, complete levels, or defeat opponents, their scores should be processed and reflected on the leaderboard instantly.


_Accurate ranking_ The system should accurately rank players based on scores, implementing tiebreaking criteria to ensure fairness. It must also support dynamic filtering, allowing players to view global, regional, or event-based rankings.

_Filtering and segmentation_ Players should be able to view leaderboards based on various criteria like global standings, friends’ scores, or time-specific leaderboards (daily, weekly, monthly).

_In-game notifications_ Real-time notifications should be integrated to inform players of ranking changes, new milestones, or other significant events, enhancing engagement.

Designing a leaderboard system that can handle the immense scale and the demand for real-time updates is a complex challenge. It involves managing high volumes of data, ensuring low latency for both reads and writes, and maintaining data consistency across distributed systems—all while providing a seamless experience to the end user.

The system should meet the following NFRs to ensure a smooth and competitive player experience:

_Real-time updates_ Players expect near-instant updates to their scores on the leaderboard, necessitating low-latency write and read operations. Write latency should be under one second, while read latency for leaderboard retrievals should be less than 100 ms.

_Consistency_ The system should maintain eventual consistency across distributed servers, ensuring that players see accurate and up-to-date rankings.

_High availability_ The system must maintain 24-7 availability, with redundant architecture to handle failures without affecting user experience.

_Scalability_ The system should handle fluctuating player volumes, from a few during off-peak times to millions during global events or tournaments. It should be able to scale horizontally, enabling seamless expansion as player engagement grows.

_Low latency_ Both write and read operations must be optimized to ensure a low-latency experience. Network communication between servers and clients should be efficient, minimizing delay.


### System Scale

Understanding the scale at which the system needs to operate is essential for making informed design decisions. Let’s explore the scale considerations in terms of storage, bandwidth, throughput, and latency.

**Storage requirements**

The storage solution must accommodate the growing amount of data, including player profiles, scores, game statistics, and historical data. Let’s calculate estimates for one thousand players, each potentially submitting multiple scores per day.

The assumptions are:

Average submissions per player per day = 5

Average storage record size = 500 bytes (player ID, score, timestamp, and metadata)

With these assumptions, the storage requirement for one thousand players can be calculated as:

Daily data ingestion = 1,000 players × 5 submissions/player × 500 bytes = 2.5 MB/day

Monthly data storage = 2.5 MB/day × 30 days = 75 MB/month

Calculate storage requirements for 10 million players with the same assumptions:

Daily data ingestion = 107 players × 5 submissions/player × 500 bytes = 25 GB/day

Monthly data storage = 25 GB/day × 30 days = 750 GB/month

Annual data storage = 750 GB/month × 12 months = 9 TB/year

Configure the following data retention policies for older data to optimize costs:

_Historical data_ Decide how long to retain historical scores. For example, keep data for one year before archiving.

_Archiving_ Move older data to cost-effective storage solutions like Amazon S3 Glacier or Infrequent access tiers.


We also suggest using data compression techniques where applicable to reduce the data footprint.

**Bandwidth and throughput**

The system must handle a high number of read and write requests per second, especially during peak gaming hours.

The requirements for write operations (score submissions) are:

Peak write rate per second assuming 1% of total players (107 players × 1% = 100,000 players) submit scores simultaneously and submissions occur over a 10-minute window = 100,000 submissions ÷ 600 seconds ≈ 167 writes/sec

Peak write rate (tournaments) = 1,000 writes per second

The requirements for read operations (leaderboard retrievals) are:

Assuming each player checks the leaderboard twice a day = 107 players × 2 retrievals/player = 20 million retrievals/day

Average read requests per second = 20 million retrievals/day ÷ 86,400 seconds/day ≈ 231 reads/sec

We take networking solutions for granted and assume they work out of the box because of the multiple serverless offerings by AWS and the easy configuration management of all the services. We discussed multiple distributed system fallacies in Chapter 1, and most of them are related to management of computer networks. We often assume the network is reliable and secure with zero latency and infinite available bandwidth, but this is not the case. We should always take into consideration the required network bandwidth for our business use case. Let’s calculate this for an online gaming leaderboard:

Average payload size = retrieval of 100 entries at 1 KB per entry = 100 entries × 1 KB = 100 KB

Bandwidth for reads = 231 reads/sec × 100 KB = 23.1 MB/sec

Bandwidth for writes = 167 writes/sec × 500 bytes = 83.5 KB/sec

We’ve gathered the system requirements and gotten an idea of the scale the architecture needs to support. Let’s dive into the design.


## Starting with the Design

Designing a robust, scalable online game leaderboard system requires a deep understanding of fundamental concepts and principles for distributed systems, data modeling, and concurrency control. By applying these first principles, we can create an architecture that not only meets the current requirements but also is flexible enough to adapt to future needs.

### Concepts and Principles

We’ll discuss different principles and try to figure out a direction for breaking the problem into smaller parts, starting with data modeling. We’ll also touch on other factors, such as latency and consistency.

**Data modeling**

At the heart of our leaderboard system lies the need for efficient data structures capable of handling sorting and ranking operations at scale. These are the major aspects of data modeling:

_Efficient sorting and ranking_ We need data structures that allow quick insertion, deletion, and retrieval while maintaining order based on player scores. Using sorted data structures like skip lists or balanced binary search trees can be beneficial. In-memory data stores like Redis sorted sets provide built-in support for these operations with high performance.

_Schema design_ The database schema should support various querying patterns, including filtering by region, friends, or time frames. Denormalization may be employed to optimize read performance, sacrificing some storage efficiency for speed.

**Latency**

Low latency is one of the requirements for a smooth user experience with the system. A write latency of 500 ms is an acceptable number. Multiple factors can affect the latency, such as network delays, database write times, and implementation logic processing overhead. For optimizing the write operations, we recommend asynchronous processing and batch writes wherever feasible.

Similarly, we decided 100 ms was an acceptable read latency in “System Requirements” on page 442. Some factors that can affect read latency include data retrieval time, sorting algorithms, and network transmission. We can leverage in-memory caching and efficient data-retrieval methods as an optimization strategy to fix the


potential bottlenecks. Users are located worldwide, and solutions like CDN and multiregion deployments can help reduce the overall latency.

**Eventual consistency**

Balancing the need for real-time updates with system performance may involve accepting eventual consistency in certain components since strong consistency can affect performance and availability. For leaderboards, slight delays in updates are often acceptable, making eventual consistency a viable option.

Choosing the right consistency model depends on the specific use case even with the eventual consistency option. For example, we discussed “reads your write” consistency in Chapter 16, and that might be important for displaying a player’s own score immediately after it is submitted.

**Data partitioning and sharding**

We discussed sharding and partitioning in Chapter 2: these are important with increasing data. Distributing data effectively prevents bottlenecks and allows the system to scale horizontally.

There are two possible partitioning strategies:

_By player ID_ Distribute data based on player IDs to ensure even load distribution.

_By region_ Partition data by geographic region to reduce latency and comply with dataresidency laws.

Selecting an appropriate shard key is vital. It should ensure an even distribution of data and workload. Examples include using a hash of the player ID or combining multiple fields like region and player ID. The system should be capable of rebalancing shards dynamically to handle changes in data distribution or workload. Consistent hashing algorithms are used to distribute data evenly and handle dynamic scaling.

**Sorting algorithms**

Efficient sorting is crucial for maintaining accurate rankings, especially with large datasets. For small datasets, in-memory sorting algorithms like quicksort or heapsort can be sufficient. With datasets that cannot fit into memory, external merge sort allows sorting by dividing the data into manageable chunks. For incremental updates, instead of re-sorting the entire dataset upon each new score submission, algorithms that support incremental updates can improve efficiency.


**Caching strategies**

Implementing caching mechanisms is vital to reduce latency and offload read traffic from the database. Use in-memory data stores like Redis to cache frequently accessed data, such as top leaderboard entries. Define strategies for cache expiration and invalidation to ensure data freshness.

Based on these concepts and principles, let’s compose a rough system design that stitches the basic components together.

### A Rough System Design

A high-level system design that meets our requirements is shown in Figure 17-1 .

![](../images/system_design_on_aws_page_0470_0.png)

_Figure 17-1. Online game leaderboard system architecture_

Let’s review each piece of this architecture in more detail.

**Score submission service**

The _score submission service _handles incoming score submissions from players with the following features:

_API endpoints_ Provide secure endpoints for game clients to submit scores

_Input validation_ Ensures that the submitted scores are valid and not tampered with

_Authentication and authorization_ Verify the identity of the player and ensure that they have the right to submit a score


_Asynchronous processing_ Uses a messaging system to queue score updates for processing, allowing the service to respond quickly to the client

The client can have “reads your write” consistency with sticky sessions for the server node, with synchronous response and asynchronous processing to queue score updates for other server nodes for other players to view.

**Ranking service**

The _ranking service_ is responsible for calculating player rankings based on the scores with the following features:

_Real-time processing_ Updates rankings as new scores are processed

_Efficient data structures_ Use data structures that support quick ranking operations, such as sorted sets in Redis

_Tie-breaking logic_ Implements rules to handle players with identical scores, such as using submission timestamps as tiebreakers

**Leaderboard service**

The _leaderboard service _provides the interface for retrieving leaderboard data with the following features:

_API endpoints_ Allows clients to request leaderboards with various filters (global, regional, friends)

_Pagination_ Supports pagination to handle leaderboards with large numbers of entries

_Cache utilization_ Retrieves data from the cache layer to minimize latency

**Database**

The database stores player scores, profiles, and other relevant data with the following components:

_Primary storage_ A NoSQL database like Amazon DynamoDB can handle high write throughput and scale horizontally.


_Data partitioning_ Shards data based on player ID or region to distribute the load.

_Indexes_ Secondary indexes are created to support various querying patterns.

_Data backups and replication_ The data is replicated across multiple nodes for faster response times, and backups are maintained for recovery mechanisms.

**Cache layer**

The _cache layer_ improves read performance by storing frequently accessed data in memory with the following features:

_In-memory store_ Uses Redis for its sorted set data structure, which is ideal for ranking

_Data expiration policies_ Define when cached data should be refreshed or invalidated to ensure accuracy

_Distributed cache_ Employs a cluster of cache servers to handle the load and provide redundancy

**Messaging system**

The _messaging system_ handles asynchronous communication between services with the following features:

_Message queues_ Implement queues using systems like Amazon SQS or Apache Kafka to decouple score submissions from processing.

_Event-driven architecture_ Services react to events, such as new score submissions, to trigger necessary actions like updating rankings.

_Scalability_ The messaging system should scale to handle spikes in message volume during peak times.

**Frontend API**

The _frontend API_ acts as the gateway between game clients and backend services as follows:

_Load balancing_ Uses load balancers to distribute incoming requests evenly


_Security measures_ Implements SSL/TLS for secure communication and protects against common web vulnerabilities

_Rate limiting_ Prevents abuse by limiting the number of requests a client can make in a given time frame; the requests are throttled in case the limit is breached

**Additional components**

Along with the core functionalities, the following services need to be added to the overall system:

_Monitoring and logging_ Implements tools like Amazon CloudWatch to monitor system performance and troubleshoot issues.

_Analytics service_ Collects data on player behavior and system performance for business insights; this can be a planned component that can be built as part of scaling the architecture to Day N.

_Notification service_ Sends in-game notifications to players when their rankings change using services like Amazon SNS.

With the rough system design in place, the next step involves launching the system on AWS. This process will leverage various AWS services to ensure scalability, reliability, and performance optimization across all components of the application.

## Launching the System on AWS

Having established the foundational principles and requirements for our online game leaderboard system, we can now begin designing the initial architecture on AWS. For a startup with approximately a thousand players, the system doesn’t need to be overly complex. However, it should be designed with scalability in mind to accommodate future growth seamlessly.

### Day 0 Architecture

Our Day 0 architecture focuses on simplicity and cost-effectiveness while ensuring that the core functionalities—score submission, real-time leaderboard updates, and data retrieval—are efficiently handled. The architecture leverages several AWS services to meet these needs:


_Amazon API Gateway_ Acts as the entry point for all client requests, providing a secure, scalable API endpoint

_AWS Lambda functions_ Handle stateless compute tasks for processing score submissions and retrieving leaderboard data

_Amazon DynamoDB_ Serves as the primary data store for player scores, profiles, and metadata

_Amazon ElastiCache for Redis_ Implements an in-memory caching layer to store frequently accessed leaderboard entries for quick retrieval

_Amazon SQS_ Manages asynchronous processing of score updates and decouples components for better scalability

_Amazon SNS_ Facilitates in-game notifications when a player’s ranking changes

Figure 17-2 illustrates the Day 0 architecture for our online game leaderboard system.

![](../images/system_design_on_aws_page_0474_1.png)

_Figure 17-2. Day 0 architecture for online game leaderboard system on AWS_


Let’s delve into how each component functions within the architecture and how they interact to fulfill our system’s requirements. Table 17-1 describes the different Lambda functions and their purposes.

_Table 17-1. Lambda functions in the system architecture_

**Lambda function** **Triggered by** **Operations** Score submission handler

Amazon API Gateway when a player submits a score

Validates the incoming score data Writes the score to Amazon DynamoDB Sends a message to an SQS queue for asynchronous processing

Leaderboard retrieval handler

Amazon API Gateway when a player requests leaderboard data

Checks ElastiCache (Redis) for cached leaderboard data If cached data is not available or outdated, retrieves data from DynamoDB, updates the cache, and returns the data to the client

Ranking update processor

Messages in the SQS queue Processes score submissions from the queue Refreshes relevant leaderboard caches in ElastiCache Updates rankings in DynamoDB Publishes notifications to SNS if a player’s ranking has changed significantly

We decided to use DynamoDB to store player scores, profiles, and rankings. Table 17-2 lists the different tables and suggested schema. We could very well use a single-table design to store all the entities, as discussed in the previous use case chapters.

_Table 17-2. Amazon DynamoDB schema_

**Table name** **Partition key** **Sort key** **Additional attributes** Player Scores table Player ID Timestamp or game session ID

Score, metadata, region, etc.

Leaderboard table Leaderboard type (e.g., global, regional) with leaderboard ID, such as `Global#{leaderboardId}`

Rank (inverted for descending order)

Player ID, score, etc.

We’re also using Amazon ElastiCache for Redis as a caching and processing layer to reduce read latency for frequently accessed data with the following features:

_Leaderboard data cache_ Stores the top _N_ leaderboard entries to serve quick read requests

_Sorted sets_ Utilizes Redis sorted sets to maintain ordered lists of players based on their scores

_Cache invalidation_ Implements strategies to refresh or invalidate cached data when updates occur


_Performance_ Offers submillisecond latency for read operations

In place of Amazon ElastiCache and Amazon DynamoDB in the Day 0 architecture, we can use Amazon RDS to store the players’ data and use a combination of indexes and an `ORDER BY` query to retrieve the leaderboard.

In addition, SQS facilitates asynchronous processing of score submissions and decouples the score submission from the ranking update process. SNS is used to send notifications to players when significant events occur, such as changes in rankings. SNS receives notifications from the ranking update processor and forwards them to subscribed endpoints, such as mobile push notifications, email, or SMS. Table 17-3 describes flows in the architecture to summarize how the different components interact to achieve the needed functionality.

_Table 17-3. Implementation flows in the system architecture_

**Flow name** **Flow details** Score submission flow

The game client submits a score via the API Gateway. The API Gateway invokes the score submission handler Lambda function. The Lambda function validates the score and writes it to DynamoDB. A message is sent to the SQS queue for asynchronous ranking updates.

Ranking update flow

The ranking update processor Lambda function is triggered by messages in the SQS queue. It reads the new scores from DynamoDB. Rankings are recalculated, and the Leaderboard table in DynamoDB is updated. Relevant entries in ElastiCache are refreshed to reflect the new rankings. Notifications are sent via SNS if necessary.

Leaderboard retrieval flow

The game client requests leaderboard data via the API Gateway. The API Gateway invokes the leaderboard retrieval handler Lambda function. The Lambda function first checks ElastiCache for the requested data. If the data is not available or stale, it retrieves the information from DynamoDB, updates the cache, and returns the data to the client.

Now, let’s examine potential issues that might occur in the current architecture and suggestions for scaling it to millions of users.

### Scaling to Millions and Beyond

As our online game gains popularity and the player base grows from thousands to millions, our system architecture must evolve to handle the increased load while maintaining low latency and high availability. Scaling the leaderboard system involves identifying potential bottlenecks, optimizing components for high throughput, and leveraging AWS services designed for large-scale operations. Let’s discuss different


areas for improvement of the architecture, starting with the compute for deploying the systems.

**Compute**

Lambda as a compute option removes all the operational burden, but since it is fully managed, there are limited configuration options. There are certain limitations for allowed quota, but we can resolve them by requesting a higher concurrency limit from AWS or implementing efficient batching and throttling mechanisms within the application logic. Revisit “AWS Lambda” on page 286 in Chapter 11 for resolutions to problems like cold start with Lambda.

As the system grows, moving from Lambda functions to containerized services using AWS Fargate or Amazon ECS with EC2 might provide better performance and control. We discussed ECS in Chapter 11, but let’s reiterate some of the benefits we can achieve with it:

_Fine-grained resource management_ Allocate specific CPU and memory resources based on workload requirements

_Persistent connections_ Maintain persistent connections to databases and caches, reducing connection overhead

_Customization_ Customize runtime environments and optimize for specific application needs

We recommend configuring autoscaling policies for the compute resources, such as automatically adjusting the number of ECS tasks based on resource utilization. This helps handle scaling in and scaling out, and you pay for resources only when they are needed.

Another important consideration is storage for scaling out the architecture, which we’ll discuss next.

**Storage**

DynamoDB is an infinitely scalable database, and we recommend designing optimal query patterns to avoid issues like hot partitions and maintain submillisecond latency of DynamoDB invocations. We also recommend leveraging DynamoDB capabilities like on-demand capacity mode and provisioned capacity mode with autoscaling to avoid request throttling.

Caching and prefetching data become important mostly at peak hours for improving latency when retrieving leaderboard data. We discussed multiregion deployments in Chapter 16, and they can be leveraged here as well to increase resiliency and reduce application latency. Some other recommendations include:


- Employing techniques discussed in Chapter 4 like cache-aside or write-through • caching, which can improve data freshness and access speed

- Distributing data across multiple Redis nodes with Redis cluster mode, allowing • the cluster to store more data and handle higher throughput, which adds more shards to the cluster to increase capacity and enhances the fault tolerance via automatic failovers to replicas

- Using Global Datastore for cross-region replication of cached data, similar to • DynamoDB global tables

We’ve leveraged the leaderboard retrieval handler Lambda to support user read queries. Let’s discuss some improvements on this.

**Scaling data retrieval**

The logic for data updates is dependent on the fact that the user app is requesting leaderboard updates continuously. This is not scalable and can add to server loads. The more efficient approach here is to push the data from the server to the user devices instead of all the user devices pulling the data.

We discussed a similar architecture in “Scaling post comments” on page 430 in Chapter 16 that can be used here as well. We recommend using persistent connections for such use cases, which we also touch on in Chapters 6 and 19. We can have a custom implementation to manage these connections, as we do in Chapter 19, or we can leverage AWS AppSync for managed GraphQL service-to-pubs real-time updates to the clients over WebSocket connections.

We came up with the storage and bandwidth calculations based on read and write traffic assumptions. We can now use this information to calculate the cost that will be incurred to deploy the solution on the AWS cloud. One factor we often skip when developing software systems is the overall cost; instead, we just look at the cloud provider bills. Let’s discuss the _total cost of ownership (TCO)_ with respect to building any solution.

**Total cost of ownership**

The TCO is the cost associated with operating a product throughout its lifecycle. There are multiple components of TCO, as shown in Figure 17-3, and each component has an associated cost. We should understand each component to get a complete view of the cost for building and launching a product, starting with the initial costs.


![](../images/system_design_on_aws_page_0479_2.png)

_Figure 17-3. Product lifecycle in the context of TCO_

**Initial costs.   ** As you plan the initial software launch, there is a setup cost for software operations. This includes cloud provider costs for infrastructure (such as EC2, Lambda, etc.), networking (such as NAT gateway), AuthN and AuthZ (such as Cognito), security (such as Shield or WAF) and CI/CD (such as CodePipeline for continuous software delivery and GitHub or CodeCommit for hosting code with version control). There can also be costs related to security and compliance certifications or other services used from a cloud provider depending on the needs, such as Redshift for analytics and CloudWatch for monitoring.

Apart from direct costs paid to a cloud provider or other vendors, there are indirect expenses associated with the launch of the software, such as hiring DevOps engineers to help with infrastructure deployment and software engineers to design and write the business logic code. If the newly designed software is replacing existing software, there is the added cost of building intermediary solutions for traffic and data migration.

We recommend using freely available tools for forecasting the expenses to be incurred depending on the system scale calculations, such as the AWS Pricing Calculator. Take the AWS region into consideration when calculating the costs since the prices of different AWS services vary based on the region. We will try to calculate the cost on AWS for the suggested scale given in “System Scale” on page 444. Note that these example costs are calculated using the Pricing Calculator and are for reference only.

For the storage cost calculation, we used a storage requirement of 750 GB/month, an average read TPS of 231, and an average write TPS of 167. Let’s calculate the cost of DynamoDB with these numbers for the us-east-1 region and on-demand capacity mode selection. The total cost comes out to be $812 per month (note that we have


not included costs for additional features, such as backups, DynamoDB streams, and GSIs):

Average item size (all attributes): 500 Byte = 0.48828125 KB

Total storage requirement = 750 GB

Total data storage cost = 750 GB × $0.25 = $187.50

DynamoDB data storage cost (monthly): $187.50

Monthly write cost (monthly): $548.60

Monthly read cost (monthly): $75.88

In the Day N architecture (see Figure 17-4 in that section), the system exposes APIs via API Gateway for the write traffic and leverages AWS AppSync for reads. Let’s calculate the cost for API Gateway. The total cost comes out to be $1,462 per month, assuming a single REST API for writes and without any caching capability to cache the responses:

Average write TPS = 167

Total monthly write requests = (167 × 60 × 60 × 24 × 365)/12 = 438,876,000 total REST API requests

Tiered price for: 438,876,000 requests

333,000,000 requests × $0.0000035 = $1,165.50

105,876,000 requests × $0.0000028 = $296.45

Total tier cost: $1,165.50 + $296.45 = $1,461.9528

For networking infrastructure on the AWS cloud, there is no direct cost associated with the creation of the VPC, and the pricing depends on the associated features we use, such as:

_NAT gateways_ The pricing depends on the number of NAT gateways and the data processed per NAT gateway. For example, a $38 cost is incurred for one NAT gateway processing 100 GB data per month in the us-east-1 region.

_Outbound data transfer_ The outbound data transfer pricing depends on where the data is transferred. For example, it costs $9 to transfer 100 GB per month to the internet, and the cost is zero for transferring to CloudFront.


Similarly, we can calculate pricing for other services being used in the architecture. Let’s discuss operational costs next.

**Operational costs.   ** Once you launch the software, it runs continuously to serve customer traffic (or the build for any organization’s use case). You pay for running this software in the cloud for existing or newly increasing traffic. Here are a few examples of AWS services used in the architecture:

- Amazon CloudWatch for storing logs and metrics •

- Data storage cost with managed services •

- Introduction of capabilities to expand the infrastructure with scale •

You pay based on instance size with RDS, but you can also choose a pay-as-you-go pricing model to pay only for the actual usage with solutions like Amazon DynamoDB and Amazon Aurora Serverless. There can be additional costs associated with storage, such as managing backups in Amazon S3 and data caching in Amazon ElastiCache. We often skip these calculations in the beginning, but they add up as the system scales.

Other operational costs include improving the existing software to resolve any existing tech debts or introducing new features.

**Maintenance costs.   ** We’ve discussed multiple options for deploying software applications with respect to compute and databases. We can choose to deploy the entire architecture on bare-metal servers or to use AWS managed services like Lambda and DynamoDB. This aspect of management falls under maintenance costs, as do system upgrades (security vulnerability fixes or newer version upgrades of software dependencies).

We’ve also discussed AWS managed services that are automatically deployed in multiple AZs, removing the headache of disaster management from the customer. We recommend selecting services based on previous expertise; for example, if there is already a team managing infrastructure for other applications in the company, the same team can manage infrastructure for the new applications.

**Support and scaling costs.   ** We strive for 100% application availability, but this doesn’t really happen in the real world, and errors are bound to happen. The system might be completely down or not working per the expectations of some of the customers. Generally, the organization has incident management mechanisms to address such queries. Some examples of these mechanisms include answering user queries via AI chatbots and raising incident tickets for the engineering team (or support team) to look into. There is a cost associated with maintaining these end-to-end mechanisms,


such as paying Atlassian for Jira (ticket lifecycle) and Opsgenie (on-call and alert management). Apart from all this, there is someone dedicating time to look into these issues, which incurs costs to the organization.

We design systems with the hope that they will be used by millions of customers (in an iterative way), but the system demands additional infrastructure to support the scale. The scaling costs can also be considered part of operational costs since scaling is needed for system operations. Increasing scale can be supported in two ways:

- The existing infrastructure is expanded by adding more servers. •

- The existing system becomes a bottleneck and requires a rearchitecture to scale • further.

Both of these approaches have costs associated with them, and regular examinations into the reasons for system bottlenecks can help you decide which solution works best.

**Retirement costs.   ** We mentioned that the existing system can become a bottleneck, so we plan for redesigning the system. Sunsetting an existing system and moving to the new system comes with migration costs. We discussed strategies for moving from Day 0 architecture to Day N architecture in Chapter 16.

We should take a holistic view to figure out the costs associated with a system to avoid any surprises. Returning to the system architecture discussion, we’ll look at the Day N architecture for our system next.

### Day N Architecture

Scaling the system requires reevaluating each component to ensure that it can handle the projected load. Figure 17-4 illustrates the scaled architecture for our online game leaderboard system.

To ensure that the online game leaderboard system is robust, scalable, and capable of handling millions of users with high performance, low latency, and strong security, it’s critical to adopt best practices across various architecture components. Let’s discuss implementation in Redis first.


![](../images/system_design_on_aws_page_0483_3.png)

_Figure 17-4. Scaled architecture for online game leaderboard system on AWS_

**Scaling Redis**

In-memory data stores like Redis should also be sharded by leveraging Redis Cluster, allowing data to spread across multiple nodes. This setup ensures that requests are balanced and that read and write operations are processed efficiently. The ranking in the leaderboard is calculated using sorted sets in Redis based on scores that are processed and submitted by the score submission service, picked from the SQS queue. Redis will operate as a single node in the Day 0 architecture but can be set up as Redis HA or Redis Cluster with a primary-secondary setup to handle large leaderboard sorted sets. The primary will serve as a sticky server for the involved players for “read your write” consistency; the secondary will be updated using replication, leading to eventual consistency. You can review Redis’s setup for distributed handling in Chapter 4.


Redis sorted sets can efficiently store and manage leaderboard data and allow it to be queried for a high volume of player scores in the Day N architecture. Here is how it will work:

- Each time a user submits a new score, it’s added to a Redis sorted set using the • command `ZADD <leaderboardId> <score> <userId>`.

- To retrieve and display the leaderboard’s top one hundred users, use `ZREVRANGE` • `<leaderboardId> 0 99`, which retrieves the highest scores efficiently, even with millions of users and updates per minute.

- To get a specific user’s rank, call `ZRANK <leaderboardId> <userId>`, which • provides the user’s current position based on score.

Redis sorted sets allow for more than just top scores or global rank; you can also show scores of users near a specific user’s rank, creating a localized leaderboard view.

Now, let’s discuss a few general recommendations for the architecture to ensure smooth operations and optimal performance.

**System considerations**

An effective caching strategy is key to reducing latency and enhancing read performance. We advise using hierarchical caching that includes multiple layers, such as client-side caching, edge caching with services like Amazon CloudFront, and server-side caching with Amazon ElastiCache. The server-side caching can be divided into further layers, such as request level caching accessible over a lifetime of user request, instance level (or kubernetes pod level) caching accessible to all the requests of an server instance and distributed caching accessible to all the requests across the application instances. This multilayered caching ensures that the most frequently accessed data is served quickly, thereby reducing the load on primary databases and improving user experience.

By implementing these scaling strategies and best practices, we can design an online game leaderboard system that will be well equipped to handle millions of users while maintaining high performance, low latency, and robust security. Leveraging AWS’s scalable services allows us to focus on delivering an exceptional gaming experience, confident that the underlying infrastructure can support the demands of a global player base.

Be sure to set up monitoring and logging for CPU usage, memory consumption, error rates, and latency alerts, as well as anomaly detection to identify unusual patterns using CloudWatch. For security, conduct regular access reviews to verify that IAM policies and access logs are up to date and reflect current needs.

Last, for disaster recovery, the system should define an RPO and an RTO, which outline the acceptable limits for data loss and downtime, respectively, and should be


tested with recovery procedures to ensure these SLAs. Enable point-in-time recovery for continuous backups of Amazon DynamoDB and schedule automatic snapshots of Redis data on Amazon ElastiCache.

## Conclusion

Designing an online game leaderboard system requires a careful balance between technical requirements and an understanding of player behavior. By starting with a simple architecture and progressively optimizing it, we can build a system capable of scaling from thousands to millions of users while maintaining low latency and high availability. Throughout this chapter, we emphasized the importance of efficient data modeling, scalable storage solutions, and effective leveraging of AWS services.

We explored how to evolve our architecture as the system grows, transitioning from basic components like AWS Lambda and Amazon DynamoDB to more advanced solutions, such as DynamoDB global tables, Redis clusters, and containerized services. This progression mirrors how systems often start simply and adapt over time to meet new requirements and handle increased load. By applying best practices, such as proper data partitioning, caching strategies, and continuous monitoring, we ensure the system remains robust and efficient.

Security and disaster recovery were integral to our design, emphasizing the need for fine-grained access controls, data encryption, and multiregion failover strategies. Leveraging AWS’s scalable infrastructure and services allows us to focus on delivering an engaging user experience, confident that the underlying system can support a global player base.

In the next chapter, we’ll delve into designing a hotel reservation system.


