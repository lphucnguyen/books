<!-- PAGE 152 -->
 152 -->

Chapter 5  Distributed transactions
Choreography
Orchestration
Less resource-intensive, less chatty, and less net-
work traffic; hence, it has lower latency overall.
Since every step must pass through the orchestra-
tor, the number of events is double that of chore-
ography. The overall effect is that orchestration is 
more resource-intensive, chattier, and has more 
network traffic; hence, it has higher latency overall.
Parallel requests also result in lower latency.
Requests are linear, so latency is higher.
Services have a less independent software devel-
opment lifecycle because developers must under-
stand all services to change any one of them.
Services are more independent. A change to a 
service only affects the orchestrator and does not 
affect other services.
No such single point of failure as in orchestration 
(i.e., no service needs to be highly available except 
the Kafka service).
If the orchestration service fails, the entire saga 
cannot execute (i.e., the orchestrator and the Kafka 
service must be highly available).
Compensating transactions are triggered by the 
various services involved in the saga.
Compensating transactions are triggered by the 
orchestrator.
5.7	
Other transaction types
The following consensus algorithms are typically more useful for achieving consen-
sus for a large number of nodes, typically in distributed databases. We will not discuss 
them in this book. Refer to Designing Data-Intensive Applications by Martin Kleppman for 
more details.
¡ Quorum writes
¡ Paxos and EPaxos 
¡ Raft 
¡ Zab (ZooKeeper atomic broadcast protocol) – Used by Apache ZooKeeper.
5.8	
Further reading 
¡ Designing Data-Intensive Applications: The Big Ideas Behind Reliable, Scalable, and 
Maintainable Systems by Martin Kleppmann (O'Reilly Media, 2017)
¡ Cloud Native: Using Containers, Functions, and Data to Build Next-Generation Applica-
tions by Boris Scholl, Trent Swanson, and Peter Jausovec (O’Reilly Media, 2019) 
¡ Cloud Native Patterns by Cornelia Davis (Manning Publications, 2019)
¡ Microservices Patterns: With Examples in Java by Chris Richardson (Manning Publi-
cations, 2019). Chapter 3.3.7 discusses the transaction log tailing pattern. Chap-
ter 4 is a detailed chapter on saga.


<!-- PAGE 153 -->
 153 -->

	
Summary
Summary
¡ A distributed transaction writes the same data to multiple services, with either 
eventual consistency or consensus.
¡ In event sourcing, write events are stored in a log, which is the source of truth and 
an audit trail that can replay events to reconstruct the system state.
¡ In Change Data Capture (CDC), an event stream has multiple consumers, each 
corresponding to a downstream service.
¡ A saga is a series of transactions that are either all completed successfully or are 
all rolled back.
¡ Choreography (parallel) or orchestration (linear) are two ways to coordinate 
sagas. 


<!-- PAGE 154 -->
 154 -->

Common services for 
functional partitioning
This chapter covers
¡ Centralizing cross-cutting concerns with API 	
	 gateway or service mesh/sidecar
¡ Minimizing network traffic with a metadata 	
	 service
¡ Considering web and mobile frameworks to 	
	 fulfill requirements
¡ Implementing functionality as libraries vs. 		
	 services
¡ Selecting an appropriate API paradigm between 	
	 REST, RPC, and GraphQL
Earlier in this book, we discussed functional partitioning as a scalability technique 
that partitions out specific functions from our backend to run on their own dedi-
cated clusters. This chapter first discusses the API gateway, followed by the sidecar 
pattern (also called service mesh), which was a recent innovation. Next, we discuss 
centralization of common data into a metadata service. A common theme of these 
services is that they contain functionalities common to many backend services, 
which we can partition from those services into shared common services. 
NOTE    Istio, a popular service mesh implementation, had its first production 
release in 2018.


<!-- PAGE 155 -->
 155 -->

	
Common functionalities of various services
Last, we discuss frameworks that can be used to develop the various components in a 
system design. 
6.1	
Common functionalities of various services
A service can have many non-functional requirements, and many services with differ-
ent functional requirements can share the same non-functional requirements. For 
example, a service that calculates sales taxes and a service to check hotel room avail-
ability may both take advantage of caching to improve performance or only accept 
requests from registered users.
If engineers implement these functionalities separately for each service, there 
may be duplication of work or duplicate code. Errors or inefficiencies are more likely 
because scarce engineering resources are spread out across a larger amount of work. 
One possible solution is to place this code into libraries where various services can 
use them. However, this solution has the disadvantages discussed in section 6.7. Library 
updates are controlled by users, so the services may continue to run old versions that 
contain bugs or security problems fixed in newer versions. Each host running the ser-
vice also runs the libraries, so the different functionalities cannot be independently 
scaled.
A solution is to centralize these cross-cutting concerns with an API gateway. An API 
gateway is a lightweight web service that consists of stateless machines located across 
several data centers. It provides common functionalities to our organization’s many 
services for centralization of cross-cutting concerns across various services, even if they 
are written in different programming languages. It should be kept as simple as possi-
ble despite its many responsibilities. Amazon API Gateway (https://aws.amazon.com/
api-gateway/) and Kong (https://konghq.com/kong) are examples of cloud-provided 
API gateways.
The functionalities of an API gateway include the following, which can be grouped 
into categories. 
6.1.1	
Security
These functionalities prevent unauthorized access to a service’s data:
¡ Authentication: Verifies that a request is from an authorized user. 
¡ Authorization: Verifies that a user is allowed to make this request. 
¡ SSL termination: Termination is usually not handled by the API gateway itself but 
by a separate HTTP proxy that runs as a process on the same host. We do termi-
nation on the API gateway because termination on a load balancer is expensive. 
Although the term “SSL termination” is commonly used, the actual protocol is 
TLS, which is the successor to SSL. 
¡ Server-side data encryption: If we need to store data securely on backend hosts or 
on a database, the API gateway can encrypt data before storage and decrypt data 
before it is sent to a requestor. 


