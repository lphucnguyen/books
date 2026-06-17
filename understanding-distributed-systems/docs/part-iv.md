# **Part IV** 

**Resiliency** 

# **Introduction** 

_“Anything that can go wrong will go wrong.”_ 

– Murphy’s law 

In the last part, we discussed the three fundamental scalability patterns: functional decomposition, data partitioning, and replication. They all have one thing in common: they increase the number of moving parts (machines, services, processes, etc.) in our applications. But since every part has a probability of failing, the more moving parts there are, the higher the chance that any of them will fail. Eventually, anything that can go wrong will go wrong[8] ; power outages, hardware faults, software crashes, memory leaks — you name it. 

Remember when we talked about availability and “nines” in chapter 1? Well, to guarantee just two nines, an application can only be unavailable for up to 15 minutes a day. That’s very little time to take any manual action when something goes wrong. And if we strive for three nines, we only have 43 minutes per _month_ available. Clearly, the more nines we want, the faster our systems need to detect, react to, and repair faults as they occur. In this part, we will discuss a variety of resiliency best practices and patterns to achieve that. 

To build fault-tolerant applications, we first need to have an idea of what can go wrong. In chapter 24, we will explore some of the most common root causes of failures. 

> 8Also known as Murphy’s law 

Chapter 25 describes how to use redundancy, the replication of functionality or state, to increase the availability of a system. As we will learn, redundancy is only helpful when the redundant nodes can’t fail for the same reason at the same time, i.e., when failures are not correlated. 

Chapter 26 discusses how to isolate correlated failures by partitioning resources and then describes two very powerful forms of partitioning: shuffle sharding and cellular architectures. 

Chapter 27 dives into more tactical resiliency patterns for tolerating failures of downstream dependencies that you can apply to existing systems with few changes, like timeouts and retries. 

Chapter 28 discusses resiliency patterns, like load shedding and rate-limiting, for protecting systems against overload from upstream dependencies. 

