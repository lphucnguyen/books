<!-- PAGE 108 -->
 108 -->

# Chapter 3  Non-functional requirements
Summary
¡ We must discuss both the functional and non-functional requirements of a 
system. Do not make assumptions about the non-functional requirements. 
­Non-functional characteristics can be traded off against each other to optimize 
## for the non-functional requirements.
¡ Scalability is the ability to easily adjust the system’s hardware resource usage for 
cost efficiency. This is almost always discussed because it is difficult or impossible 
to predict the amount of traffic to our system.
¡ Availability is the percentage of time a system can accept requests and return the 
desired response. Most, but not all, systems require high availability, so we should 
clarify whether it is a requirement in our system.
¡ Fault-tolerance is the ability of a system to continue operating if some compo-
nents fail and the prevention of permanent harm should downtime occur. This 
allows our users to continue using some features and buys time for engineers to 
fix the failed components.
¡ Performance or latency is the time taken for a user’s request to the system to 
return a response. Users expect interactive applications to load fast and respond 
quickly to their input.
¡ Consistency is defined as all nodes containing the same data at a moment in time, 
and when changes in data occur, all nodes must start serving the changed data at 
the same time. In certain systems, such as financial systems, multiple users view-
ing the same data must see the same values, while in other systems such as social 
media, it may be permissible for different users to view slightly different data at 
any point in time, as long as the data is eventually the same.
¡ Eventually, consistent systems trade off accuracy for lower complexity and cost. 
¡ Complexity must be minimized so the system is cheaper and easier to build 
and maintain. Use common techniques, such as common services, wherever 
applicable.
¡ Cost discussions include minimizing complexity, cost of outages, cost of main-
tenance, cost of switching to other technologies, and cost of decommissioning.
¡ Security discussions include which data must be secured and which can be unse-
cured, followed by using concepts such as encryption in transit and encryption 
at rest. 
¡ Privacy considerations include access control mechanisms and procedures, dele-
tion or obfuscation of user data, and prevention and mitigation of data breaches.
¡ Cloud native is an approach to system design that employs a collection of tech-
niques to achieve common non-functional requirements.


<!-- PAGE 109 -->
 109 -->

**Scaling databases**
This chapter covers
¡ Understanding various types of storage 	
	
	 services
¡ Replicating databases
¡ Aggregating events to reduce database writes
¡ Differentiating normalization vs. 	 	
	
## denormalization
¡ Caching frequent queries in memory
In this chapter, we discuss concepts in scaling databases, their tradeoffs, and com-
mon databases that utilize these concepts in their implementations. We consider 
these concepts when choosing databases for various services in our system.  
4.1	
## Brief prelude on storage services
Storage services are stateful services. Compared to stateless services, stateful services 
have mechanisms to ensure consistency and require redundancy to avoid data loss. 
A stateful service may choose mechanisms like Paxos for strong consistency or even-
tual-consistency mechanisms. These are complex decisions, and tradeoffs have to 
be made, which depend on the various requirements like consistency, complexity, 
security, latency, and performance. This is one reason we keep all services stateless 
as much as possible and keep state only in stateful services.


