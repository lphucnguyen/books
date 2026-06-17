# **Part II** 

**Coordination** 

# **Introduction** 

_“Here is a Raft joke. It is really a Paxos joke, but easier to follow.”_ 

# – Aleksey Charapko 

So far, we have learned how to get processes to communicate reliably and securely with each other. We didn’t go into all this trouble just for the sake of it, though. Our ultimate goal is to build a distributed application made of a group of processes that gives its users the illusion they are interacting with one coherent node. Although achieving a perfect illusion is not always possible or desirable, some degree of coordination is always needed to build a distributed application. 

In this part, we will explore the core distributed algorithms at the heart of distributed applications. This is the most challenging part of the book since it contains the most theory, but also the most rewarding one once you understand it. If something isn’t clear during your first read, try to read it again and engage with the content by following the references in the text. Some of these references point to papers, but don’t be intimidated. You will find that many papers are a lot easier to digest and more practical than you think. There is only so much depth a book can go into, and if you want to become an expert, reading papers should become a habit. 

Chapter 6 introduces formal models that categorize systems based on what guarantees they offer about the behavior of processes, communication links, and timing; they allow us to reason about distributed systems by abstracting away the implementation details. 

Chapter 7 describes how to detect that a remote process is unreachable. Failure detection is a crucial component of any distributed system. Because networks are unreliable, and processes can crash at any time, without failure detection a process trying to communicate with another could hang forever. 

Chapter 8 dives into the concept of time and order. We will first learn why agreeing on the time an event happened in a distributed system is much harder than it looks and then discuss a solution based on clocks that don’t measure the passing of time. 

Chapter 9 describes how a group of processes can elect a leader that can perform privileged operations, like accessing a shared resource or coordinating the actions of other processes. 

Chapter 10 introduces one of the fundamental challenges in distributed systems: replicating data across multiple processes. This chapter also discusses the implications of the CAP and PACELC theorems, namely the tradeoff between consistency and availability/performance. 

Chapter 11 explores weaker consistency models for replicated data, like strong eventual consistency and causal consistency, which allow us to build consistent, available, and partition-tolerant systems. 

Chapter 12 dives into the implementation of ACID transactions that span data partitioned among multiple processes or services. Transactions relieve us from a whole range of possible failure scenarios so that we can focus on the actual application logic rather than all the possible things that can go wrong. 

Chapter 13 discusses how to implement long-running atomic transactions that don’t block by sacrificing the isolation guarantees of ACID. This chapter is particularly relevant in practice since it showcases techniques commonly used in microservice architectures. 

