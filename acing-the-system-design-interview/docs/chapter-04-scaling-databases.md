<!-- PAGE 140 -->
 140 -->

Chapter 4  Scaling databases
¡ Database writes are expensive and difficult to scale, so we should minimize data-
base writes wherever possible. Aggregating events helps to reduce the rate of 
database writes.
¡ Lambda architecture involves using parallel batch and streaming pipelines to 
process the same data, and realize the benefits of both approaches while allowing 
them to compensate for each other’s disadvantages.
¡ Denormalizing is frequently used to optimize read latency and simpler SELECT 
queries, with tradeoffs like consistency, slower writes, more storage required, and 
slower index rebuilds.
¡ Caching frequent queries in memory reduces average query latency.
¡ Read strategies are for fast reads, trading off cache staleness.
¡ Cache-aside is best for read-heavy loads, but the cached data may become stale 
and cache misses are slower than if the cache wasn’t present.
¡ A read-through cache makes requests to the database, removing this burden 
from the application.
¡ A write-through cache is never stale, but it is slower.
¡ A write-back cache periodically flushes updated data to the database. Unlike 
other cache designs, it must have high availability to prevent possible data loss 
from outages.
¡ A write-around cache has slow writes and a higher chance of cache staleness. It is 
suitable for situations where the cached data is unlikely to change.
¡ A dedicated caching service can serve our users much better than caching on the 
memory of our services’ hosts.
¡ Do not cache private data. Cache public data; revalidation and cache expiry time 
depends on how often and likely the data will change.
¡ Cache invalidation strategies are different in services versus clients because we 
have access to the hosts in the former but not the latter.
¡ Warming a cache allows the first user of the cached data to be served as quickly as 
subsequent users, but cache warming has many disadvantages.


<!-- PAGE 141 -->
 141 -->

Distributed transactions
This chapter covers
¡ Creating data consistency across multiple 		
	 services
¡ Using event sourcing for scalability, availability, 	
	 lower cost, and consistency
¡ Writing a change to multiple services with 		
	 Change Data Capture (CDC) 
¡ Doing transactions with choreography vs. 	 	
	 orchestration
In a system, a unit of work may involve writing data to multiple services. Each write 
to each service is a separate request/event. Any write may fail; the causes may 
include bugs or host or network outages. This may cause data inconsistency across 
the services. For example, if a customer bought a tour package consisting of both an 
air ticket and a hotel room, the system may need to write to a ticket service, a room 
reservation service, and a payments service. If any write fails, the system will be in an 
inconsistent state. Another example is a messaging system that sends messages to 
recipients and logs to a database that messages have been sent. If a message is suc-
cessfully sent to a recipient’s device, but the write to the database fails, it will appear 
that the message has not been delivered.


