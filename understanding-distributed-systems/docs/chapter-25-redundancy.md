## **Chapter 25** 

## **Redundancy** 

Redundancy, the replication of functionality or state, is arguably the first line of defense against failures. When functionality or state is replicated over multiple nodes and a node fails, the others can take over. Moreover, as discussed in Part III, replication is also a core pattern that enables our applications to scale out horizontally. 

Redundancy is the main reason why distributed applications can achieve better availability than single-node applications. But only some forms of redundancy actually improve availability. Marc Brooker lists four prerequisites[1] : 

1. The complexity added by introducing redundancy mustn’t cost more availability than it adds. 

2. The system must reliably detect which of the redundant components are healthy and which are unhealthy. 

3. The system must be able to run in degraded mode. 

4. The system must be able to return to fully redundant mode. 

Let’s see how these prerequisites apply to a concrete example. Hardware faults such as disk, memory, and network failures can cause a node to crash, degrade or become otherwise unavailable. In a stateless service, a load balancer can mask these faults using 

> 1“When Redundancy Actually Helps,” https://brooker.co.za/blog/2019/06 /20/redundancy.html 


244 a pool of redundant nodes. Although the load balancer increases the system’s complexity and, therefore, the number of ways the system can fail, the benefits in terms of scalability and availability almost always outweigh the risks it introduces (e.g., the load balancer failing). 

The load balancer needs to detect which nodes are healthy and which aren’t to take the faulty ones out of the pool. It does that with health checks, as we learned in chapter 18. Health checks are critical to achieving high availability; if there are ten servers in the pool and one is unresponsive for some reason, then 10% of requests will fail, causing the availability to drop. Therefore, the longer it takes for the load balancer to detect the unresponsive server, the longer the failures will be visible to the clients. 

Now, when the load balancer takes one or more unhealthy servers out of the pool, the assumption is that the others have enough capacity left to handle the increase in load. In other words, the system must be able to run in degraded mode. However, that by itself is not enough; new servers also need to be added to the pool to replace the ones that have been removed. Otherwise, there eventually won’t be enough servers left to cope with the load. 

In stateful services, masking a node failure is a lot more complex since it involves replicating state. We have discussed replication at length in the previous chapters, and it shouldn’t come as a surprise by now that meeting the above requisites is a lot more challenging for a stateful service than for a stateless one. 

## **25.1 Correlation** 

Redundancy is only helpful when the redundant nodes can’t fail for the same reason at the same time, i.e., when failures are not correlated. For example, if a faulty memory module causes a server to crash, it’s unlikely other servers will fail simultaneously for the same reason since they are running on different machines. However, if the servers are hosted in the same data center, and a fiber cut or an electrical storm causes a data-center-wide outage, the en245 tire application becomes unavailable no matter how many servers there are. In other words, the failures caused by a data center outage are correlated and limit the application’s availability. So if we want to increase the availability, we have to reduce the correlation between failures by using more than one data center. 

Cloud providers such as AWS and Azure replicate their entire stack in multiple regions for that very reason. Each region comprises multiple data centers called Availability Zones (AZs) that are cross-connected with high-speed network links. AZs are far enough from each other to minimize the risk of correlated failures (e.g., power cuts) but still close enough to have low network latency, which is bounded by the speed of light. In fact, the latency is low enough by design to support synchronous replication protocols without a significant latency penalty. 

With AZs, we can create applications that are resilient to data center outages. For example, a stateless service could have instances running in multiple AZs behind a shared load balancer so that if an AZ becomes unavailable, it doesn’t impact the availability of the service. On the other hand, stateful services require the use of a replication protocol to keep their state in sync across AZs. But since latencies are low enough between AZs, the replication protocol can be partially synchronous, like Raft, or even fully synchronous, like chain replication. 

Taking it to the extreme, a catastrophic event could destroy an entire region with all of its AZs. To tolerate that, we can duplicate the entire application stack in multiple regions. To distribute the traffic to different data centers located in different regions, we can use _global DNS load balancing_ . Unlike earlier, the application’s state needs to be replicated asynchronously across regions[2] given the high network latency between regions (see Figure 25.1). 

That said, the chance of an entire region being destroyed is extremely low. Before embarking on the effort of making your application resilient against region failures, you should have very good 

> 2“Active-Active for Multi-Regional Resiliency,” https://netflixtechblog.com/ active-active-for-multi-regional-resiliency-c47719f6685b 


246 


![](understanding-distributed-systems-github-pages/images/Roberto_Vitillo_-_Understanding_Distributed_Systems_-_2nd_Edition_-2022-.pdf-0264-02.png)


Figure 25.1: A simplistic multi-region architecture reasons for it. It’s more likely your application will be forced to have a presence in multiple regions for legal compliance reasons. For example, there are laws mandating that the data of European customers has to be processed and stored within Europe[3] . 

> 3“The CJEU judgment in the Schrems II case,” https://www.europarl.europa. eu/RegData/etudes/ATAG/2020/652073/EPRS_ATA(2020)652073_EN.pdf 


