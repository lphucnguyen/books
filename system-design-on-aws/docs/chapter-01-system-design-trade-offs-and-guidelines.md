# Chapter 1: System Design Trade-offs and Guidelines

Today’s modern technological revolution is happening because of large-scale software systems. Big enterprise companies like Google, Amazon, Oracle, and SAP have all built large-scale software systems to run their (and their customers’) businesses. Building and operating such large-scale software systems requires first-principles thinking to design and develop the technical architecture before actually putting the system into code. This is because we don’t want to be in a state where these systems will not work or scale as more users need them.

If the design is right in the first place, the rest of the implementation journey becomes smooth. This requires looking at the business requirements, understanding the needs and objectives of the customer, evaluating different trade-offs, thinking about error handling and edge cases, and contemplating future changes and robustness while worrying about basic details like algorithms and data structures. Enterprises can avoid the mistake of wasted software-development effort by carefully thinking about systems and investing time in understanding bottlenecks, system requirements, users being targeted, user access patterns, and many such decisions, which, in short, is _system design_.

This chapter covers the basics of system design with the goal of helping you understand the fundamental concepts, the trade-offs that naturally arise in such large-scale software systems, the fallacies to avoid in building such systems, and the guidelines of system design—those lessons that have been learned from building large-scale software systems over the years. This chapter is intended to introduce you to the essentials—we’ll dig into the details in later chapters, but we want you to have a good foundation to start. Let’s begin with the basic concepts of system design.


## CHAPTER 1 System Design Trade-offs and Guidelines: System Design Concepts

To understand the building blocks of system design, we should understand the fundamental concepts around systems. We can leverage_ abstraction_ here: the concept in computer science of obfuscating the inner details to create a model of these system design concepts, which can help us grasp the bigger picture. The concepts in system design, be it any software system, revolve around communication, consistency, availability, reliability, scalability, system maintainability, and fault tolerance. We will go over each of these concepts in detail, creating a mental model while also exploring how they are applied in large-scale system design.

### Communication

A large-scale software system is composed of small subsystems, known as _servers_, that communicate with one another—that is, they exchange information or data over the network to solve a business problem, provide business logic, and compose functionality. Communication can take place in either a synchronous or an asynchronous fashion, depending on the needs and requirements of the system. Figure 1-1 shows the differences in the sequence of actions in synchronous and asynchronous communication.

We will cover the communication protocols as well as mechanisms for asynchronous communication in detail in Chapter 6.


![](../images/system_design_on_aws_page_0029_0.png)

_Figure 1-1. Sequence diagram for synchronous versus asynchronous communication_

**Synchronous communication**

Imagine having a phone conversation with your friend: you hear them and speak with them at the same time and use pauses in between to allow the conversation to complete. This is an example of _synchronous communication_: a type of communication in which two or more parties communicate with one another in real time. This type of communication is more immediate and allows for quicker resolution of issues or questions.

In system design, a communication mechanism is synchronous when the sender will block (or wait) for the call or execution to return before continuing. This means that until a response is returned by the receiver, the application will not execute any further, which could be perceived by the user as latency or performance lag in the application.


**Asynchronous communication**

Now, imagine that instead of a phone conversation, you switch to email. As you communicate over email with your friend, you send the message and wait for the reply to come at a later time (but within an acceptable time limit). You also follow a practice to follow up if there is no response after this time limit has passed. This is an example of _asynchronous communication_: a type of communication in which two or more parties do not communicate with one another in real time. Asynchronous communication can also take place through messaging platforms, forums, and social media, where users can post messages and responses may not be immediate.

In system design, a communication mechanism is asynchronous when the sender does not block (or wait) for the call or execution to return from the receiver. Execution continues in your program or system, and when the call returns from the receiving server, a _callback_ function is executed. Asynchronous communication is often used in system design when an immediate response is not required or when the system needs to be more flexible and tolerant of delays or failures.

In general, the choice of synchronous or asynchronous communication in system design depends on the specific requirements and constraints of the system. Synchronous communication is often preferred when real-time response is needed (such as the communication between the frontend UI and the backend), while asynchronous communication is often preferred when flexibility and robustness are more important (such as checking the status of a long-running job).

### Consistency

_Consistency_—being consistent or in accordance with a set of rules or standards—is an important requirement when it comes to communication between servers in a software system. Consistency can refer to a variety of concepts and contexts in system design.

In the context of distributed systems, consistency can be the property of all _replica_ nodes (more on this in a moment) or servers having the same view of data at a given point in time. This means that all replica nodes have the same data, and any updates to the data are immediately reflected on all replica nodes.

In the context of data storage and retrieval, consistency refers to the property of each read request returning the value of the most recent write. This means that if a write operation updates the value of a piece of data, any subsequent read requests for that data should return the updated value. Let’s discuss each of these in more detail.

**Consistency in distributed systems**

_Distributed systems_ are software systems that are separated physically but connected over the network to achieve common goals using shared computing resources.


Ensuring consistency—that is, providing the same view of the data to each server in a distributed system—can be challenging because multiple replica servers may be in different physical locations and may be subject to different failures or delays.

To address these challenges and ensure data consistency in distributed systems, we can use various techniques:

_Data replication_ In this approach, multiple copies of the data are maintained on different replica nodes, and updates to the data are made on all replica nodes simultaneously through blocking synchronous communication. This ensures that all replica nodes have the same view of the data at any given time.

_Consensus protocols_ Consensus protocols ensure that all replica nodes agree on the updates to be made to the data. They can use a variety of mechanisms, such as voting or leader election, to make sure all replica nodes are in agreement before updating the data.

_Conflict resolution_ If two or more replica nodes try to update the same data simultaneously, conflict resolution algorithms are used to determine which update should be applied. These algorithms can employ various strategies, such as last writer wins or merge algorithms, to resolve conflicts.

**Consistency in data storage and retrieval**

Large-scale software systems produce and consume a large amount of data, and thus, ensuring consistency in data storage and retrieval is important for maintaining the accuracy and integrity of the data in these systems. For example, consider a database that stores the balance of a bank account. If we withdraw money from the account, the database should reflect the updated balance immediately. If the database does not ensure consistency, it is possible for a read request to return an old balance, which could lead to incorrect financial decisions or even financial losses for us or our banks.

To address these challenges and ensure read consistency in data storage systems, we can use various techniques:

_Write-ahead logging_ In this technique, writes to the data are first recorded in a log before they are applied to the actual data. This ensures that if the system crashes or fails, the data can be restored to a consistent state by replaying the log.


_Locking_ Locking mechanisms are used to ensure that only one write operation can be performed at a time. This ensures that multiple writes do not interfere with one another and that reads always return the value of the most recent write.

_Data versioning_ In this technique, each write operation is assigned a version number, and reads always return the value of the most recent version. This allows for multiple writes to be performed concurrently while still ensuring that reads return the value of the most recent write.

We will discuss some of these techniques for ensuring consistency in detail in Chapters 2 and 3.

**Consistency spectrum model**

Since consistency can mean different things, the _consistency spectrum model_ helps us reason about whether a distributed system is working correctly when it’s doing multiple things at the same time, like reading, writing, and updating data. The consistency spectrum model represents the various consistency guarantees that a distributed system can offer, ranging from eventual consistency to strong consistency. The consistency guarantee chosen depends on the specific requirements and constraints of the system. Let’s walk through the consistency levels in the consistency spectrum model:

_Strong consistency_ At one end of the spectrum, strong consistency guarantees that all replica nodes have the same view of the data at all times and that any updates to the data are immediately reflected on all replica nodes. This ensures that the data is always accurate and up to date, but it can be difficult to achieve in practice as it requires all replica nodes to be in constant communication with one another.

We will cover the strong consistency requirements of relational databases as part of the ACID model in Chapter 2.

_Monotonic read consistency_ Monotonic read consistency guarantees that once a client has read a value from a replica node, all subsequent reads from that client will return the same value or a more recent value. This means that a client will not see “stale” data that has been


updated by another client. This provides a stronger consistency guarantee than eventual consistency because it ensures that a client will not see outdated data.

_Monotonic write consistency_ Monotonic write consistency guarantees that once a write operation has been acknowledged by a replica node, all subsequent reads from that replica node will return the updated value. This means that a replica node will not return outdated data to clients after a write operation has been acknowledged. This provides a stronger consistency guarantee than eventual consistency because it ensures that a replica node will not return outdated data to clients.

_Causal consistency_ Causal consistency works by categorizing operations into dependent and independent operations. Dependent operations are also called _causally related opera‐_ _tions_. Causal consistency preserves the order of the causally related operations. It guarantees that if two operations are causally related in dependent and independent operations, then they will be seen in the same order by all processes in the system. This means that if operation A must happen before operation B, then all processes in the system will see A before they see B. This provides a stronger consistency guarantee than eventual consistency because it ensures that the order of related operations is preserved.

_Eventual consistency_ At the other end of the spectrum, eventual consistency guarantees that, given enough time, all replica nodes will eventually have the same view of the data. This allows for more flexibility and tolerance of delays or failures but can result in temporary inconsistencies in the data.

We will cover the tunable consistency feature of some of the nonrelational columnar databases like Cassandra in Chapter 3.

Figure 1-2 shows the difference in the results of performing a sequence of actions under either strong consistency or eventual consistency. As you can see on the left showing strong consistency, when _x_ is read from a replica node after updating it from 0 to 2, it will block the request until replication happens and then return 2 as the result. On the right illustrating eventual consistency, you can see that when the replica node is queried, it will give a stale result of _x_ as 0 before replication completes.

The consistency spectrum model therefore provides a framework for understanding the trade-offs between consistency and availability in distributed systems and helps system designers choose the appropriate consistency guarantee for their specific needs.


![](../images/system_design_on_aws_page_0034_1.png)

_Figure 1-2. Sequence diagrams for strong consistency and eventual consistency_

The level of consistency that a distributed system aims to achieve directly affects its complexity: stricter consistency models (like strong consistency) require extensive coordination, synchronization, and consensus across nodes, increasing latency and operational costs and making failure handling more challenging. This complexity is especially pronounced in geographically distributed systems, where network latency and scalability constraints complicate synchronization of global data. Conversely, relaxing consistency requirements (as in eventual consistency) reduces system complexity, enabling higher scalability and availability at the cost of allowing temporary data inconsistencies. Ultimately, there’s a trade-off between data accuracy and system simplicity, with each choice tailored to the specific needs and tolerance for latency, availability, and correctness in the application.


### Availability

In a large-scale software system, subsystems or servers can go down and may not be fully available to respond to the client’s requests; this is referred to as the system’s _availability_. A system that is highly available can process requests and return responses in a timely manner, even under heavy load or when there are failures or errors. Let’s try to quantify the measurement of availability of the system.

**Measuring availability**

Availability can be measured mathematically as the percentage of the time the system was up (total time − time system was down) over the total time the system should have been running:

Availability % = Total Time −Sum total of time system was down

Total Time × 100

Availability percentages are represented in nines based on this formula over a period of time. You can see a breakdown of what these numbers really work out to in Table 1-1.

_Table 1-1. Availability percentages represented in nines_

**Availability percentage** **Downtime per year** **Downtime per month** **Downtime per week** 90% (1 nine) 36.5 days 72 hours 16.8 hours

99% (2 nines) 3.65 days 7.2 hours 1.68 hours

99.5% (2 nines) 1.83 days 3.60 hours 50.4 minutes

99.9% (3 nines) 8.76 hours 43.8 minutes 10.1 minutes

99.99% (4 nines) 52.56 minutes 4.32 minutes 1.01 minutes

99.999% (5 nines) 5.26 minutes 25.9 seconds 6.05 seconds

99.9999% (6 nines) 31.5 seconds 2.59 seconds 0.605 seconds

99.99999% (7 nines) 3.15 seconds 0.259 seconds 0.0605 seconds

The goal for availability usually is to achieve the highest level possible, such as “five nines” (99.999%) or even “six nines” (99.9999%). However, the level of availability that is considered realistic or achievable depends on several factors, including the complexity of the system, the resources available for maintenance and redundancy, and the specific requirements of the application or service.

Achieving higher levels of availability becomes progressively more challenging and resource intensive. Each additional nine requires an exponential increase in redundancy, fault-tolerant architecture, and rigorous maintenance practices. It often involves implementing redundant components, backup systems, load balancing,


failover mechanisms, and continuous monitoring to minimize downtime and ensure rapid recovery in case of failures.

While some critical systems, such as financial trading platforms or emergency services, may strive for the highest levels of availability, achieving and maintaining them can be extremely difficult and costly. In contrast, for less critical applications or services with a lower level of availability, such as 99% or 99.9%, may be more realistic and achievable within reasonable resource constraints.

Ultimately, determining what level of availability is realistic and achievable depends on a careful evaluation of the specific requirements, resources, costs, and trade-offs involved in each case.

**Availability in parallel versus in sequence**

The availability of a system that consists of multiple subsystems depends on whether the components are arranged in sequence or in parallel with respect to serving the request. Figure 1-3 shows the arrangement of components in the sequential system on the left, where the request needs to be served from each component in sequence, and the parallel system on the right, where the request can be served from either component in parallel.

![](../images/system_design_on_aws_page_0036_2.png)

_Figure 1-3. Sequential system versus parallel system_

If the components are in sequence, the overall availability of the service will be the product of the availability of each component. For example, if two components with 99.9% availability are in sequence, their total availability will be 99.8%:

Availability of two components in sequence = Availability of component 1 × Availability of component 2 = . 999 × . 999 = . 998001 ∼99 . 8 %


On the other hand, if the components are in parallel, the overall availability of the service will be the sum of the availability of each component minus the product of their unavailability. For example, if two components with 99.9% availability are in parallel, their total availability will be 99.9999%. This can lead to significantly higher availability compared to the same components arranged in sequence (from 3 nines to 6 nines in the example):

Availability of two components in parallel = 1 −Unavailability of both components = 1 −P(Component 1 going down × P(Component 2 going down = 1 −.001 × .001 = 1 −.000001 = .999999 ∼99.9999 %

The arrangement of components in a service can have a significant impact on its overall availability, so it is important to consider this when designing a system for high availability.

**Ensuring availability**

Ensuring availability in a system is critical for maintaining the performance and reliability of the system. There are several ways to increase the availability of a system:

_Redundancy_ When a system has multiple copies of critical components or subsystems, it can continue to function even if one component fails. This can be achieved by using redundant load balancers, failover systems, or replicated data stores.

_Fault tolerance_ Systems designed to be resistant to failures or errors can continue to function even when there are unexpected events. This can be achieved by using errorhandling mechanisms, redundant hardware, or self-healing systems.

_Load balancing_ By distributing incoming requests among multiple servers or components, a system can more effectively handle heavy loads and maintain high availability. This can be achieved by using multiple load balancers or distributed systems.

We will cover load balancing in detail in Chapter 5 and explore the different types of AWS load balancers in Chapter 9.


**Availability patterns**

There are two major complementary patterns to support high availability: failover and replication.

**Failover patterns.   ** _Failover _refers to the process of switching to a redundant or backup system in the event of a failure or error in the primary system. The failover pattern chosen depends on the specific requirements and constraints of the system, including the desired level of availability and the cost of implementing the failover solution. The two main types of failover patterns are active-active and active-passive:

_Active-active failover_ In an active-active failover pattern, as shown on the left in Figure 1-4, multiple systems are used in parallel, and all systems are actively processing requests. If one system fails, the remaining systems can continue to process requests and maintain high availability. This approach allows for more flexibility and better utilization of resources but can be more complex to implement and maintain because it requires more sophisticated load balancing and failover mechanisms.

_Active-passive failover_ In an active-passive failover pattern, as shown on the right in Figure 1-4, one system is designated as the primary system and actively processes requests while one or more backup systems are maintained in a passive state. If the primary system fails, the backup system is activated to take over processing of requests. This approach is simpler to implement and maintain because data only needs to be replicated in one direction: from the active server to the passive server. It also avoids the complexities of data conflicts and the synchronization issues that can occur in an active-active setup. However, this can result in reduced availability if the primary system fails, as there is a delay in switching to the backup system.

Failover patterns can require additional hardware and can add complexity to the system. There is also the potential for data loss if the active system fails before newly written data can be replicated to the passive system. The choice of failover pattern depends on the specific requirements and constraints of the system, including the desired level of availability and the cost of implementing the failover solution.

These failover patterns are employed in relational data stores, nonrelational data stores, caches, and load balancers, which we will cover in Chapters 2, 3, 4, and 5, respectively.


![](../images/system_design_on_aws_page_0039_3.png)

_Figure 1-4. Active-active failover system setup versus active-passive failover system setup_

**Replication patterns.   ** _Replication_ is the process of maintaining multiple copies of data or other resources to improve availability and fault tolerance. The replication pattern chosen depends on the specific requirements and constraints of the system, including the desired level of availability and the cost of implementing the replication solution. The two main types of replication patterns are multileader and single leader:

_Multileader replication_ In a multileader replication pattern, as shown on the left in Figure 1-5, multiple systems are used in parallel, and all systems can read and write data. This allows for more flexibility and better utilization of resources because all systems can process requests and updates to the data simultaneously. A load balancer is required or application logic changes need to be made to support multiple leaders and identify on which leader node to write. Most multileader systems either are loosely consistent or have increased write latency for synchronization to remain consistent. Conflict resolution comes more into play as more write nodes are added, leading to increases in latency. This approach can become complex to implement and maintain because it requires careful management of conflicts and errors.

_Single-leader replication_ In a single-leader replication pattern, as shown on the right in Figure 1-5, one system is designated as the leader system and is responsible for both reading and writing data while one or more follower systems are used to replicate the data. The follower systems can be used only for reading data; updates to the data must be made on the leader system. Additional logic is required to be implemented to promote a follower to the leader. This approach is simpler to implement and


maintain but can result in reduced availability if the leader system fails because updates to the data can be made only on the leader system and there is a risk of losing the data updates.

![](../images/system_design_on_aws_page_0040_4.png)

_Figure 1-5. Multileader versus single-leader replication system setup_

There is a risk of data loss if the leader system fails before newly written data can be replicated to other nodes. The more read replicas that are used, the more writes need to be replicated, which can lead to greater replication lag. In addition, using read replicas can affect the performance of the system because the system may get bogged down with replaying writes and become unable to process as many reads. Furthermore, replication can require additional hardware that can add complexity to the system. Finally, some systems may have more efficient write performance on the leader system since it can spawn multiple threads to write in parallel, while read replicas may only support writing sequentially with a single thread. The choice of replication pattern depends on the specific requirements and constraints of the system, including the desired level of availability and the cost of implementing the replication solution.

We will cover how relational and nonrelational data stores ensure availability using single-leader and multileader replication in Chapters 2 and 3. Do look out for leaderless replication using consistent hashing to ensure availability in nonrelational stores like key-value stores and columnar stores in Chapter 3.


### Reliability

In system design, _reliability_ refers to the ability of a system or component to perform its intended function consistently and without failure over a given period of time. It is a measure of the dependability or trustworthiness of the system. Reliability is typically expressed as a probability or percentage of time that the system will operate without failure. For example, a system with a reliability of 99% will fail only 1% of the time. Let’s try to quantify the measurement of reliability of the system.

**Measuring reliability**

One way to measure the reliability of a system is by using mean time between failures (MTBF) and mean time to repair (MTTR).

**Mean time between failures.   ** MTBF is a measure of the average amount of time that a system can operate without experiencing a failure. It is typically expressed in hours or other units of time. The higher the MTBF, the more reliable the system is considered to be:

Mean time between failures (MTBF)

= Total Elapsed Time −Sum total of time system was down

Total Number of Failures

For mission-critical systems, an MTBF of tens of thousands of hours or more is generally desired, while consumer electronics may have lower MTBF values. For example, high-reliability servers typically aim for an MTBF of 50,000 hours or more; consumer-grade laptops may have an MTBF of around 5,000−10,000 hours.

MTBF helps estimate the frequency of failures, allowing for better planning and budgeting of maintenance activities. If MTBF is low for a critical component, redundancy can be implemented to minimize downtime. In high-availability setups, multiple servers or components with lower MTBFs may be clustered to achieve overall reliability. As MTBF increases with design changes, you can quantitatively assess reliability improvements, ultimately leading to fewer failures and reduced operational costs.

**Mean time to repair.   ** MTTR is a measure of the average amount of time it takes to repair a failure in the system. It is also typically expressed in hours or other units of time. The lower the MTTR, the more quickly the system can be restored to operation after a failure:

Mean time to repair (MTTR) = Total Maintenance Time

Total Number of Repairs


Together, MTBF and MTTR can be used to understand the overall reliability of a system. For example, a system with a high MTBF and a low MTTR is considered to be more reliable than a system with a low MTBF and a high MTTR as it is less likely to experience failures and can be restored to operation more quickly when failures do occur.

**Reliability and availability**

It is important to note that reliability and availability are not mutually exclusive. A system can be both reliable and available, or it can be neither. A system that is reliable but not available is not particularly useful since it may be reliable but not able to perform its intended function when needed. A system that is available but not reliable is also not useful since it may be able to perform its intended function when needed, but it may not do so consistently or without failure.

To achieve high reliability and availability to meet agreed service-level objectives (SLOs), it is important to design and maintain systems with redundant components and robust failover mechanisms. Performing maintenance and testing regularly also ensures that the system is operating at its optimal level of performance. In general, the reliability of a system is an important consideration in system design because it can affect the performance and availability of the system over time.

SLOs and goals, including change management, problem management, and service request management, of AWS Managed Services (which will be introduced in Part II) are provided in the AWS documentation.

### Scalability

In system design, we need to ensure that the performance of the system increases with the resources added based on the increasing workload, which can be either request workload or data storage workload. This is referred to as _scalability_ in system design, which requires the system to respond to increased demand and load. For example, a social network needs to scale with the increasing number of users as well as the content feed on the platform that it indexes and serves.

The two major complementary patterns to scale a system are vertical scaling and horizontal scaling:

_Vertical scaling_ Vertical scaling involves meeting the load requirements of the system by increasing the capacity of a single server by upgrading it with more resources (CPU, RAM, graphics processing units, storage, etc.), as shown on the left in Figure 1-6. Vertical scaling is useful when dealing with predictable traffic since it allows


for more resources to be used to handle the existing demand. However, there are limitations to how much a single server can scale up based on its current configuration. The cost of scaling up is also generally high as adding more higher-end resources to the existing server will require a greater investment.

_Horizontal scaling_ Horizontal scaling involves meeting the load requirements of the system by increasing the number of the servers by adding more commodity servers to serve the requests, as shown on the right in Figure 1-6. Horizontal scaling is useful when dealing with unpredictable traffic because there is increased capacity to handle more requests, and if demand arises, more servers can be added to the pool cost-effectively. Although horizontal scaling provides a better cost proposition for scaling, the complexity of managing multiple servers and ensuring that they work collectively as an abstracted single server to handle the workload is the catch here.

![](../images/system_design_on_aws_page_0043_5.png)

_Figure 1-6. Vertical scaling versus horizontal scaling_

We will cover both scaling approaches and mechanisms in detail in Chapter 5.

In early-stage systems, you can start scaling up by vertically scaling the system and adding better configurations to it. Later, when you hit the limitation in scaling up, you can move to horizontally scaling the system.

### Maintainability

In system design, _maintainability_ is the system’s ability to be modified, adapted, or extended to meet the changing needs of its users while ensuring smooth operations. For a software system to be maintainable, it must be designed to be flexible and easy to modify or extend. Maintainability involves these three underlying aspects of the system:


_Operability_ This requires the system to operate smoothly under normal conditions and even return to normal operations within a stipulated time after a fault. When a system is maintainable in terms of operability, that reduces the time and effort required to keep the system running smoothly. This is important because efficient operations and management contribute to overall system stability, reliability, and availability.

_Lucidity_ This requires the system to be simple and clear to understand, to extend by adding features, and even to fix bugs. When a system is lucid, that enables efficient collaboration among team members, simplifies debugging and maintenance tasks, and facilitates knowledge transfer. It also reduces the risk of introducing errors during modifications or updates.

_Modifiability_ This requires the system to be built in a modular way to allow it to be changed and extended easily, without disrupting the functionality of other subsystems. Modifiability is vital because software systems need to evolve to adapt to new business needs, technological advancements, or user feedback. A system that lacks modifiability can become stagnant, resistant to change, and difficult to enhance or adapt to future demands.

By prioritizing maintainability, organizations can reduce downtime, lower maintenance costs, enhance productivity, and increase the longevity and value of their software systems.

### Fault Tolerance

Large-scale systems generally employ a large number of servers and storage devices to handle and respond to user requests and store data. _Fault tolerance_ requires the system to recover from any failure (either hardware or software failure) and continue to serve the requests. This means avoiding single points of failure in a large system and being able to reroute requests to functioning subsystems to complete the workload.

Fault tolerance needs to be supported at hardware as well as software levels while ensuring data safety—that is, making sure the data is not lost. The two major mechanisms to ensure data safety are replication and checkpointing.

**Replication**

Replication-based fault tolerance ensures both data safety and serving the request by replicating the service through multiple replica servers and replicating the data as multiple copies across multiple storage servers. During a failure, the failed node is swapped with a fully functioning replica node. Similarly, data is served again from


a replica store in case the data store has failed. We discussed replication patterns in “Availability” on page 13.

**Checkpointing**

Checkpointing-based fault tolerance ensures that data is reliably stored and backed up, even after the initial processing is completed. It allows for a system to recover from any potential data loss by restoring a previous system state and preventing data loss. Checkpointing is commonly used to ensure system and data integrity, especially when dealing with large datasets. It can also be used to verify that data is not corrupted or missing because it can quickly detect any changes or issues in the data and then take corrective measures. Checkpointing is an important tool for data integrity, reliability, and security.

Recovery managers of databases use checkpointing to ensure the durability and reliability of the database in the event of failures or crashes. This will be covered in detail in Chapter 2.

Checkpointing can be done using either synchronous or asynchronous mechanisms:

_Synchronous checkpointing_ Synchronous checkpointing in a system is achieved by stopping all the data mutation requests and allowing only read requests while waiting for the checkpointing process to complete for the current data mutation. This always ensures a consistent data state across all the nodes.

_Asynchronous checkpointing_ Asynchronous checkpointing in a system is done by checkpointing asynchronously on all the nodes while continuing to serve all the requests (including data mutation requests) without waiting for the acknowledgment of the checkpointing process to complete. This mechanism suffers from the possibility of having an inconsistent data state across the servers.

In checkpointing-based fault tolerance, recovery time objective (RTO) and recovery point objective (RPO) are key metrics that help define the effectiveness of data recovery and system reliability:

_Recovery point objective_ RPO defines the maximum acceptable amount of data loss measured in time. It represents how much data a system can afford to lose before that significantly affects operations. In checkpointing, RPO determines how frequently checkpoints should be created. For instance, if the RPO is set to 15 minutes, the system should take a checkpoint every 15 minutes to ensure that no more than


15 minutes’ worth of data is lost during recovery. A smaller RPO (more frequent checkpoints) provides better data protection but can increase system load and storage requirements. For large datasets, achieving a low RPO requires efficient data storage and fast checkpointing.

_Recovery time objective_ RTO specifies the maximum acceptable downtime following a failure, indicating how quickly the system should be restored to operational status. Checkpointing helps reduce RTO by allowing the system to resume from the most recent checkpoint rather than restarting from scratch. Faster recovery time is critical when handling large datasets or processing real-time data, where any downtime can impact users or services. The effectiveness of checkpointing on RTO depends on the ease of restoring data from the checkpoint and the system’s ability to resume operations quickly without extensive reprocessing.

You should now understand the basic concepts and requirements of a large-scale system. We strive toward building a performant and scalable system—one that is also highly available, reliable, maintainable, and fault tolerant. Before getting into how to build such systems, let’s go through the inherent fallacies as well as the trade-offs in designing them.

## Fallacies of Distributed Computing

Because a large-scale software system involves multiple distributed systems, it is often subject to certain fallacies that can lead to incorrect assumptions and implementations. These fallacies were introduced by L. Peter Deutsch. They cover the false assumptions that software developers commonly make when implementing distributed systems. The eight fallacies are as follows:

_Reliable network_ The first fallacy is assuming that “the network is reliable.” Networks are complex, dynamic, and often unpredictable. Small issues like switch or power failures can bring the entire network of a data center down, making the network unreliable. Thus, it is important to account for the potential of an unreliable network when designing large-scale systems, ensuring network fault tolerance from the start. Given that networks are inherently unreliable, to build reliable services on top we must rely on protocols that can cope with network outages and packet loss.

_Zero latency_ The second fallacy is assuming that “latency is zero.” Latency is an inherent limitation of networks, constrained by the speed of light—that is, even in theoretically perfect systems, the data can’t transfer between the nodes faster than the speed of light. To account for latency, the system should be designed to bring clients close to the data through edge computing and even by choosing the


servers in geographic data centers nearer to the clients and routing the traffic wisely.

_Infinite bandwidth_ The third fallacy is assuming that “bandwidth is infinite.” When a high volume of data is flowing through the network, there is always network resource contention, leading to queuing delays, bottlenecks, packet drops, and network congestion. To account for finite bandwidth, build the system using lightweight data formats for the data in transit that will preserve the network bandwidth and avoid network congestion.

_Secure network_ The fourth fallacy is assuming that “the network is secure.” Assuming a network is always secure when there are multiple ways it can be compromised (including software bugs, OS vulnerabilities, viruses and malware, cross-site scripting, unencrypted communication, malicious middle actors, etc.) can lead to system compromise and failure. To account for insecure networks, build systems with a security-first mindset and perform defense testing and threat modeling on the built system.

_Fixed topology_ The fifth fallacy is assuming that “topology doesn’t change.” In distributed systems, the topology changes continuously because of node failures or node additions. Building a system that assumes a fixed topology will lead to system issues and failures due to latency and bandwidth constraints. Hence, the underlying topology must be abstracted out, and the system must be built oblivious to the underlying topology and tolerant to its changes.

_Single administrator_ The sixth fallacy is assuming that “there is one administrator.” This can be a fair assumption in a very small system like a personal project, but this assumption breaks down in large-scale distributed computing, where multiple systems have separate OS, separate teams working on them, and thus, multiple administrators. To account for this, the system should be built in a decoupled manner, ensuring that repair and troubleshooting become easy and distributed, too.

_Zero transport cost_ The seventh fallacy is assuming that “transport cost is zero.” Network infrastructure has costs, including the costs of network servers, switches, routers, other hardware, the OS of that hardware, and the team cost to keep it all running smoothly. Thus, the assumption that the cost of transporting data from one node to another is negligible is false and must consequently be noted in budgets to avoid vast shortfalls.


_Homogeneous network_ The eighth fallacy is assuming that “the network is homogeneous.” A network is built with multiple devices with different configurations and using multiple protocols at different layers. Taking into consideration the heterogeneity of the network as well as focusing on the interoperability of the system (i.e., ensuring that subsystems can communicate and work together despite having such differences) will help to avoid this pitfall.

The AWS Well-Architected Framework consists of six core pillars that provide guidance and best practices for designing and building systems on the AWS cloud to avoid these fallacies and pitfalls. The Operational Excellence pillar avoids the fallacy of single administrator and homogeneous network. The Security pillar avoids the secure-network fallacy. The Reliability pillar avoids the fallacy of a reliable network and fixed topology. The Performance Efficiency pillar avoids the fallacy of zero latency and infinite bandwidth. The Cost Optimization and Sustainability pillars avoid the fallacy of zero transport cost. We won’t cover the Well-Architected Framework in detail here.

These fallacies cover the basic assumptions we should avoid when building largescale systems. Overall, neglecting the fallacies of distributed computing can lead to a range of issues, including system failures, performance bottlenecks, data inconsistencies, security vulnerabilities, scalability challenges, and increased complexity of system administration. It is important to acknowledge and account for these fallacies during the design and implementation of distributed systems to ensure their robustness, reliability, and effective operation in real-world environments.

Now, let’s go through the trade-offs that are generally encountered when designing large-scale software systems.

## System Design Trade-offs

System design involves making a number of trade-offs that can have a significant impact on the performance and usability of a system. When designing a system, you must consider factors like cost, scalability, reliability, maintainability, and robustness. These factors must be balanced to create a system that is optimized for the particular needs of the user. Ultimately, the goal is to create a system that meets user needs without sacrificing any of these important factors.

For example, if a system needs to be highly reliable but also have scalability, then you need to consider the trade-offs between cost and robustness. A system with a high level of reliability may require more expensive components, but these components may also be robust and allow for scalability in the future. On the other hand, if cost is


a priority, then you may have to sacrifice robustness or scalability to keep the system within budget.

Trade-offs in addition to cost and scalability must be taken into account when designing a system. Performance, security, maintainability, and usability are all important considerations that must be weighed. In this section, we will discuss some theoretical trade-offs that arise in system design.

### Time Versus Space

Time-space trade-offs or time-memory trade-offs arise inherently in implementing algorithms in computer science for the workload, even in distributed systems. These trade-offs are necessary because system designers need to consider the time limitations of the algorithms and sometimes use extra memory or storage to make sure everything works optimally. One example of such a trade-off is using look-up tables in memory or data storage instead of performing recalculations and thus serving more requests by just looking up precalculated values.

### Latency Versus Throughput

Another trade-off that arises inherently in system design is latency versus throughput. Before diving into the trade-off, let’s make sure you understand these concepts.

**Latency, processing time, and response time**

_Latency_ is the time that a request waits to be handled. _Processing time_, on the other hand, is the time taken by the system to process the request once it is picked up. Hence, the overall response time is the duration between the request that was sent and the corresponding response that was received, accounting for network and server latencies. Mathematically, it can be represented by the following formula:

Response Time = Latency + Processing Time

**Throughput and bandwidth**

Throughput and bandwidth are metrics of network data capacity and are used to account for network scalability and load. _Bandwidth_ refers to the maximum amount of data that could theoretically travel from one point in the network to another in a given time. _Throughput_ refers to the actual amount of data transmitted and processed throughout the network. Thus, bandwidth describes the theoretical limit, and throughput provides the empirical metric. The throughput is always lower than the bandwidth unless the network is operating at its maximum efficiency.

Bandwidth is a limited resource because each network device can handle and process only a limited capacity of data before passing it to the next network device, and some


devices consume more bandwidth than others. Insufficient bandwidth can lead to network congestion, which slows connectivity.

Since latency measures how long the packets take to reach the destination in a network, while throughput measures how many packets are processed within a specified period of time, they have an inverse relationship. Higher latency causes packets to queue up in the network, slowing packet processing and ultimately reducing throughput.

Because the system is being gauged for lower latency under high throughput or load, the metric to capture latency is through percentiles, such as p50, p90, p99, and so on. For example, the p90 latency is the highest latency value (slowest response) of the fastest 90% of requests. In other words, 90% of requests have responses that are equal to or faster than the p90 latency value. Note that average latency of a workload is not used as a metric because averages as point estimates are susceptible to outliers.

Because of the latency versus throughput trade-off, the latency will also increase as the load is increased on the system for higher throughput. Hence, systems should be designed with an aim for maximal throughput within acceptable latency.

### Performance Versus Scalability

As discussed in “Scalability” on page 20, _scalability_ is the system’s ability to respond to increased demand and load. On the other hand, _performance_ is how fast the system responds to a single request. A service is scalable if it results in increased performance in a manner proportional to resources added. When a system has performance problems, it is slow for a single user (p50 latency = 100 ms), but when the system has scalability problems, the system may be fast for some users (p50 latency = 1 ms for one hundred requests) but slow under heavy load for the users (p50 latency = 100 ms under one hundred thousand requests).

### Consistency Versus Availability

_Strong consistency_ in data storage and retrieval is the guarantee that every read receives the most recent write, while _high availability_ is the requirement of the system to always provide a nonerror response to the request. In a distributed system where the network fails (i.e., packets get dropped or delayed due to the fallacies of distributed computing leading to partitions), there emerges an inherent trade-off between strong consistency and high availability. This trade-off is called the _CAP_ _theorem_, also known as _Brewer’s theorem_.

**CAP theorem**

The CAP theorem, illustrated as a Venn diagram in Figure 1-7, states that it is impossible for a distributed system to simultaneously provide all three of the following


guarantees: consistency (C), availability (A), and partition tolerance (P). According to the theorem, a distributed system can provide at most two of these guarantees at any given time. Systems need to be designed to handle network partitions because networks aren’t reliable, and hence, partition tolerance needs to be built in. So the CAP theorem implies that in the presence of a network partition, one has to choose between consistency and availability.

![](../images/system_design_on_aws_page_0051_6.png)

_Figure 1-7. CAP theorem Venn diagram_

However, the CAP theorem is frequently misunderstood to mean that one has to choose to abandon one of the three guarantees at all times. In fact, the choice is really between consistency and availability only when a network partition or failure happens; at all other times, the trade-off has to be made based on the PACELC theorem.

**PACELC theorem**

The PACELC theorem, illustrated as a decision flowchart in Figure 1-8, is a more nuanced version of the CAP theorem. It states that in the case of network partitioning (P) in a distributed computer system, one must choose between availability (A) and consistency (C) as per the CAP theorem, but otherwise (E), even when the system is running normally in the absence of partitions, one has to choose between latency (L) and consistency (C). This trade-off arises naturally because to handle network partitions, data and services are replicated in large-scale systems, leading to the choice between the consistency spectrum and the corresponding latency.


![](../images/system_design_on_aws_page_0052_7.png)

_Figure 1-8. PACELC theorem decision flowchart_

If the system tries to provide for strong consistency at one end of the consistency spectrum model, it has to do replication with synchronous communication and blocking to ensure that all the read replicas receive the most recent write, waiting on the acknowledgment from all the replica nodes, which adds to high latency. On the other hand, if the system does asynchronous replication without waiting for acknowledgment from all nodes, it will end up providing eventual consistency (i.e., the read request will eventually reflect the last recent write) when the replica node has acknowledged the data mutation change for serving the requests.

The CAP and PACELC theorems are important concepts in distributed systems design that provide a framework for understanding the trade-offs involved in designing highly available and strongly consistent systems.

We will cover how nonrelational stores navigate the CAP theorem trade-off by discussing BASE properties in detail in Chapter 3.

Given such requirements, fallacies, and trade-offs in system design, to avoid repeating mistakes of the past, we should adhere to a set of guidelines that the previous generation of software design practitioners learned. Let’s dig into those now.


## System Design Guidelines

System design will always present the most interesting and challenging trade-offs, and a system designer should be aware of the hidden costs and be well equipped to get it right—though not perfect! These guidelines, which have emerged over years of practicing system design, help us avoid pitfalls and handle trade-offs when designing large-scale systems. These guidelines aren’t just vague generalities but rather virtues that help us reflect on why the system was designed and implemented the way it was and why that was the right thing to do.

### Guideline of Isolation: Build It Modularly

_Controlling complexity is the essence of computer programming._ —Brian Kernighan

The first guideline is to build the system modularly—that is, break a complex system down into smaller, independent components or modules that can function independently yet also work together to form the larger system. Building a large-scale system modularly helps improve all its requirements:

_Maintainability_ Modules can be updated or replaced individually without affecting the rest of the system.

_Reusability_ Modules can be reused in different systems or projects, reducing the amount of new development required.

_Scalability_ Modules can be added or removed and even scaled independently as needed to accommodate changes in requirements or to support growth.

_Reliability_ Modules can be tested and validated independently, reducing the risk of systemwide failures.

Modular systems can be implemented in a variety of ways, including through the use of microservice architecture, component-based development, and modular programming, which we will cover in more detail in Chapter 7. However, designing modular systems can be challenging as it requires careful consideration of the interfaces between modules, data sharing and flow, and dependencies.


### Guideline of Simplicity: Keep It Simple, Silly

_Everything should be made as simple as possible, but no simpler._ —attributed to Albert Einstein

The second guideline is to keep the design simple by avoiding complex and unnecessary features and overengineering. To build simple systems using the KISS (Keep It Simple, Silly) guideline, designers can follow these principles:

_Identify the core requirements_ Determine the essential features and functions the system must have and prioritize them.

_Minimize the number of components_ Reduce the number of components or modules in the system, making sure each component serves a specific purpose.

_Avoid overengineering_ Don’t add unnecessary complexity to the system, such as features that are not necessary for its functioning.

_Make the system easy to use_ Ensure that the system is intuitive and straightforward for users to use and understand.

_Test and refine_ Test the system to ensure that it works as intended, and make changes to simplify the system if necessary.

By following the KISS guideline, you as a system designer can build simple, efficient, and effective systems that are easier to maintain and less prone to failure.

### Guideline of Performance: Metrics Don’t Lie

_Performance problems cannot be solved only through the use of Zen meditation._ —Jeffrey C. Mogul

The third guideline is to measure, then build, and rely on the metrics since you can’t cheat the performance and scalability. Metrics and observability are crucial for understanding the behavior and performance of large-scale systems and for identifying potential issues before they become problems.

_Metrics_ are quantitative measures that are used to assess the performance of a system. They provide a way to track key performance indicators, such as resource utilization, response times, and error rates, and to identify trends and patterns in system behavior. By monitoring metrics, engineers can detect performance bottlenecks and


anomalies and take corrective actions to improve the overall performance and reliability of the system.

_Observability_ refers to the degree to which the state of a system can be inferred from its externally visible outputs. This includes being able to monitor system health and diagnose problems in real time. Observability is important in large-scale systems because it provides a way to monitor the behavior of complex systems and detect issues that may be affecting their performance.

Together, metrics and observability provide the information needed to make informed decisions about the operation and management of large-scale systems. By ensuring that systems are properly instrumented with metrics and that observability is designed into the system, you can detect and resolve issues more quickly, prevent outages, and improve the system’s overall performance and reliability.

### Guideline of Trade-offs: There Is No Such Thing as a Free Lunch

_Get it right. Neither abstraction nor simplicity is a substitute for getting it right._ —Butler Lampson

The fourth guideline is “there is no such thing as a free lunch” (TINSTAAFL), or the realization that all decisions come with trade-offs and that optimizing for one aspect of a system often comes at the expense of others. There are always trade-offs and compromises that must be made when designing a system. For example, choosing a highly optimized solution for a specific problem might result in reduced maintainability or increased complexity. Conversely, opting for a simple solution might result in lower performance or increased latency.

The TINSTAAFL guideline highlights the need for careful consideration and balancing of competing factors in system design, such as performance, scalability, reliability, maintainability, and cost. Designers must weigh the trade-offs between these factors and make informed decisions that meet the specific requirements and constraints of each project. Ultimately, you need to realize that there is no single solution that is optimal in all situations and that, to build the right system, you as the system designer must carefully consider the trade-offs and implications of your design decisions.

### Guideline of Use Cases: It Always Depends

_Not everything worth doing is worth doing well._ —Tom West

The fifth guideline is _design always depends_ because system design is a complex, multifaceted process that is influenced by a variety of factors, including requirements, user needs, technological constraints, cost, scalability, maintenance, and even regulations. By considering these and other factors, you can develop systems that meet the


needs of the users, are feasible to implement, and are sustainable over time. Since there are many ways to design a system to solve a common problem, this guideline indicates a stronger underlying truth: there is no one “best” way to design the system. In other words, there is no silver bullet. Thus, we settle for something reasonable and hope it is good enough.

## Conclusion

This chapter has given you a solid introduction to how we design software systems. We’ve talked about the main concepts underlying system design, the trade-offs we must make when dealing with big software systems, the fallacies to avoid in building such large-scale systems, and smart guidelines for avoiding such fallacies.

Think of system design as like balancing on a seesaw: you must find the right equilibrium between different trade-offs. As an overall guideline, system design is always a trade-off between competing factors, and you as a system designer must carefully weigh these factors to create systems that are effective and efficient.

In the rest of Part I, we’re going to explore the basic building blocks of systems. We’ll talk about important topics like where we store data, how we speed things up with caches, how we distribute work with load balancers, and how different parts of a system talk to one another through networking and orchestration.

Once you’ve got a handle on those basics, we’ll dive into the world of AWS systems in Part II. This will help you understand how to make big and powerful systems using Amazon Web Services. All this knowledge will come together in Part III, where we’ll put everything into practice and learn how to design and build large-scale systems on AWS for specific use cases.

Before we get there, our next stop is exploring different ways to store data and introducing you to relational databases.

