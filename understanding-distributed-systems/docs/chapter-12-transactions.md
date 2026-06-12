## **Chapter 12** 

## **Transactions** 

Transactions[1] provide the illusion that either all the operations within a group complete successfully or none of them do, as if the group were a single atomic operation. If you have used a relational database such as MySQL or PostgreSQL in the past, you should be familiar with the concept. 

If your application exclusively updates data within a single relational database, then bundling some changes into a transaction is straightforward. On the other hand, if your system needs to atomically update data that resides in multiple data stores, the operations need to be wrapped into a _distributed_ transaction, which is a lot more challenging to implement. This is a fairly common scenario in microservice architectures where a service needs to interact with other services to handle a request, and each service has its own separate data store. In this chapter, we explore various solutions to this problem. 

> 1“Transaction processing,” https://en.wikipedia.org/wiki/Transaction_proce ssing 


112 

## **12.1 ACID** 

Consider a money transfer from one bank account to another. If the withdrawal succeeds, but the deposit fails for some reason, the funds need to be deposited back into the source account. In other words, the transfer needs to execute atomically; either both the withdrawal and the deposit succeed, or in case of a failure, neither do. To achieve that, the withdrawal and deposit need to be wrapped in an inseparable unit of change: a _transaction_ . 

In a traditional relational database, a transaction is a group of operations for which the database guarantees a set of properties, known as _ACID_ : 

- **A** tomicity guarantees that partial failures aren’t possible; either all the operations in the transactions complete successfully, or none do. So if a transaction begins execution but fails for whatever reason, any changes it made must be undone. This needs to happen regardless of whether the transaction itself failed (e.g., divide by zero) or the database crashed mid way. 

- **C** onsistency guarantees that the application-level invariants must always be true. In other words, a transaction can only transition a database from a correct state to another correct state. How this is achieved is the responsibility of the application developer who defines the transaction. For example, in a money transfer, the invariant is that the sum of money across the accounts is the same after the transfer, i.e., money can’t be destroyed or created. Confusingly, the “C” in ACID has nothing to do with the consistency models we talked about so far, and according to Joe Hellerstein, it was tossed in to make the acronym work[2] . Therefore, we will safely ignore this property in the rest of the chapter. 

- **I** solation guarantees that a transaction appears to run in isolation as if no other transactions are executing, i.e., the concurrent execution of transactions doesn’t cause any race con- 

> 2“When is”ACID” ACID? Rarely.” http://www.bailis.org/blog/when-is-acidacid-rarely/ 


113 ditions. 

- **D** urability guarantees that once the database commits the transaction, the changes are persisted on durable storage so that the database doesn’t lose the changes if it subsequently crashes. In the way I described it, it sounds like the job is done once the data is persisted to a storage device. But, we know better by now, and replication[3] is required to ensure durability in the presence of storage failures. 

Transactions relieve developers from a whole range of possible failure scenarios so that they can focus on the actual application logic rather than handling failures. But to understand how distributed transactions work, we first need to discuss how centralized, nondistributed databases implement transactions. 

## **12.2 Isolation** 

The easiest way to guarantee that no transaction interferes with another is to run them serially one after another (e.g., using a global lock). But, of course, that would be extremely inefficient, which is why in practice transactions run concurrently. However, a group of concurrently running transactions accessing the same data can run into all sorts of race conditions, like dirty writes, dirty reads, fuzzy reads, and phantom reads: 

- A _dirty write_ happens when a transaction overwrites the value written by another transaction that hasn’t committed yet. 

- A _dirty read_ happens when a transaction observes a write from a transaction that hasn’t completed yet. 

- A _fuzzy read_ happens when a transaction reads an object’s value twice but sees a different value in each read because another transaction updated the value between the two reads. 

- A _phantom read_ happens when a transaction reads a group of objects matching a specific condition, while another transaction concurrently adds, updates, or deletes objects match3see Chapter 10 


114 ing the same condition. For example, if one transaction is summing all employees’ salaries while another deletes some employee records simultaneously, the final sum will be incorrect at commit time. 

To protect against these race conditions, a transaction needs to be isolated from others. An _isolation level_ protects against one or more types of race conditions and provides an abstraction that we can use to reason about concurrency. The stronger the isolation level is, the more protection it offers against race conditions, but the less performant it is. 

An isolation level is defined based on the type of race conditions it forbids, as shown in Figure 12.1. 


![](understanding-distributed-systems-github-pages/images/Roberto_Vitillo_-_Understanding_Distributed_Systems_-_2nd_Edition_-2022-.pdf-0132-05.png)


Figure 12.1: Isolation levels define which race conditions they forbid. 

Serializability is the only isolation level that isolates against all pos115 sible race conditions. It guarantees that executing a group of transactions has the same side effects as if the transactions run serially (one after another) in _some_ order. For example, suppose we have two concurrent transactions, X and Y, and transaction X commits before transaction Y. A serializable system guarantees that even though their operations are interleaved, they appear to run after the other, i.e., X before Y or Y before X (even if Y committed after!). To add a real-time requirement on the order of transactions, we need a stronger isolation level: _strict serializability_ . This level combines serializability with the real-time guarantees of linearizability so that when a transaction completes, its side effects become immediately visible to all future transactions. 

(Strict) serializability is slow as it requires coordination, which creates contention in the system. For example, a transaction may be forced to wait for other transactions. In some cases, it may even be forced to abort because it can no longer be executed as part of a serializable execution. Because not all applications require the guarantees that serializability provides, data stores allow developers to use weaker isolation levels. As a rule of thumb, we need to consciously decide which isolation level to use and understand its implications, or the data store will silently make that decision for us; for example, PostgreSQL’s default isolation[4] is read committed. So, if in doubt, choose strict serializability. 

There are more isolation levels and race conditions than the ones we discussed here. Jepsen[5] provides a good formal reference for the existing isolation levels, how they relate to one another, and which guarantees they offer. Although vendors typically document the isolation levels of their products, these specifications don’t always match[6] the formal definitions. 

Now that we know what serializability is, the challenge becomes maximizing concurrency while still preserving the appearance of serial execution. The concurrency strategy is defined by a _concur-_ 

> 4“PostgreSQL Transaction Isolation,” https://www.postgresql.org/docs/12/t ransaction-iso.html 

> 5“Consistency Models,” https://jepsen.io/consistency 

> 6“Jepsen Analyses,” https://jepsen.io/analyses 


116 

_rency control protocol_ , and there are two categories of protocols that guarantee serializability: pessimistic and optimistic. 

## **12.2.1 Concurrency control** 

A _pessimistic_ protocol uses locks to block other transactions from accessing an object. The most commonly used protocol is _two-phase locking_[7] (2PL). 2PL has two types of locks, one for reads and one for writes. A read lock can be shared by multiple transactions that access the object in read-only mode, but it blocks transactions trying to acquire a write lock. A write lock can be held only by a single transaction and blocks anyone trying to acquire either a read or write lock on the object. The locks are held by a _lock manager_ that keeps track of the locks granted so far, the transactions that acquired them, and the transactions waiting for them to be released. 

There are two phases in 2PL, an expanding phase and a shrinking one. In the expanding phase, the transaction is allowed only to acquire locks but not release them. In the shrinking phase, the transaction is permitted only to release locks but not acquire them. If these rules are obeyed, it can be formally proven that the protocol guarantees strict serializability. In practice, locks are only released when the transaction completes (aka strict 2PL). This ensures that data written by an uncommitted transaction X is locked until it’s committed, preventing another transaction Y from reading it and consequently aborting if X is aborted (aka _cascading abort_ ), resulting in wasted work. 

Unfortunately, with 2PL, it’s possible for two or more transactions to _deadlock_ and get stuck. For example, if transaction X is waiting for a lock that transaction Y holds, and transaction Y is waiting for a lock granted to transaction X, then the two transactions won’t make any progress. A general approach to deal with deadlocks is to detect them after they occur and select a “victim” transaction to abort and restart to break the deadlock. 

In contrast to a pessimistic protocol, an _optimistic_ protocol optimistically executes a transaction without blocking based on the 

7“Two-phase locking,” https://en.wikipedia.org/wiki/Two-phase_locking 


117 assumption that conflicts are rare and transactions are short-lived. _Optimistic concurrency control_[8] (OCC) is arguably the best-known protocol in the space. In OCC, a transaction writes to a local workspace without modifying the actual data store. Then, when the transaction wants to commit, the data store compares the transaction’s workspace to see whether it conflicts with the workspace of another running transaction. This is done by assigning each transaction a timestamp that determines its serializability order. If the validation succeeds, the content of the local workspace is copied to the data store. If the validation fails, the transaction is aborted and restarted. 

It’s worth pointing out that OCC uses _locks_ to guarantee mutual exclusion on internal shared data structures. These _physical_ locks are held for a short duration and are unrelated to the _logical_ locks we discussed earlier in the context of 2PL. For example, during the validation phase, the data store has to acquire locks to access the workspaces of the running transactions to avoid race conditions. In the database world, these locks are also referred to as _latches_ to distinguish them from logical locks. 

Optimistic protocols avoid the overhead of pessimistic protocols, such as acquiring locks and managing deadlocks. As a result, these protocols are well suited for read-heavy workloads that rarely perform writes or workloads that perform writes that only occasionally conflict with each other. On the other hand, pessimistic protocols are more efficient for conflict-heavy workloads since they avoid wasting work. 

Taking a step back, both the optimistic and pessimistic protocols discussed this far aren’t optimal for read-only transactions. In 2PC, a read-only transaction might wait for a long time to acquire a shared lock. On the other hand, in OCC, a read-only transaction may be aborted because the value it read has been overwritten. Generally, the number of read-only transactions is much higher than the number of write transactions, so it would be ideal if a read-only transaction could never block or abort because of a con- 

> 8“On Optimistic Methods for Concurrency Control,” https://www.eecs.harva rd.edu/~htk/publication/1981-tods-kung-robinson.pdf 


118 

_Multi-version concurrency control_[9] (MVCC) delivers on that premise by maintaining older versions of the data. Conceptually, when a transaction writes an object, the data store creates a new version of it. And when the transaction reads an object, it reads the newest version that existed when the transaction started. This mechanism allows a read-only transaction to read an immutable and consistent snapshot of the data store without blocking or aborting due to a conflict with a write transaction. However, for write transactions, MVCC falls back to one of the concurrency control protocols we discussed before (i.e., 2PL or OCC). Since generally most transactions are read-only, this approach delivers major performance improvements, which is why MVCC is the most widely used concurrency control scheme nowadays. 

For example, when MVCC is combined with 2PL, a write transaction uses 2PL to access any objects it wants to read or write so that if another transaction tries to update any of them, it will block. When the transaction is ready to commit, the transaction manager gives it an unique _commit timestamp_ 𝑇𝐶𝑖, which is assigned to all new versions the transaction created. Because only a single transaction can commit at a time, this guarantees that once the transaction commits, a read-only transaction whose _start timestamp_ 𝑇𝑆𝑗 is greater than or equal to the commit timestamp of the previous transaction (𝑇𝑆𝑗 ≥𝑇𝐶𝑖), will see all changes applied by the previous transaction. This is a consequence of the protocol allowing read-only transactions to read only the newest committed version of an object that has a timestamp less than or equal 𝑇𝑆𝑗. Thanks to this mechanism, a read-only transaction can read an immutable and consistent snapshot of the data store without blocking or aborting due to a conflict with a write transaction. 

I have deliberately glossed over the details of how these concurrency control protocols are implemented, as it’s unlikely you will have to implement them from scratch. But, the commercial data stores your applications depend on use the above protocols to iso- 

> 9“Multi-version concurrency control,” https://en.wikipedia.org/wiki/Multiv ersion_concurrency_control 


119 late transactions, so you must have a basic grasp of their tradeoffs. If you are interested in the details, I highly recommend Andy Pavlo’s database systems course[10] . 

That said, there is a limited form of OCC at the level of individual objects that is widely used in distributed applications and that you should know how to implement. The protocol assigns a version number to each object, which is incremented every time the object is updated. A transaction can then read a value from a data store, do some local computation, and finally update the value conditional on the version of the object not having changed. This validation step can be performed atomically using a compare-and-swap operation, which is supported by many data stores.[11] For example, if a transaction reads version 42 of an object, it can later update the object only if the version hasn’t changed. So if the version is the same, the object is updated and the version number is incremented to 43 (atomically). Otherwise, the transaction is aborted and restarted. 

## **12.3 Atomicity** 

When executing a transaction, there are two possible outcomes: it either commits after completing all its operations or aborts due to a failure after executing some operations. When a transaction is aborted, the data store needs to guarantee that all the changes the transaction performed are undone (rolled back). 

To guarantee atomicity (and also durability), the data store records all changes to a write-ahead log (WAL) persisted on disk before applying them. Each log entry records the identifier of the transaction making the change, the identifier of the object being modified, and both the old and new value of the object. Most of the time, the database doesn’t read from this log at all. But if a transaction is aborted or the data store crashes, the log contains enough information to redo changes to ensure atomicity and durability and 

> 10“CMU 15-445/645: Database Systems,” https://15445.courses.cs.cmu.edu/fal l2019/ 

> 11 We have already seen an example of this when discussing leases in section 9.2. 


120 undo changes in case of a failure during a transaction execution.[12] 

Unfortunately, this WAL-based recovery mechanism only guarantees atomicity within a single data store. Going back to our original example of sending money from one bank account to another, suppose the two accounts belong to two different banks that use separate data stores. We can’t just run two separate transactions to respectively withdraw and deposit the funds — if the second transaction fails, the system is left in an inconsistent state. What we want is the guarantee that either both transactions succeed and their changes are committed or they fail without any side effects. 

## **12.3.1 Two-phase commit** 

_Two-phase commit_[13] (2PC) is a protocol used to implement atomic transaction commits across multiple processes. The protocol is split into two phases, _prepare_ and _commit_ . It assumes a process acts as _coordinator_ and orchestrates the actions of the other processes, called _participants_ . For example, the client application that initiates the transaction could act as the coordinator for the protocol. 

When a coordinator wants to commit a transaction, it sends a _prepare_ request asking the participants whether they are prepared to commit the transaction (see Figure 12.2). If all participants reply that they are ready to commit, the coordinator sends a _commit_ request to all participants ordering them to do so. In contrast, if any process replies that it’s unable to commit or doesn’t respond promptly, the coordinator sends an _abort_ request to all participants. 

There are two points of no return in the protocol. If a participant replies to a prepare message that it’s ready to commit, it will have to do so later, no matter what. The participant can’t make progress from that point onward until it receives a message from the coordinator to either commit or abort the transaction. This means that 

> 12The details of how this recovery mechanism works are outside the scope of this book, but you can learn more about it from any database textbook. 

> 13“Two-phase commit protocol,” https://en.wikipedia.org/wiki/Two-phase_c ommit_protocol 


121 


![](understanding-distributed-systems-github-pages/images/Roberto_Vitillo_-_Understanding_Distributed_Systems_-_2nd_Edition_-2022-.pdf-0139-02.png)


Figure 12.2: The two-phase commit protocol consists of a prepare and a commit phase. if the coordinator crashes, the participant is stuck. 

The other point of no return is when the coordinator decides to commit or abort the transaction after receiving a response to its prepare message from all participants. Once the coordinator makes the decision, it can’t change its mind later and has to see the transaction through to being committed or aborted, no matter what. If a participant is temporarily down, the coordinator will keep retrying until the request eventually succeeds. 

Two-phase commit has a mixed reputation[14] . It’s slow since it requires multiple round trips for a transaction to complete, and if either the coordinator or a participant fails, then all processes part of the transactions are blocked until the failing process comes back online. On top of that, the participants need to implement the protocol; you can’t just take two different data stores and expect them 

> 14“It’s Time to Move on from Two Phase Commit,” http://dbmsmusings.blog spot.com/2019/01/its-time-to-move-on-from-two-phase.html 


122 to play ball with each other. 

If we are willing to increase the complexity of the protocol, we can make it more resilient to failures by replicating the state of each process involved in the transaction. For example, replicating the coordinator with a consensus protocol like Raft makes 2PC resilient to coordinator failures. Similarly, the participants can also be replicated. 

As it turns out, atomically committing a transaction is a form of consensus, called _uniform consensus_ , where all the processes have to agree on a value, even the faulty ones. In contrast, the general form of consensus introduced in section 10.2 only guarantees that all non-faulty processes agree on the proposed value. Therefore, uniform consensus is actually harder[15] than consensus. Nevertheless, as mentioned earlier, general consensus can be used to replicate the state of each process and make the overall protocol more robust to failures. 

## **12.4 NewSQL** 

As a historical side note, the first versions of modern large-scale data stores that came out in the late 2000s used to be referred to as _NoSQL_ stores since their core features were focused entirely on scalability and lacked the guarantees of traditional relational databases, such as ACID transactions. But in recent years, that has started to change as distributed data stores have continued to add features that only traditional databases offered. 

Arguably one of the most successful implementations of a NewSQL data store is Google’s Spanner[16] . At a high level, Spanner breaks data (key-value pairs) into partitions in order to scale. Each partition is replicated across a group of nodes in different data centers using a state machine replication protocol (Paxos). 

> 15“Uniform consensus is harder than consensus,” https://infoscience.epfl.ch/ record/88273/files/CBS04.pdf?version=1 

> 16“Spanner: Google’s Globally-Distributed Database,” https://static.googleuse rcontent.com/media/research.google.com/en//archive/spanner-osdi2012.pdf 


123 

In each replication group, there is one specific node that acts as the leader, which handles a client write transaction for that partition by first replicating it across a majority of the group and then applying it. The leader also serves as a lock manager and implements 2PL to isolate transactions modifying the partition from each other. 

To support transactions that span multiple partitions, Spanner implements 2PC. A transaction is initiated by a client and coordinated by one of the group leaders of the partitions involved. All the other group leaders act as participants of the transaction (see Figure 12.3). 

The coordinator logs the transaction’s state into a local write-ahead log, which is replicated across its replication group. That way, if the coordinator crashes, another node in the replication group is elected as the leader and resumes coordinating the transaction. Similarly, each participant logs the transaction’s state in its log, which is also replicated across its group. So if the participant fails, another node in the group takes over as the leader and resumes the transaction. 

To guarantee isolation between transactions, Spanner uses MVCC combined with 2PL. Thanks to that, read-only transactions are lock-free and see a consistent snapshot of the data store. In contrast, write transactions use two-phase locking to create new versions of the objects they change to guarantee strict serializability. 

If you recall the discussion about MVCC in section 12.2, you should know that each transaction is assigned a unique timestamp. While it’s easy to do that on a single machine, it’s a lot more challenging in a distributed setting since clocks aren’t perfectly synchronized. Although we could use a centralized timestamp service that allocates unique timestamps to transactions, it would become a scalability bottleneck. To solve this problem, Spanner uses physical clocks that, rather than returning precise timestamps, return _uncertainty intervals_ [𝑡𝑒𝑎𝑟𝑙𝑖𝑒𝑠𝑡, 𝑡𝑙𝑎𝑡𝑒𝑠𝑡] that take into account the error boundary of the measurements, where 𝑡𝑒𝑎𝑟𝑙𝑖𝑒𝑠𝑡 ≤𝑡𝑟𝑒𝑎𝑙 ≤𝑡𝑙𝑎𝑡𝑒𝑠𝑡. So although a node doesn’t know the 


124 


![](understanding-distributed-systems-github-pages/images/Roberto_Vitillo_-_Understanding_Distributed_Systems_-_2nd_Edition_-2022-.pdf-0142-02.png)


Figure 12.3: Spanner combines 2PC with 2PL and state machine replication. In this figure, there are three partitions and three replicas per partition. current physical time 𝑡𝑟𝑒𝑎𝑙, it knows it’s within the interval with a very high probability. 

Conceptually, when a transaction wants to commit, it’s assigned the 𝑡𝑙𝑎𝑡𝑒𝑠𝑡 timestamp of the interval returned by the transaction coordinator’s clock. But before the transaction can commit and release the locks, it waits for a duration equal to the uncertainty period (𝑡𝑙𝑎𝑡𝑒𝑠𝑡−𝑡𝑒𝑎𝑟𝑙𝑖𝑒𝑠𝑡). The waiting time guarantees that any transaction that starts after the previous transaction committed sees the changes applied by it. Of course, the challenge is to keep the uncertainty interval as small as possible in order for the transactions to be fast. Spanner does this by deploying GPS and atomic clocks in every data center and frequently synchronizing the quartz clocks 


125 of the nodes with them.[17] . Other systems inspired by Spanner, like CockroachDB[18] , take a different approach and rely instead on hybrid-logical clocks which are composed of a physical timestamp and a logical timestamp.[19] 

> 17The clock uncertainty is generally less than 10ms. 

> 18“CockroachDB,” https://www.cockroachlabs.com/ 

> 19“Logical Physical Clocks and Consistent Snapshots in Globally Distributed Databases,” https://cse.buffalo.edu/tech-reports/2014-04.pdf 


