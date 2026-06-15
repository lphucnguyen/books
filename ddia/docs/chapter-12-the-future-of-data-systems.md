# Chapter 12. The Future of Data Systems

_If a thing be ordained to another as to its end, its last end cannot consist in the preservation of its being. Hence a captain does not intend as a last end, the preservation of the ship entrusted to him, since a ship is ordained to something else as its end, viz. to navigation. (Often quoted as: If the highest aim of a captain was the preserve his ship, he would keep it in port forever.)_ 

—St. Thomas Aquinas, _Summa Theologica_ (1265–1274) 

So far, this book has been mostly about describing things as they _are_ at present. In this final chapter, we will shift our perspective toward the future and discuss how things _should be_ : I will propose some ideas and approaches that, I believe, may fundamentally improve the ways we design and build applications. 

Opinions and speculation about the future are of course subjective, and so I will use the first person in this chapter when writing about my personal opinions. You are welcome to disagree with them and form your own opinions, but I hope that the ideas in this chapter will at least be a starting point for a productive discussion and bring some clarity to concepts that are often confused. 

The goal of this book was outlined in Chapter 1: to explore how to create applications and systems that are _reliable_ , _scalable_ , and _maintainable_ . These themes have run through all of the chapters: for example, we discussed many fault-tolerance algorithms that help improve reliability, partitioning to improve scalability, and mechanisms for evolution and abstraction that improve maintainability. In this chapter we will bring all of these ideas together, and build on them to envisage the future. Our goal is to discover how to design applications that are better than the ones of today— robust, correct, evolvable, and ultimately beneficial to humanity. 


## Data Integration

A recurring theme in this book has been that for any given problem, there are several solutions, all of which have different pros, cons, and trade-offs. For example, when discussing storage engines in Chapter 3, we saw log-structured storage, B-trees, and column-oriented storage. When discussing replication in Chapter 5, we saw singleleader, multi-leader, and leaderless approaches. 

If you have a problem such as “I want to store some data and look it up again later,” there is no one right solution, but many different approaches that are each appropriate in different circumstances. A software implementation typically has to pick one particular approach. It’s hard enough to get one code path robust and performing well—trying to do everything in one piece of software almost guarantees that the implementation will be poor. 

Thus, the most appropriate choice of software tool also depends on the circumstances. Every piece of software, even a so-called “general-purpose” database, is designed for a particular usage pattern. 

Faced with this profusion of alternatives, the first challenge is then to figure out the mapping between the software products and the circumstances in which they are a good fit. Vendors are understandably reluctant to tell you about the kinds of workloads for which their software is poorly suited, but hopefully the previous chapters have equipped you with some questions to ask in order to read between the lines and better understand the trade-offs. 

However, even if you perfectly understand the mapping between tools and circumstances for their use, there is another challenge: in complex applications, data is often used in several different ways. There is unlikely to be one piece of software that is suitable for _all_ the different circumstances in which the data is used, so you inevitably end up having to cobble together several different pieces of software in order to provide your application’s functionality. 

### Combining Specialized Tools by Deriving Data 

For example, it is common to need to integrate an OLTP database with a full-text search index in order to handle queries for arbitrary keywords. Although some databases (such as PostgreSQL) include a full-text indexing feature, which can be sufficient for simple applications [1], more sophisticated search facilities require specialist information retrieval tools. Conversely, search indexes are generally not very suitable as a durable system of record, and so many applications need to combine two different tools in order to satisfy all of the requirements. 

We touched on the issue of integrating data systems in “Keeping Systems in Sync” on page 452. As the number of different representations of the data increases, the integration problem becomes harder. Besides the database and the search index, perhaps you need to keep copies of the data in analytics systems (data warehouses, or batch and stream processing systems); maintain caches or denormalized versions of objects that were derived from the original data; pass the data through machine learning, classification, ranking, or recommendation systems; or send notifications based on changes to the data. 

Surprisingly often I see software engineers make statements like, “In my experience, 99% of people only need X” or “…don’t need X” (for various values of X). I think that such statements say more about the experience of the speaker than about the actual usefulness of a technology. The range of different things you might want to do with data is dizzyingly wide. What one person considers to be an obscure and pointless feature may well be a central requirement for someone else. The need for data integration often only becomes apparent if you zoom out and consider the dataflows across an entire organization. 

# **Reasoning about dataflows** 

When copies of the same data need to be maintained in several storage systems in order to satisfy different access patterns, you need to be very clear about the inputs and outputs: where is data written first, and which representations are derived from which sources? How do you get data into all the right places, in the right formats? 

For example, you might arrange for data to first be written to a system of record database, capturing the changes made to that database (see “Change Data Capture” on page 454) and then applying the changes to the search index in the same order. If change data capture (CDC) is the only way of updating the index, you can be confident that the index is entirely derived from the system of record, and therefore consistent with it (barring bugs in the software). Writing to the database is the only way of supplying new input into this system. 

Allowing the application to directly write to both the search index and the database introduces the problem shown in Figure 11-4, in which two clients concurrently send conflicting writes, and the two storage systems process them in a different order. In this case, neither the database nor the search index is “in charge” of determining the order of writes, and so they may make contradictory decisions and become permanently inconsistent with each other. 

If it is possible for you to funnel all user input through a single system that decides on an ordering for all writes, it becomes much easier to derive other representations of the data by processing the writes in the same order. This is an application of the state machine replication approach that we saw in “Total Order Broadcast” on page 348. Whether you use change data capture or an event sourcing log is less important than simply the principle of deciding on a total order. 


Updating a derived data system based on an event log can often be made deterministic and idempotent (see “Idempotence” on page 478), making it quite easy to recover from faults. 

# **Derived data versus distributed transactions** 

The classic approach for keeping different data systems consistent with each other involves distributed transactions, as discussed in “Atomic Commit and Two-Phase Commit (2PC)” on page 354. How does the approach of using derived data systems fare in comparison to distributed transactions? 

At an abstract level, they achieve a similar goal by different means. Distributed transactions decide on an ordering of writes by using locks for mutual exclusion (see “Two-Phase Locking (2PL)” on page 257), while CDC and event sourcing use a log for ordering. Distributed transactions use atomic commit to ensure that changes take effect exactly once, while log-based systems are often based on deterministic retry and idempotence. 

The biggest difference is that transaction systems usually provide linearizability (see “Linearizability” on page 324), which implies useful guarantees such as reading your own writes (see “Reading Your Own Writes” on page 162). On the other hand, derived data systems are often updated asynchronously, and so they do not by default offer the same timing guarantees. 

Within limited environments that are willing to pay the cost of distributed transactions, they have been used successfully. However, I think that XA has poor fault tolerance and performance characteristics (see “Distributed Transactions in Practice” on page 360), which severely limit its usefulness. I believe that it might be possible to create a better protocol for distributed transactions, but getting such a protocol widely adopted and integrated with existing tools would be challenging, and unlikely to happen soon. 

In the absence of widespread support for a good distributed transaction protocol, I believe that log-based derived data is the most promising approach for integrating different data systems. However, guarantees such as reading your own writes are useful, and I don’t think that it is productive to tell everyone “eventual consistency is inevitable—suck it up and learn to deal with it” (at least not without good guidance on _how_ to deal with it). 

In “Aiming for Correctness” on page 515 we will discuss some approaches for implementing stronger guarantees on top of asynchronously derived systems, and work toward a middle ground between distributed transactions and asynchronous logbased systems. 


# **The limits of total ordering** 

With systems that are small enough, constructing a totally ordered event log is entirely feasible (as demonstrated by the popularity of databases with single-leader replication, which construct precisely such a log). However, as systems are scaled toward bigger and more complex workloads, limitations begin to emerge: 

- In most cases, constructing a totally ordered log requires all events to pass through a _single leader node_ that decides on the ordering. If the throughput of events is greater than a single machine can handle, you need to partition it across multiple machines (see “Partitioned Logs” on page 446). The order of events in two different partitions is then ambiguous. 

- If the servers are spread across multiple _geographically distributed_ datacenters, for example in order to tolerate an entire datacenter going offline, you typically have a separate leader in each datacenter, because network delays make synchronous cross-datacenter coordination inefficient (see “Multi-Leader Replication” on page 168). This implies an undefined ordering of events that originate in two different datacenters. 

- When applications are deployed as _microservices_ (see “Dataflow Through Services: REST and RPC” on page 131), a common design choice is to deploy each service and its durable state as an independent unit, with no durable state shared between services. When two events originate in different services, there is no defined order for those events. 

- Some applications maintain client-side state that is updated immediately on user input (without waiting for confirmation from a server), and even continue to work offline (see “Clients with offline operation” on page 170). With such applications, clients and servers are very likely to see events in different orders. 

In formal terms, deciding on a total order of events is known as _total order broadcast_ , which is equivalent to consensus (see “Consensus algorithms and total order broadcast” on page 366). Most consensus algorithms are designed for situations in which the throughput of a single node is sufficient to process the entire stream of events, and these algorithms do not provide a mechanism for multiple nodes to share the work of ordering the events. It is still an open research problem to design consensus algorithms that can scale beyond the throughput of a single node and that work well in a geographically distributed setting. 

# **Ordering events to capture causality** 

In cases where there is no causal link between events, the lack of a total order is not a big problem, since concurrent events can be ordered arbitrarily. Some other cases are easy to handle: for example, when there are multiple updates of the same object, they can be totally ordered by routing all updates for a particular object ID to the same log 


partition. However, causal dependencies sometimes arise in more subtle ways (see also “Ordering and Causality” on page 339). 

For example, consider a social networking service, and two users who were in a relationship but have just broken up. One of the users removes the other as a friend, and then sends a message to their remaining friends complaining about their ex-partner. The user’s intention is that their ex-partner should not see the rude message, since the message was sent after the friend status was revoked. 

However, in a system that stores friendship status in one place and messages in another place, that ordering dependency between the _unfriend_ event and the _messagesend_ event may be lost. If the causal dependency is not captured, a service that sends notifications about new messages may process the _message-send_ event before the _unfriend_ event, and thus incorrectly send a notification to the ex-partner. 

In this example, the notifications are effectively a join between the messages and the friend list, making it related to the timing issues of joins that we discussed previously (see “Time-dependence of joins” on page 475). Unfortunately, there does not seem to be a simple answer to this problem [2, 3]. Starting points include: 

- Logical timestamps can provide total ordering without coordination (see “Sequence Number Ordering” on page 343), so they may help in cases where total order broadcast is not feasible. However, they still require recipients to handle events that are delivered out of order, and they require additional metadata to be passed around. 

- If you can log an event to record the state of the system that the user saw before making a decision, and give that event a unique identifier, then any later events can reference that event identifier in order to record the causal dependency [4]. We will return to this idea in “Reads are events too” on page 513. 

- Conflict resolution algorithms (see “Automatic Conflict Resolution” on page 174) help with processing events that are delivered in an unexpected order. They are useful for maintaining state, but they do not help if actions have external side effects (such as sending a notification to a user). 

Perhaps, over time, patterns for application development will emerge that allow causal dependencies to be captured efficiently, and derived state to be maintained correctly, without forcing all events to go through the bottleneck of total order broadcast. 

### Batch and Stream Processing 

I would say that the goal of data integration is to make sure that data ends up in the right form in all the right places. Doing so requires consuming inputs, transforming, joining, filtering, aggregating, training models, evaluating, and eventually writing to 


the appropriate outputs. Batch and stream processors are the tools for achieving this goal. 

The outputs of batch and stream processes are derived datasets such as search indexes, materialized views, recommendations to show to users, aggregate metrics, and so on (see “The Output of Batch Workflows” on page 411 and “Uses of Stream Processing” on page 465). 

As we saw in Chapter 10 and Chapter 11, batch and stream processing have a lot of principles in common, and the main fundamental difference is that stream processors operate on unbounded datasets whereas batch process inputs are of a known, finite size. There are also many detailed differences in the ways the processing engines are implemented, but these distinctions are beginning to blur. 

Spark performs stream processing on top of a batch processing engine by breaking the stream into _microbatches_ , whereas Apache Flink performs batch processing on top of a stream processing engine [5]. In principle, one type of processing can be emulated on top of the other, although the performance characteristics vary: for example, microbatching may perform poorly on hopping or sliding windows [6]. 

# **Maintaining derived state** 

Batch processing has a quite strong functional flavor (even if the code is not written in a functional programming language): it encourages deterministic, pure functions whose output depends only on the input and which have no side effects other than the explicit outputs, treating inputs as immutable and outputs as append-only. Stream processing is similar, but it extends operators to allow managed, fault-tolerant state (see “Rebuilding state after a failure” on page 478). 

The principle of deterministic functions with well-defined inputs and outputs is not only good for fault tolerance (see “Idempotence” on page 478), but also simplifies reasoning about the dataflows in an organization [7]. No matter whether the derived data is a search index, a statistical model, or a cache, it is helpful to think in terms of data pipelines that derive one thing from another, pushing state changes in one system through functional application code and applying the effects to derived systems. 

In principle, derived data systems could be maintained synchronously, just like a relational database updates secondary indexes synchronously within the same transaction as writes to the table being indexed. However, asynchrony is what makes systems based on event logs robust: it allows a fault in one part of the system to be contained locally, whereas distributed transactions abort if any one participant fails, so they tend to amplify failures by spreading them to the rest of the system (see “Limitations of distributed transactions” on page 363). 

We saw in “Partitioning and Secondary Indexes” on page 206 that secondary indexes often cross partition boundaries. A partitioned system with secondary indexes either 


needs to send writes to multiple partitions (if the index is term-partitioned) or send reads to all partitions (if the index is document-partitioned). Such cross-partition communication is also most reliable and scalable if the index is maintained asynchronously [8] (see also “Multi-partition data processing” on page 514). 

# **Reprocessing data for application evolution** 

When maintaining derived data, batch and stream processing are both useful. Stream processing allows changes in the input to be reflected in derived views with low delay, whereas batch processing allows large amounts of accumulated historical data to be reprocessed in order to derive new views onto an existing dataset. 

In particular, reprocessing existing data provides a good mechanism for maintaining a system, evolving it to support new features and changed requirements (see Chapter 4). Without reprocessing, schema evolution is limited to simple changes like adding a new optional field to a record, or adding a new type of record. This is the case both in a schema-on-write and in a schema-on-read context (see “Schema flexibility in the document model” on page 39). On the other hand, with reprocessing it is possible to restructure a dataset into a completely different model in order to better serve new requirements. 

# **Schema Migrations on Railways** 

Large-scale “schema migrations” occur in noncomputer systems as well. For example, in the early days of railway building in 19th-century England there were various competing standards for the gauge (the distance between the two rails). Trains built for one gauge couldn’t run on tracks of another gauge, which restricted the possible interconnections in the train network [9]. 

After a single standard gauge was finally decided upon in 1846, tracks with other gauges had to be converted—but how do you do this without shutting down the train line for months or years? The solution is to first convert the track to _dual gauge_ or _mixed gauge_ by adding a third rail. This conversion can be done gradually, and when it is done, trains of both gauges can run on the line, using two of the three rails. Eventually, once all trains have been converted to the standard gauge, the rail providing the nonstandard gauge can be removed. 

“Reprocessing” the existing tracks in this way, and allowing the old and new versions to exist side by side, makes it possible to change the gauge gradually over the course of years. Nevertheless, it is an expensive undertaking, which is why nonstandard gauges still exist today. For example, the BART system in the San Francisco Bay Area uses a different gauge from the majority of the US. 


Derived views allow _gradual_ evolution. If you want to restructure a dataset, you do not need to perform the migration as a sudden switch. Instead, you can maintain the old schema and the new schema side by side as two independently derived views onto the same underlying data. You can then start shifting a small number of users to the new view in order to test its performance and find any bugs, while most users continue to be routed to the old view. Gradually, you can increase the proportion of users accessing the new view, and eventually you can drop the old view [10]. 

The beauty of such a gradual migration is that every stage of the process is easily reversible if something goes wrong: you always have a working system to go back to. By reducing the risk of irreversible damage, you can be more confident about going ahead, and thus move faster to improve your system [11]. 

# **The lambda architecture** 

If batch processing is used to reprocess historical data, and stream processing is used to process recent updates, then how do you combine the two? The _lambda architecture_ [12] is a proposal in this area that has gained a lot of attention. 

The core idea of the lambda architecture is that incoming data should be recorded by appending immutable events to an always-growing dataset, similarly to event sourcing (see “Event Sourcing” on page 457). From these events, read-optimized views are derived. The lambda architecture proposes running two different systems in parallel: a batch processing system such as Hadoop MapReduce, and a separate streamprocessing system such as Storm. 

In the lambda approach, the stream processor consumes the events and quickly produces an approximate update to the view; the batch processor later consumes the _same_ set of events and produces a corrected version of the derived view. The reasoning behind this design is that batch processing is simpler and thus less prone to bugs, while stream processors are thought to be less reliable and harder to make faulttolerant (see “Fault Tolerance” on page 476). Moreover, the stream process can use fast approximate algorithms while the batch process uses slower exact algorithms. 

The lambda architecture was an influential idea that shaped the design of data systems for the better, particularly by popularizing the principle of deriving views onto streams of immutable events and reprocessing events when needed. However, I also think that it has a number of practical problems: 

- Having to maintain the same logic to run both in a batch and in a stream processing framework is significant additional effort. Although libraries such as Summingbird [13] provide an abstraction for computations that can be run in either a batch or a streaming context, the operational complexity of debugging, tuning, and maintaining two different systems remains [14]. 


- Since the stream pipeline and the batch pipeline produce separate outputs, they need to be merged in order to respond to user requests. This merge is fairly easy if the computation is a simple aggregation over a tumbling window, but it becomes significantly harder if the view is derived using more complex operations such as joins and sessionization, or if the output is not a time series. 

- Although it is great to have the ability to reprocess the entire historical dataset, doing so frequently is expensive on large datasets. Thus, the batch pipeline often needs to be set up to process incremental batches (e.g., an hour’s worth of data at the end of every hour) rather than reprocessing everything. This raises the problems discussed in “Reasoning About Time” on page 468, such as handling stragglers and handling windows that cross boundaries between batches. Incrementalizing a batch computation adds complexity, making it more akin to the streaming layer, which runs counter to the goal of keeping the batch layer as simple as possible. 

# **Unifying batch and stream processing** 

More recent work has enabled the benefits of the lambda architecture to be enjoyed without its downsides, by allowing both batch computations (reprocessing historical data) and stream computations (processing events as they arrive) to be implemented in the same system [15]. 

Unifying batch and stream processing in one system requires the following features, which are becoming increasingly widely available: 

- The ability to replay historical events through the same processing engine that handles the stream of recent events. For example, log-based message brokers have the ability to replay messages (see “Replaying old messages” on page 451), and some stream processors can read input from a distributed filesystem like HDFS. 

- Exactly-once semantics for stream processors—that is, ensuring that the output is the same as if no faults had occurred, even if faults did in fact occur (see “Fault Tolerance” on page 476). Like with batch processing, this requires discarding the partial output of any failed tasks. 

- Tools for windowing by event time, not by processing time, since processing time is meaningless when reprocessing historical events (see “Reasoning About Time” on page 468). For example, Apache Beam provides an API for expressing such computations, which can then be run using Apache Flink or Google Cloud Dataflow. 


## Unbundling Databases

At a most abstract level, databases, Hadoop, and operating systems all perform the same functions: they store some data, and they allow you to process and query that data [16]. A database stores data in records of some data model (rows in tables, documents, vertices in a graph, etc.) while an operating system’s filesystem stores data in files—but at their core, both are “information management” systems [17]. As we saw in Chapter 10, the Hadoop ecosystem is somewhat like a distributed version of Unix. 

Of course, there are many practical differences. For example, many filesystems do not cope very well with a directory containing 10 million small files, whereas a database containing 10 million small records is completely normal and unremarkable. Nevertheless, the similarities and differences between operating systems and databases are worth exploring. 

Unix and relational databases have approached the information management problem with very different philosophies. Unix viewed its purpose as presenting programmers with a logical but fairly low-level hardware abstraction, whereas relational databases wanted to give application programmers a high-level abstraction that would hide the complexities of data structures on disk, concurrency, crash recovery, and so on. Unix developed pipes and files that are just sequences of bytes, whereas databases developed SQL and transactions. 

Which approach is better? Of course, it depends what you want. Unix is “simpler” in the sense that it is a fairly thin wrapper around hardware resources; relational databases are “simpler” in the sense that a short declarative query can draw on a lot of powerful infrastructure (query optimization, indexes, join methods, concurrency control, replication, etc.) without the author of the query needing to understand the implementation details. 

The tension between these philosophies has lasted for decades (both Unix and the relational model emerged in the early 1970s) and still isn’t resolved. For example, I would interpret the NoSQL movement as wanting to apply a Unix-esque approach of low-level abstractions to the domain of distributed OLTP data storage. 

In this section I will attempt to reconcile the two philosophies, in the hope that we can combine the best of both worlds. 

### Composing Data Storage Technologies 

Over the course of this book we have discussed various features provided by databases and how they work, including: 

- Secondary indexes, which allow you to efficiently search for records based on the value of a field (see “Other Indexing Structures” on page 85) 


- Materialized views, which are a kind of precomputed cache of query results (see “Aggregation: Data Cubes and Materialized Views” on page 101) 

- Replication logs, which keep copies of the data on other nodes up to date (see “Implementation of Replication Logs” on page 158) 

- Full-text search indexes, which allow keyword search in text (see “Full-text search and fuzzy indexes” on page 88) and which are built into some relational databases [1] 

In Chapters 10 and 11, similar themes emerged. We talked about building full-text search indexes (see “The Output of Batch Workflows” on page 411), about materialized view maintenance (see “Maintaining materialized views” on page 467), and about replicating changes from a database to derived data systems (see “Change Data Capture” on page 454). 

It seems that there are parallels between the features that are built into databases and the derived data systems that people are building with batch and stream processors. 

# **Creating an index** 

Think about what happens when you run `CREATE INDEX` to create a new index in a relational database. The database has to scan over a consistent snapshot of a table, pick out all of the field values being indexed, sort them, and write out the index. Then it must process the backlog of writes that have been made since the consistent snapshot was taken (assuming the table was not locked while creating the index, so writes could continue). Once that is done, the database must continue to keep the index up to date whenever a transaction writes to the table. 

This process is remarkably similar to setting up a new follower replica (see “Setting Up New Followers” on page 155), and also very similar to bootstrapping change data capture in a streaming system (see “Initial snapshot” on page 455). 

Whenever you run `CREATE INDEX` , the database essentially reprocesses the existing dataset (as discussed in “Reprocessing data for application evolution” on page 496) and derives the index as a new view onto the existing data. The existing data may be a snapshot of the state rather than a log of all changes that ever happened, but the two are closely related (see “State, Streams, and Immutability” on page 459). 

# **The meta-database of everything** 

In this light, I think that the dataflow across an entire organization starts looking like one huge database [7]. Whenever a batch, stream, or ETL process transports data from one place and form to another place and form, it is acting like the database subsystem that keeps indexes or materialized views up to date. 


Viewed like this, batch and stream processors are like elaborate implementations of triggers, stored procedures, and materialized view maintenance routines. The derived data systems they maintain are like different index types. For example, a relational database may support B-tree indexes, hash indexes, spatial indexes (see “Multicolumn indexes” on page 87), and other types of indexes. In the emerging architecture of derived data systems, instead of implementing those facilities as features of a single integrated database product, they are provided by various different pieces of software, running on different machines, administered by different teams. 

Where will these developments take us in the future? If we start from the premise that there is no single data model or storage format that is suitable for all access patterns, I speculate that there are two avenues by which different storage and processing tools can nevertheless be composed into a cohesive system: 

# _Federated databases: unifying reads_ 

It is possible to provide a unified query interface to a wide variety of underlying storage engines and processing methods—an approach known as a _federated database_ or _polystore_ [18, 19]. For example, PostgreSQL’s _foreign data wrapper_ feature fits this pattern [20]. Applications that need a specialized data model or query interface can still access the underlying storage engines directly, while users who want to combine data from disparate places can do so easily through the federated interface. 

A federated query interface follows the relational tradition of a single integrated system with a high-level query language and elegant semantics, but a complicated implementation. 

# _Unbundled databases: unifying writes_ 

While federation addresses read-only querying across several different systems, it does not have a good answer to synchronizing writes across those systems. We said that within a single database, creating a consistent index is a built-in feature. When we compose several storage systems, we similarly need to ensure that all data changes end up in all the right places, even in the face of faults. Making it easier to reliably plug together storage systems (e.g., through change data capture and event logs) is like _unbundling_ a database’s index-maintenance features in a way that can synchronize writes across disparate technologies [7, 21]. 

The unbundled approach follows the Unix tradition of small tools that do one thing well [22], that communicate through a uniform low-level API (pipes), and that can be composed using a higher-level language (the shell) [16]. 

# **Making unbundling work** 

Federation and unbundling are two sides of the same coin: composing a reliable, scalable, and maintainable system out of diverse components. Federated read-only 


querying requires mapping one data model into another, which takes some thought but is ultimately quite a manageable problem. I think that keeping the writes to several storage systems in sync is the harder engineering problem, and so I will focus on it. 

The traditional approach to synchronizing writes requires distributed transactions across heterogeneous storage systems [18], which I think is the wrong solution (see “Derived data versus distributed transactions” on page 492). Transactions within a single storage or stream processing system are feasible, but when data crosses the boundary between different technologies, I believe that an asynchronous event log with idempotent writes is a much more robust and practical approach. 

For example, distributed transactions are used within some stream processors to achieve exactly-once semantics (see “Atomic commit revisited” on page 477), and this can work quite well. However, when a transaction would need to involve systems written by different groups of people (e.g., when data is written from a stream processor to a distributed key-value store or search index), the lack of a standardized transaction protocol makes integration much harder. An ordered log of events with idempotent consumers (see “Idempotence” on page 478) is a much simpler abstraction, and thus much more feasible to implement across heterogeneous systems [7]. 

The big advantage of log-based integration is _loose coupling_ between the various components, which manifests itself in two ways: 

1. At a system level, asynchronous event streams make the system as a whole more robust to outages or performance degradation of individual components. If a consumer runs slow or fails, the event log can buffer messages (see “Disk space usage” on page 450), allowing the producer and any other consumers to continue running unaffected. The faulty consumer can catch up when it is fixed, so it doesn’t miss any data, and the fault is contained. By contrast, the synchronous interaction of distributed transactions tends to escalate local faults into largescale failures (see “Limitations of distributed transactions” on page 363). 

2. At a human level, unbundling data systems allows different software components and services to be developed, improved, and maintained independently from each other by different teams. Specialization allows each team to focus on doing one thing well, with well-defined interfaces to other teams’ systems. Event logs provide an interface that is powerful enough to capture fairly strong consistency properties (due to durability and ordering of events), but also general enough to be applicable to almost any kind of data. 

# **Unbundled versus integrated systems** 

If unbundling does indeed become the way of the future, it will not replace databases in their current form—they will still be needed as much as ever. Databases are still 


required for maintaining state in stream processors, and in order to serve queries for the output of batch and stream processors (see “The Output of Batch Workflows” on page 411 and “Processing Streams” on page 464). Specialized query engines will continue to be important for particular workloads: for example, query engines in MPP data warehouses are optimized for exploratory analytic queries and handle this kind of workload very well (see “Comparing Hadoop to Distributed Databases” on page 414). 

The complexity of running several different pieces of infrastructure can be a problem: each piece of software has a learning curve, configuration issues, and operational quirks, and so it is worth deploying as few moving parts as possible. A single integrated software product may also be able to achieve better and more predictable performance on the kinds of workloads for which it is designed, compared to a system consisting of several tools that you have composed with application code [23]. As I said in the Preface, building for scale that you don’t need is wasted effort and may lock you into an inflexible design. In effect, it is a form of premature optimization. 

The goal of unbundling is not to compete with individual databases on performance for particular workloads; the goal is to allow you to combine several different databases in order to achieve good performance for a much wider range of workloads than is possible with a single piece of software. It’s about breadth, not depth—in the same vein as the diversity of storage and processing models that we discussed in “Comparing Hadoop to Distributed Databases” on page 414. 

Thus, if there is a single technology that does everything you need, you’re most likely best off simply using that product rather than trying to reimplement it yourself from lower-level components. The advantages of unbundling and composition only come into the picture when there is no single piece of software that satisfies all your requirements. 

# **What’s missing?** 

The tools for composing data systems are getting better, but I think one major part is missing: we don’t yet have the unbundled-database equivalent of the Unix shell (i.e., a high-level language for composing storage and processing systems in a simple and declarative way). 

For example, I would love it if we could simply declare `mysql | elasticsearch` , by analogy to Unix pipes [22], which would be the unbundled equivalent of `CREATE INDEX` : it would take all the documents in a MySQL database and index them in an Elasticsearch cluster. It would then continually capture all the changes made to the database and automatically apply them to the search index, without us having to write custom application code. This kind of integration should be possible with almost any kind of storage or indexing system. 


Similarly, it would be great to be able to precompute and update caches more easily. Recall that a materialized view is essentially a precomputed cache, so you could imagine creating a cache by declaratively specifying materialized views for complex queries, including recursive queries on graphs (see “Graph-Like Data Models” on page 49) and application logic. There is interesting early-stage research in this area, such as _differential dataflow_ [24, 25], and I hope that these ideas will find their way into production systems. 

### Designing Applications Around Dataflow 

The approach of unbundling databases by composing specialized storage and processing systems with application code is also becoming known as the “database inside-out” approach [26], after the title of a conference talk I gave in 2014 [27]. However, calling it a “new architecture” is too grandiose. I see it more as a design pattern, a starting point for discussion, and we give it a name simply so that we can better talk about it. 

These ideas are not mine; they are simply an amalgamation of other people’s ideas from which I think we should learn. In particular, there is a lot of overlap with _dataflow_ languages such as Oz [28] and Juttle [29], _functional reactive programming_ (FRP) languages such as Elm [30, 31], and _logic programming_ languages such as Bloom [32]. The term _unbundling_ in this context was proposed by Jay Kreps [7]. 

Even spreadsheets have dataflow programming capabilities that are miles ahead of most mainstream programming languages [33]. In a spreadsheet, you can put a formula in one cell (for example, the sum of cells in another column), and whenever any input to the formula changes, the result of the formula is automatically recalculated. This is exactly what we want at a data system level: when a record in a database changes, we want any index for that record to be automatically updated, and any cached views or aggregations that depend on the record to be automatically refreshed. You should not have to worry about the technical details of how this refresh happens, but be able to simply trust that it works correctly. 

Thus, I think that most data systems still have something to learn from the features that VisiCalc already had in 1979 [34]. The difference from spreadsheets is that today’s data systems need to be fault-tolerant, scalable, and store data durably. They also need to be able to integrate disparate technologies written by different groups of people over time, and reuse existing libraries and services: it is unrealistic to expect all software to be developed using one particular language, framework, or tool. 

In this section I will expand on these ideas and explore some ways of building applications around the ideas of unbundled databases and dataflow. 


# **Application code as a derivation function** 

When one dataset is derived from another, it goes through some kind of transformation function. For example: 

- A secondary index is a kind of derived dataset with a straightforward transformation function: for each row or document in the base table, it picks out the values in the columns or fields being indexed, and sorts by those values (assuming a B- tree or SSTable index, which are sorted by key, as discussed in Chapter 3). 

- A full-text search index is created by applying various natural language processing functions such as language detection, word segmentation, stemming or lemmatization, spelling correction, and synonym identification, followed by building a data structure for efficient lookups (such as an inverted index). 

- In a machine learning system, we can consider the model as being derived from the training data by applying various feature extraction and statistical analysis functions. When the model is applied to new input data, the output of the model is derived from the input and the model (and hence, indirectly, from the training data). 

- A cache often contains an aggregation of data in the form in which it is going to be displayed in a user interface (UI). Populating the cache thus requires knowledge of what fields are referenced in the UI; changes in the UI may require updating the definition of how the cache is populated and rebuilding the cache. 

The derivation function for a secondary index is so commonly required that it is built into many databases as a core feature, and you can invoke it by merely saying `CREATE INDEX` . For full-text indexing, basic linguistic features for common languages may be built into a database, but the more sophisticated features often require domainspecific tuning. In machine learning, feature engineering is notoriously applicationspecific, and often has to incorporate detailed knowledge about the user interaction and deployment of an application [35]. 

When the function that creates a derived dataset is not a standard cookie-cutter function like creating a secondary index, custom code is required to handle the application-specific aspects. And this custom code is where many databases struggle. Although relational databases commonly support triggers, stored procedures, and user-defined functions, which can be used to execute application code within the database, they have been somewhat of an afterthought in database design (see “Transmitting Event Streams” on page 440). 

# **Separation of application code and state** 

In theory, databases could be deployment environments for arbitrary application code, like an operating system. However, in practice they have turned out to be 


poorly suited for this purpose. They do not fit well with the requirements of modern application development, such as dependency and package management, version control, rolling upgrades, evolvability, monitoring, metrics, calls to network services, and integration with external systems. 

On the other hand, deployment and cluster management tools such as Mesos, YARN, Docker, Kubernetes, and others are designed specifically for the purpose of running application code. By focusing on doing one thing well, they are able to do it much better than a database that provides execution of user-defined functions as one of its many features. 

I think it makes sense to have some parts of a system that specialize in durable data storage, and other parts that specialize in running application code. The two can interact while still remaining independent. 

Most web applications today are deployed as stateless services, in which any user request can be routed to any application server, and the server forgets everything about the request once it has sent the response. This style of deployment is convenient, as servers can be added or removed at will, but the state has to go somewhere: typically, a database. The trend has been to keep stateless application logic separate from state management (databases): not putting application logic in the database and not putting persistent state in the application [36]. As people in the functional programming community like to joke, “We believe in the separation of Church and state” [37].[i] 

In this typical web application model, the database acts as a kind of mutable shared variable that can be accessed synchronously over the network. The application can read and update the variable, and the database takes care of making it durable, providing some concurrency control and fault tolerance. 

However, in most programming languages you cannot subscribe to changes in a mutable variable—you can only read it periodically. Unlike in a spreadsheet, readers of the variable don’t get notified if the value of the variable changes. (You can imple‐ — ment such notifications in your own code—this is known as the _observer pattern_ but most languages do not have this pattern as a built-in feature.) 

Databases have inherited this passive approach to mutable data: if you want to find out whether the content of the database has changed, often your only option is to poll (i.e., to repeat your query periodically). Subscribing to changes is only just beginning to emerge as a feature (see “API support for change streams” on page 456). 

> i. Explaining a joke rarely improves it, but I don’t want anyone to feel left out. Here, _Church_ is a reference to the mathematician Alonzo Church, who created the lambda calculus, an early form of computation that is the basis for most functional programming languages. The lambda calculus has no mutable state (i.e., no variables that can be overwritten), so one could say that mutable state is separate from Church’s work. 


# **Dataflow: Interplay between state changes and application code** 

Thinking about applications in terms of dataflow implies renegotiating the relationship between application code and state management. Instead of treating a database as a passive variable that is manipulated by the application, we think much more about the interplay and collaboration between state, state changes, and code that processes them. Application code responds to state changes in one place by triggering state changes in another place. 

We saw this line of thinking in “Databases and Streams” on page 451, where we discussed treating the log of changes to a database as a stream of events that we can subscribe to. Message-passing systems such as actors (see “Message-Passing Dataflow” on page 136) also have this concept of responding to events. Already in the 1980s, the _tuple spaces_ model explored expressing distributed computations in terms of processes that observe state changes and react to them [38, 39]. 

As discussed, similar things happen inside a database when a trigger fires due to a data change, or when a secondary index is updated to reflect a change in the table being indexed. Unbundling the database means taking this idea and applying it to the creation of derived datasets outside of the primary database: caches, full-text search indexes, machine learning, or analytics systems. We can use stream processing and messaging systems for this purpose. 

The important thing to keep in mind is that maintaining derived data is not the same as asynchronous job execution, for which messaging systems are traditionally designed (see “Logs compared to traditional messaging” on page 448): 

- When maintaining derived data, the order of state changes is often important (if several views are derived from an event log, they need to process the events in the same order so that they remain consistent with each other). As discussed in “Acknowledgments and redelivery” on page 445, many message brokers do not have this property when redelivering unacknowledged messages. Dual writes are also ruled out (see “Keeping Systems in Sync” on page 452). 

- Fault tolerance is key for derived data: losing just a single message causes the derived dataset to go permanently out of sync with its data source. Both message delivery and derived state updates must be reliable. For example, many actor systems by default maintain actor state and messages in memory, so they are lost if the machine running the actor crashes. 

Stable message ordering and fault-tolerant message processing are quite stringent demands, but they are much less expensive and more operationally robust than distributed transactions. Modern stream processors can provide these ordering and reliability guarantees at scale, and they allow application code to be run as stream operators. 


This application code can do the arbitrary processing that built-in derivation functions in databases generally don’t provide. Like Unix tools chained by pipes, stream operators can be composed to build large systems around dataflow. Each operator takes streams of state changes as input, and produces other streams of state changes as output. 

# **Stream processors and services** 

The currently trendy style of application development involves breaking down functionality into a set of _services_ that communicate via synchronous network requests such as REST APIs (see “Dataflow Through Services: REST and RPC” on page 131). The advantage of such a service-oriented architecture over a single monolithic application is primarily organizational scalability through loose coupling: different teams can work on different services, which reduces coordination effort between teams (as long as the services can be deployed and updated independently). 

Composing stream operators into dataflow systems has a lot of similar characteristics to the microservices approach [40]. However, the underlying communication mechanism is very different: one-directional, asynchronous message streams rather than synchronous request/response interactions. 

Besides the advantages listed in “Message-Passing Dataflow” on page 136, such as better fault tolerance, dataflow systems can also achieve better performance. For example, say a customer is purchasing an item that is priced in one currency but paid for in another currency. In order to perform the currency conversion, you need to know the current exchange rate. This operation could be implemented in two ways [40, 41]: 

1. In the microservices approach, the code that processes the purchase would probably query an exchange-rate service or database in order to obtain the current rate for a particular currency. 

2. In the dataflow approach, the code that processes purchases would subscribe to a stream of exchange rate updates ahead of time, and record the current rate in a local database whenever it changes. When it comes to processing the purchase, it only needs to query the local database. 

The second approach has replaced a synchronous network request to another service with a query to a local database (which may be on the same machine, even in the same process).[ii] Not only is the dataflow approach faster, but it is also more robust to 

> ii. In the microservices approach, you could avoid the synchronous network request by caching the exchange rate locally in the service that processes the purchase. However, in order to keep that cache fresh, you would need to periodically poll for updated exchange rates, or subscribe to a stream of changes—which is exactly what happens in the dataflow approach. 


the failure of another service. The fastest and most reliable network request is no network request at all! Instead of RPC, we now have a stream join between purchase events and exchange rate update events (see “Stream-table join (stream enrichment)” on page 473). 

The join is time-dependent: if the purchase events are reprocessed at a later point in time, the exchange rate will have changed. If you want to reconstruct the original output, you will need to obtain the historical exchange rate at the original time of purchase. No matter whether you query a service or subscribe to a stream of exchange rate updates, you will need to handle this time dependence (see “Time-dependence of joins” on page 475). 

Subscribing to a stream of changes, rather than querying the current state when needed, brings us closer to a spreadsheet-like model of computation: when some piece of data changes, any derived data that depends on it can swiftly be updated. There are still many open questions, for example around issues like time-dependent joins, but I believe that building applications around dataflow ideas is a very promising direction to go in. 

### Observing Derived State 

At an abstract level, the dataflow systems discussed in the last section give you a process for creating derived datasets (such as search indexes, materialized views, and predictive models) and keeping them up to date. Let’s call that process the _write path_ : whenever some piece of information is written to the system, it may go through multiple stages of batch and stream processing, and eventually every derived dataset is updated to incorporate the data that was written. Figure 12-1 shows an example of updating a search index. 


![](../images/Designing_Data_Intensive_Applications-0531-05.png)


_Figure 12-1. In a search index, writes (document updates) meet reads (queries)._ 

But why do you create the derived dataset in the first place? Most likely because you want to query it again at a later time. This is the _read path_ : when serving a user 


request you read from the derived dataset, perhaps perform some more processing on the results, and construct the response to the user. 

Taken together, the write path and the read path encompass the whole journey of the data, from the point where it is collected to the point where it is consumed (probably by another human). The write path is the portion of the journey that is precomputed —i.e., that is done eagerly as soon as the data comes in, regardless of whether anyone has asked to see it. The read path is the portion of the journey that only happens when someone asks for it. If you are familiar with functional programming languages, you might notice that the write path is similar to eager evaluation, and the read path is similar to lazy evaluation. 

The derived dataset is the place where the write path and the read path meet, as illustrated in Figure 12-1. It represents a trade-off between the amount of work that needs to be done at write time and the amount that needs to be done at read time. 

# **Materialized views and caching** 

A full-text search index is a good example: the write path updates the index, and the read path searches the index for keywords. Both reads and writes need to do some work. Writes need to update the index entries for all terms that appear in the document. Reads need to search for each of the words in the query, and apply Boolean logic to find documents that contain _all_ of the words in the query (an `AND` operator), or _any_ synonym of each of the words (an `OR` operator). 

If you didn’t have an index, a search query would have to scan over all documents (like `grep` ), which would get very expensive if you had a large number of documents. No index means less work on the write path (no index to update), but a lot more work on the read path. 

On the other hand, you could imagine precomputing the search results for all possible queries. In that case, you would have less work to do on the read path: no Boolean logic, just find the results for your query and return them. However, the write path would be a lot more expensive: the set of possible search queries that could be asked is infinite, and thus precomputing all possible search results would require infinite time and storage space. That wouldn’t work so well.[iii] 

Another option would be to precompute the search results for only a fixed set of the most common queries, so that they can be served quickly without having to go to the index. The uncommon queries can still be served from the index. This would generally be called a _cache_ of common queries, although we could also call it a materialized 

> iii. Less facetiously, the set of distinct search queries with nonempty search results is finite, assuming a finite corpus. However, it would be exponential in the number of terms in the corpus, which is still pretty bad news. 


view, as it would need to be updated when new documents appear that should be included in the results of one of the common queries. 

From this example we can see that an index is not the only possible boundary between the write path and the read path. Caching of common search results is possible, and `grep` -like scanning without the index is also possible on a small number of documents. Viewed like this, the role of caches, indexes, and materialized views is simple: they shift the boundary between the read path and the write path. They allow us to do more work on the write path, by precomputing results, in order to save effort on the read path. 

Shifting the boundary between work done on the write path and the read path was in fact the topic of the Twitter example at the beginning of this book, in “Describing Load” on page 11. In that example, we also saw how the boundary between write path and read path might be drawn differently for celebrities compared to ordinary users. After 500 pages we have come full circle! 

# **Stateful, offline-capable clients** 

I find the idea of a boundary between write and read paths interesting because we can discuss shifting that boundary and explore what that shift means in practical terms. Let’s look at the idea in a different context. 

The huge popularity of web applications in the last two decades has led us to certain assumptions about application development that are easy to take for granted. In particular, the client/server model—in which clients are largely stateless and servers have the authority over data—is so common that we almost forget that anything else exists. However, technology keeps moving on, and I think it is important to question the status quo from time to time. 

Traditionally, web browsers have been stateless clients that can only do useful things when you have an internet connection (just about the only thing you could do offline was to scroll up and down in a page that you had previously loaded while online). However, recent “single-page” JavaScript web apps have gained a lot of stateful capabilities, including client-side user interface interaction and persistent local storage in the web browser. Mobile apps can similarly store a lot of state on the device and don’t require a round-trip to the server for most user interactions. 

These changing capabilities have led to a renewed interest in _offline-first_ applications that do as much as possible using a local database on the same device, without requiring an internet connection, and sync with remote servers in the background when a network connection is available [42]. Since mobile devices often have slow and unreliable cellular internet connections, it’s a big advantage for users if their user interface does not have to wait for synchronous network requests, and if apps mostly work offline (see “Clients with offline operation” on page 170). 


When we move away from the assumption of stateless clients talking to a central database and toward state that is maintained on end-user devices, a world of new opportunities opens up. In particular, we can think of the on-device state as a _cache of state on the server_ . The pixels on the screen are a materialized view onto model objects in the client app; the model objects are a local replica of state in a remote datacenter [27]. 

# **Pushing state changes to clients** 

In a typical web page, if you load the page in a web browser and the data subsequently changes on the server, the browser does not find out about the change until you reload the page. The browser only reads the data at one point in time, assuming that it is static—it does not subscribe to updates from the server. Thus, the state on the device is a stale cache that is not updated unless you explicitly poll for changes. (HTTP-based feed subscription protocols like RSS are really just a basic form of polling.) 

More recent protocols have moved beyond the basic request/response pattern of HTTP: server-sent events (the EventSource API) and WebSockets provide communication channels by which a web browser can keep an open TCP connection to a server, and the server can actively push messages to the browser as long as it remains connected. This provides an opportunity for the server to actively inform the enduser client about any changes to the state it has stored locally, reducing the staleness of the client-side state. 

In terms of our model of write path and read path, actively pushing state changes all the way to client devices means extending the write path all the way to the end user. When a client is first initialized, it would still need to use a read path to get its initial state, but thereafter it could rely on a stream of state changes sent by the server. The ideas we discussed around stream processing and messaging are not restricted to running only in a datacenter: we can take the ideas further, and extend them all the way to end-user devices [43]. 

The devices will be offline some of the time, and unable to receive any notifications of state changes from the server during that time. But we already solved that problem: in “Consumer offsets” on page 449 we discussed how a consumer of a log-based message broker can reconnect after failing or becoming disconnected, and ensure that it doesn’t miss any messages that arrived while it was disconnected. The same technique works for individual users, where each device is a small subscriber to a small stream of events. 

# **End-to-end event streams** 

Recent tools for developing stateful clients and user interfaces, such as the Elm language [30] and Facebook’s toolchain of React, Flux, and Redux [44], already manage 


internal client-side state by subscribing to a stream of events representing user input or responses from a server, structured similarly to event sourcing (see “Event Sourcing” on page 457). 

It would be very natural to extend this programming model to also allow a server to push state-change events into this client-side event pipeline. Thus, state changes could flow through an end-to-end write path: from the interaction on one device that triggers a state change, via event logs and through several derived data systems and stream processors, all the way to the user interface of a person observing the state on another device. These state changes could be propagated with fairly low delay—say, under one second end to end. 

Some applications, such as instant messaging and online games, already have such a “real-time” architecture (in the sense of interactions with low delay, not in the sense of “Response time guarantees” on page 298). But why don’t we build all applications this way? 

The challenge is that the assumption of stateless clients and request/response interactions is very deeply ingrained in our databases, libraries, frameworks, and protocols. Many datastores support read and write operations where a request returns one response, but much fewer provide an ability to subscribe to changes—i.e., a request that returns a stream of responses over time (see “API support for change streams” on page 456). 

In order to extend the write path all the way to the end user, we would need to fundamentally rethink the way we build many of these systems: moving away from request/ response interaction and toward publish/subscribe dataflow [27]. I think that the advantages of more responsive user interfaces and better offline support would make it worth the effort. If you are designing data systems, I hope that you will keep in mind the option of subscribing to changes, not just querying the current state. 

# **Reads are events too** 

We discussed that when a stream processor writes derived data to a store (database, cache, or index), and when user requests query that store, the store acts as the boundary between the write path and the read path. The store allows random-access read queries to the data that would otherwise require scanning the whole event log. 

In many cases, the data storage is separate from the streaming system. But recall that stream processors also need to maintain state to perform aggregations and joins (see “Stream Joins” on page 472). This state is normally hidden inside the stream processor, but some frameworks allow it to also be queried by outside clients [45], turning the stream processor itself into a kind of simple database. 

I would like to take that idea further. As discussed so far, the writes to the store go through an event log, while reads are transient network requests that go directly to 


the nodes that store the data being queried. This is a reasonable design, but not the only possible one. It is also possible to represent read requests as streams of events, and send both the read events and the write events through a stream processor; the processor responds to read events by emitting the result of the read to an output stream [46]. 

When both the writes and the reads are represented as events, and routed to the same stream operator in order to be handled, we are in fact performing a stream-table join between the stream of read queries and the database. The read event needs to be sent to the database partition holding the data (see “Request Routing” on page 214), just like batch and stream processors need to copartition inputs on the same key when joining (see “Reduce-Side Joins and Grouping” on page 403). 

This correspondence between serving requests and performing joins is quite fundamental [47]. A one-off read request just passes the request through the join operator and then immediately forgets it; a subscribe request is a persistent join with past and future events on the other side of the join. 

Recording a log of read events potentially also has benefits with regard to tracking causal dependencies and data provenance across a system: it would allow you to reconstruct what the user saw before they made a particular decision. For example, in an online shop, it is likely that the predicted shipping date and the inventory status shown to a customer affect whether they choose to buy an item [4]. To analyze this connection, you need to record the result of the user’s query of the shipping and inventory status. 

Writing read events to durable storage thus enables better tracking of causal dependencies (see “Ordering events to capture causality” on page 493), but it incurs additional storage and I/O cost. Optimizing such systems to reduce the overhead is still an open research problem [2]. But if you already log read requests for operational purposes, as a side effect of request processing, it is not such a great change to make the log the source of the requests instead. 

# **Multi-partition data processing** 

For queries that only touch a single partition, the effort of sending queries through a stream and collecting a stream of responses is perhaps overkill. However, this idea opens the possibility of distributed execution of complex queries that need to combine data from several partitions, taking advantage of the infrastructure for message routing, partitioning, and joining that is already provided by stream processors. 

Storm’s distributed RPC feature supports this usage pattern (see “Message passing and RPC” on page 468). For example, it has been used to compute the number of people who have seen a URL on Twitter—i.e., the union of the follower sets of everyone who has tweeted that URL [48]. As the set of Twitter users is partitioned, this computation requires combining results from many partitions. 


Another example of this pattern occurs in fraud prevention: in order to assess the risk of whether a particular purchase event is fraudulent, you can examine the reputation scores of the user’s IP address, email address, billing address, shipping address, and so on. Each of these reputation databases is itself partitioned, and so collecting the scores for a particular purchase event requires a sequence of joins with differently partitioned datasets [49]. 

The internal query execution graphs of MPP databases have similar characteristics (see “Comparing Hadoop to Distributed Databases” on page 414). If you need to perform this kind of multi-partition join, it is probably simpler to use a database that provides this feature than to implement it using a stream processor. However, treating queries as streams provides an option for implementing large-scale applications that run against the limits of conventional off-the-shelf solutions. 

## Aiming for correctness

With stateless services that only read data, it is not a big deal if something goes wrong: you can fix the bug and restart the service, and everything returns to normal. Stateful systems such as databases are not so simple: they are designed to remember things forever (more or less), so if something goes wrong, the effects also potentially last forever—which means they require more careful thought [50]. 

We want to build applications that are reliable and _correct_ (i.e., programs whose semantics are well defined and understood, even in the face of various faults). For approximately four decades, the transaction properties of atomicity, isolation, and durability (Chapter 7) have been the tools of choice for building correct applications. However, those foundations are weaker than they seem: witness for example the confusion of weak isolation levels (see “Weak Isolation Levels” on page 233). 

In some areas, transactions are being abandoned entirely and replaced with models that offer better performance and scalability, but much messier semantics (see for example “Leaderless Replication” on page 177). _Consistency_ is often talked about, but poorly defined (see “Consistency” on page 224 and Chapter 9). Some people assert that we should “embrace weak consistency” for the sake of better availability, while lacking a clear idea of what that actually means in practice. 

For a topic that is so important, our understanding and our engineering methods are surprisingly flaky. For example, it is very difficult to determine whether it is safe to run a particular application at a particular transaction isolation level or replication configuration [51, 52]. Often simple solutions appear to work correctly when concurrency is low and there are no faults, but turn out to have many subtle bugs in more demanding circumstances. 

For example, Kyle Kingsbury’s Jepsen experiments [53] have highlighted the stark discrepancies between some products’ claimed safety guarantees and their actual 


behavior in the presence of network problems and crashes. Even if infrastructure products like databases were free from problems, application code would still need to correctly use the features they provide, which is error-prone if the configuration is hard to understand (which is the case with weak isolation levels, quorum configurations, and so on). 

If your application can tolerate occasionally corrupting or losing data in unpredictable ways, life is a lot simpler, and you might be able to get away with simply crossing your fingers and hoping for the best. On the other hand, if you need stronger assurances of correctness, then serializability and atomic commit are established approaches, but they come at a cost: they typically only work in a single datacenter (ruling out geographically distributed architectures), and they limit the scale and fault-tolerance properties you can achieve. 

While the traditional transaction approach is not going away, I also believe it is not the last word in making applications correct and resilient to faults. In this section I will suggest some ways of thinking about correctness in the context of dataflow architectures. 

### The End-to-End Argument for Databases 

Just because an application uses a data system that provides comparatively strong safety properties, such as serializable transactions, that does not mean the application is guaranteed to be free from data loss or corruption. For example, if an application has a bug that causes it to write incorrect data, or delete data from a database, serializable transactions aren’t going to save you. 

This example may seem frivolous, but it is worth taking seriously: application bugs occur, and people make mistakes. I used this example in “State, Streams, and Immutability” on page 459 to argue in favor of immutable and append-only data, because it is easier to recover from such mistakes if you remove the ability of faulty code to destroy good data. 

Although immutability is useful, it is not a cure-all by itself. Let’s look at a more subtle example of data corruption that can occur. 

# **Exactly-once execution of an operation** 

In “Fault Tolerance” on page 476 we encountered an idea called _exactly-once_ (or _effectively-once_ ) semantics. If something goes wrong while processing a message, you can either give up (drop the message—i.e., incur data loss) or try again. If you try again, there is the risk that it actually succeeded the first time, but you just didn’t find out about the success, and so the message ends up being processed twice. 

Processing twice is a form of data corruption: it is undesirable to charge a customer twice for the same service (billing them too much) or increment a counter twice 


(overstating some metric). In this context, _exactly-once_ means arranging the computation such that the final effect is the same as if no faults had occurred, even if the operation actually was retried due to some fault. We previously discussed a few approaches for achieving this goal. 

One of the most effective approaches is to make the operation _idempotent_ (see “Idempotence” on page 478); that is, to ensure that it has the same effect, no matter whether it is executed once or multiple times. However, taking an operation that is not naturally idempotent and making it idempotent requires some effort and care: you may need to maintain some additional metadata (such as the set of operation IDs that have updated a value), and ensure fencing when failing over from one node to another (see “The leader and the lock” on page 301). 

# **Duplicate suppression** 

The same pattern of needing to suppress duplicates occurs in many other places besides stream processing. For example, TCP uses sequence numbers on packets to put them in the correct order at the recipient, and to determine whether any packets were lost or duplicated on the network. Any lost packets are retransmitted and any duplicates are removed by the TCP stack before it hands the data to an application. 

However, this duplicate suppression only works within the context of a single TCP connection. Imagine the TCP connection is a client’s connection to a database, and it is currently executing the transaction in Example 12-1. In many databases, a transaction is tied to a client connection (if the client sends several queries, the database knows that they belong to the same transaction because they are sent on the same TCP connection). If the client suffers a network interruption and connection timeout after sending the `COMMIT` , but before hearing back from the database server, it does not know whether the transaction has been committed or aborted (Figure 8-1). 

# _Example 12-1. A nonidempotent transfer of money from one account to another_ 

# **`BEGIN`** `TRANSACTION;` 

```
UPDATEaccountsSETbalance=balance+11.00WHEREaccount_id=1234;
UPDATEaccountsSETbalance=balance-11.00WHEREaccount_id=4321;
COMMIT;
```

The client can reconnect to the database and retry the transaction, but now it is outside of the scope of TCP duplicate suppression. Since the transaction in Example 12-1 is not idempotent, it could happen that $22 is transferred instead of the desired $11. Thus, even though Example 12-1 is a standard example for transaction atomicity, it is actually not correct, and real banks do not work like this [3]. 

Two-phase commit (see “Atomic Commit and Two-Phase Commit (2PC)” on page 354) protocols break the 1:1 mapping between a TCP connection and a transaction, since they must allow a transaction coordinator to reconnect to a database after a net‐ 


work fault, and tell it whether to commit or abort an in-doubt transaction. Is this sufficient to ensure that the transaction will only be executed once? Unfortunately not. 

Even if we can suppress duplicate transactions between the database client and server, we still need to worry about the network between the end-user device and the application server. For example, if the end-user client is a web browser, it probably uses an HTTP POST request to submit an instruction to the server. Perhaps the user is on a weak cellular data connection, and they succeed in sending the POST, but the signal becomes too weak before they are able to receive the response from the server. 

In this case, the user will probably be shown an error message, and they may retry manually. Web browsers warn, “Are you sure you want to submit this form again?”— and the user says yes, because they wanted the operation to happen. (The Post/Redirect/Get pattern [54] avoids this warning message in normal operation, but it doesn’t help if the POST request times out.) From the web server’s point of view the retry is a separate request, and from the database’s point of view it is a separate transaction. The usual deduplication mechanisms don’t help. 

# **Operation identifiers** 

To make the operation idempotent through several hops of network communication, it is not sufficient to rely just on a transaction mechanism provided by a database— you need to consider the _end-to-end_ flow of the request. 

For example, you could generate a unique identifier for an operation (such as a UUID) and include it as a hidden form field in the client application, or calculate a hash of all the relevant form fields to derive the operation ID [3]. If the web browser submits the POST request twice, the two requests will have the same operation ID. You can then pass that operation ID all the way through to the database and check that you only ever execute one operation with a given ID, as shown in Example 12-2. 

# _Example 12-2. Suppressing duplicate requests using a unique ID_ 

```
ALTERTABLErequestsADDUNIQUE (request_id);
```

```
BEGINTRANSACTION;
```

```
INSERTINTOrequests
  (request_id, from_account, to_account, amount)
VALUES('0286FDB8-D7E1-423F-B40B-792B3608036C', 4321, 1234, 11.00);
```

```
UPDATEaccountsSETbalance=balance+11.00WHEREaccount_id=1234;
UPDATEaccountsSETbalance=balance-11.00WHEREaccount_id=4321;
```

```
COMMIT;
```


Example 12-2 relies on a uniqueness constraint on the `request_id` column. If a transaction attempts to insert an ID that already exists, the `INSERT` fails and the transaction is aborted, preventing it from taking effect twice. Relational databases can generally maintain a uniqueness constraint correctly, even at weak isolation levels (whereas an application-level check-then-insert may fail under nonserializable isolation, as discussed in “Write Skew and Phantoms” on page 246). 

Besides suppressing duplicate requests, the `requests` table in Example 12-2 acts as a kind of event log, hinting in the direction of event sourcing (see “Event Sourcing” on page 457). The updates to the account balances don’t actually have to happen in the same transaction as the insertion of the event, since they are redundant and could be derived from the request event in a downstream consumer—as long as the event is processed exactly once, which can again be enforced using the request ID. 

# **The end-to-end argument** 

This scenario of suppressing duplicate transactions is just one example of a more general principle called the _end-to-end argument_ , which was articulated by Saltzer, Reed, and Clark in 1984 [55]: 

The function in question can completely and correctly be implemented only with the knowledge and help of the application standing at the endpoints of the communication system. Therefore, providing that questioned function as a feature of the communication system itself is not possible. (Sometimes an incomplete version of the function provided by the communication system may be useful as a performance enhancement.) 

In our example, the _function in question_ was duplicate suppression. We saw that TCP suppresses duplicate packets at the TCP connection level, and some stream processors provide so-called exactly-once semantics at the message processing level, but that is not enough to prevent a user from submitting a duplicate request if the first one times out. By themselves, TCP, database transactions, and stream processors cannot entirely rule out these duplicates. Solving the problem requires an end-to-end solution: a transaction identifier that is passed all the way from the end-user client to the database. 

The end-to-end argument also applies to checking the integrity of data: checksums built into Ethernet, TCP, and TLS can detect corruption of packets in the network, but they cannot detect corruption due to bugs in the software at the sending and receiving ends of the network connection, or corruption on the disks where the data is stored. If you want to catch all possible sources of data corruption, you also need end-to-end checksums. 

A similar argument applies with encryption [55]: the password on your home WiFi network protects against people snooping your WiFi traffic, but not against attackers elsewhere on the internet; TLS/SSL between your client and the server protects 


against network attackers, but not against compromises of the server. Only end-toend encryption and authentication can protect against all of these things. 

Although the low-level features (TCP duplicate suppression, Ethernet checksums, WiFi encryption) cannot provide the desired end-to-end features by themselves, they are still useful, since they reduce the probability of problems at the higher levels. For example, HTTP requests would often get mangled if we didn’t have TCP putting the packets back in the right order. We just need to remember that the low-level reliability features are not by themselves sufficient to ensure end-to-end correctness. 

# **Applying end-to-end thinking in data systems** 

This brings me back to my original thesis: just because an application uses a data system that provides comparatively strong safety properties, such as serializable transactions, that does not mean the application is guaranteed to be free from data loss or corruption. The application itself needs to take end-to-end measures, such as duplicate suppression, as well. 

That is a shame, because fault-tolerance mechanisms are hard to get right. Low-level reliability mechanisms, such as those in TCP, work quite well, and so the remaining higher-level faults occur fairly rarely. It would be really nice to wrap up the remaining high-level fault-tolerance machinery in an abstraction so that application code needn’t worry about it—but I fear that we have not yet found the right abstraction. 

Transactions have long been seen as a good abstraction, and I do believe that they are useful. As discussed in the introduction to Chapter 7, they take a wide range of possible issues (concurrent writes, constraint violations, crashes, network interruptions, disk failures) and collapse them down to two possible outcomes: commit or abort. That is a huge simplification of the programming model, but I fear that it is not enough. 

Transactions are expensive, especially when they involve heterogeneous storage technologies (see “Distributed Transactions in Practice” on page 360). When we refuse to use distributed transactions because they are too expensive, we end up having to reimplement fault-tolerance mechanisms in application code. As numerous examples throughout this book have shown, reasoning about concurrency and partial failure is difficult and counterintuitive, and so I suspect that most application-level mechanisms do not work correctly. The consequence is lost or corrupted data. 

For these reasons, I think it is worth exploring fault-tolerance abstractions that make it easy to provide application-specific end-to-end correctness properties, but also maintain good performance and good operational characteristics in a large-scale distributed environment. 


### Enforcing Constraints 

Let’s think about correctness in the context of the ideas around unbundling databases (“Unbundling Databases” on page 499). We saw that end-to-end duplicate suppression can be achieved with a request ID that is passed all the way from the client to the database that records the write. What about other kinds of constraints? 

In particular, let’s focus on uniqueness constraints—such as the one we relied on in Example 12-2. In “Constraints and uniqueness guarantees” on page 330 we saw several other examples of application features that need to enforce uniqueness: a username or email address must uniquely identify a user, a file storage service cannot have more than one file with the same name, and two people cannot book the same seat on a flight or in a theater. 

Other kinds of constraints are very similar: for example, ensuring that an account balance never goes negative, that you don’t sell more items than you have in stock in the warehouse, or that a meeting room does not have overlapping bookings. Techniques that enforce uniqueness can often be used for these kinds of constraints as well. 

# **Uniqueness constraints require consensus** 

In Chapter 9 we saw that in a distributed setting, enforcing a uniqueness constraint requires consensus: if there are several concurrent requests with the same value, the system somehow needs to decide which one of the conflicting operations is accepted, and reject the others as violations of the constraint. 

The most common way of achieving this consensus is to make a single node the leader, and put it in charge of making all the decisions. That works fine as long as you don’t mind funneling all requests through a single node (even if the client is on the other side of the world), and as long as that node doesn’t fail. If you need to tolerate the leader failing, you’re back at the consensus problem again (see “Single-leader replication and consensus” on page 367). 

Uniqueness checking can be scaled out by partitioning based on the value that needs to be unique. For example, if you need to ensure uniqueness by request ID, as in Example 12-2, you can ensure all requests with the same request ID are routed to the same partition (see Chapter 6). If you need usernames to be unique, you can partition by hash of username. 

However, asynchronous multi-master replication is ruled out, because it could happen that different masters concurrently accept conflicting writes, and thus the values are no longer unique (see “Implementing Linearizable Systems” on page 332). If you want to be able to immediately reject any writes that would violate the constraint, synchronous coordination is unavoidable [56]. 


# **Uniqueness in log-based messaging** 

The log ensures that all consumers see messages in the same order—a guarantee that is formally known as _total order broadcast_ and is equivalent to consensus (see “Total Order Broadcast” on page 348). In the unbundled database approach with log-based messaging, we can use a very similar approach to enforce uniqueness constraints. 

A stream processor consumes all the messages in a log partition sequentially on a single thread (see “Logs compared to traditional messaging” on page 448). Thus, if the log is partitioned based on the value that needs to be unique, a stream processor can unambiguously and deterministically decide which one of several conflicting operations came first. For example, in the case of several users trying to claim the same username [57]: 

1. Every request for a username is encoded as a message, and appended to a partition determined by the hash of the username. 

2. A stream processor sequentially reads the requests in the log, using a local database to keep track of which usernames are taken. For every request for a username that is available, it records the name as taken and emits a success message to an output stream. For every request for a username that is already taken, it emits a rejection message to an output stream. 

3. The client that requested the username watches the output stream and waits for a success or rejection message corresponding to its request. 

This algorithm is basically the same as in “Implementing linearizable storage using total order broadcast” on page 350. It scales easily to a large request throughput by increasing the number of partitions, as each partition can be processed independently. 

The approach works not only for uniqueness constraints, but also for many other kinds of constraints. Its fundamental principle is that any writes that may conflict are routed to the same partition and processed sequentially. As discussed in “What is a conflict?” on page 174 and “Write Skew and Phantoms” on page 246, the definition of a conflict may depend on the application, but the stream processor can use arbitrary logic to validate a request. This idea is similar to the approach pioneered by Bayou in the 1990s [58]. 

# **Multi-partition request processing** 

Ensuring that an operation is executed atomically, while satisfying constraints, becomes more interesting when several partitions are involved. In Example 12-2, there are potentially three partitions: the one containing the request ID, the one containing the payee account, and the one containing the payer account. There is no reason why those three things should be in the same partition, since they are all independent from each other. 

In the traditional approach to databases, executing this transaction would require an atomic commit across all three partitions, which essentially forces it into a total order with respect to all other transactions on any of those partitions. Since there is now cross-partition coordination, different partitions can no longer be processed independently, so throughput is likely to suffer. 

However, it turns out that equivalent correctness can be achieved with partitioned logs, and without an atomic commit: 

1. The request to transfer money from account A to account B is given a unique request ID by the client, and appended to a log partition based on the request ID. 

2. A stream processor reads the log of requests. For each request message it emits two messages to output streams: a debit instruction to the payer account A (partitioned by A), and a credit instruction to the payee account B (partitioned by B). The original request ID is included in those emitted messages. 

3. Further processors consume the streams of credit and debit instructions, deduplicate by request ID, and apply the changes to the account balances. 

Steps 1 and 2 are necessary because if the client directly sent the credit and debit instructions, it would require an atomic commit across those two partitions to ensure that either both or neither happen. To avoid the need for a distributed transaction, we first durably log the request as a single message, and then derive the credit and debit instructions from that first message. Single-object writes are atomic in almost all data systems (see “Single-object writes” on page 230), and so the request either appears in the log or it doesn’t, without any need for a multi-partition atomic commit. 

If the stream processor in step 2 crashes, it resumes processing from its last checkpoint. In doing so, it does not skip any request messages, but it may process requests multiple times and produce duplicate credit and debit instructions. However, since it is deterministic, it will just produce the same instructions again, and the processors in step 3 can easily deduplicate them using the end-to-end request ID. 

If you want to ensure that the payer account is not overdrawn by this transfer, you can additionally have a stream processor (partitioned by payer account number) that maintains account balances and validates transactions. Only valid transactions would then be placed in the request log in step 1. 

By breaking down the multi-partition transaction into two differently partitioned stages and using the end-to-end request ID, we have achieved the same correctness property (every request is applied exactly once to both the payer and payee accounts), even in the presence of faults, and without using an atomic commit protocol. The 


idea of using multiple differently partitioned stages is similar to what we discussed in “Multi-partition data processing” on page 514 (see also “Concurrency control” on page 462). 

### Timeliness and Integrity 

A convenient property of transactions is that they are typically linearizable (see “Linearizability” on page 324): that is, a writer waits until a transaction is committed, and thereafter its writes are immediately visible to all readers. 

This is not the case when unbundling an operation across multiple stages of stream processors: consumers of a log are asynchronous by design, so a sender does not wait until its message has been processed by consumers. However, it is possible for a client to wait for a message to appear on an output stream. This is what we did in “Uniqueness in log-based messaging” on page 522 when checking whether a uniqueness constraint was satisfied. 

In this example, the correctness of the uniqueness check does not depend on whether the sender of the message waits for the outcome. The waiting only has the purpose of synchronously informing the sender whether or not the uniqueness check succeeded, but this notification can be decoupled from the effects of processing the message. 

More generally, I think the term _consistency_ conflates two different requirements that are worth considering separately: 

# _Timeliness_ 

Timeliness means ensuring that users observe the system in an up-to-date state. We saw previously that if a user reads from a stale copy of the data, they may observe it in an inconsistent state (see “Problems with Replication Lag” on page 161). However, that inconsistency is temporary, and will eventually be resolved simply by waiting and trying again. 

The CAP theorem (see “The Cost of Linearizability” on page 335) uses consistency in the sense of linearizability, which is a strong way of achieving timeliness. Weaker timeliness properties like _read-after-write_ consistency (see “Reading Your Own Writes” on page 162) can also be useful. 

# _Integrity_ 

Integrity means absence of corruption; i.e., no data loss, and no contradictory or false data. In particular, if some derived dataset is maintained as a view onto some underlying data (see “Deriving current state from the event log” on page 458), the derivation must be correct. For example, a database index must correctly reflect the contents of the database—an index in which some records are missing is not very useful. 


If integrity is violated, the inconsistency is permanent: waiting and trying again is not going to fix database corruption in most cases. Instead, explicit checking and repair is needed. In the context of ACID transactions (see “The Meaning of ACID” on page 223), consistency is usually understood as some kind of application-specific notion of integrity. Atomicity and durability are important tools for preserving integrity. 

In slogan form: violations of timeliness are “eventual consistency,” whereas violations of integrity are “perpetual inconsistency.” 

I am going to assert that in most applications, integrity is much more important than timeliness. Violations of timeliness can be annoying and confusing, but violations of integrity can be catastrophic. 

For example, on your credit card statement, it is not surprising if a transaction that you made within the last 24 hours does not yet appear—it is normal that these systems have a certain lag. We know that banks reconcile and settle transactions asynchronously, and timeliness is not very important here [3]. However, it would be very bad if the statement balance was not equal to the sum of the transactions plus the previous statement balance (an error in the sums), or if a transaction was charged to you but not paid to the merchant (disappearing money). Such problems would be violations of the integrity of the system. 

# **Correctness of dataflow systems** 

ACID transactions usually provide both timeliness (e.g., linearizability) and integrity (e.g., atomic commit) guarantees. Thus, if you approach application correctness from the point of view of ACID transactions, the distinction between timeliness and integrity is fairly inconsequential. 

On the other hand, an interesting property of the event-based dataflow systems that we have discussed in this chapter is that they decouple timeliness and integrity. When processing event streams asynchronously, there is no guarantee of timeliness, unless you explicitly build consumers that wait for a message to arrive before returning. But integrity is in fact central to streaming systems. 

_Exactly-once_ or _effectively-once_ semantics (see “Fault Tolerance” on page 476) is a mechanism for preserving integrity. If an event is lost, or if an event takes effect twice, the integrity of a data system could be violated. Thus, fault-tolerant message delivery and duplicate suppression (e.g., idempotent operations) are important for maintaining the integrity of a data system in the face of faults. 

As we saw in the last section, reliable stream processing systems can preserve integrity without requiring distributed transactions and an atomic commit protocol, which means they can potentially achieve comparable correctness with much better 


performance and operational robustness. We achieved this integrity through a combination of mechanisms: 

- Representing the content of the write operation as a single message, which can easily be written atomically—an approach that fits very well with event sourcing (see “Event Sourcing” on page 457) 

- Deriving all other state updates from that single message using deterministic derivation functions, similarly to stored procedures (see “Actual Serial Execution” on page 252 and “Application code as a derivation function” on page 505) 

- Passing a client-generated request ID through all these levels of processing, enabling end-to-end duplicate suppression and idempotence 

- Making messages immutable and allowing derived data to be reprocessed from time to time, which makes it easier to recover from bugs (see “Advantages of immutable events” on page 460) 

This combination of mechanisms seems to me a very promising direction for building fault-tolerant applications in the future. 

# **Loosely interpreted constraints** 

As discussed previously, enforcing a uniqueness constraint requires consensus, typically implemented by funneling all events in a particular partition through a single node. This limitation is unavoidable if we want the traditional form of uniqueness constraint, and stream processing cannot avoid it. 

However, another thing to realize is that many real applications can actually get away with much weaker notions of uniqueness: 

- If two people concurrently register the same username or book the same seat, you can send one of them a message to apologize, and ask them to choose a different one. This kind of change to correct a mistake is called a _compensating transaction_ [59, 60]. 

- If customers order more items than you have in your warehouse, you can order in more stock, apologize to customers for the delay, and offer them a discount. This is actually the same as what you’d have to do if, say, a forklift truck ran over some of the items in your warehouse, leaving you with fewer items in stock than you thought you had [61]. Thus, the apology workflow already needs to be part of your business processes anyway, and so it might be unnecessary to require a linearizable constraint on the number of items in stock. 

- Similarly, many airlines overbook airplanes in the expectation that some passengers will miss their flight, and many hotels overbook rooms, expecting that some guests will cancel. In these cases, the constraint of “one person per seat” is deliberately violated for business reasons, and compensation processes (refunds, upgrades, providing a complimentary room at a neighboring hotel) are put in place to handle situations in which demand exceeds supply. Even if there was no overbooking, apology and compensation processes would be needed in order to deal with flights being cancelled due to bad weather or staff on strike—recovering from such issues is just a normal part of business [3]. 

- If someone withdraws more money than they have in their account, the bank can charge them an overdraft fee and ask them to pay back what they owe. By limiting the total withdrawals per day, the risk to the bank is bounded. 

In many business contexts, it is actually acceptable to temporarily violate a constraint and fix it up later by apologizing. The cost of the apology (in terms of money or reputation) varies, but it is often quite low: you can’t unsend an email, but you can send a follow-up email with a correction. If you accidentally charge a credit card twice, you can refund one of the charges, and the cost to you is just the processing fees and perhaps a customer complaint. Once money has been paid out of an ATM, you can’t directly get it back, although in principle you can send debt collectors to recover the money if the account was overdrawn and the customer won’t pay it back. 

Whether the cost of the apology is acceptable is a business decision. If it is acceptable, the traditional model of checking all constraints before even writing the data is unnecessarily restrictive, and a linearizable constraint is not needed. It may well be a reasonable choice to go ahead with a write optimistically, and to check the constraint after the fact. You can still ensure that the validation occurs before doing things that would be expensive to recover from, but that doesn’t imply you must do the validation before you even write the data. 

These applications _do_ require integrity: you would not want to lose a reservation, or have money disappear due to mismatched credits and debits. But they _don’t_ require timeliness on the enforcement of the constraint: if you have sold more items than you have in the warehouse, you can patch up the problem after the fact by apologizing. Doing so is similar to the conflict resolution approaches we discussed in “Handling Write Conflicts” on page 171. 

# **Coordination-avoiding data systems** 

We have now made two interesting observations: 

1. Dataflow systems can maintain integrity guarantees on derived data without atomic commit, linearizability, or synchronous cross-partition coordination. 

2. Although strict uniqueness constraints require timeliness and coordination, many applications are actually fine with loose constraints that may be temporarily violated and fixed up later, as long as integrity is preserved throughout. 


Taken together, these observations mean that dataflow systems can provide the data management services for many applications without requiring coordination, while still giving strong integrity guarantees. Such _coordination-avoiding_ data systems have a lot of appeal: they can achieve better performance and fault tolerance than systems that need to perform synchronous coordination [56]. 

For example, such a system could operate distributed across multiple datacenters in a multi-leader configuration, asynchronously replicating between regions. Any one datacenter can continue operating independently from the others, because no synchronous cross-region coordination is required. Such a system would have weak timeliness guarantees—it could not be linearizable without introducing coordination —but it can still have strong integrity guarantees. 

In this context, serializable transactions are still useful as part of maintaining derived state, but they can be run at a small scope where they work well [8]. Heterogeneous distributed transactions such as XA transactions (see “Distributed Transactions in Practice” on page 360) are not required. Synchronous coordination can still be introduced in places where it is needed (for example, to enforce strict constraints before an operation from which recovery is not possible), but there is no need for everything to pay the cost of coordination if only a small part of an application needs it [43]. 

Another way of looking at coordination and constraints: they reduce the number of apologies you have to make due to inconsistencies, but potentially also reduce the performance and availability of your system, and thus potentially increase the number of apologies you have to make due to outages. You cannot reduce the number of apologies to zero, but you can aim to find the best trade-off for your needs—the sweet spot where there are neither too many inconsistencies nor too many availability problems. 

### Trust, but Verify 

All of our discussion of correctness, integrity, and fault-tolerance has been under the assumption that certain things might go wrong, but other things won’t. We call these assumptions our _system model_ (see “Mapping system models to the real world” on page 309): for example, we should assume that processes can crash, machines can suddenly lose power, and the network can arbitrarily delay or drop messages. But we might also assume that data written to disk is not lost after `fsync` , that data in memory is not corrupted, and that the multiplication instruction of our CPU always returns the correct result. 

These assumptions are quite reasonable, as they are true most of the time, and it would be difficult to get anything done if we had to constantly worry about our computers making mistakes. Traditionally, system models take a binary approach toward faults: we assume that some things can happen, and other things can never happen. In reality, it is more a question of probabilities: some things are more likely, other 


things less likely. The question is whether violations of our assumptions happen often enough that we may encounter them in practice. 

We have seen that data can become corrupted while it is sitting untouched on disks (see “Replication and Durability” on page 227), and data corruption on the network can sometimes evade the TCP checksums (see “Weak forms of lying” on page 306). Maybe this is something we should be paying more attention to? 

One application that I worked on in the past collected crash reports from clients, and some of the reports we received could only be explained by random bit-flips in the memory of those devices. It seems unlikely, but if you have enough devices running your software, even very unlikely things do happen. Besides random memory corruption due to hardware faults or radiation, certain pathological memory access patterns can flip bits even in memory that has no faults [62]—an effect that can be used to break security mechanisms in operating systems [63] (this technique is known as _rowhammer_ ). Once you look closely, hardware isn’t quite the perfect abstraction that it may seem. 

To be clear, random bit-flips are still very rare on modern hardware [64]. I just want to point out that they are not beyond the realm of possibility, and so they deserve some attention. 

# **Maintaining integrity in the face of software bugs** 

Besides such hardware issues, there is always the risk of software bugs, which would not be caught by lower-level network, memory, or filesystem checksums. Even widely used database software has bugs: I have personally seen cases of MySQL failing to correctly maintain a uniqueness constraint [65] and PostgreSQL’s serializable isolation level exhibiting write skew anomalies [66], even though MySQL and PostgreSQL are robust and well-regarded databases that have been battle-tested by many people for many years. In less mature software, the situation is likely to be much worse. 

Despite considerable efforts in careful design, testing, and review, bugs still creep in. Although they are rare, and they eventually get found and fixed, there is still a period during which such bugs can corrupt data. 

When it comes to application code, we have to assume many more bugs, since most applications don’t receive anywhere near the amount of review and testing that database code does. Many applications don’t even correctly use the features that databases offer for preserving integrity, such as foreign key or uniqueness constraints [36]. 

Consistency in the sense of ACID (see “Consistency” on page 224) is based on the idea that the database starts off in a consistent state, and a transaction transforms it from one consistent state to another consistent state. Thus, we expect the database to always be in a consistent state. However, this notion only makes sense if you assume that the transaction is free from bugs. If the application uses the database incorrectly 


in some way, for example using a weak isolation level unsafely, the integrity of the database cannot be guaranteed. 

# **Don’t just blindly trust what they promise** 

With both hardware and software not always living up to the ideal that we would like them to be, it seems that data corruption is inevitable sooner or later. Thus, we should at least have a way of finding out if data has been corrupted so that we can fix it and try to track down the source of the error. Checking the integrity of data is known as _auditing_ . 

As discussed in “Advantages of immutable events” on page 460, auditing is not just for financial applications. However, auditability is highly important in finance precisely because everyone knows that mistakes happen, and we all recognize the need to be able to detect and fix problems. 

Mature systems similarly tend to consider the possibility of unlikely things going wrong, and manage that risk. For example, large-scale storage systems such as HDFS and Amazon S3 do not fully trust disks: they run background processes that continually read back files, compare them to other replicas, and move files from one disk to another, in order to mitigate the risk of silent corruption [67]. 

If you want to be sure that your data is still there, you have to actually read it and check. Most of the time it will still be there, but if it isn’t, you really want to find out sooner rather than later. By the same argument, it is important to try restoring from your backups from time to time—otherwise you may only find out that your backup is broken when it is too late and you have already lost data. Don’t just blindly trust that it is all working. 

# **A culture of verification** 

Systems like HDFS and S3 still have to assume that disks work correctly most of the time—which is a reasonable assumption, but not the same as assuming that they _always_ work correctly. However, not many systems currently have this kind of “trust, but verify” approach of continually auditing themselves. Many assume that correctness guarantees are absolute and make no provision for the possibility of rare data corruption. I hope that in the future we will see more _self-validating_ or _self-auditing_ systems that continually check their own integrity, rather than relying on blind trust [68]. 

I fear that the culture of ACID databases has led us toward developing applications on the basis of blindly trusting technology (such as a transaction mechanism), and neglecting any sort of auditability in the process. Since the technology we trusted worked well enough most of the time, auditing mechanisms were not deemed worth the investment. 


But then the database landscape changed: weaker consistency guarantees became the norm under the banner of NoSQL, and less mature storage technologies became widely used. Yet, because the audit mechanisms had not been developed, we continued building applications on the basis of blind trust, even though this approach had now become more dangerous. Let’s think for a moment about designing for auditability. 

# **Designing for auditability** 

If a transaction mutates several objects in a database, it is difficult to tell after the fact what that transaction means. Even if you capture the transaction logs (see “Change Data Capture” on page 454), the insertions, updates, and deletions in various tables do not necessarily give a clear picture of _why_ those mutations were performed. The invocation of the application logic that decided on those mutations is transient and cannot be reproduced. 

By contrast, event-based systems can provide better auditability. In the event sourcing approach, user input to the system is represented as a single immutable event, and any resulting state updates are derived from that event. The derivation can be made deterministic and repeatable, so that running the same log of events through the same version of the derivation code will result in the same state updates. 

Being explicit about dataflow (see “Philosophy of batch process outputs” on page 413) makes the _provenance_ of data much clearer, which makes integrity checking much more feasible. For the event log, we can use hashes to check that the event storage has not been corrupted. For any derived state, we can rerun the batch and stream processors that derived it from the event log in order to check whether we get the same result, or even run a redundant derivation in parallel. 

A deterministic and well-defined dataflow also makes it easier to debug and trace the execution of a system in order to determine why it did something [4, 69]. If something unexpected occurred, it is valuable to have the diagnostic capability to reproduce the exact circumstances that led to the unexpected event—a kind of time-travel debugging capability. 

# **The end-to-end argument again** 

If we cannot fully trust that every individual component of the system will be free from corruption—that every piece of hardware is fault-free and that every piece of software is bug-free—then we must at least periodically check the integrity of our data. If we don’t check, we won’t find out about corruption until it is too late and it has caused some downstream damage, at which point it will be much harder and more expensive to track down the problem. 

Checking the integrity of data systems is best done in an end-to-end fashion (see “The End-to-End Argument for Databases” on page 516): the more systems we can 


include in an integrity check, the fewer opportunities there are for corruption to go unnoticed at some stage of the process. If we can check that an entire derived data pipeline is correct end to end, then any disks, networks, services, and algorithms along the path are implicitly included in the check. 

Having continuous end-to-end integrity checks gives you increased confidence about the correctness of your systems, which in turn allows you to move faster [70]. Like automated testing, auditing increases the chances that bugs will be found quickly, and thus reduces the risk that a change to the system or a new storage technology will cause damage. If you are not afraid of making changes, you can much better evolve an application to meet changing requirements. 

# **Tools for auditable data systems** 

At present, not many data systems make auditability a top-level concern. Some applications implement their own audit mechanisms, for example by logging all changes to a separate audit table, but guaranteeing the integrity of the audit log and the database state is still difficult. A transaction log can be made tamper-proof by periodically signing it with a hardware security module, but that does not guarantee that the right transactions went into the log in the first place. 

It would be interesting to use cryptographic tools to prove the integrity of a system in a way that is robust to a wide range of hardware and software issues, and even potentially malicious actions. Cryptocurrencies, blockchains, and distributed ledger technologies such as Bitcoin, Ethereum, Ripple, Stellar, and various others [71, 72, 73] have sprung up to explore this area. 

I am not qualified to comment on the merits of these technologies as currencies or mechanisms for agreeing contracts. However, from a data systems point of view they contain some interesting ideas. Essentially, they are distributed databases, with a data model and transaction mechanism, in which different replicas can be hosted by mutually untrusting organizations. The replicas continually check each other’s integrity and use a consensus protocol to agree on the transactions that should be executed. 

I am somewhat skeptical about the Byzantine fault tolerance aspects of these technologies (see “Byzantine Faults” on page 304), and I find the technique of _proof of work_ (e.g., Bitcoin mining) extraordinarily wasteful. The transaction throughput of Bitcoin is rather low, albeit for political and economic reasons more than for technical ones. However, the integrity checking aspects are interesting. 

Cryptographic auditing and integrity checking often relies on _Merkle trees_ [74], which are trees of hashes that can be used to efficiently prove that a record appears in some dataset (and a few other things). Outside of the hype of cryptocurrencies, _certificate transparency_ is a security technology that relies on Merkle trees to check the validity of TLS/SSL certificates [75, 76]. 


I could imagine integrity-checking and auditing algorithms, like those of certificate transparency and distributed ledgers, becoming more widely used in data systems in general. Some work will be needed to make them equally scalable as systems without cryptographic auditing, and to keep the performance penalty as low as possible. But I think this is an interesting area to watch in the future. 

## Doing the right thing

In the final section of this book, I would like to take a step back. Throughout this book we have examined a wide range of different architectures for data systems, evaluated their pros and cons, and explored techniques for building reliable, scalable, and maintainable applications. However, we have left out an important and fundamental part of the discussion, which I would now like to fill in. 

Every system is built for a purpose; every action we take has both intended and unintended consequences. The purpose may be as simple as making money, but the consequences for the world may reach far beyond that original purpose. We, the engineers building these systems, have a responsibility to carefully consider those consequences and to consciously decide what kind of world we want to live in. 

We talk about data as an abstract thing, but remember that many datasets are about people: their behavior, their interests, their identity. We must treat such data with humanity and respect. Users are humans too, and human dignity is paramount. 

Software development increasingly involves making important ethical choices. There are guidelines to help software engineers navigate these issues, such as the ACM’s Software Engineering Code of Ethics and Professional Practice [77], but they are rarely discussed, applied, and enforced in practice. As a result, engineers and product managers sometimes take a very cavalier attitude to privacy and potential negative consequences of their products [78, 79, 80]. 

A technology is not good or bad in itself—what matters is how it is used and how it affects people. This is true for a software system like a search engine in much the same way as it is for a weapon like a gun. I think it is not sufficient for software engineers to focus exclusively on the technology and ignore its consequences: the ethical responsibility is ours to bear also. Reasoning about ethics is difficult, but it is too important to ignore. 

### Predictive Analytics 

For example, predictive analytics is a major part of the “Big Data” hype. Using data analysis to predict the weather, or the spread of diseases, is one thing [81]; it is another matter to predict whether a convict is likely to reoffend, whether an applicant for a loan is likely to default, or whether an insurance customer is likely to make expensive claims. The latter have a direct effect on individual people’s lives. 


Naturally, payment networks want to prevent fraudulent transactions, banks want to avoid bad loans, airlines want to avoid hijackings, and companies want to avoid hiring ineffective or untrustworthy people. From their point of view, the cost of a missed business opportunity is low, but the cost of a bad loan or a problematic employee is much higher, so it is natural for organizations to want to be cautious. If in doubt, they are better off saying no. 

However, as algorithmic decision-making becomes more widespread, someone who has (accurately or falsely) been labeled as risky by some algorithm may suffer a large number of those “no” decisions. Systematically being excluded from jobs, air travel, insurance coverage, property rental, financial services, and other key aspects of society is such a large constraint of the individual’s freedom that it has been called “algorithmic prison” [82]. In countries that respect human rights, the criminal justice system presumes innocence until proven guilty; on the other hand, automated systems can systematically and arbitrarily exclude a person from participating in society without any proof of guilt, and with little chance of appeal. 

# **Bias and discrimination** 

Decisions made by an algorithm are not necessarily any better or any worse than those made by a human. Every person is likely to have biases, even if they actively try to counteract them, and discriminatory practices can become culturally institutionalized. There is hope that basing decisions on data, rather than subjective and instinctive assessments by people, could be more fair and give a better chance to people who are often overlooked in the traditional system [83]. 

When we develop predictive analytics systems, we are not merely automating a human’s decision by using software to specify the rules for when to say yes or no; we are even leaving the rules themselves to be inferred from data. However, the patterns learned by these systems are opaque: even if there is some correlation in the data, we may not know why. If there is a systematic bias in the input to an algorithm, the system will most likely learn and amplify that bias in its output [84]. 

In many countries, anti-discrimination laws prohibit treating people differently depending on protected traits such as ethnicity, age, gender, sexuality, disability, or beliefs. Other features of a person’s data may be analyzed, but what happens if they are correlated with protected traits? For example, in racially segregated neighborhoods, a person’s postal code or even their IP address is a strong predictor of race. Put like this, it seems ridiculous to believe that an algorithm could somehow take biased data as input and produce fair and impartial output from it [85]. Yet this belief often seems to be implied by proponents of data-driven decision making, an attitude that has been satirized as “machine learning is like money laundering for bias” [86]. 

Predictive analytics systems merely extrapolate from the past; if the past is discriminatory, they codify that discrimination. If we want the future to be better than the 


past, moral imagination is required, and that’s something only humans can provide [87]. Data and models should be our tools, not our masters. 

# **Responsibility and accountability** 

Automated decision making opens the question of responsibility and accountability [87]. If a human makes a mistake, they can be held accountable, and the person affected by the decision can appeal. Algorithms make mistakes too, but who is accountable if they go wrong [88]? When a self-driving car causes an accident, who is responsible? If an automated credit scoring algorithm systematically discriminates against people of a particular race or religion, is there any recourse? If a decision by your machine learning system comes under judicial review, can you explain to the judge how the algorithm made its decision? 

Credit rating agencies are an old example of collecting data to make decisions about people. A bad credit score makes life difficult, but at least a credit score is normally based on relevant facts about a person’s actual borrowing history, and any errors in the record can be corrected (although the agencies normally do not make this easy). However, scoring algorithms based on machine learning typically use a much wider range of inputs and are much more opaque, making it harder to understand how a particular decision has come about and whether someone is being treated in an unfair or discriminatory way [89]. 

A credit score summarizes “How did you behave in the past?” whereas predictive analytics usually work on the basis of “Who is similar to you, and how did people like you behave in the past?” Drawing parallels to others’ behavior implies stereotyping people, for example based on where they live (a close proxy for race and socioeconomic class). What about people who get put in the wrong bucket? Furthermore, if a decision is incorrect due to erroneous data, recourse is almost impossible [87]. 

Much data is statistical in nature, which means that even if the probability distribution on the whole is correct, individual cases may well be wrong. For example, if the average life expectancy in your country is 80 years, that doesn’t mean you’re expected to drop dead on your 80th birthday. From the average and the probability distribution, you can’t say much about the age to which one particular person will live. Similarly, the output of a prediction system is probabilistic and may well be wrong in individual cases. 

A blind belief in the supremacy of data for making decisions is not only delusional, it is positively dangerous. As data-driven decision making becomes more widespread, we will need to figure out how to make algorithms accountable and transparent, how to avoid reinforcing existing biases, and how to fix them when they inevitably make mistakes. 

We will also need to figure out how to prevent data being used to harm people, and realize its positive potential instead. For example, analytics can reveal financial and 


social characteristics of people’s lives. On the one hand, this power could be used to focus aid and support to help those people who most need it. On the other hand, it is sometimes used by predatory business seeking to identify vulnerable people and sell them risky products such as high-cost loans and worthless college degrees [87, 90]. 

# **Feedback loops** 

Even with predictive applications that have less immediately far-reaching effects on people, such as recommendation systems, there are difficult issues that we must confront. When services become good at predicting what content users want to see, they may end up showing people only opinions they already agree with, leading to echo chambers in which stereotypes, misinformation, and polarization can breed. We are already seeing the impact of social media echo chambers on election campaigns [91]. 

When predictive analytics affect people’s lives, particularly pernicious problems arise due to self-reinforcing feedback loops. For example, consider the case of employers using credit scores to evaluate potential hires. You may be a good worker with a good credit score, but suddenly find yourself in financial difficulties due to a misfortune outside of your control. As you miss payments on your bills, your credit score suffers, and you will be less likely to find work. Joblessness pushes you toward poverty, which further worsens your scores, making it even harder to find employment [87]. It’s a downward spiral due to poisonous assumptions, hidden behind a camouflage of mathematical rigor and data. 

We can’t always predict when such feedback loops happen. However, many consequences can be predicted by thinking about the entire system (not just the computerized parts, but also the people interacting with it)—an approach known as _systems thinking_ [92]. We can try to understand how a data analysis system responds to different behaviors, structures, or characteristics. Does the system reinforce and amplify existing differences between people (e.g., making the rich richer or the poor poorer), or does it try to combat injustice? And even with the best intentions, we must beware of unintended consequences. 

### Privacy and Tracking 

Besides the problems of predictive analytics—i.e., using data to make automated decisions about people—there are ethical problems with data collection itself. What is the relationship between the organizations collecting data and the people whose data is being collected? 

When a system only stores data that a user has explicitly entered, because they want the system to store and process it in a certain way, the system is performing a service for the user: the user is the customer. But when a user’s activity is tracked and logged as a side effect of other things they are doing, the relationship is less clear. The service 


no longer just does what the user tells it to do, but it takes on interests of its own, which may conflict with the user’s interests. 

Tracking behavioral data has become increasingly important for user-facing features of many online services: tracking which search results are clicked helps improve the ranking of search results; recommending “people who liked X also liked Y” helps users discover interesting and useful things; A/B tests and user flow analysis can help indicate how a user interface might be improved. Those features require some amount of tracking of user behavior, and users benefit from them. 

However, depending on a company’s business model, tracking often doesn’t stop there. If the service is funded through advertising, the advertisers are the actual customers, and the users’ interests take second place. Tracking data becomes more detailed, analyses become further-reaching, and data is retained for a long time in order to build up detailed profiles of each person for marketing purposes. 

Now the relationship between the company and the user whose data is being collected starts looking quite different. The user is given a free service and is coaxed into engaging with it as much as possible. The tracking of the user serves not primarily that individual, but rather the needs of the advertisers who are funding the service. I think this relationship can be appropriately described with a word that has more sinister connotations: _surveillance_ . 

# **Surveillance** 

As a thought experiment, try replacing the word _data_ with _surveillance_ , and observe if common phrases still sound so good [93]. How about this: “In our surveillancedriven organization we collect real-time surveillance streams and store them in our surveillance warehouse. Our surveillance scientists use advanced analytics and surveillance processing in order to derive new insights.” 

This thought experiment is unusually polemic for this book, _Designing SurveillanceIntensive Applications_ , but I think that strong words are needed to emphasize this point. In our attempts to make software “eat the world” [94], we have built the greatest mass surveillance infrastructure the world has ever seen. Rushing toward an Internet of Things, we are rapidly approaching a world in which every inhabited space contains at least one internet-connected microphone, in the form of smartphones, smart TVs, voice-controlled assistant devices, baby monitors, and even children’s toys that use cloud-based speech recognition. Many of these devices have a terrible security record [95]. 

Even the most totalitarian and repressive regimes could only dream of putting a microphone in every room and forcing every person to constantly carry a device capable of tracking their location and movements. Yet we apparently voluntarily, even enthusiastically, throw ourselves into this world of total surveillance. The differ‐ 


ence is just that the data is being collected by corporations rather than government agencies [96]. 

Not all data collection necessarily qualifies as surveillance, but examining it as such can help us understand our relationship with the data collector. Why are we seemingly happy to accept surveillance by corporations? Perhaps you feel you have nothing to hide—in other words, you are totally in line with existing power structures, you are not a marginalized minority, and you needn’t fear persecution [97]. Not everyone is so fortunate. Or perhaps it’s because the purpose seems benign—it’s not overt coercion and conformance, but merely better recommendations and more personalized marketing. However, combined with the discussion of predictive analytics from the last section, that distinction seems less clear. 

We are already seeing car insurance premiums linked to tracking devices in cars, and health insurance coverage that depends on people wearing a fitness tracking device. When surveillance is used to determine things that hold sway over important aspects of life, such as insurance coverage or employment, it starts to appear less benign. Moreover, data analysis can reveal surprisingly intrusive things: for example, the movement sensor in a smartwatch or fitness tracker can be used to work out what you are typing (for example, passwords) with fairly good accuracy [98]. And algorithms for analysis are only going to get better. 

# **Consent and freedom of choice** 

We might assert that users voluntarily choose to use a service that tracks their activity, and they have agreed to the terms of service and privacy policy, so they consent to data collection. We might even claim that users are receiving a valuable service in return for the data they provide, and that the tracking is necessary in order to provide the service. Undoubtedly, social networks, search engines, and various other free online services are valuable to users—but there are problems with this argument. 

Users have little knowledge of what data they are feeding into our databases, or how it is retained and processed—and most privacy policies do more to obscure than to illuminate. Without understanding what happens to their data, users cannot give any meaningful consent. Often, data from one user also says things about other people who are not users of the service and who have not agreed to any terms. The derived datasets that we discussed in this part of the book—in which data from the entire user base may have been combined with behavioral tracking and external data sources—are precisely the kinds of data of which users cannot have any meaningful understanding. 

Moreover, data is extracted from users through a one-way process, not a relationship with true reciprocity, and not a fair value exchange. There is no dialog, no option for users to negotiate how much data they provide and what service they receive in 


return: the relationship between the service and the user is very asymmetric and onesided. The terms are set by the service, not by the user [99]. 

For a user who does not consent to surveillance, the only real alternative is simply not to use a service. But this choice is not free either: if a service is so popular that it is “regarded by most people as essential for basic social participation” [99], then it is not reasonable to expect people to opt out of this service—using it is _de facto_ mandatory. For example, in most Western social communities, it has become the norm to carry a smartphone, to use Facebook for socializing, and to use Google for finding information. Especially when a service has network effects, there is a social cost to people choosing _not_ to use it. 

Declining to use a service due to its tracking of users is only an option for the small number of people who are privileged enough to have the time and knowledge to understand its privacy policy, and who can afford to potentially miss out on social participation or professional opportunities that may have arisen if they had participated in the service. For people in a less privileged position, there is no meaningful freedom of choice: surveillance becomes inescapable. 

# **Privacy and use of data** 

Sometimes people claim that “privacy is dead” on the grounds that some users are willing to post all sorts of things about their lives to social media, sometimes mundane and sometimes deeply personal. However, this claim is false and rests on a misunderstanding of the word _privacy_ . 

Having privacy does not mean keeping everything secret; it means having the freedom to choose which things to reveal to whom, what to make public, and what to keep secret. The right to privacy is a decision right: it enables each person to decide where they want to be on the spectrum between secrecy and transparency in each situation [99]. It is an important aspect of a person’s freedom and autonomy. 

When data is extracted from people through surveillance infrastructure, privacy rights are not necessarily eroded, but rather transferred to the data collector. Companies that acquire data essentially say “trust us to do the right thing with your data,” which means that the right to decide what to reveal and what to keep secret is transferred from the individual to the company. 

The companies in turn choose to keep much of the outcome of this surveillance secret, because to reveal it would be perceived as creepy, and would harm their business model (which relies on knowing more about people than other companies do). Intimate information about users is only revealed indirectly, for example in the form of tools for targeting advertisements to specific groups of people (such as those suffering from a particular illness). 


Even if particular users cannot be personally reidentified from the bucket of people targeted by a particular ad, they have lost their agency about the disclosure of some intimate information, such as whether they suffer from some illness. It is not the user who decides what is revealed to whom on the basis of their personal preferences—it is the company that exercises the privacy right with the goal of maximizing its profit. 

Many companies have a goal of not being _perceived_ as creepy—avoiding the question of how intrusive their data collection actually is, and instead focusing on managing user perceptions. And even these perceptions are often managed poorly: for example, something may be factually correct, but if it triggers painful memories, the user may not want to be reminded about it [100]. With any kind of data we should expect the possibility that it is wrong, undesirable, or inappropriate in some way, and we need to build mechanisms for handling those failures. Whether something is “undesirable” or “inappropriate” is of course down to human judgment; algorithms are oblivious to such notions unless we explicitly program them to respect human needs. As engineers of these systems we must be humble, accepting and planning for such failings. 

Privacy settings that allow a user of an online service to control which aspects of their data other users can see are a starting point for handing back some control to users. However, regardless of the setting, the service itself still has unfettered access to the data, and is free to use it in any way permitted by the privacy policy. Even if the service promises not to sell the data to third parties, it usually grants itself unrestricted rights to process and analyze the data internally, often going much further than what is overtly visible to users. 

This kind of large-scale transfer of privacy rights from individuals to corporations is historically unprecedented [99]. Surveillance has always existed, but it used to be expensive and manual, not scalable and automated. Trust relationships have always existed, for example between a patient and their doctor, or between a defendant and their attorney—but in these cases the use of data has been strictly governed by ethical, legal, and regulatory constraints. Internet services have made it much easier to amass huge amounts of sensitive information without meaningful consent, and to use it at massive scale without users understanding what is happening to their private data. 

# **Data as assets and power** 

Since behavioral data is a byproduct of users interacting with a service, it is sometimes called “data exhaust”—suggesting that the data is worthless waste material. Viewed this way, behavioral and predictive analytics can be seen as a form of recycling that extracts value from data that would have otherwise been thrown away. 

More correct would be to view it the other way round: from an economic point of view, if targeted advertising is what pays for a service, then behavioral data about people is the service’s core asset. In this case, the application with which the user interacts is merely a means to lure users into feeding more and more personal information into the surveillance infrastructure [99]. The delightful human creativity and social relationships that often find expression in online services are cynically exploited by the data extraction machine. 

The assertion that personal data is a valuable asset is supported by the existence of data brokers, a shady industry operating in secrecy, purchasing, aggregating, analyzing, inferring, and reselling intrusive personal data about people, mostly for marketing purposes [90]. Startups are valued by their user numbers, by “eyeballs”—i.e., by their surveillance capabilities. 

Because the data is valuable, many people want it. Of course companies want it— that’s why they collect it in the first place. But governments want to obtain it too: by means of secret deals, coercion, legal compulsion, or simply stealing it [101]. When a company goes bankrupt, the personal data it has collected is one of the assets that get sold. Moreover, the data is difficult to secure, so breaches happen disconcertingly often [102]. 

These observations have led critics to saying that data is not just an asset, but a “toxic asset” [101], or at least “hazardous material” [103]. Even if we think that we are capable of preventing abuse of data, whenever we collect data, we need to balance the benefits with the risk of it falling into the wrong hands: computer systems may be compromised by criminals or hostile foreign intelligence services, data may be leaked by insiders, the company may fall into the hands of unscrupulous management that does not share our values, or the country may be taken over by a regime that has no qualms about compelling us to hand over the data. 

When collecting data, we need to consider not just today’s political environment, but all possible future governments. There is no guarantee that every government elected in future will respect human rights and civil liberties, so “it is poor civic hygiene to install technologies that could someday facilitate a police state” [104]. 

“Knowledge is power,” as the old adage goes. And furthermore, “to scrutinize others while avoiding scrutiny oneself is one of the most important forms of power” [105]. This is why totalitarian governments want surveillance: it gives them the power to control the population. Although today’s technology companies are not overtly seeking political power, the data and knowledge they have accumulated nevertheless gives them a lot of power over our lives, much of which is surreptitious, outside of public oversight [106]. 

# **Remembering the Industrial Revolution** 

Data is the defining feature of the information age. The internet, data storage, processing, and software-driven automation are having a major impact on the global economy and human society. As our daily lives and social organization have changed in the past decade, and will probably continue to radically change in the coming decades, comparisons to the Industrial Revolution come to mind [87, 96]. 


The Industrial Revolution came about through major technological and agricultural advances, and it brought sustained economic growth and significantly improved living standards in the long run. Yet it also came with major problems: pollution of the air (due to smoke and chemical processes) and the water (from industrial and human waste) was dreadful. Factory owners lived in splendor, while urban workers often lived in very poor housing and worked long hours in harsh conditions. Child labor was common, including dangerous and poorly paid work in mines. 

It took a long time before safeguards were established, such as environmental protection regulations, safety protocols for workplaces, outlawing child labor, and health inspections for food. Undoubtedly the cost of doing business increased when factories could no longer dump their waste into rivers, sell tainted foods, or exploit workers. But society as a whole benefited hugely, and few of us would want to return to a time before those regulations [87]. 

Just as the Industrial Revolution had a dark side that needed to be managed, our transition to the information age has major problems that we need to confront and solve. I believe that the collection and use of data is one of those problems. In the words of Bruce Schneier [96]: 

Data is the pollution problem of the information age, and protecting privacy is the environmental challenge. Almost all computers produce information. It stays around, festering. How we deal with it—how we contain it and how we dispose of it—is central to the health of our information economy. Just as we look back today at the early decades of the industrial age and wonder how our ancestors could have ignored pollution in their rush to build an industrial world, our grandchildren will look back at us during these early decades of the information age and judge us on how we addressed the challenge of data collection and misuse. 

We should try to make them proud. 

# **Legislation and self-regulation** 

Data protection laws might be able to help preserve individuals’ rights. For example, the 1995 European Data Protection Directive states that personal data must be “collected for specified, explicit and legitimate purposes and not further processed in a way incompatible with those purposes,” and furthermore that data must be “adequate, relevant and not excessive in relation to the purposes for which they are collected” [107]. 

However, it is doubtful whether this legislation is effective in today’s internet context [108]. These rules run directly counter to the philosophy of Big Data, which is to maximize data collection, to combine it with other datasets, to experiment and to explore in order to generate new insights. Exploration means using data for unforeseen purposes, which is the opposite of the “specified and explicit” purposes for which the user gave their consent (if we can meaningfully speak of consent at all [109]). Updated regulations are now being developed [89]. 


Companies that collect lots of data about people oppose regulation as being a burden and a hindrance to innovation. To some extent that opposition is justified. For example, when sharing medical data, there are clear risks to privacy, but there are also potential opportunities: how many deaths could be prevented if data analysis was able to help us achieve better diagnostics or find better treatments [110]? Overregulation may prevent such breakthroughs. It is difficult to balance such potential opportunities with the risks [105]. 

Fundamentally, I think we need a culture shift in the tech industry with regard to personal data. We should stop regarding users as metrics to be optimized, and remember that they are humans who deserve respect, dignity, and agency. We should self-regulate our data collection and processing practices in order to establish and maintain the trust of the people who depend on our software [111]. And we should take it upon ourselves to educate end users about how their data is used, rather than keeping them in the dark. 

We should allow each individual to maintain their privacy—i.e., their control over own data—and not steal that control from them through surveillance. Our individual right to control our data is like the natural environment of a national park: if we don’t explicitly protect and care for it, it will be destroyed. It will be the tragedy of the commons, and we will all be worse off for it. Ubiquitous surveillance is not inevitable —we are still able to stop it. 

How exactly we might achieve this is an open question. To begin with, we should not retain data forever, but purge it as soon as it is no longer needed [111, 112]. Purging data runs counter to the idea of immutability (see “Limitations of immutability” on page 463), but that issue can be solved. A promising approach I see is to enforce access control through cryptographic protocols, rather than merely by policy [113, 114]. Overall, culture and attitude changes will be necessary. 

## Summary 

In this chapter we discussed new approaches to designing data systems, and I included my personal opinions and speculations about the future. We started with the observation that there is no one single tool that can efficiently serve all possible use cases, and so applications necessarily need to compose several different pieces of software to accomplish their goals. We discussed how to solve this _data integration_ problem by using batch processing and event streams to let data changes flow between different systems. 

In this approach, certain systems are designated as systems of record, and other data is derived from them through transformations. In this way we can maintain indexes, materialized views, machine learning models, statistical summaries, and more. By making these derivations and transformations asynchronous and loosely coupled, a 


problem in one area is prevented from spreading to unrelated parts of the system, increasing the robustness and fault-tolerance of the system as a whole. 

Expressing dataflows as transformations from one dataset to another also helps evolve applications: if you want to change one of the processing steps, for example to change the structure of an index or cache, you can just rerun the new transformation code on the whole input dataset in order to rederive the output. Similarly, if something goes wrong, you can fix the code and reprocess the data in order to recover. 

These processes are quite similar to what databases already do internally, so we recast the idea of dataflow applications as _unbundling_ the components of a database, and building an application by composing these loosely coupled components. 

Derived state can be updated by observing changes in the underlying data. Moreover, the derived state itself can further be observed by downstream consumers. We can even take this dataflow all the way through to the end-user device that is displaying the data, and thus build user interfaces that dynamically update to reflect data changes and continue to work offline. 

Next, we discussed how to ensure that all of this processing remains correct in the presence of faults. We saw that strong integrity guarantees can be implemented scalably with asynchronous event processing, by using end-to-end operation identifiers to make operations idempotent and by checking constraints asynchronously. Clients can either wait until the check has passed, or go ahead without waiting but risk having to apologize about a constraint violation. This approach is much more scalable and robust than the traditional approach of using distributed transactions, and fits with how many business processes work in practice. 

By structuring applications around dataflow and checking constraints asynchronously, we can avoid most coordination and create systems that maintain integrity but still perform well, even in geographically distributed scenarios and in the presence of faults. We then talked a little about using audits to verify the integrity of data and detect corruption. 

Finally, we took a step back and examined some ethical aspects of building dataintensive applications. We saw that although data can be used to do good, it can also do significant harm: making justifying decisions that seriously affect people’s lives and are difficult to appeal against, leading to discrimination and exploitation, normalizing surveillance, and exposing intimate information. We also run the risk of data breaches, and we may find that a well-intentioned use of data has unintended consequences. 

As software and data are having such a large impact on the world, we engineers must remember that we carry a responsibility to work toward the kind of world that we want to live in: a world that treats people with humanity and respect. I hope that we can work together toward that goal. 


# **References** 

[1] Rachid Belaid: “Postgres Full-Text Search is Good Enough!,” _rachbelaid.com_ , July 13, 2015. 

[2] Philippe Ajoux, Nathan Bronson, Sanjeev Kumar, et al.: “Challenges to Adopting Stronger Consistency at Scale,” at _15th USENIX Workshop on Hot Topics in Operating Systems_ (HotOS), May 2015. 

[3] Pat Helland and Dave Campbell: “Building on Quicksand,” at _4th Biennial Conference on Innovative Data Systems Research_ (CIDR), January 2009. 

[4] Jessica Kerr: “Provenance and Causality in Distributed Systems,” _blog.jessitron.com_ , September 25, 2016. 

[5] Kostas Tzoumas: “Batch Is a Special Case of Streaming,” _data-artisans.com_ , September 15, 2015. 

[6] Shinji Kim and Robert Blafford: “Stream Windowing Performance Analysis: Concord and Spark Streaming,” _concord.io_ , July 6, 2016. 

[7] Jay Kreps: “The Log: What Every Software Engineer Should Know About RealTime Data’s Unifying Abstraction,” _engineering.linkedin.com_ , December 16, 2013. 

[8] Pat Helland: “Life Beyond Distributed Transactions: An Apostate’s Opinion,” at _3rd Biennial Conference on Innovative Data Systems Research_ (CIDR), January 2007. 

[9] “Great Western Railway (1835–1948),” Network Rail Virtual Archive, _networkrail.co.uk_ . 

[10] Jacqueline Xu: “Online Migrations at Scale,” _stripe.com_ , February 2, 2017. 

[11] Molly Bartlett Dishman and Martin Fowler: “Agile Architecture,” at _O’Reilly Software Architecture Conference_ , March 2015. 

[12] Nathan Marz and James Warren: _Big Data: Principles and Best Practices of Scalable Real-Time Data Systems_ . Manning, 2015. ISBN: 978-1-617-29034-3 

[13] Oscar Boykin, Sam Ritchie, Ian O’Connell, and Jimmy Lin: “Summingbird: A Framework for Integrating Batch and Online MapReduce Computations,” at _40th International Conference on Very Large Data Bases_ (VLDB), September 2014. 

[14] Jay Kreps: “Questioning the Lambda Architecture,” _oreilly.com_ , July 2, 2014. 

[15] Raul Castro Fernandez, Peter Pietzuch, Jay Kreps, et al.: “Liquid: Unifying Nearline and Offline Big Data Integration,” at _7th Biennial Conference on Innovative Data Systems Research_ (CIDR), January 2015. 


[16] Dennis M. Ritchie and Ken Thompson: “The UNIX Time-Sharing System,” _Communications of the ACM_ , volume 17, number 7, pages 365–375, July 1974. doi: 10.1145/361011.361061 

[17] Eric A. Brewer and Joseph M. Hellerstein: “CS262a: Advanced Topics in Computer Systems,” lecture notes, University of California, Berkeley, _cs.berkeley.edu_ , August 2011. 

[18] Michael Stonebraker: “The Case for Polystores,” _wp.sigmod.org_ , July 13, 2015. 

[19] Jennie Duggan, Aaron J. Elmore, Michael Stonebraker, et al.: “The BigDAWG Polystore System,” _ACM SIGMOD Record_ , volume 44, number 2, pages 11–16, June 2015. doi:10.1145/2814710.2814713 

[20] Patrycja Dybka: “Foreign Data Wrappers for PostgreSQL,” _vertabelo.com_ , March 24, 2015. 

[21] David B. Lomet, Alan Fekete, Gerhard Weikum, and Mike Zwilling: “Unbundling Transaction Services in the Cloud,” at _4th Biennial Conference on Innovative Data Systems Research_ (CIDR), January 2009. 

[22] Martin Kleppmann and Jay Kreps: “Kafka, Samza and the Unix Philosophy of Distributed Data,” _IEEE Data Engineering Bulletin_ , volume 38, number 4, pages 4–14, December 2015. 

[23] John Hugg: “Winning Now and in the Future: Where VoltDB Shines,” _voltdb.com_ , March 23, 2016. 

[24] Frank McSherry, Derek G. Murray, Rebecca Isaacs, and Michael Isard: “Differential Dataflow,” at _6th Biennial Conference on Innovative Data Systems Research_ (CIDR), January 2013. 

[25] Derek G Murray, Frank McSherry, Rebecca Isaacs, et al.: “Naiad: A Timely Dataflow System,” at _24th ACM Symposium on Operating Systems Principles_ (SOSP), pages 439–455, November 2013. doi:10.1145/2517349.2522738 

[26] Gwen Shapira: “We have a bunch of customers who are implementing ‘database inside-out’ concept and they all ask ‘is anyone else doing it? are we crazy?’” _twitter.com_ , July 28, 2016. 

[27] Martin Kleppmann: “Turning the Database Inside-out with Apache Samza,” at _Strange Loop_ , September 2014. 

[28] Peter Van Roy and Seif Haridi: _Concepts, Techniques, and Models of Computer Programming_ . MIT Press, 2004. ISBN: 978-0-262-22069-9 

[29] “Juttle Documentation,” _juttle.github.io_ , 2016. 


[30] Evan Czaplicki and Stephen Chong: “Asynchronous Functional Reactive Programming for GUIs,” at _34th ACM SIGPLAN Conference on Programming Language Design and Implementation_ (PLDI), June 2013. doi:10.1145/2491956.2462161 

[31] Engineer Bainomugisha, Andoni Lombide Carreton, Tom van Cutsem, Stijn Mostinckx, and Wolfgang de Meuter: “A Survey on Reactive Programming,” _ACM Computing Surveys_ , volume 45, number 4, pages 1–34, August 2013. doi: 10.1145/2501654.2501666 

[32] Peter Alvaro, Neil Conway, Joseph M. Hellerstein, and William R. Marczak: “Consistency Analysis in Bloom: A CALM and Collected Approach,” at _5th Biennial Conference on Innovative Data Systems Research_ (CIDR), January 2011. 

[33] Felienne Hermans: “Spreadsheets Are Code,” at _Code Mesh_ , November 2015. 

[34] Dan Bricklin and Bob Frankston: “VisiCalc: Information from Its Creators,” _danbricklin.com_ . 

[35] D. Sculley, Gary Holt, Daniel Golovin, et al.: “Machine Learning: The HighInterest Credit Card of Technical Debt,” at _NIPS Workshop on Software Engineering for Machine Learning_ (SE4ML), December 2014. 

[36] Peter Bailis, Alan Fekete, Michael J Franklin, et al.: “Feral Concurrency Control: An Empirical Investigation of Modern Application Integrity,” at _ACM International Conference on Management of Data_ (SIGMOD), June 2015. doi: 10.1145/2723372.2737784 

[37] Guy Steele: “Re: Need for Macros (Was Re: Icon),” email to _ll1-discuss_ mailing list, _people.csail.mit.edu_ , December 24, 2001. 

[38] David Gelernter: “Generative Communication in Linda,” _ACM Transactions on Programming Languages and Systems_ (TOPLAS), volume 7, number 1, pages 80–112, January 1985. doi:10.1145/2363.2433 

[39] Patrick Th. Eugster, Pascal A. Felber, Rachid Guerraoui, and Anne-Marie Kermarrec: “The Many Faces of Publish/Subscribe,” _ACM Computing Surveys_ , volume 35, number 2, pages 114–131, June 2003. doi:10.1145/857076.857078 

[40] Ben Stopford: “Microservices in a Streaming World,” at _QCon London_ , March 2016. 

[41] Christian Posta: “Why Microservices Should Be Event Driven: Autonomy vs Authority,” _blog.christianposta.com_ , May 27, 2016. 

[42] Alex Feyerke: “Say Hello to Offline First,” _hood.ie_ , November 5, 2013. 

[43] Sebastian Burckhardt, Daan Leijen, Jonathan Protzenko, and Manuel Fähndrich: “Global Sequence Protocol: A Robust Abstraction for Replicated Shared State,” at 


_29th European Conference on Object-Oriented Programming_ (ECOOP), July 2015. doi:10.4230/LIPIcs.ECOOP.2015.568 

[44] Mark Soper: “Clearing Up React Data Management Confusion with Flux, Redux, and Relay,” _medium.com_ , December 3, 2015. 

[45] Eno Thereska, Damian Guy, Michael Noll, and Neha Narkhede: “Unifying Stream Processing and Interactive Queries in Apache Kafka,” _confluent.io_ , October 26, 2016. 

[46] Frank McSherry: “Dataflow as Database,” _github.com_ , July 17, 2016. 

[47] Peter Alvaro: “I See What You Mean,” at _Strange Loop_ , September 2015. 

[48] Nathan Marz: “Trident: A High-Level Abstraction for Realtime Computation,” _blog.twitter.com_ , August 2, 2012. 

[49] Edi Bice: “Low Latency Web Scale Fraud Prevention with Apache Samza, Kafka and Friends,” at _Merchant Risk Council MRC Vegas Conference_ , March 2016. 

[50] Charity Majors: “The Accidental DBA,” _charity.wtf_ , October 2, 2016. 

[51] Arthur J. Bernstein, Philip M. Lewis, and Shiyong Lu: “Semantic Conditions for Correctness at Different Isolation Levels,” at _16th International Conference on Data Engineering_ (ICDE), February 2000. doi:10.1109/ICDE.2000.839387 

[52] Sudhir Jorwekar, Alan Fekete, Krithi Ramamritham, and S. Sudarshan: “Automating the Detection of Snapshot Isolation Anomalies,” at _33rd International Conference on Very Large Data Bases_ (VLDB), September 2007. 

[53] Kyle Kingsbury: Jepsen blog post series, _aphyr.com_ , 2013–2016. 

[54] Michael Jouravlev: “Redirect After Post,” _theserverside.com_ , August 1, 2004. 

[55] Jerome H. Saltzer, David P. Reed, and David D. Clark: “End-to-End Arguments in System Design,” _ACM Transactions on Computer Systems_ , volume 2, number 4, pages 277–288, November 1984. doi:10.1145/357401.357402 

[56] Peter Bailis, Alan Fekete, Michael J. Franklin, et al.: “Coordination-Avoiding Database Systems,” _Proceedings of the VLDB Endowment_ , volume 8, number 3, pages 185–196, November 2014. 

[57] Alex Yarmula: “Strong Consistency in Manhattan,” _blog.twitter.com_ , March 17, 2016. 

[58] Douglas B Terry, Marvin M Theimer, Karin Petersen, et al.: “Managing Update Conflicts in Bayou, a Weakly Connected Replicated Storage System,” at _15th ACM Symposium on Operating Systems Principles_ (SOSP), pages 172–182, December 1995. doi:10.1145/224056.224070 


[59] Jim Gray: “The Transaction Concept: Virtues and Limitations,” at _7th International Conference on Very Large Data Bases_ (VLDB), September 1981. 

[60] Hector Garcia-Molina and Kenneth Salem: “Sagas,” at _ACM International Conference on Management of Data_ (SIGMOD), May 1987. doi:10.1145/38713.38742 

[61] Pat Helland: “Memories, Guesses, and Apologies,” _blogs.msdn.com_ , May 15, 2007. 

[62] Yoongu Kim, Ross Daly, Jeremie Kim, et al.: “Flipping Bits in Memory Without Accessing Them: An Experimental Study of DRAM Disturbance Errors,” at _41st Annual International Symposium on Computer Architecture_ (ISCA), June 2014. doi: 10.1145/2678373.2665726 

[63] Mark Seaborn and Thomas Dullien: “Exploiting the DRAM Rowhammer Bug to Gain Kernel Privileges,” _googleprojectzero.blogspot.co.uk_ , March 9, 2015. 

[64] Jim N. Gray and Catharine van Ingen: “Empirical Measurements of Disk Failure Rates and Error Rates,” Microsoft Research, MSR-TR-2005-166, December 2005. 

[65] Annamalai Gurusami and Daniel Price: “Bug #73170: Duplicates in Unique Secondary Index Because of Fix of Bug#68021,” _bugs.mysql.com_ , July 2014. 

[66] Gary Fredericks: “Postgres Serializability Bug,” _github.com_ , September 2015. 

[67] Xiao Chen: “HDFS DataNode Scanners and Disk Checker Explained,” _blog.cloudera.com_ , December 20, 2016. 

[68] Jay Kreps: “Getting Real About Distributed System Reliability,” _blog.empathybox.com_ , March 19, 2012. 

[69] Martin Fowler: “The LMAX Architecture,” _martinfowler.com_ , July 12, 2011. 

[70] Sam Stokes: “Move Fast with Confidence,” _blog.samstokes.co.uk_ , July 11, 2016. 

[71] “Sawtooth Lake Documentation,” Intel Corporation, _intelledger.github.io_ , 2016. 

[72] Richard Gendal Brown: “Introducing R3 Corda™: A Distributed Ledger Designed for Financial Services,” _gendal.me_ , April 5, 2016. 

[73] Trent McConaghy, Rodolphe Marques, Andreas Müller, et al.: “BigchainDB: A Scalable Blockchain Database,” _bigchaindb.com_ , June 8, 2016. 

[74] Ralph C. Merkle: “A Digital Signature Based on a Conventional Encryption Function,” at _CRYPTO ’87_ , August 1987. doi:10.1007/3-540-48184-2_32 

[75] Ben Laurie: “Certificate Transparency,” _ACM Queue_ , volume 12, number 8, pages 10-19, August 2014. doi:10.1145/2668152.2668154 


[76] Mark D. Ryan: “Enhanced Certificate Transparency and End-to-End Encrypted Mail,” at _Network and Distributed System Security Symposium_ (NDSS), February 2014. doi:10.14722/ndss.2014.23379 

[77] “Software Engineering Code of Ethics and Professional Practice,” Association for Computing Machinery, _acm.org_ , 1999. 

[78] François Chollet: “Software development is starting to involve important ethical choices,” _twitter.com_ , October 30, 2016. 

[79] Igor Perisic: “Making Hard Choices: The Quest for Ethics in Machine Learning,” _engineering.linkedin.com_ , November 2016. 

[80] John Naughton: “Algorithm Writers Need a Code of Conduct,” _theguardian.com_ , December 6, 2015. 

[81] Logan Kugler: “What Happens When Big Data Blunders?,” _Communications of the ACM_ , volume 59, number 6, pages 15–16, June 2016. doi:10.1145/2911975 

[82] Bill Davidow: “Welcome to Algorithmic Prison,” _theatlantic.com_ , February 20, 2014. 

[83] Don Peck: “They’re Watching You at Work,” _theatlantic.com_ , December 2013. 

[84] Leigh Alexander: “Is an Algorithm Any Less Racist Than a Human?” _theguardian.com_ , August 3, 2016. 

[85] Jesse Emspak: “How a Machine Learns Prejudice,” _scientificamerican.com_ , December 29, 2016. 

[86] Maciej Cegłowski: “The Moral Economy of Tech,” _idlewords.com_ , June 2016. 

[87] Cathy O’Neil: _Weapons of Math Destruction: How Big Data Increases Inequality and Threatens Democracy_ . Crown Publishing, 2016. ISBN: 978-0-553-41881-1 

[88] Julia Angwin: “Make Algorithms Accountable,” _nytimes.com_ , August 1, 2016. 

[89] Bryce Goodman and Seth Flaxman: “European Union Regulations on Algorithmic Decision-Making and a ‘Right to Explanation’,” _arXiv:1606.08813_ , August 31, 2016. 

[90] “A Review of the Data Broker Industry: Collection, Use, and Sale of Consumer Data for Marketing Purposes,” Staff Report, _United States Senate Committee on Commerce, Science, and Transportation_ , _commerce.senate.gov_ , December 2013. 

[91] Olivia Solon: “Facebook’s Failure: Did Fake News and Polarized Politics Get Trump Elected?” _theguardian.com_ , November 10, 2016. 

[92] Donella H. Meadows and Diana Wright: _Thinking in Systems: A Primer_ . Chelsea Green Publishing, 2008. ISBN: 978-1-603-58055-7 


[93] Daniel J. Bernstein: “Listening to a ‘big data’/‘data science’ talk,” _twitter.com_ , May 12, 2015. 

[94] Marc Andreessen: “Why Software Is Eating the World,” _The Wall Street Journal_ , 20 August 2011. 

[95] J. M. Porup: “‘Internet of Things’ Security Is Hilariously Broken and Getting Worse,” _arstechnica.com_ , January 23, 2016. 

[96] Bruce Schneier: _Data and Goliath: The Hidden Battles to Collect Your Data and Control Your World_ . W. W. Norton, 2015. ISBN: 978-0-393-35217-7 

[97] The Grugq: “Nothing to Hide,” _grugq.tumblr.com_ , April 15, 2016. 

[98] Tony Beltramelli: “Deep-Spying: Spying Using Smartwatch and Deep Learning,” Masters Thesis, IT University of Copenhagen, December 2015. Available at _arxiv.org/abs/1512.05616_ 

[99] Shoshana Zuboff: “Big Other: Surveillance Capitalism and the Prospects of an Information Civilization,” _Journal of Information Technology_ , volume 30, number 1, pages 75–89, April 2015. doi:10.1057/jit.2015.5 

[100] Carina C. Zona: “Consequences of an Insightful Algorithm,” at _GOTO Berlin_ , November 2016. 

[101] Bruce Schneier: “Data Is a Toxic Asset, So Why Not Throw It Out?,” _schneier.com_ , March 1, 2016. 

[102] John E. Dunn: “The UK’s 15 Most Infamous Data Breaches,” _techworld.com_ , November 18, 2016. 

[103] Cory Scott: “Data is not toxic - which implies no benefit - but rather hazardous material, where we must balance need vs. want,” _twitter.com_ , March 6, 2016. 

[104] Bruce Schneier: “Mission Creep: When Everything Is Terrorism,” _schneier.com_ , July 16, 2013. 

[105] Lena Ulbricht and Maximilian von Grafenstein: “Big Data: Big Power Shifts?,” _Internet Policy Review_ , volume 5, number 1, March 2016. doi:10.14763/2016.1.406 

[106] Ellen P. Goodman and Julia Powles: “Facebook and Google: Most Powerful and Secretive Empires We’ve Ever Known,” _theguardian.com_ , September 28, 2016. 

[107] Directive 95/46/EC on the protection of individuals with regard to the processing of personal data and on the free movement of such data, Official Journal of the European Communities No. L 281/31, _eur-lex.europa.eu_ , November 1995. 

[108] Brendan Van Alsenoy: “Regulating Data Protection: The Allocation of Responsibility and Risk Among Actors Involved in Personal Data Processing,” Thesis, KU Leuven Centre for IT and IP Law, August 2016. 


[109] Michiel Rhoen: “Beyond Consent: Improving Data Protection Through Consumer Protection Law,” _Internet Policy Review_ , volume 5, number 1, March 2016. doi: 10.14763/2016.1.404 

[110] Jessica Leber: “Your Data Footprint Is Affecting Your Life in Ways You Can’t Even Imagine,” _fastcoexist.com_ , March 15, 2016. 

[111] Maciej Cegłowski: “Haunted by Data,” _idlewords.com_ , October 2015. 

[112] Sam Thielman: “You Are Not What You Read: Librarians Purge User Data to Protect Privacy,” _theguardian.com_ , January 13, 2016. 

[113] Conor Friedersdorf: “Edward Snowden’s Other Motive for Leaking,” _theatlantic.com_ , May 13, 2014. 

[114] Phillip Rogaway: “The Moral Character of Cryptographic Work,” Cryptology ePrint 2015/1162, December 2015. 


# **Glossary** 


![](../images/Designing_Data_Intensive_Applications-0575-01.png)


Please note that the definitions in this glossary are short and simple, intended to convey the core idea but not the full subtleties of a term. For more detail, please follow the references into the main text. 

# **asynchronous** 

Not waiting for something to complete (e.g., sending data over the network to another node), and not making any assumptions about how long it is going to take. See “Synchronous Versus Asynchronous Replication” on page 153, “Synchronous Versus Asynchronous Networks” on page 284, and “System Model and Reality” on page 306. 

# **atomic** 

1. In the context of concurrent operations: describing an operation that appears to take effect at a single point in time, so another concurrent process can never encounter the operation in a “halffinished” state. See also _isolation_ . 

2. In the context of transactions: grouping together a set of writes that must either all be committed or all be rolled back, even if faults occur. See “Atomicity” on page 223 and “Atomic Commit and Two-Phase Commit (2PC)” on page 354. 

# **backpressure** 

Forcing the sender of some data to slow down because the recipient cannot keep up with it. Also known as _flow control_ . See “Messaging Systems” on page 441. 

# **batch process** 

A computation that takes some fixed (and usually large) set of data as input and produces some other data as output, without modifying the input. See Chapter 10. 

# **bounded** 

Having some known upper limit or size. Used for example in the context of network delay (see “Timeouts and Unbounded Delays” on page 281) and datasets (see the introduction to Chapter 11). 

# **Byzantine fault** 

A node that behaves incorrectly in some arbitrary way, for example by sending contradictory or malicious messages to other nodes. See “Byzantine Faults” on page 304. 

# **cache** 

A component that remembers recently used data in order to speed up future reads of the same data. It is generally not complete: thus, if some data is missing from the cache, it has to be fetched from some underlying, slower data storage 


**CAP theorem**
system that has a complete copy of the data. 

# **CAP theorem** 

A widely misunderstood theoretical result that is not useful in practice. See “The CAP theorem” on page 336. 

# **causality** 

The dependency between events that arises when one thing “happens before” another thing in a system. For example, a later event that is in response to an earlier event, or builds upon an earlier event, or should be understood in the light of an earlier event. See “The “happens-before” relationship and concurrency” on page 186 and “Ordering and Causality” on page 339. 

# **consensus** 

A fundamental problem in distributed computing, concerning getting several nodes to agree on something (for example, which node should be the leader for a database cluster). The problem is much harder than it seems at first glance. See “Fault-Tolerant Consensus” on page 364. 

# **data warehouse** 

A database in which data from several different OLTP systems has been combined and prepared to be used for analytics purposes. See “Data Warehousing” on page 91. 

# **declarative** 

Describing the properties that something should have, but not the exact steps for how to achieve it. In the context of queries, a query optimizer takes a declarative query and decides how it should best be executed. See “Query Languages for Data” on page 42. ized view. See “Single-Object and MultiObject Operations” on page 228 and “Deriving several views from the same event log” on page 461. 

# **derived data** 

A dataset that is created from some other data through a repeatable process, which you could run again if necessary. Usually, derived data is needed to speed up a particular kind of read access to the data. Indexes, caches, and materialized views are examples of derived data. See the introduction to Part III. 

# **deterministic** 

Describing a function that always produces the same output if you give it the same input. This means it cannot depend on random numbers, the time of day, network communication, or other unpredictable things. 

# **distributed** 

Running on several nodes connected by a network. Characterized by _partial failures_ : some part of the system may be broken while other parts are still working, and it is often impossible for the software to know what exactly is broken. See “Faults and Partial Failures” on page 274. 

# **durable** 

Storing data in a way such that you believe it will not be lost, even if various faults occur. See “Durability” on page 226. 

# **ETL** 

Extract–Transform–Load. The process of extracting data from a source database, transforming it into a form that is more suitable for analytic queries, and loading it into a data warehouse or batch processing system. See “Data Warehousing” on page 91. 

# **denormalize** 

To introduce some amount of redundancy or duplication in a _normalized_ dataset, typically in the form of a _cache_ or _index_ , in order to speed up reads. A denormalized value is a kind of precomputed query result, similar to a material‐ 

# **failover** 

In systems that have a single leader, failover is the process of moving the leadership role from one node to another. See “Handling Node Outages” on page 156. 


**locality** 

# **fault-tolerant** 

Able to recover automatically if something goes wrong (e.g., if a machine crashes or a network link fails). See “Reliability” on page 6. 

# **flow control** 

See _backpressure_ . 

# **follower** 

A replica that does not directly accept any writes from clients, but only processes data changes that it receives from a leader. Also known as a _secondary_ , _slave_ , _read replica_ , or _hot standby_ . See “Leaders and Followers” on page 152. 

# **full-text search** 

Searching text by arbitrary keywords, often with additional features such as matching similarly spelled words or synonyms. A full-text index is a kind of _secondary index_ that supports such queries. See “Full-text search and fuzzy indexes” on page 88. 

# **graph** 

A data structure consisting of _vertices_ (things that you can refer to, also known as _nodes_ or _entities_ ) and _edges_ (connections from one vertex to another, also known as _relationships_ or _arcs_ ). See “Graph-Like Data Models” on page 49. 

# **hash** 

A function that turns an input into a random-looking number. The same input always returns the same number as output. Two different inputs are very likely to have two different numbers as output, although it is possible that two different inputs produce the same output (this is called a _collision_ ). See “Partitioning by Hash of Key” on page 203. 

# **idempotent** 

Describing an operation that can be safely retried; if it is executed more than once, it has the same effect as if it was only executed once. See “Idempotence” on page 478. 

# **index** 

A data structure that lets you efficiently search for all records that have a particular value in a particular field. See “Data Structures That Power Your Database” on page 70. 

# **isolation** 

In the context of transactions, describing the degree to which concurrently executing transactions can interfere with each other. _Serializable_ isolation provides the strongest guarantees, but weaker isolation levels are also used. See “Isolation” on page 225. 

# **join** 

To bring together records that have something in common. Most commonly used in the case where one record has a reference to another (a foreign key, a document reference, an edge in a graph) and a query needs to get the record that the reference points to. See “Many-to-One and Many-to-Many Relationships” on page 33 and “Reduce-Side Joins and Grouping” on page 403. 

# **leader** 

When data or a service is replicated across several nodes, the leader is the designated replica that is allowed to make changes. A leader may be elected through some protocol, or manually chosen by an administrator. Also known as the _primary_ or _master_ . See “Leaders and Followers” on page 152. 

# **linearizable** 

Behaving as if there was only a single copy of data in the system, which is updated by atomic operations. See “Linearizability” on page 324. 

# **locality** 

A performance optimization: putting several pieces of data in the same place if they are frequently needed at the same time. See “Data locality for queries” on page 41. 


**lock** 

# **lock** 

A mechanism to ensure that only one thread, node, or transaction can access something, and anyone else who wants to access the same thing must wait until the lock is released. See “Two-Phase Locking (2PL)” on page 257 and “The leader and the lock” on page 301. 

# **log** 

An append-only file for storing data. A _write-ahead log_ is used to make a storage engine resilient against crashes (see “Making B-trees reliable” on page 82), a _logstructured_ storage engine uses logs as its primary storage format (see “SSTables and LSM-Trees” on page 76), a _replication log_ is used to copy writes from a leader to followers (see “Leaders and Followers” on page 152), and an _event log_ can represent a data stream (see “Partitioned Logs” on page 446). 

# **materialize** 

To perform a computation eagerly and write out its result, as opposed to calculating it on demand when requested. See “Aggregation: Data Cubes and Materialized Views” on page 101 and “Materialization of Intermediate State” on page 419. 

# **node** 

An instance of some software running on a computer, which communicates with other nodes via a network in order to accomplish some task. 

# **normalized** 

Structured in such a way that there is no redundancy or duplication. In a normalized database, when some piece of data changes, you only need to change it in one place, not many copies in many different places. See “Many-to-One and Many-toMany Relationships” on page 33. 

# **OLAP** 

Online analytic processing. Access pattern characterized by aggregating (e.g., count, sum, average) over a large number of records. See “Transaction Processing or Analytics?” on page 90. 

# **OLTP** 

Online transaction processing. Access pattern characterized by fast queries that read or write a small number of records, usually indexed by key. See “Transaction Processing or Analytics?” on page 90. 

# **partitioning** 

Splitting up a large dataset or computation that is too big for a single machine into smaller parts and spreading them across several machines. Also known as _sharding_ . See Chapter 6. 

# **percentile** 

A way of measuring the distribution of values by counting how many values are above or below some threshold. For example, the 95th percentile response time during some period is the time _t_ such that 95% of requests in that period complete in less than _t_ , and 5% take longer than _t_ . See “Describing Performance” on page 13. 

# **primary key** 

A value (typically a number or a string) that uniquely identifies a record. In many applications, primary keys are generated by the system when a record is created (e.g., sequentially or randomly); they are not usually set by users. See also _secondary index_ . 

# **quorum** 

The minimum number of nodes that need to vote on an operation before it can be considered successful. See “Quorums for reading and writing” on page 179. 

# **rebalance** 

To move data or services from one node to another in order to spread the load fairly. See “Rebalancing Partitions” on page 209. 

# **replication** 

Keeping a copy of the same data on several nodes ( _replicas_ ) so that it remains 


**total order**
accessible if a node becomes unreachable. See Chapter 5. 

_skew_ in “Timestamps for ordering events” on page 291. 

# **schema** 

A description of the structure of some data, including its fields and datatypes. Whether some data conforms to a schema can be checked at various points in the data’s lifetime (see “Schema flexibility in the document model” on page 39), and a schema can change over time (see Chapter 4). 

# **secondary index** 

An additional data structure that is maintained alongside the primary data storage and which allows you to efficiently search for records that match a certain kind of condition. See “Other Indexing Structures” on page 85 and “Partitioning and Secondary Indexes” on page 206. 

# **serializable** 

A guarantee that if several transactions execute concurrently, they behave the same as if they had executed one at a time, in some serial order. See “Serializability” on page 251. 

# **shared-nothing** 

An architecture in which independent nodes—each with their own CPUs, memory, and disks—are connected via a conventional network, in contrast to sharedmemory or shared-disk architectures. See the introduction to Part II. 

# **split brain** 

A scenario in which two nodes simultaneously believe themselves to be the leader, and which may cause system guarantees to be violated. See “Handling Node Outages” on page 156 and “The Truth Is Defined by the Majority” on page 300. 

# **stored procedure** 

A way of encoding the logic of a transaction such that it can be entirely executed on a database server, without communicating back and forth with a client during the transaction. See “Actual Serial Execution” on page 252. 

# **stream process** 

A continually running computation that consumes a never-ending stream of events as input, and derives some output from it. See Chapter 11. 

# **synchronous** 

The opposite of _asynchronous_ . 

# **system of record** 

A system that holds the primary, authoritative version of some data, also known as the _source of truth_ . Changes are first written here, and other datasets may be derived from the system of record. See the introduction to Part III. 

# **timeout** 

# **skew** 

1. Imbalanced load across partitions, such that some partitions have lots of requests or data, and others have much less. Also known as _hot spots_ . See “Skewed Workloads and Relieving Hot Spots” on page 205 and “Handling skew” on page 407. 

2. A timing anomaly that causes events to appear in an unexpected, nonsequential order. See the discussions of _read skew_ in “Snapshot Isolation and Repeatable Read” on page 237, _write skew_ in “Write Skew and Phantoms” on page 246, and _clock_ 

One of the simplest ways of detecting a fault, namely by observing the lack of a response within some amount of time. However, it is impossible to know whether a timeout is due to a problem with the remote node, or an issue in the network. See “Timeouts and Unbounded Delays” on page 281. 

# **total order** 

A way of comparing things (e.g., timestamps) that allows you to always say which one of two things is greater and which one is lesser. An ordering in which 


**transaction**
some things are incomparable (you cannot say which is greater or smaller) is called a _partial order_ . See “The causal order is not a total order” on page 341. 

# **transaction** 

Grouping together several reads and writes into a logical unit, in order to simplify error handling and concurrency issues. See Chapter 7. 

# **two-phase commit (2PC)** 

An algorithm to ensure that several database nodes either all commit or all abort a transaction. See “Atomic Commit and Two-Phase Commit (2PC)” on page 354. 

# **two-phase locking (2PL)** 

An algorithm for achieving serializable isolation that works by a transaction acquiring a lock on all data it reads or writes, and holding the lock until the end of the transaction. See “Two-Phase Locking (2PL)” on page 257. 

# **unbounded** 

Not having any known upper limit or size. The opposite of _bounded_ . 


# **Index** 

# **A** 

aborts (transactions), 222, 224 in two-phase commit, 356 performance of optimistic concurrency control, 266 retrying aborted transactions, 231 abstraction, 21, 27, 222, 266, 321 access path (in network model), 37, 60 accidental complexity, removing, 21 accountability, 535 ACID properties (transactions), 90, 223 atomicity, 223, 228 consistency, 224, 529 durability, 226 isolation, 225, 228 acknowledgements (messaging), 445 active/active replication (see multi-leader replication) active/passive replication (see leader-based replication) ActiveMQ (messaging), 137, 444 distributed transaction support, 361 ActiveRecord (object-relational mapper), 30, 232 actor model, 138 (see also message-passing) comparison to Pregel model, 425 comparison to stream processing, 468 Advanced Message Queuing Protocol (see AMQP) aerospace systems, 6, 10, 305, 372 aggregation data cubes and materialized views, 101 in batch processes, 406 in stream processes, 466 aggregation pipeline query language, 48 Agile, 22 minimizing irreversibility, 414, 497 moving faster with confidence, 532 Unix philosophy, 394 agreement, 365 (see also consensus) Airflow (workflow scheduler), 402 Ajax, 131 Akka (actor framework), 139 algorithms algorithm correctness, 308 B-trees, 79-83 for distributed systems, 306 hash indexes, 72-75 mergesort, 76, 402, 405 red-black trees, 78 SSTables and LSM-trees, 76-79 all-to-all replication topologies, 175 AllegroGraph (database), 50 ALTER TABLE statement (SQL), 40, 111 Amazon Dynamo (database), 177 Amazon Web Services (AWS), 8 Kinesis Streams (messaging), 448 network reliability, 279 postmortems, 9 RedShift (database), 93 S3 (object storage), 398 checking data integrity, 530 amplification of bias, 534 of failures, 364, 495 


of tail latency, 16, 207 write amplification, 84 AMQP (Advanced Message Queuing Protocol), 444 (see also messaging systems) comparison to log-based messaging, 448, 451 message ordering, 446 analytics, 90 comparison to transaction processing, 91 data warehousing (see data warehousing) parallel query execution in MPP databases, 415 predictive (see predictive analytics) relation to batch processing, 411 schemas for, 93-95 snapshot isolation for queries, 238 stream analytics, 466 using MapReduce, analysis of user activity events (example), 404 anti-caching (in-memory databases), 89 anti-entropy, 178 Apache ActiveMQ (see ActiveMQ) Apache Avro (see Avro) Apache Beam (see Beam) Apache BookKeeper (see BookKeeper) Apache Cassandra (see Cassandra) Apache CouchDB (see CouchDB) Apache Curator (see Curator) Apache Drill (see Drill) Apache Flink (see Flink) Apache Giraph (see Giraph) Apache Hadoop (see Hadoop) Apache HAWQ (see HAWQ) Apache HBase (see HBase) Apache Helix (see Helix) Apache Hive (see Hive) Apache Impala (see Impala) Apache Jena (see Jena) Apache Kafka (see Kafka) Apache Lucene (see Lucene) Apache MADlib (see MADlib) Apache Mahout (see Mahout) Apache Oozie (see Oozie) Apache Parquet (see Parquet) Apache Qpid (see Qpid) Apache Samza (see Samza) Apache Solr (see Solr) Apache Spark (see Spark) 

Apache Storm (see Storm) Apache Tajo (see Tajo) Apache Tez (see Tez) Apache Thrift (see Thrift) Apache ZooKeeper (see ZooKeeper) Apama (stream analytics), 466 append-only B-trees, 82, 242 append-only files (see logs) Application Programming Interfaces (APIs), 5, 27 for batch processing, 403 for change streams, 456 for distributed transactions, 361 for graph processing, 425 for services, 131-136 (see also services) evolvability, 136 RESTful, 133 SOAP, 133 application state (see state) approximate search (see similarity search) archival storage, data from databases, 131 arcs (see edges) arithmetic mean, 14 ASCII text, 119, 395 ASN.1 (schema language), 127 asynchronous networks, 278, 553 comparison to synchronous networks, 284 formal model, 307 asynchronous replication, 154, 553 conflict detection, 172 data loss on failover, 157 reads from asynchronous follower, 162 Asynchronous Transfer Mode (ATM), 285 atomic broadcast (see total order broadcast) atomic clocks (caesium clocks), 294, 295 (see also clocks) atomicity (concurrency), 553 atomic increment-and-get, 351 compare-and-set, 245, 327 (see also compare-and-set operations) replicated operations, 246 write operations, 243 atomicity (transactions), 223, 228, 553 atomic commit, 353 avoiding, 523, 528 blocking and nonblocking, 359 in stream processing, 360, 477 maintaining derived data, 453 


for multi-object transactions, 229 for single-object writes, 230 auditability, 528-533 designing for, 531 self-auditing systems, 530 through immutability, 460 tools for auditable data systems, 532 availability, 8 (see also fault tolerance) in CAP theorem, 337 in service level agreements (SLAs), 15 Avro (data format), 122-127 code generation, 127 dynamically generated schemas, 126 object container files, 125, 131, 414 reader determining writer’s schema, 125 schema evolution, 123 use in Hadoop, 414 awk (Unix tool), 391 AWS (see Amazon Web Services) Azure (see Microsoft) 

# **B** 

B-trees (indexes), 79-83 append-only/copy-on-write variants, 82, 242 branching factor, 81 comparison to LSM-trees, 83-85 crash recovery, 82 growing by splitting a page, 81 optimizations, 82 similarity to dynamic partitioning, 212 backpressure, 441, 553 in TCP, 282 backups database snapshot for replication, 156 integrity of, 530 snapshot isolation for, 238 use for ETL processes, 405 backward compatibility, 112 BASE, contrast to ACID, 223 bash shell (Unix), 70, 395, 503 batch processing, 28, 389-431, 553 combining with stream processing lambda architecture, 497 unifying technologies, 498 comparison to MPP databases, 414-418 comparison to stream processing, 464 comparison to Unix, 413-414 dataflow engines, 421-423 fault tolerance, 406, 414, 422, 442 for data integration, 494-498 graphs and iterative processing, 424-426 high-level APIs and languages, 403, 426-429 log-based messaging and, 451 maintaining derived state, 495 MapReduce and distributed filesystems, 397-413 (see also MapReduce) measuring performance, 13, 390 outputs, 411-413 key-value stores, 412 search indexes, 411 using Unix tools (example), 391-394 Bayou (database), 522 Beam (dataflow library), 498 bias, 534 big ball of mud, 20 Bigtable data model, 41, 99 binary data encodings, 115-128 Avro, 122-127 MessagePack, 116-117 Thrift and Protocol Buffers, 117-121 binary encoding based on schemas, 127 by network drivers, 128 binary strings, lack of support in JSON and XML, 114 BinaryProtocol encoding (Thrift), 118 Bitcask (storage engine), 72 crash recovery, 74 Bitcoin (cryptocurrency), 532 Byzantine fault tolerance, 305 concurrency bugs in exchanges, 233 bitmap indexes, 97 blockchains, 532 Byzantine fault tolerance, 305 blocking atomic commit, 359 Bloom (programming language), 504 Bloom filter (algorithm), 79, 466 BookKeeper (replicated log), 372 Bottled Water (change data capture), 455 bounded datasets, 430, 439, 553 (see also batch processing) bounded delays, 553 in networks, 285 process pauses, 298 broadcast hash joins, 409 


brokerless messaging, 442 Brubeck (metrics aggregator), 442 BTM (transaction coordinator), 356 bulk synchronous parallel (BSP) model, 425 bursty network traffic patterns, 285 business data processing, 28, 90, 390 byte sequence, encoding data in, 112 Byzantine faults, 304-306, 307, 553 Byzantine fault-tolerant systems, 305, 532 Byzantine Generals Problem, 304 consensus algorithms and, 366 

**C** caches, 89, 553 and materialized views, 101 as derived data, 386, 499-504 database as cache of transaction log, 460 in CPUs, 99, 338, 428 invalidation and maintenance, 452, 467 linearizability, 324 CAP theorem, 336-338, 554 Cascading (batch processing), 419, 427 hash joins, 409 workflows, 403 cascading failures, 9, 214, 281 Cascalog (batch processing), 60 Cassandra (database) column-family data model, 41, 99 compaction strategy, 79 compound primary key, 204 gossip protocol, 216 hash partitioning, 203-205 last-write-wins conflict resolution, 186, 292 leaderless replication, 177 linearizability, lack of, 335 log-structured storage, 78 multi-datacenter support, 184 partitioning scheme, 213 secondary indexes, 207 sloppy quorums, 184 cat (Unix tool), 391 causal context, 191 (see also causal dependencies) causal dependencies, 186-191 capturing, 191, 342, 494, 514 by total ordering, 493 causal ordering, 339 in transactions, 262 sending message to friends (example), 494 causality, 554 causal ordering, 339-343 linearizability and, 342 total order consistent with, 344, 345 consistency with, 344-347 consistent snapshots, 340 happens-before relationship, 186 in serializable transactions, 262-265 mismatch with clocks, 292 ordering events to capture, 493 violations of, 165, 176, 292, 340 with synchronized clocks, 294 CEP (see complex event processing) certificate transparency, 532 chain replication, 155 linearizable reads, 351 change data capture, 160, 454 API support for change streams, 456 comparison to event sourcing, 457 implementing, 454 initial snapshot, 455 log compaction, 456 changelogs, 460 change data capture, 454 for operator state, 479 generating with triggers, 455 in stream joins, 474 log compaction, 456 maintaining derived state, 452 Chaos Monkey, 7, 280 checkpointing in batch processors, 422, 426 in high-performance computing, 275 in stream processors, 477, 523 chronicle data model, 458 circuit-switched networks, 284 circular buffers, 450 circular replication topologies, 175 clickstream data, analysis of, 404 clients calling services, 131 pushing state changes to, 512 request routing, 214 stateful and offline-capable, 170, 511 clocks, 287-299 atomic (caesium) clocks, 294, 295 confidence interval, 293-295 for global snapshots, 294 logical (see logical clocks) 


skew, 291-294, 334 slewing, 289 synchronization and accuracy, 289-291 synchronization using GPS, 287, 290, 294, 295 time-of-day versus monotonic clocks, 288 timestamping events, 471 cloud computing, 146, 275 need for service discovery, 372 network glitches, 279 shared resources, 284 single-machine reliability, 8 Cloudera Impala (see Impala) clustered indexes, 86 CODASYL model, 36 (see also network model) code generation with Avro, 127 with Thrift and Protocol Buffers, 118 with WSDL, 133 collaborative editing multi-leader replication and, 170 column families (Bigtable), 41, 99 column-oriented storage, 95-101 column compression, 97 distinction between column families and, 99 in batch processors, 428 Parquet, 96, 131, 414 sort order in, 99-100 vectorized processing, 99, 428 writing to, 101 comma-separated values (see CSV) command query responsibility segregation (CQRS), 462 commands (event sourcing), 459 commits (transactions), 222 atomic commit, 354-355 (see also atomicity; transactions) read committed isolation, 234 three-phase commit (3PC), 359 two-phase commit (2PC), 355-359 commutative operations, 246 compaction of changelogs, 456 (see also log compaction) for stream operator state, 479 of log-structured storage, 73 issues with, 84 size-tiered and leveled approaches, 79 

CompactProtocol encoding (Thrift), 119 compare-and-set operations, 245, 327 implementing locks, 370 implementing uniqueness constraints, 331 implementing with total order broadcast, 350 relation to consensus, 335, 350, 352, 374 relation to transactions, 230 compatibility, 112, 128 calling services, 136 properties of encoding formats, 139 using databases, 129-131 using message-passing, 138 compensating transactions, 355, 461, 526 complex event processing (CEP), 465 complexity distilling in theoretical models, 310 hiding using abstraction, 27 of software systems, managing, 20 composing data systems (see unbundling databases) compute-intensive applications, 3, 275 concatenated indexes, 87 in Cassandra, 204 Concord (stream processor), 466 concurrency actor programming model, 138, 468 (see also message-passing) bugs from weak transaction isolation, 233 conflict resolution, 171, 174 detecting concurrent writes, 184-191 dual writes, problems with, 453 happens-before relationship, 186 in replicated systems, 161-191, 324-338 lost updates, 243 multi-version concurrency control (MVCC), 239 optimistic concurrency control, 261 ordering of operations, 326, 341 reducing, through event logs, 351, 462, 507 time and relativity, 187 transaction isolation, 225 write skew (transaction isolation), 246-251 conflict-free replicated datatypes (CRDTs), 174 conflicts conflict detection, 172 causal dependencies, 186, 342 in consensus algorithms, 368 in leaderless replication, 184 


in log-based systems, 351, 521 in nonlinearizable systems, 343 in serializable snapshot isolation (SSI), 264 in two-phase commit, 357, 364 conflict resolution automatic conflict resolution, 174 by aborting transactions, 261 by apologizing, 527 convergence, 172-174 in leaderless systems, 190 last write wins (LWW), 186, 292 using atomic operations, 246 using custom logic, 173 determining what is a conflict, 174, 522 in multi-leader replication, 171-175 avoiding conflicts, 172 lost updates, 242-246 materializing, 251 relation to operation ordering, 339 write skew (transaction isolation), 246-251 congestion (networks) avoidance, 282 limiting accuracy of clocks, 293 queueing delays, 282 consensus, 321, 364-375, 554 algorithms, 366-368 preventing split brain, 367 safety and liveness properties, 365 using linearizable operations, 351 cost of, 369 distributed transactions, 352-375 in practice, 360-364 two-phase commit, 354-359 XA transactions, 361-364 impossibility of, 353 membership and coordination services, 370-373 relation to compare-and-set, 335, 350, 352, 374 relation to replication, 155, 349 relation to uniqueness constraints, 521 consistency, 224, 524 across different databases, 157, 452, 462, 492 causal, 339-348, 493 consistent prefix reads, 165-167 consistent snapshots, 156, 237-242, 294, 455, 500 (see also snapshots) crash recovery, 82 enforcing constraints (see constraints) eventual, 162, 322 (see also eventual consistency) in ACID transactions, 224, 529 in CAP theorem, 337 linearizability, 324-338 meanings of, 224 monotonic reads, 164-165 of secondary indexes, 231, 241, 354, 491, 500 ordering guarantees, 339-352 read-after-write, 162-164 sequential, 351 strong (see linearizability) timeliness and integrity, 524 using quorums, 181, 334 consistent hashing, 204 consistent prefix reads, 165 constraints (databases), 225, 248 asynchronously checked, 526 coordination avoidance, 527 ensuring idempotence, 519 in log-based systems, 521-524 across multiple partitions, 522 in two-phase commit, 355, 357 relation to consensus, 374, 521 relation to event ordering, 347 requiring linearizability, 330 Consul (service discovery), 372 consumers (message streams), 137, 440 backpressure, 441 consumer offsets in logs, 449 failures, 445, 449 fan-out, 11, 445, 448 load balancing, 444, 448 not keeping up with producers, 441, 450, 502 context switches, 14, 297 convergence (conflict resolution), 172-174, 322 coordination avoidance, 527 cross-datacenter, 168, 493 cross-partition ordering, 256, 294, 348, 523 services, 330, 370-373 coordinator (in 2PC), 356 failure, 358 in XA transactions, 361-364 recovery, 363 


copy-on-write (B-trees), 82, 242 CORBA (Common Object Request Broker Architecture), 134 correctness, 6 auditability, 528-533 Byzantine fault tolerance, 305, 532 dealing with partial failures, 274 in log-based systems, 521-524 of algorithm within system model, 308 of compensating transactions, 355 of consensus, 368 of derived data, 497, 531 of immutable data, 461 of personal data, 535, 540 of time, 176, 289-295 of transactions, 225, 515, 529 timeliness and integrity, 524-528 corruption of data detecting, 519, 530-533 due to pathological memory access, 529 due to radiation, 305 due to split brain, 158, 302 due to weak transaction isolation, 233 formalization in consensus, 366 integrity as absence of, 524 network packets, 306 on disks, 227 preventing using write-ahead logs, 82 recovering from, 414, 460 Couchbase (database) durability, 89 hash partitioning, 203-204, 211 rebalancing, 213 request routing, 216 CouchDB (database) B-tree storage, 242 change feed, 456 document data model, 31 join support, 34 MapReduce support, 46, 400 replication, 170, 173 covering indexes, 86 CPUs cache coherence and memory barriers, 338 caching and pipelining, 99, 428 increasing parallelism, 43 CRDTs (see conflict-free replicated datatypes) CREATE INDEX statement (SQL), 85, 500 credit rating agencies, 535 

Crunch (batch processing), 419, 427 hash joins, 409 sharded joins, 408 workflows, 403 cryptography defense against attackers, 306 end-to-end encryption and authentication, 519, 543 proving integrity of data, 532 CSS (Cascading Style Sheets), 44 CSV (comma-separated values), 70, 114, 396 Curator (ZooKeeper recipes), 330, 371 curl (Unix tool), 135, 397 cursor stability, 243 Cypher (query language), 52 comparison to SPARQL, 59 

# **D** 

data corruption (see corruption of data) data cubes, 102 data formats (see encoding) data integration, 490-498, 543 batch and stream processing, 494-498 lambda architecture, 497 maintaining derived state, 495 reprocessing data, 496 unifying, 498 by unbundling databases, 499-515 comparison to federated databases, 501 combining tools by deriving data, 490-494 derived data versus distributed transactions, 492 limits of total ordering, 493 ordering events to capture causality, 493 reasoning about dataflows, 491 need for, 385 data lakes, 415 data locality (see locality) data models, 27-64 graph-like models, 49-63 Datalog language, 60-63 property graphs, 50 RDF and triple-stores, 55-59 query languages, 42-48 relational model versus document model, 28-42 data protection regulations, 542 data systems, 3 about, 4 


concerns when designing, 5 future of, 489-544 correctness, constraints, and integrity, 515-533 data integration, 490-498 unbundling databases, 499-515 heterogeneous, keeping in sync, 452 maintainability, 18-22 possible faults in, 221 reliability, 6-10 hardware faults, 7 human errors, 9 importance of, 10 software errors, 8 scalability, 10-18 unreliable clocks, 287-299 data warehousing, 91-95, 554 comparison to data lakes, 415 ETL (extract-transform-load), 92, 416, 452 keeping data systems in sync, 452 schema design, 93 slowly changing dimension (SCD), 476 data-intensive applications, 3 database triggers (see triggers) database-internal distributed transactions, 360, 364, 477 databases archival storage, 131 comparison of message brokers to, 443 dataflow through, 129 end-to-end argument for, 519-520 checking integrity, 531 inside-out, 504 (see also unbundling databases) output from batch workflows, 412 relation to event streams, 451-464 (see also changelogs) API support for change streams, 456, 506 change data capture, 454-457 event sourcing, 457-459 keeping systems in sync, 452-453 philosophy of immutable events, 459-464 unbundling, 499-515 composing data storage technologies, 499-504 designing applications around dataflow, 504-509 observing derived state, 509-515 datacenters geographically distributed, 145, 164, 278, 493 multi-tenancy and shared resources, 284 network architecture, 276 network faults, 279 replication across multiple, 169 leaderless replication, 184 multi-leader replication, 168, 335 dataflow, 128-139, 504-509 correctness of dataflow systems, 525 differential, 504 message-passing, 136-139 reasoning about, 491 through databases, 129 through services, 131-136 dataflow engines, 421-423 comparison to stream processing, 464 directed acyclic graphs (DAG), 424 partitioning, approach to, 429 support for declarative queries, 427 Datalog (query language), 60-63 datatypes binary strings in XML and JSON, 114 conflict-free, 174 in Avro encodings, 122 in Thrift and Protocol Buffers, 121 numbers in XML and JSON, 114 Datomic (database) B-tree storage, 242 data model, 50, 57 Datalog query language, 60 excision (deleting data), 463 languages for transactions, 255 serial execution of transactions, 253 deadlocks detection, in two-phase commit (2PC), 364 in two-phase locking (2PL), 258 Debezium (change data capture), 455 declarative languages, 42, 554 Bloom, 504 CSS and XSL, 44 Cypher, 52 Datalog, 60 for batch processing, 427 recursive SQL queries, 53 relational algebra and SQL, 42 SPARQL, 59 


delays bounded network delays, 285 bounded process pauses, 298 unbounded network delays, 282 unbounded process pauses, 296 deleting data, 463 denormalization (data representation), 34, 554 costs, 39 in derived data systems, 386 materialized views, 101 updating derived data, 228, 231, 490 versus normalization, 462 derived data, 386, 439, 554 from change data capture, 454 in event sourcing, 458-458 maintaining derived state through logs, 452-457, 459-463 observing, by subscribing to streams, 512 outputs of batch and stream processing, 495 through application code, 505 versus distributed transactions, 492 deterministic operations, 255, 274, 554 accidental nondeterminism, 423 and fault tolerance, 423, 426 and idempotence, 478, 492 computing derived data, 495, 526, 531 in state machine replication, 349, 452, 458 joins, 476 DevOps, 394 differential dataflow, 504 dimension tables, 94 dimensional modeling (see star schemas) directed acyclic graphs (DAGs), 424 dirty reads (transaction isolation), 234 dirty writes (transaction isolation), 235 discrimination, 534 disks (see hard disks) distributed actor frameworks, 138 distributed filesystems, 398-399 decoupling from query engines, 417 indiscriminately dumping data into, 415 use by MapReduce, 402 distributed systems, 273-312, 554 Byzantine faults, 304-306 cloud versus supercomputing, 275 detecting network faults, 280 faults and partial failures, 274-277 formalization of consensus, 365 impossibility results, 338, 353 issues with failover, 157 limitations of distributed transactions, 363 multi-datacenter, 169, 335 network problems, 277-286 quorums, relying on, 301 reasons for using, 145, 151 synchronized clocks, relying on, 291-295 system models, 306-310 use of clocks and time, 287 distributed transactions (see transactions) Django (web framework), 232 DNS (Domain Name System), 216, 372 Docker (container manager), 506 document data model, 30-42 comparison to relational model, 38-42 document references, 38, 403 document-oriented databases, 31 many-to-many relationships and joins, 36 multi-object transactions, need for, 231 versus relational model convergence of models, 41 data locality, 41 document-partitioned indexes, 206, 217, 411 domain-driven design (DDD), 457 DRBD (Distributed Replicated Block Device), 153 drift (clocks), 289 Drill (query engine), 93 Druid (database), 461 Dryad (dataflow engine), 421 dual writes, problems with, 452, 507 duplicates, suppression of, 517 (see also idempotence) using a unique ID, 518, 522 durability (transactions), 226, 554 duration (time), 287 measurement with monotonic clocks, 288 dynamic partitioning, 212 dynamically typed languages analogy to schema-on-read, 40 code generation and, 127 Dynamo-style databases (see leaderless replication) 

# **E** 

edges (in graphs), 49, 403 property graph model, 50 edit distance (full-text search), 88 effectively-once semantics, 476, 516 


(see also exactly-once semantics) preservation of integrity, 525 elastic systems, 17 Elasticsearch (search server) document-partitioned indexes, 207 partition rebalancing, 211 percolator (stream search), 467 usage example, 4 use of Lucene, 79 ElephantDB (database), 413 Elm (programming language), 504, 512 encodings (data formats), 111-128 Avro, 122-127 binary variants of JSON and XML, 115 compatibility, 112 calling services, 136 using databases, 129-131 using message-passing, 138 defined, 113 JSON, XML, and CSV, 114 language-specific formats, 113 merits of schemas, 127 representations of data, 112 Thrift and Protocol Buffers, 117-121 end-to-end argument, 277, 519-520 checking integrity, 531 publish/subscribe streams, 512 enrichment (stream), 473 Enterprise JavaBeans (EJB), 134 entities (see vertices) epoch (consensus algorithms), 368 epoch (Unix timestamps), 288 equi-joins, 403 erasure coding (error correction), 398 Erlang OTP (actor framework), 139 error handling for network faults, 280 in transactions, 231 error-correcting codes, 277, 398 Esper (CEP engine), 466 etcd (coordination service), 370-373 linearizable operations, 333 locks and leader election, 330 quorum reads, 351 service discovery, 372 use of Raft algorithm, 349, 353 Ethereum (blockchain), 532 Ethernet (networks), 276, 278, 285 packet checksums, 306, 519 

Etherpad (collaborative editor), 170 ethics, 533-543 code of ethics and professional practice, 533 legislation and self-regulation, 542 predictive analytics, 533-536 amplifying bias, 534 feedback loops, 536 privacy and tracking, 536-543 consent and freedom of choice, 538 data as assets and power, 540 meaning of privacy, 539 surveillance, 537 respect, dignity, and agency, 543, 544 unintended consequences, 533, 536 ETL (extract-transform-load), 92, 405, 452, 554 use of Hadoop for, 416 event sourcing, 457-459 commands and events, 459 comparison to change data capture, 457 comparison to lambda architecture, 497 deriving current state from event log, 458 immutability and auditability, 459, 531 large, reliable data systems, 519, 526 Event Store (database), 458 event streams (see streams) events, 440 deciding on total order of, 493 deriving views from event log, 461 difference to commands, 459 event time versus processing time, 469, 477, 498 immutable, advantages of, 460, 531 ordering to capture causality, 493 reads as, 513 stragglers, 470, 498 timestamp of, in stream processing, 471 EventSource (browser API), 512 eventual consistency, 152, 162, 308, 322 (see also conflicts) and perpetual inconsistency, 525 evolvability, 21, 111 calling services, 136 graph-structured data, 52 of databases, 40, 129-131, 461, 497 of message-passing, 138 reprocessing data, 496, 498 schema evolution in Avro, 123 schema evolution in Thrift and Protocol Buffers, 120 


schema-on-read, 39, 111, 128 exactly-once semantics, 360, 476, 516 parity with batch processors, 498 preservation of integrity, 525 exclusive mode (locks), 258 eXtended Architecture transactions (see XA transactions) extract-transform-load (see ETL) 

**F** Facebook Presto (query engine), 93 React, Flux, and Redux (user interface libraries), 512 social graphs, 49 Wormhole (change data capture), 455 fact tables, 93 failover, 157, 554 (see also leader-based replication) in leaderless replication, absence of, 178 leader election, 301, 348, 352 potential problems, 157 failures amplification by distributed transactions, 364, 495 failure detection, 280 automatic rebalancing causing cascading failures, 214 perfect failure detectors, 359 timeouts and unbounded delays, 282, 284 using ZooKeeper, 371 faults versus, 7 partial failures in distributed systems, 275-277, 310 fan-out (messaging systems), 11, 445 fault tolerance, 6-10, 555 abstractions for, 321 formalization in consensus, 365-369 use of replication, 367 human fault tolerance, 414 in batch processing, 406, 414, 422, 425 in log-based systems, 520, 524-526 in stream processing, 476-479 atomic commit, 477 idempotence, 478 maintaining derived state, 495 microbatching and checkpointing, 477 rebuilding state after a failure, 478 of distributed transactions, 362-364 transaction atomicity, 223, 354-361 faults, 6 Byzantine faults, 304-306 failures versus, 7 handled by transactions, 221 handling in supercomputers and cloud computing, 275 hardware, 7 in batch processing versus distributed databases, 417 in distributed systems, 274-277 introducing deliberately, 7, 280 network faults, 279-281 asymmetric faults, 300 detecting, 280 tolerance of, in multi-leader replication, 169 software errors, 8 tolerating (see fault tolerance) federated databases, 501 fence (CPU instruction), 338 fencing (preventing split brain), 158, 302-304 generating fencing tokens, 349, 370 properties of fencing tokens, 308 stream processors writing to databases, 478, 517 Fibre Channel (networks), 398 field tags (Thrift and Protocol Buffers), 119-121 file descriptors (Unix), 395 financial data, 460 Firebase (database), 456 Flink (processing framework), 421-423 dataflow APIs, 427 fault tolerance, 422, 477, 479 Gelly API (graph processing), 425 integration of batch and stream processing, 495, 498 machine learning, 428 query optimizer, 427 stream processing, 466 flow control, 282, 441, 555 FLP result (on consensus), 353 FlumeJava (dataflow library), 403, 427 followers, 152, 555 (see also leader-based replication) foreign keys, 38, 403 forward compatibility, 112 forward decay (algorithm), 16 


Fossil (version control system), 463 shunning (deleting data), 463 FoundationDB (database) serializable transactions, 261, 265, 364 fractal trees, 83 full table scans, 403 full-text search, 555 and fuzzy indexes, 88 building search indexes, 411 Lucene storage engine, 79 functional reactive programming (FRP), 504 functional requirements, 22 futures (asynchronous operations), 135 fuzzy search (see similarity search) 

# **G** 

garbage collection immutability and, 463 process pauses for, 14, 296-299, 301 (see also process pauses) genome analysis, 63, 429 geographically distributed datacenters, 145, 164, 278, 493 geospatial indexes, 87 Giraph (graph processing), 425 Git (version control system), 174, 342, 463 GitHub, postmortems, 157, 158, 309 global indexes (see term-partitioned indexes) GlusterFS (distributed filesystem), 398 GNU Coreutils (Linux), 394 GoldenGate (change data capture), 161, 170, 455 (see also Oracle) Google Bigtable (database) data model (see Bigtable data model) partitioning scheme, 199, 202 storage layout, 78 Chubby (lock service), 370 Cloud Dataflow (stream processor), 466, 477, 498 (see also Beam) Cloud Pub/Sub (messaging), 444, 448 Docs (collaborative editor), 170 Dremel (query engine), 93, 96 FlumeJava (dataflow library), 403, 427 GFS (distributed file system), 398 gRPC (RPC framework), 135 MapReduce (batch processing), 390 

(see also MapReduce) building search indexes, 411 task preemption, 418 Pregel (graph processing), 425 Spanner (see Spanner) TrueTime (clock API), 294 gossip protocol, 216 government use of data, 541 GPS (Global Positioning System) use for clock synchronization, 287, 290, 294, 295 GraphChi (graph processing), 426 graphs, 555 as data models, 49-63 example of graph-structured data, 49 property graphs, 50 RDF and triple-stores, 55-59 versus the network model, 60 processing and analysis, 424-426 fault tolerance, 425 Pregel processing model, 425 query languages Cypher, 52 Datalog, 60-63 recursive SQL queries, 53 SPARQL, 59-59 Gremlin (graph query language), 50 grep (Unix tool), 392 GROUP BY clause (SQL), 406 grouping records in MapReduce, 406 handling skew, 407 

# **H** 

Hadoop (data infrastructure) comparison to distributed databases, 390 comparison to MPP databases, 414-418 comparison to Unix, 413-414, 499 diverse processing models in ecosystem, 417 HDFS distributed filesystem (see HDFS) higher-level tools, 403 join algorithms, 403-410 (see also MapReduce) MapReduce (see MapReduce) YARN (see YARN) happens-before relationship, 340 capturing, 187 concurrency and, 186 hard disks access patterns, 84 


detecting corruption, 519, 530 faults in, 7, 227 sequential write throughput, 75, 450 hardware faults, 7 hash indexes, 72-75 broadcast hash joins, 409 partitioned hash joins, 409 hash partitioning, 203-205, 217 consistent hashing, 204 problems with hash mod N, 210 range queries, 204 suitable hash functions, 203 with fixed number of partitions, 210 HAWQ (database), 428 HBase (database) bug due to lack of fencing, 302 bulk loading, 413 column-family data model, 41, 99 dynamic partitioning, 212 key-range partitioning, 202 log-structured storage, 78 request routing, 216 size-tiered compaction, 79 use of HDFS, 417 use of ZooKeeper, 370 HDFS (Hadoop Distributed File System), 398-399 (see also distributed filesystems) checking data integrity, 530 decoupling from query engines, 417 indiscriminately dumping data into, 415 metadata about datasets, 410 NameNode, 398 use by Flink, 479 use by HBase, 212 use by MapReduce, 402 HdrHistogram (numerical library), 16 head (Unix tool), 392 head vertex (property graphs), 51 head-of-line blocking, 15 heap files (databases), 86 Helix (cluster manager), 216 heterogeneous distributed transactions, 360, 364 heuristic decisions (in 2PC), 363 Hibernate (object-relational mapper), 30 hierarchical model, 36 high availability (see fault tolerance) high-frequency trading, 290, 299 high-performance computing (HPC), 275 hinted handoff, 183 histograms, 16 Hive (query engine), 419, 427 for data warehouses, 93 HCatalog and metastore, 410 map-side joins, 409 query optimizer, 427 skewed joins, 408 workflows, 403 Hollerith machines, 390 hopping windows (stream processing), 472 (see also windows) horizontal scaling (see scaling out) HornetQ (messaging), 137, 444 distributed transaction support, 361 hot spots, 201 due to celebrities, 205 for time-series data, 203 in batch processing, 407 relieving, 205 hot standbys (see leader-based replication) HTTP, use in APIs (see services) human errors, 9, 279, 414 HyperDex (database), 88 HyperLogLog (algorithm), 466 

# **I** 

I/O operations, waiting for, 297 IBM DB2 (database) distributed transaction support, 361 recursive query support, 54 serializable isolation, 242, 257 XML and JSON support, 30, 42 electromechanical card-sorting machines, 390 IMS (database), 36 imperative query APIs, 46 InfoSphere Streams (CEP engine), 466 MQ (messaging), 444 distributed transaction support, 361 System R (database), 222 WebSphere (messaging), 137 idempotence, 134, 478, 555 by giving operations unique IDs, 518, 522 idempotent operations, 517 immutability advantages of, 460, 531 


deriving state from event log, 459-464 for crash recovery, 75 in B-trees, 82, 242 in event sourcing, 457 inputs to Unix commands, 397 limitations of, 463 Impala (query engine) for data warehouses, 93 hash joins, 409 native code generation, 428 use of HDFS, 417 impedance mismatch, 29 imperative languages, 42 setting element styles (example), 45 in doubt (transaction status), 358 holding locks, 362 orphaned transactions, 363 in-memory databases, 88 durability, 227 serial transaction execution, 253 incidents cascading failures, 9 crashes due to leap seconds, 290 data corruption and financial losses due to concurrency bugs, 233 data corruption on hard disks, 227 data loss due to last-write-wins, 173, 292 data on disks unreadable, 309 deleted items reappearing, 174 disclosure of sensitive data due to primary key reuse, 157 errors in transaction serializability, 529 gigabit network interface with 1 Kb/s throughput, 311 network faults, 279 network interface dropping only inbound packets, 279 network partitions and whole-datacenter failures, 275 poor handling of network faults, 280 sending message to ex-partner, 494 sharks biting undersea cables, 279 split brain due to 1-minute packet delay, 158, 279 vibrations in server rack, 14 violation of uniqueness constraint, 529 indexes, 71, 555 and snapshot isolation, 241 as derived data, 386, 499-504 

B-trees, 79-83 building in batch processes, 411 clustered, 86 comparison of B-trees and LSM-trees, 83-85 concatenated, 87 covering (with included columns), 86 creating, 500 full-text search, 88 geospatial, 87 hash, 72-75 index-range locking, 260 multi-column, 87 partitioning and secondary indexes, 206-209, 217 secondary, 85 (see also secondary indexes) problems with dual writes, 452, 491 SSTables and LSM-trees, 76-79 updating when data changes, 452, 467 Industrial Revolution, 541 InfiniBand (networks), 285 InfiniteGraph (database), 50 InnoDB (storage engine) clustered index on primary key, 86 not preventing lost updates, 245 preventing write skew, 248, 257 serializable isolation, 257 snapshot isolation support, 239 inside-out databases, 504 (see also unbundling databases) integrating different data systems (see data integration) integrity, 524 coordination-avoiding data systems, 528 correctness of dataflow systems, 525 in consensus formalization, 365 integrity checks, 530 (see also auditing) end-to-end, 519, 531 use of snapshot isolation, 238 maintaining despite software bugs, 529 Interface Definition Language (IDL), 117, 122 intermediate state, materialization of, 420-423 internet services, systems for implementing, 275 invariants, 225 (see also constraints) inversion of control, 396 IP (Internet Protocol) 


unreliability of, 277 ISDN (Integrated Services Digital Network), 284 isolation (in transactions), 225, 228, 555 correctness and, 515 for single-object writes, 230 serializability, 251-266 actual serial execution, 252-256 serializable snapshot isolation (SSI), 261-266 two-phase locking (2PL), 257-261 violating, 228 weak isolation levels, 233-251 preventing lost updates, 242-246 read committed, 234-237 snapshot isolation, 237-242 iterative processing, 424-426 

# **J** 

Java Database Connectivity (JDBC) distributed transaction support, 361 network drivers, 128 Java Enterprise Edition (EE), 134, 356, 361 Java Message Service (JMS), 444 (see also messaging systems) comparison to log-based messaging, 448, 451 distributed transaction support, 361 message ordering, 446 Java Transaction API (JTA), 355, 361 Java Virtual Machine (JVM) bytecode generation, 428 garbage collection pauses, 296 process reuse in batch processors, 422 JavaScript in MapReduce querying, 46 setting element styles (example), 45 use in advanced queries, 48 Jena (RDF framework), 57 Jepsen (fault tolerance testing), 515 jitter (network delay), 284 joins, 555 by index lookup, 403 expressing as relational operators, 427 in relational and document databases, 34 MapReduce map-side joins, 408-410 broadcast hash joins, 409 merge joins, 410 partitioned hash joins, 409 

MapReduce reduce-side joins, 403-408 handling skew, 407 sort-merge joins, 405 parallel execution of, 415 secondary indexes and, 85 stream joins, 472-476 stream-stream join, 473 stream-table join, 473 table-table join, 474 time-dependence of, 475 support in document databases, 42 JOTM (transaction coordinator), 356 JSON Avro schema representation, 122 binary variants, 115 for application data, issues with, 114 in relational databases, 30, 42 representing a résumé (example), 31 Juttle (query language), 504 

# **K** 

k-nearest neighbors, 429 Kafka (messaging), 137, 448 Kafka Connect (database integration), 457, 461 Kafka Streams (stream processor), 466, 467 fault tolerance, 479 leader-based replication, 153 log compaction, 456, 467 message offsets, 447, 478 request routing, 216 transaction support, 477 usage example, 4 Ketama (partitioning library), 213 key-value stores, 70 as batch process output, 412 hash indexes, 72-75 in-memory, 89 partitioning, 201-205 by hash of key, 203, 217 by key range, 202, 217 dynamic partitioning, 212 skew and hot spots, 205 Kryo (Java), 113 Kubernetes (cluster manager), 418, 506 

# **L** 

lambda architecture, 497 Lamport timestamps, 345 


Large Hadron Collider (LHC), 64 last write wins (LWW), 173, 334 discarding concurrent writes, 186 problems with, 292 prone to lost updates, 246 late binding, 396 latency instability under two-phase locking, 259 network latency and resource utilization, 286 response time versus, 14 tail latency, 15, 207 leader-based replication, 152-161 (see also replication) failover, 157, 301 handling node outages, 156 implementation of replication logs change data capture, 454-457 (see also changelogs) statement-based, 158 trigger-based replication, 161 write-ahead log (WAL) shipping, 159 linearizability of operations, 333 locking and leader election, 330 log sequence number, 156, 449 read-scaling architecture, 161 relation to consensus, 367 setting up new followers, 155 synchronous versus asynchronous, 153-155 leaderless replication, 177-191 (see also replication) detecting concurrent writes, 184-191 capturing happens-before relationship, 187 happens-before relationship and concurrency, 186 last write wins, 186 merging concurrently written values, 190 version vectors, 191 multi-datacenter, 184 quorums, 179-182 consistency limitations, 181-183, 334 sloppy quorums and hinted handoff, 183 read repair and anti-entropy, 178 leap seconds, 8, 290 in time-of-day clocks, 288 leases, 295 implementation with ZooKeeper, 370 need for fencing, 302 ledgers, 460 distributed ledger technologies, 532 legacy systems, maintenance of, 18 less (Unix tool), 397 LevelDB (storage engine), 78 leveled compaction, 79 Levenshtein automata, 88 limping (partial failure), 311 linearizability, 324-338, 555 cost of, 335-338 CAP theorem, 336 memory on multi-core CPUs, 338 definition, 325-329 implementing with total order broadcast, 350 in ZooKeeper, 370 of derived data systems, 492, 524 avoiding coordination, 527 of different replication methods, 332-335 using quorums, 334 relying on, 330-332 constraints and uniqueness, 330 cross-channel timing dependencies, 331 locking and leader election, 330 stronger than causal consistency, 342 using to implement total order broadcast, 351 versus serializability, 329 LinkedIn Azkaban (workflow scheduler), 402 Databus (change data capture), 161, 455 Espresso (database), 31, 126, 130, 153, 216 Helix (cluster manager) (see Helix) profile (example), 30 reference to company entity (example), 34 Rest.li (RPC framework), 135 Voldemort (database) (see Voldemort) Linux, leap second bug, 8, 290 liveness properties, 308 LMDB (storage engine), 82, 242 load approaches to coping with, 17 describing, 11 load testing, 16 load balancing (messaging), 444 local indexes (see document-partitioned indexes) locality (data access), 32, 41, 555 


in batch processing, 400, 405, 421 in stateful clients, 170, 511 in stream processing, 474, 478, 508, 522 location transparency, 134 in the actor model, 138 locks, 556 deadlock, 258 distributed locking, 301-304, 330 fencing tokens, 303 implementation with ZooKeeper, 370 relation to consensus, 374 for transaction isolation in snapshot isolation, 239 in two-phase locking (2PL), 257-261 making operations atomic, 243 performance, 258 preventing dirty writes, 236 preventing phantoms with index-range locks, 260, 265 read locks (shared mode), 236, 258 shared mode and exclusive mode, 258 in two-phase commit (2PC) deadlock detection, 364 in-doubt transactions holding locks, 362 materializing conflicts with, 251 preventing lost updates by explicit locking, 244 log sequence number, 156, 449 logic programming languages, 504 logical clocks, 293, 343, 494 for read-after-write consistency, 164 logical logs, 160 logs (data structure), 71, 556 advantages of immutability, 460 compaction, 73, 79, 456, 460 for stream operator state, 479 creating using total order broadcast, 349 implementing uniqueness constraints, 522 log-based messaging, 446-451 comparison to traditional messaging, 448, 451 consumer offsets, 449 disk space usage, 450 replaying old messages, 451, 496, 498 slow consumers, 450 using logs for message storage, 447 log-structured storage, 71-79 log-structured merge tree (see LSMtrees) replication, 152, 158-161 change data capture, 454-457 (see also changelogs) coordination with snapshot, 156 logical (row-based) replication, 160 statement-based replication, 158 trigger-based replication, 161 write-ahead log (WAL) shipping, 159 scalability limits, 493 loose coupling, 396, 419, 502 lost updates (see updates) LSM-trees (indexes), 78-79 comparison to B-trees, 83-85 Lucene (storage engine), 79 building indexes in batch processes, 411 similarity search, 88 Luigi (workflow scheduler), 402 LWW (see last write wins) 

# **M** 

machine learning ethical considerations, 534 (see also ethics) iterative processing, 424 models derived from training data, 505 statistical and numerical algorithms, 428 MADlib (machine learning toolkit), 428 magic scaling sauce, 18 Mahout (machine learning toolkit), 428 maintainability, 18-22, 489 defined, 23 design principles for software systems, 19 evolvability (see evolvability) operability, 19 simplicity and managing complexity, 20 many-to-many relationships in document model versus relational model, 39 modeling as graphs, 49 many-to-one and many-to-many relationships, 33-36 many-to-one relationships, 34 MapReduce (batch processing), 390, 399-400 accessing external services within job, 404, 412 comparison to distributed databases designing for frequent faults, 417 diversity of processing models, 416 diversity of storage, 415 


comparison to stream processing, 464 comparison to Unix, 413-414 disadvantages and limitations of, 419 fault tolerance, 406, 414, 422 higher-level tools, 403, 426 implementation in Hadoop, 400-403 the shuffle, 402 implementation in MongoDB, 46-48 machine learning, 428 map-side processing, 408-410 broadcast hash joins, 409 merge joins, 410 partitioned hash joins, 409 mapper and reducer functions, 399 materialization of intermediate state, 419-423 output of batch workflows, 411-413 building search indexes, 411 key-value stores, 412 reduce-side processing, 403-408 analysis of user activity events (example), 404 grouping records by same key, 406 handling skew, 407 sort-merge joins, 405 workflows, 402 marshalling (see encoding) massively parallel processing (MPP), 216 comparison to composing storage technologies, 502 comparison to Hadoop, 414-418, 428 master-master replication (see multi-leader replication) master-slave replication (see leader-based replication) materialization, 556 aggregate values, 101 conflicts, 251 intermediate state (batch processing), 420-423 materialized views, 101 as derived data, 386, 499-504 maintaining, using stream processing, 467, 475 Maven (Java build tool), 428 Maxwell (change data capture), 455 mean, 14 media monitoring, 467 median, 14 meeting room booking (example), 249, 259, 521 membership services, 372 Memcached (caching server), 4, 89 memory in-memory databases, 88 durability, 227 serial transaction execution, 253 in-memory representation of data, 112 random bit-flips in, 529 use by indexes, 72, 77 memory barrier (CPU instruction), 338 MemSQL (database) in-memory storage, 89 read committed isolation, 236 memtable (in LSM-trees), 78 Mercurial (version control system), 463 merge joins, MapReduce map-side, 410 mergeable persistent data structures, 174 merging sorted files, 76, 402, 405 Merkle trees, 532 Mesos (cluster manager), 418, 506 message brokers (see messaging systems) message-passing, 136-139 advantages over direct RPC, 137 distributed actor frameworks, 138 evolvability, 138 MessagePack (encoding format), 116 messages exactly-once semantics, 360, 476 loss of, 442 using total order broadcast, 348 messaging systems, 440-451 (see also streams) backpressure, buffering, or dropping messages, 441 brokerless messaging, 442 event logs, 446-451 comparison to traditional messaging, 448, 451 consumer offsets, 449 replaying old messages, 451, 496, 498 slow consumers, 450 message brokers, 443-446 acknowledgements and redelivery, 445 comparison to event logs, 448, 451 multiple consumers of same topic, 444 reliability, 442 uniqueness in log-based messaging, 522 


Meteor (web framework), 456 microbatching, 477, 495 microservices, 132 (see also services) causal dependencies across services, 493 loose coupling, 502 relation to batch/stream processors, 389, 508 Microsoft Azure Service Bus (messaging), 444 Azure Storage, 155, 398 Azure Stream Analytics, 466 DCOM (Distributed Component Object Model), 134 MSDTC (transaction coordinator), 356 Orleans (see Orleans) SQL Server (see SQL Server) migrating (rewriting) data, 40, 130, 461, 497 modulus operator (%), 210 MongoDB (database) aggregation pipeline, 48 atomic operations, 243 BSON, 41 document data model, 31 hash partitioning (sharding), 203-204 key-range partitioning, 202 lack of join support, 34, 42 leader-based replication, 153 MapReduce support, 46, 400 oplog parsing, 455, 456 partition splitting, 212 request routing, 216 secondary indexes, 207 Mongoriver (change data capture), 455 monitoring, 10, 19 monotonic clocks, 288 monotonic reads, 164 MPP (see massively parallel processing) MSMQ (messaging), 361 multi-column indexes, 87 multi-leader replication, 168-177 (see also replication) handling write conflicts, 171 conflict avoidance, 172 converging toward a consistent state, 172 custom conflict resolution logic, 173 determining what is a conflict, 174 linearizability, lack of, 333 replication topologies, 175-177 use cases, 168 clients with offline operation, 170 collaborative editing, 170 multi-datacenter replication, 168, 335 multi-object transactions, 228 need for, 231 Multi-Paxos (total order broadcast), 367 multi-table index cluster tables (Oracle), 41 multi-tenancy, 284 multi-version concurrency control (MVCC), 239, 266 detecting stale MVCC reads, 263 indexes and snapshot isolation, 241 mutual exclusion, 261 (see also locks) MySQL (database) binlog coordinates, 156 binlog parsing for change data capture, 455 circular replication topology, 175 consistent snapshots, 156 distributed transaction support, 361 InnoDB storage engine (see InnoDB) JSON support, 30, 42 leader-based replication, 153 performance of XA transactions, 360 row-based replication, 160 schema changes in, 40 snapshot isolation support, 242 (see also InnoDB) statement-based replication, 159 Tungsten Replicator (multi-leader replication), 170 conflict detection, 177 

# **N** 

nanomsg (messaging library), 442 Narayana (transaction coordinator), 356 NATS (messaging), 137 near-real-time (nearline) processing, 390 (see also stream processing) Neo4j (database) Cypher query language, 52 graph data model, 50 Nephele (dataflow engine), 421 netcat (Unix tool), 397 Netflix Chaos Monkey, 7, 280 Network Attached Storage (NAS), 146, 398 network model, 36 


graph databases versus, 60 imperative query APIs, 46 Network Time Protocol (see NTP) networks congestion and queueing, 282 datacenter network topologies, 276 faults (see faults) linearizability and network delays, 338 network partitions, 279, 337 timeouts and unbounded delays, 281 next-key locking, 260 nodes (in graphs) (see vertices) nodes (processes), 556 handling outages in leader-based replication, 156 system models for failure, 307 noisy neighbors, 284 nonblocking atomic commit, 359 nondeterministic operations accidental nondeterminism, 423 partial failures in distributed systems, 275 nonfunctional requirements, 22 nonrepeatable reads, 238 (see also read skew) normalization (data representation), 33, 556 executing joins, 39, 42, 403 foreign key references, 231 in systems of record, 386 versus denormalization, 462 NoSQL, 29, 499 transactions and, 223 Notation3 (N3), 56 npm (package manager), 428 NTP (Network Time Protocol), 287 accuracy, 289, 293 adjustments to monotonic clocks, 289 multiple server addresses, 306 numbers, in XML and JSON encodings, 114 

# **O** 

object-relational mapping (ORM) frameworks, 30 error handling and aborted transactions, 232 unsafe read-modify-write cycle code, 244 object-relational mismatch, 29 observer pattern, 506 offline systems, 390 (see also batch processing) stateful, offline-capable clients, 170, 511 offline-first applications, 511 offsets consumer offsets in partitioned logs, 449 messages in partitioned logs, 447 OLAP (online analytic processing), 91, 556 data cubes, 102 OLTP (online transaction processing), 90, 556 analytics queries versus, 411 workload characteristics, 253 one-to-many relationships, 30 JSON representation, 32 online systems, 389 (see also services) Oozie (workflow scheduler), 402 OpenAPI (service definition format), 133 OpenStack Nova (cloud infrastructure) use of ZooKeeper, 370 Swift (object storage), 398 operability, 19 operating systems versus databases, 499 operation identifiers, 518, 522 operational transformation, 174 operators, 421 flow of data between, 424 in stream processing, 464 optimistic concurrency control, 261 Oracle (database) distributed transaction support, 361 GoldenGate (change data capture), 161, 170, 455 lack of serializability, 226 leader-based replication, 153 multi-table index cluster tables, 41 not preventing write skew, 248 partitioned indexes, 209 PL/SQL language, 255 preventing lost updates, 245 read committed isolation, 236 Real Application Clusters (RAC), 330 recursive query support, 54 snapshot isolation support, 239, 242 TimesTen (in-memory database), 89 WAL-based replication, 160 XML support, 30 ordering, 339-352 by sequence numbers, 343-348 causal ordering, 339-343 


partial order, 341 limits of total ordering, 493 total order broadcast, 348-352 Orleans (actor framework), 139 outliers (response time), 14 Oz (programming language), 504 

# **P** 

package managers, 428, 505 packet switching, 285 packets corruption of, 306 sending via UDP, 442 PageRank (algorithm), 49, 424 paging (see virtual memory) ParAccel (database), 93 parallel databases (see massively parallel processing) parallel execution of graph analysis algorithms, 426 queries in MPP databases, 216 Parquet (data format), 96, 131 (see also column-oriented storage) use in Hadoop, 414 partial failures, 275, 310 limping, 311 partial order, 341 partitioning, 199-218, 556 and replication, 200 in batch processing, 429 multi-partition operations, 514 enforcing constraints, 522 secondary index maintenance, 495 of key-value data, 201-205 by key range, 202 skew and hot spots, 205 rebalancing partitions, 209-214 automatic or manual rebalancing, 213 problems with hash mod N, 210 using dynamic partitioning, 212 using fixed number of partitions, 210 using N partitions per node, 212 replication and, 147 request routing, 214-216 secondary indexes, 206-209 document-based partitioning, 206 term-based partitioning, 208 serial execution of transactions and, 255 Paxos (consensus algorithm), 366 ballot number, 368 Multi-Paxos (total order broadcast), 367 percentiles, 14, 556 calculating efficiently, 16 importance of high percentiles, 16 use in service level agreements (SLAs), 15 Percona XtraBackup (MySQL tool), 156 performance describing, 13 of distributed transactions, 360 of in-memory databases, 89 of linearizability, 338 of multi-leader replication, 169 perpetual inconsistency, 525 pessimistic concurrency control, 261 phantoms (transaction isolation), 250 materializing conflicts, 251 preventing, in serializability, 259 physical clocks (see clocks) pickle (Python), 113 Pig (dataflow language), 419, 427 replicated joins, 409 skewed joins, 407 workflows, 403 Pinball (workflow scheduler), 402 pipelined execution, 423 in Unix, 394 point in time, 287 polyglot persistence, 29 polystores, 501 PostgreSQL (database) BDR (multi-leader replication), 170 causal ordering of writes, 177 Bottled Water (change data capture), 455 Bucardo (trigger-based replication), 161, 173 distributed transaction support, 361 foreign data wrappers, 501 full text search support, 490 leader-based replication, 153 log sequence number, 156 MVCC implementation, 239, 241 PL/pgSQL language, 255 PostGIS geospatial indexes, 87 preventing lost updates, 245 preventing write skew, 248, 261 read committed isolation, 236 recursive query support, 54 representing graphs, 51 


serializable snapshot isolation (SSI), 261 snapshot isolation support, 239, 242 WAL-based replication, 160 XML and JSON support, 30, 42 pre-splitting, 212 Precision Time Protocol (PTP), 290 predicate locks, 259 predictive analytics, 533-536 amplifying bias, 534 ethics of (see ethics) feedback loops, 536 preemption of datacenter resources, 418 of threads, 298 Pregel processing model, 425 primary keys, 85, 556 compound primary key (Cassandra), 204 primary-secondary replication (see leaderbased replication) privacy, 536-543 consent and freedom of choice, 538 data as assets and power, 540 deleting data, 463 ethical considerations (see ethics) legislation and self-regulation, 542 meaning of, 539 surveillance, 537 tracking behavioral data, 536 probabilistic algorithms, 16, 466 process pauses, 295-299 processing time (of events), 469 producers (message streams), 440 programming languages dataflow languages, 504 for stored procedures, 255 functional reactive programming (FRP), 504 logic programming, 504 Prolog (language), 61 (see also Datalog) promises (asynchronous operations), 135 property graphs, 50 Cypher query language, 52 Protocol Buffers (data format), 117-121 field tags and schema evolution, 120 provenance of data, 531 publish/subscribe model, 441 publishers (message streams), 440 punch card tabulating machines, 390 pure functions, 48 putting computation near data, 400 

# **Q** 

Qpid (messaging), 444 quality of service (QoS), 285 Quantcast File System (distributed filesystem), 398 query languages, 42-48 aggregation pipeline, 48 CSS and XSL, 44 Cypher, 52 Datalog, 60 Juttle, 504 MapReduce querying, 46-48 recursive SQL queries, 53 relational algebra and SQL, 42 SPARQL, 59 query optimizers, 37, 427 queueing delays (networks), 282 head-of-line blocking, 15 latency and response time, 14 queues (messaging), 137 quorums, 179-182, 556 for leaderless replication, 179 in consensus algorithms, 368 limitations of consistency, 181-183, 334 making decisions in distributed systems, 301 monitoring staleness, 182 multi-datacenter replication, 184 relying on durability, 309 sloppy quorums and hinted handoff, 183 

# **R** 

R-trees (indexes), 87 RabbitMQ (messaging), 137, 444 leader-based replication, 153 race conditions, 225 (see also concurrency) avoiding with linearizability, 331 caused by dual writes, 452 dirty writes, 235 in counter increments, 235 lost updates, 242-246 preventing with event logs, 462, 507 preventing with serializable isolation, 252 write skew, 246-251 Raft (consensus algorithm), 366 


sensitivity to network problems, 369 term number, 368 use in etcd, 353 RAID (Redundant Array of Independent Disks), 7, 398 railways, schema migration on, 496 RAMCloud (in-memory storage), 89 ranking algorithms, 424 RDF (Resource Description Framework), 57 querying with SPARQL, 59 RDMA (Remote Direct Memory Access), 276 read committed isolation level, 234-237 implementing, 236 multi-version concurrency control (MVCC), 239 no dirty reads, 234 no dirty writes, 235 read path (derived data), 509 read repair (leaderless replication), 178 for linearizability, 335 read replicas (see leader-based replication) read skew (transaction isolation), 238, 266 as violation of causality, 340 read-after-write consistency, 163, 524 cross-device, 164 read-modify-write cycle, 243 read-scaling architecture, 161 reads as events, 513 real-time collaborative editing, 170 near-real-time processing, 390 (see also stream processing) publish/subscribe dataflow, 513 response time guarantees, 298 time-of-day clocks, 288 rebalancing partitions, 209-214, 556 (see also partitioning) automatic or manual rebalancing, 213 dynamic partitioning, 212 fixed number of partitions, 210 fixed number of partitions per node, 212 problems with hash mod N, 210 recency guarantee, 324 recommendation engines batch process outputs, 412 batch workflows, 403, 420 iterative processing, 424 statistical and numerical algorithms, 428 records, 399 events in stream processing, 440 recursive common table expressions (SQL), 54 redelivery (messaging), 445 Redis (database) atomic operations, 243 durability, 89 Lua scripting, 255 single-threaded execution, 253 usage example, 4 redundancy hardware components, 7 of derived data, 386 (see also derived data) Reed–Solomon codes (error correction), 398 refactoring, 22 (see also evolvability) regions (partitioning), 199 register (data structure), 325 relational data model, 28-42 comparison to document model, 38-42 graph queries in SQL, 53 in-memory databases with, 89 many-to-one and many-to-many relationships, 33 multi-object transactions, need for, 231 NoSQL as alternative to, 29 object-relational mismatch, 29 relational algebra and SQL, 42 versus document model convergence of models, 41 data locality, 41 relational databases eventual consistency, 162 history, 28 leader-based replication, 153 logical logs, 160 philosophy compared to Unix, 499, 501 schema changes, 40, 111, 130 statement-based replication, 158 use of B-tree indexes, 80 relationships (see edges) reliability, 6-10, 489 building a reliable system from unreliable components, 276 defined, 6, 22 hardware faults, 7 human errors, 9 importance of, 10 of messaging systems, 442 


software errors, 8 Remote Method Invocation (Java RMI), 134 remote procedure calls (RPCs), 134-136 (see also services) based on futures, 135 data encoding and evolution, 136 issues with, 134 using Avro, 126, 135 using Thrift, 135 versus message brokers, 137 repeatable reads (transaction isolation), 242 replicas, 152 replication, 151-193, 556 and durability, 227 chain replication, 155 conflict resolution and, 246 consistency properties, 161-167 consistent prefix reads, 165 monotonic reads, 164 reading your own writes, 162 in distributed filesystems, 398 leaderless, 177-191 detecting concurrent writes, 184-191 limitations of quorum consistency, 181-183, 334 sloppy quorums and hinted handoff, 183 monitoring staleness, 182 multi-leader, 168-177 across multiple datacenters, 168, 335 handling write conflicts, 171-175 replication topologies, 175-177 partitioning and, 147, 200 reasons for using, 145, 151 single-leader, 152-161 failover, 157 implementation of replication logs, 158-161 relation to consensus, 367 setting up new followers, 155 synchronous versus asynchronous, 153-155 state machine replication, 349, 452 using erasure coding, 398 with heterogeneous data systems, 453 replication logs (see logs) reprocessing data, 496, 498 (see also evolvability) from log-based messaging, 451 request routing, 214-216 approaches to, 214 parallel query execution, 216 resilient systems, 6 (see also fault tolerance) response time as performance metric for services, 13, 389 guarantees on, 298 latency versus, 14 mean and percentiles, 14 user experience, 15 responsibility and accountability, 535 REST (Representational State Transfer), 133 (see also services) RethinkDB (database) document data model, 31 dynamic partitioning, 212 join support, 34, 42 key-range partitioning, 202 leader-based replication, 153 subscribing to changes, 456 Riak (database) Bitcask storage engine, 72 CRDTs, 174, 191 dotted version vectors, 191 gossip protocol, 216 hash partitioning, 203-204, 211 last-write-wins conflict resolution, 186 leaderless replication, 177 LevelDB storage engine, 78 linearizability, lack of, 335 multi-datacenter support, 184 preventing lost updates across replicas, 246 rebalancing, 213 search feature, 209 secondary indexes, 207 siblings (concurrently written values), 190 sloppy quorums, 184 ring buffers, 450 Ripple (cryptocurrency), 532 rockets, 10, 36, 305 RocksDB (storage engine), 78 leveled compaction, 79 rollbacks (transactions), 222 rolling upgrades, 8, 112 routing (see request routing) row-oriented storage, 96 row-based replication, 160 rowhammer (memory corruption), 529 RPCs (see remote procedure calls) 


Rubygems (package manager), 428 rules (Datalog), 61 

**S** safety and liveness properties, 308 in consensus algorithms, 366 in transactions, 222 sagas (see compensating transactions) Samza (stream processor), 466, 467 fault tolerance, 479 streaming SQL support, 466 sandboxes, 9 SAP HANA (database), 93 scalability, 10-18, 489 approaches for coping with load, 17 defined, 22 describing load, 11 describing performance, 13 partitioning and, 199 replication and, 161 scaling up versus scaling out, 146 scaling out, 17, 146 (see also shared-nothing architecture) scaling up, 17, 146 scatter/gather approach, querying partitioned databases, 207 SCD (slowly changing dimension), 476 schema-on-read, 39 comparison to evolvable schema, 128 in distributed filesystems, 415 schema-on-write, 39 schemaless databases (see schema-on-read) schemas, 557 Avro, 122-127 reader determining writer’s schema, 125 schema evolution, 123 dynamically generated, 126 evolution of, 496 affecting application code, 111 compatibility checking, 126 in databases, 129-131 in message-passing, 138 in service calls, 136 flexibility in document model, 39 for analytics, 93-95 for JSON and XML, 115 merits of, 127 schema migration on railways, 496 Thrift and Protocol Buffers, 117-121 schema evolution, 120 traditional approach to design, fallacy in, 462 searches building search indexes in batch processes, 411 k-nearest neighbors, 429 on streams, 467 partitioned secondary indexes, 206 secondaries (see leader-based replication) secondary indexes, 85, 557 partitioning, 206-209, 217 document-partitioned, 206 index maintenance, 495 term-partitioned, 208 problems with dual writes, 452, 491 updating, transaction isolation and, 231 secondary sorts, 405 sed (Unix tool), 392 self-describing files, 127 self-joins, 480 self-validating systems, 530 semantic web, 57 semi-synchronous replication, 154 sequence number ordering, 343-348 generators, 294, 344 insufficiency for enforcing constraints, 347 Lamport timestamps, 345 use of timestamps, 291, 295, 345 sequential consistency, 351 serializability, 225, 233, 251-266, 557 linearizability versus, 329 pessimistic versus optimistic concurrency control, 261 serial execution, 252-256 partitioning, 255 using stored procedures, 253, 349 serializable snapshot isolation (SSI), 261-266 detecting stale MVCC reads, 263 detecting writes that affect prior reads, 264 distributed execution, 265, 364 performance of SSI, 265 preventing write skew, 262-265 two-phase locking (2PL), 257-261 index-range locks, 260 performance, 258 Serializable (Java), 113 


serialization, 113 (see also encoding) service discovery, 135, 214, 372 using DNS, 216, 372 service level agreements (SLAs), 15 service-oriented architecture (SOA), 132 (see also services) services, 131-136 microservices, 132 causal dependencies across services, 493 loose coupling, 502 relation to batch/stream processors, 389, 508 remote procedure calls (RPCs), 134-136 issues with, 134 similarity to databases, 132 web services, 132, 135 session windows (stream processing), 472 (see also windows) sessionization, 407 sharding (see partitioning) shared mode (locks), 258 shared-disk architecture, 146, 398 shared-memory architecture, 146 shared-nothing architecture, 17, 146-147, 557 (see also replication) distributed filesystems, 398 (see also distributed filesystems) partitioning, 199 use of network, 277 sharks biting undersea cables, 279 counting (example), 46-48 finding (example), 42 website about (example), 44 shredding (in relational model), 38 siblings (concurrent values), 190, 246 (see also conflicts) similarity search edit distance, 88 genome data, 63 k-nearest neighbors, 429 single-leader replication (see leader-based replication) single-threaded execution, 243, 252 in batch processing, 406, 421, 426 in stream processing, 448, 463, 522 size-tiered compaction, 79 skew, 557 clock skew, 291-294, 334 in transaction isolation read skew, 238, 266 write skew, 246-251, 262-265 (see also write skew) meanings of, 238 unbalanced workload, 201 compensating for, 205 due to celebrities, 205 for time-series data, 203 in batch processing, 407 slaves (see leader-based replication) sliding windows (stream processing), 472 (see also windows) sloppy quorums, 183 (see also quorums) lack of linearizability, 334 slowly changing dimension (data warehouses), 476 smearing (leap seconds adjustments), 290 snapshots (databases) causal consistency, 340 computing derived data, 500 in change data capture, 455 serializable snapshot isolation (SSI), 261-266, 329 setting up a new replica, 156 snapshot isolation and repeatable read, 237-242 implementing with MVCC, 239 indexes and MVCC, 241 visibility rules, 240 synchronized clocks for global snapshots, 294 snowflake schemas, 95 SOAP, 133 (see also services) evolvability, 136 software bugs, 8 maintaining integrity, 529 solid state drives (SSDs) access patterns, 84 detecting corruption, 519, 530 faults in, 227 sequential write throughput, 75 Solr (search server) building indexes in batch processes, 411 document-partitioned indexes, 207 request routing, 216 


usage example, 4 use of Lucene, 79 sort (Unix tool), 392, 394, 395 sort-merge joins (MapReduce), 405 Sorted String Tables (see SSTables) sorting sort order in column storage, 99 source of truth (see systems of record) Spanner (database) data locality, 41 snapshot isolation using clocks, 295 TrueTime API, 294 Spark (processing framework), 421-423 bytecode generation, 428 dataflow APIs, 427 fault tolerance, 422 for data warehouses, 93 GraphX API (graph processing), 425 machine learning, 428 query optimizer, 427 Spark Streaming, 466 microbatching, 477 stream processing on top of batch processing, 495 SPARQL (query language), 59 spatial algorithms, 429 split brain, 158, 557 in consensus algorithms, 352, 367 preventing, 322, 333 using fencing tokens to avoid, 302-304 spreadsheets, dataflow programming capabilities, 504 SQL (Structured Query Language), 21, 28, 43 advantages and limitations of, 416 distributed query execution, 48 graph queries in, 53 isolation levels standard, issues with, 242 query execution on Hadoop, 416 résumé (example), 30 SQL injection vulnerability, 305 SQL on Hadoop, 93 statement-based replication, 158 stored procedures, 255 SQL Server (database) data warehousing support, 93 distributed transaction support, 361 leader-based replication, 153 preventing lost updates, 245 preventing write skew, 248, 257 read committed isolation, 236 recursive query support, 54 serializable isolation, 257 snapshot isolation support, 239 T-SQL language, 255 XML support, 30 SQLstream (stream analytics), 466 SSDs (see solid state drives) SSTables (storage format), 76-79 advantages over hash indexes, 76 concatenated index, 204 constructing and maintaining, 78 making LSM-Tree from, 78 staleness (old data), 162 cross-channel timing dependencies, 331 in leaderless databases, 178 in multi-version concurrency control, 263 monitoring for, 182 of client state, 512 versus linearizability, 324 versus timeliness, 524 standbys (see leader-based replication) star replication topologies, 175 star schemas, 93-95 similarity to event sourcing, 458 Star Wars analogy (event time versus processing time), 469 state derived from log of immutable events, 459 deriving current state from the event log, 458 interplay between state changes and application code, 507 maintaining derived state, 495 maintenance by stream processor in streamstream joins, 473 observing derived state, 509-515 rebuilding after stream processor failure, 478 separation of application code and, 505 state machine replication, 349, 452 statement-based replication, 158 statically typed languages analogy to schema-on-write, 40 code generation and, 127 statistical and numerical algorithms, 428 StatsD (metrics aggregator), 442 stdin, stdout, 395, 396 Stellar (cryptocurrency), 532 


stock market feeds, 442 STONITH (Shoot The Other Node In The Head), 158 stop-the-world (see garbage collection) storage composing data storage technologies, 499-504 diversity of, in MapReduce, 415 Storage Area Network (SAN), 146, 398 storage engines, 69-104 column-oriented, 95-101 column compression, 97-99 defined, 96 distinction between column families and, 99 Parquet, 96, 131 sort order in, 99-100 writing to, 101 comparing requirements for transaction processing and analytics, 90-96 in-memory storage, 88 durability, 227 row-oriented, 70-90 B-trees, 79-83 comparing B-trees and LSM-trees, 83-85 defined, 96 log-structured, 72-79 stored procedures, 161, 253-255, 557 and total order broadcast, 349 pros and cons of, 255 similarity to stream processors, 505 Storm (stream processor), 466 distributed RPC, 468, 514 Trident state handling, 478 straggler events, 470, 498 stream processing, 464-481, 557 accessing external services within job, 474, 477, 478, 517 combining with batch processing lambda architecture, 497 unifying technologies, 498 comparison to batch processing, 464 complex event processing (CEP), 465 fault tolerance, 476-479 atomic commit, 477 idempotence, 478 microbatching and checkpointing, 477 rebuilding state after a failure, 478 for data integration, 494-498 maintaining derived state, 495 maintenance of materialized views, 467 messaging systems (see messaging systems) reasoning about time, 468-472 event time versus processing time, 469, 477, 498 knowing when window is ready, 470 types of windows, 472 relation to databases (see streams) relation to services, 508 search on streams, 467 single-threaded execution, 448, 463 stream analytics, 466 stream joins, 472-476 stream-stream join, 473 stream-table join, 473 table-table join, 474 time-dependence of, 475 streams, 440-451 end-to-end, pushing events to clients, 512 messaging systems (see messaging systems) processing (see stream processing) relation to databases, 451-464 (see also changelogs) API support for change streams, 456 change data capture, 454-457 derivative of state by time, 460 event sourcing, 457-459 keeping systems in sync, 452-453 philosophy of immutable events, 459-464 topics, 440 strict serializability, 329 strong consistency (see linearizability) strong one-copy serializability, 329 subjects, predicates, and objects (in triplestores), 55 subscribers (message streams), 440 (see also consumers) supercomputers, 275 surveillance, 537 (see also privacy) Swagger (service definition format), 133 swapping to disk (see virtual memory) synchronous networks, 285, 557 comparison to asynchronous networks, 284 formal model, 307 synchronous replication, 154, 557 chain replication, 155 


conflict detection, 172 system models, 300, 306-310 assumptions in, 528 correctness of algorithms, 308 mapping to the real world, 309 safety and liveness, 308 systems of record, 386, 557 change data capture, 454, 491 treating event log as, 460 systems thinking, 536 

# **T** 

t-digest (algorithm), 16 table-table joins, 474 Tableau (data visualization software), 416 tail (Unix tool), 447 tail vertex (property graphs), 51 Tajo (query engine), 93 Tandem NonStop SQL (database), 200 TCP (Transmission Control Protocol), 277 comparison to circuit switching, 285 comparison to UDP, 283 connection failures, 280 flow control, 282, 441 packet checksums, 306, 519, 529 reliability and duplicate suppression, 517 retransmission timeouts, 284 use for transaction sessions, 229 telemetry (see monitoring) Teradata (database), 93, 200 term-partitioned indexes, 208, 217 termination (consensus), 365 Terrapin (database), 413 Tez (dataflow engine), 421-423 fault tolerance, 422 support by higher-level tools, 427 thrashing (out of memory), 297 threads (concurrency) actor model, 138, 468 (see also message-passing) atomic operations, 223 background threads, 73, 85 execution pauses, 286, 296-298 memory barriers, 338 preemption, 298 single (see single-threaded execution) three-phase commit, 359 Thrift (data format), 117-121 BinaryProtocol, 118 

CompactProtocol, 119 field tags and schema evolution, 120 throughput, 13, 390 TIBCO, 137 Enterprise Message Service, 444 StreamBase (stream analytics), 466 time concurrency and, 187 cross-channel timing dependencies, 331 in distributed systems, 287-299 (see also clocks) clock synchronization and accuracy, 289 relying on synchronized clocks, 291-295 process pauses, 295-299 reasoning about, in stream processors, 468-472 event time versus processing time, 469, 477, 498 knowing when window is ready, 470 timestamp of events, 471 types of windows, 472 system models for distributed systems, 307 time-dependence in stream joins, 475 time-of-day clocks, 288 timeliness, 524 coordination-avoiding data systems, 528 correctness of dataflow systems, 525 timeouts, 279, 557 dynamic configuration of, 284 for failover, 158 length of, 281 timestamps, 343 assigning to events in stream processing, 471 for read-after-write consistency, 163 for transaction ordering, 295 insufficiency for enforcing constraints, 347 key range partitioning by, 203 Lamport, 345 logical, 494 ordering events, 291, 345 Titan (database), 50 tombstones, 74, 191, 456 topics (messaging), 137, 440 total order, 341, 557 limits of, 493 sequence numbers or timestamps, 344 total order broadcast, 348-352, 493, 522 consensus algorithms and, 366-368 


implementation in ZooKeeper and etcd, 370 implementing with linearizable storage, 351 using, 349 using to implement linearizable storage, 350 tracking behavioral data, 536 (see also privacy) transaction coordinator (see coordinator) transaction manager (see coordinator) transaction processing, 28, 90-95 comparison to analytics, 91 comparison to data warehousing, 93 transactions, 221-267, 558 ACID properties of, 223 atomicity, 223 consistency, 224 durability, 226 isolation, 225 compensating (see compensating transactions) concept of, 222 distributed transactions, 352-364 avoiding, 492, 502, 521-528 failure amplification, 364, 495 in doubt/uncertain status, 358, 362 two-phase commit, 354-359 use of, 360-361 XA transactions, 361-364 OLTP versus analytics queries, 411 purpose of, 222 serializability, 251-266 actual serial execution, 252-256 pessimistic versus optimistic concurrency control, 261 serializable snapshot isolation (SSI), 261-266 two-phase locking (2PL), 257-261 single-object and multi-object, 228-232 handling errors and aborts, 231 need for multi-object transactions, 231 single-object writes, 230 snapshot isolation (see snapshots) weak isolation levels, 233-251 preventing lost updates, 242-246 read committed, 234-238 transitive closure (graph algorithm), 424 trie (data structure), 88 triggers (databases), 161, 441 implementing change data capture, 455 implementing replication, 161 triple-stores, 55-59 SPARQL query language, 59 tumbling windows (stream processing), 472 (see also windows) in microbatching, 477 tuple spaces (programming model), 507 Turtle (RDF data format), 56 Twitter constructing home timelines (example), 11, 462, 474, 511 DistributedLog (event log), 448 Finagle (RPC framework), 135 Snowflake (sequence number generator), 294 Summingbird (processing library), 497 two-phase commit (2PC), 353, 355-359, 558 confusion with two-phase locking, 356 coordinator failure, 358 coordinator recovery, 363 how it works, 357 issues in practice, 363 performance cost, 360 transactions holding locks, 362 two-phase locking (2PL), 257-261, 329, 558 confusion with two-phase commit, 356 index-range locks, 260 performance of, 258 type checking, dynamic versus static, 40 

**U** 

UDP (User Datagram Protocol) comparison to TCP, 283 multicast, 442 unbounded datasets, 439, 558 (see also streams) unbounded delays, 558 in networks, 282 process pauses, 296 unbundling databases, 499-515 composing data storage technologies, 499-504 federation versus unbundling, 501 need for high-level language, 503 designing applications around dataflow, 504-509 observing derived state, 509-515 materialized views and caching, 510 multi-partition data processing, 514 pushing state changes to clients, 512 


uncertain (transaction status) (see in doubt) uniform consensus, 365 

(see also consensus) uniform interfaces, 395 union type (in Avro), 125 uniq (Unix tool), 392 uniqueness constraints asynchronously checked, 526 requiring consensus, 521 requiring linearizability, 330 uniqueness in log-based messaging, 522 Unix philosophy, 394-397 command-line batch processing, 391-394 Unix pipes versus dataflow engines, 423 comparison to Hadoop, 413-414 comparison to relational databases, 499, 501 comparison to stream processing, 464 composability and uniform interfaces, 395 loose coupling, 396 pipes, 394 relation to Hadoop, 499 UPDATE statement (SQL), 40 updates preventing lost updates, 242-246 atomic write operations, 243 automatically detecting lost updates, 245 compare-and-set operations, 245 conflict resolution and replication, 246 using explicit locking, 244 preventing write skew, 246-251 

# **V** 

validity (consensus), 365 vBuckets (partitioning), 199 vector clocks, 191 (see also version vectors) vectorized processing, 99, 428 verification, 528-533 avoiding blind trust, 530 culture of, 530 designing for auditability, 531 end-to-end integrity checks, 531 tools for auditable data systems, 532 version control systems, reliance on immutable data, 463 version vectors, 177, 191 capturing causal dependencies, 343 versus vector clocks, 191 Vertica (database), 93 handling writes, 101 replicas using different sort orders, 100 vertical scaling (see scaling up) vertices (in graphs), 49 property graph model, 50 Viewstamped Replication (consensus algorithm), 366 view number, 368 virtual machines, 146 (see also cloud computing) context switches, 297 network performance, 282 noisy neighbors, 284 reliability in cloud services, 8 virtualized clocks in, 290 virtual memory process pauses due to page faults, 14, 297 versus memory management by databases, 89 VisiCalc (spreadsheets), 504 vnodes (partitioning), 199 Voice over IP (VoIP), 283 Voldemort (database) building read-only stores in batch processes, 413 hash partitioning, 203-204, 211 leaderless replication, 177 multi-datacenter support, 184 rebalancing, 213 reliance on read repair, 179 sloppy quorums, 184 VoltDB (database) cross-partition serializability, 256 deterministic stored procedures, 255 in-memory storage, 89 output streams, 456 secondary indexes, 207 serial execution of transactions, 253 statement-based replication, 159, 479 transactions in stream processing, 477 

# **W** 

WAL (write-ahead log), 82 web services (see services) Web Services Description Language (WSDL), 133 webhooks, 443 webMethods (messaging), 137 WebSocket (protocol), 512 


windows (stream processing), 466, 468-472 infinite windows for changelogs, 467, 474 knowing when all events have arrived, 470 stream joins within a window, 473 types of windows, 472 winners (conflict resolution), 173 WITH RECURSIVE syntax (SQL), 54 workflows (MapReduce), 402 outputs, 411-414 key-value stores, 412 search indexes, 411 with map-side joins, 410 working set, 393 write amplification, 84 write path (derived data), 509 write skew (transaction isolation), 246-251 characterizing, 246-251, 262 examples of, 247, 249 materializing conflicts, 251 occurrence in practice, 529 phantoms, 250 preventing in snapshot isolation, 262-265 in two-phase locking, 259-261 options for, 248 write-ahead log (WAL), 82, 159 writes (database) atomic write operations, 243 detecting writes affecting prior reads, 264 preventing dirty writes with read committed, 235 WS-* framework, 133 (see also services) WS-AtomicTransaction (2PC), 355 

# **X** 

XA transactions, 355, 361-364 heuristic decisions, 363 limitations of, 363 xargs (Unix tool), 392, 396 XML binary variants, 115 encoding RDF data, 57 for application data, issues with, 114 in relational databases, 30, 41 XSL/XPath, 45 

# **Y** 

Yahoo! Pistachio (database), 461 Sherpa (database), 455 YARN (job scheduler), 416, 506 preemption of jobs, 418 use of ZooKeeper, 370 

# **Z** 

Zab (consensus algorithm), 366 use in ZooKeeper, 353 ZeroMQ (messaging library), 442 ZooKeeper (coordination service), 370-373 generating fencing tokens, 303, 349, 370 linearizable operations, 333, 351 locks and leader election, 330 service discovery, 372 use for partition assignment, 215, 371 use of Zab algorithm, 349, 353, 366 


# **About the Author** 

**Martin Kleppmann** is a researcher in distributed systems at the University of Cambridge, UK. Previously he was a software engineer and entrepreneur at internet companies including LinkedIn and Rapportive, where he worked on large-scale data infrastructure. In the process he learned a few things the hard way, and he hopes this book will save you from repeating the same mistakes. 

Martin is a regular conference speaker, blogger, and open source contributor. He believes that profound technical ideas should be accessible to everyone, and that deeper understanding will help us develop better software. 

# **Colophon** 

The animal on the cover of _Designing Data-Intensive Applications_ is an Indian wild boar ( _Sus scrofa cristatus_ ), a subspecies of wild boar found in India, Myanmar, Nepal, Sri Lanka, and Thailand. They are distinctive from European boars in that they have higher back bristles, no woolly undercoat, and a larger, straighter skull. 

The Indian wild boar has a coat of gray or black hair, with stiff bristles running along the spine. Males have protruding canine teeth (called tushes) that are used to fight with rivals or fend off predators. Males are larger than females, but the species averages 33–35 inches tall at the shoulder and 200–300 pounds in weight. Their natural predators include bears, tigers, and various big cats. 

These animals are nocturnal and omnivorous—they eat a wide variety of things, including roots, insects, carrion, nuts, berries, and small animals. Wild boars are also known to root through garbage and crop fields, causing a great deal of destruction and earning the enmity of farmers. They need to eat 4,000–4,500 calories a day. Boars have a well-developed sense of smell, which helps them forage for underground plant material and burrowing animals. However, their eyesight is poor. 

Wild boars have long held significance in human culture. In Hindu lore, the boar is an avatar of the god Vishnu. In ancient Greek funerary monuments, it was a symbol of a gallant loser (in contrast to the victorious lion). Due to its aggression, it was depicted on the armor and weapons of Scandinavian, Germanic, and Anglo-Saxon warriors. In the Chinese zodiac, it symbolizes determination and impetuosity. 

Many of the animals on O’Reilly covers are endangered; all of them are important to the world. To learn more about how you can help, go to _animals.oreilly.com_ . 

The cover image is from Shaw’s _Zoology_ . The cover fonts are URW Typewriter and Guardian Sans. The text font is Adobe Minion Pro; the font in diagrams is Adobe Myriad Pro; the heading font is Adobe Myriad Condensed; and the code font is Dalton Maag’s Ubuntu Mono. 


