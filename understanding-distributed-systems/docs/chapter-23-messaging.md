## **Chapter 23** 

## **Messaging** 

Suppose _Cruder_ has an endpoint that allows users to upload a video and encode it in different formats and resolutions tailored to specific devices (TVs, mobile phones, tablets, etc.). When the API gateway receives a request from a client, it uploads the video to a file store, like S3, and sends a request to an encoding service to process the file. 

Since the encoding can take minutes to complete, we would like the API gateway to send the request to the encoding service without waiting for the response. But the naive implementation (fireand-forget) would cause the request to be lost if the encoding service instance handling it on the other side crashes or fails for any reason. 

A more robust solution is to introduce a message channel between the API gateway and the encoding service. Messaging was first introduced in chapter 5 when discussing APIs. It’s a form of indirect communication in which a producer writes a message to a channel — or message broker — that delivers the message to a consumer on the other end. 

A message channel acts as a temporary buffer for the receiver. Unlike the direct request-response communication style we have been using so far, messaging is inherently asynchronous, as sending a 


218 message doesn’t require the receiving service to be online. The messages themselves have a well-defined format, consisting of a header and a body. The message header contains metadata, such as a unique message ID, while the body contains the actual content. 

Typically, a message can either be a command, which specifies an operation to be invoked by the receiver, or an event, which signals the receiver that something of interest happened to the sender. A service can use inbound adapters to receive messages from channels and outbound adapters to send messages to channels, as shown in Figure 23.1. 


![](understanding-distributed-systems-github-pages/images/Roberto_Vitillo_-_Understanding_Distributed_Systems_-_2nd_Edition_-2022-.pdf-0236-04.png)


Figure 23.1: The message consumer (an inbound adapter) is part of the API surface of the service. 

After the API gateway has uploaded the video to the file store, it writes a message to the channel with a link to the uploaded file and responds with _202 Accepted_ , signaling to the client that the request has been accepted for processing but hasn’t completed yet. Eventually, the encoding service will read the message from the channel and process it. Because the request is deleted from the channel only when it’s successfully processed, the request will eventually be picked up again and retried if the encoding service fails to han219 

## dle it. 

Decoupling the API gateway (producer) from the encoding service (consumer) with a channel provides many benefits. The producer can send requests to the consumer even if the consumer is temporarily unavailable. Also, requests can be load-balanced across a pool of consumer instances, making it easy to scale out the consuming side. And because the consumer can read from the channel at its own pace, the channel smooths out load spikes, preventing it from getting overloaded. 

Another benefit is that messaging enables to process multiple messages within a single _batch_ or _unit of work_ . Most messaging brokers support this pattern by allowing clients to fetch up to _N_ messages with a single read request. Although batching degrades the processing latency of individual messages, it dramatically improves the application’s throughput. So when we can afford the extra latency, batching is a no brainer. 

In general, a message channel allows any number of producer and consumer instances to write and read from it. But depending on how the channel delivers a message, it’s classified as either pointto-point or publish-subscribe. In a _point-to-point_ channel, the message is delivered to exactly one consumer instance. Instead, in a _publish-subscribe_ channel, each consumer instance receives a copy of the message. 

Unsurprisingly, introducing a message channel adds complexity. The message broker is yet another service that needs to be maintained and operated. And because there is an additional hop between the producer and consumer, the communication latency is necessarily going to be higher; more so if the channel has a large backlog of messages waiting to be processed. As always, it’s all about tradeoffs. 

Because messaging is a core pattern of distributed systems, we will take a closer look at it in this chapter, starting with the most common communication styles it enables. 

## **One-way messaging** 


220 

In this messaging style, the producer writes a message to a pointto-point channel with the expectation that a consumer will eventually read and process it (see Figure 23.2). This is the style we used in the example earlier. 


![](understanding-distributed-systems-github-pages/images/Roberto_Vitillo_-_Understanding_Distributed_Systems_-_2nd_Edition_-2022-.pdf-0238-03.png)


Figure 23.2: One-way messaging style 

## **Request-response messaging** 

This messaging style is similar to the direct request-response style we are familiar with, albeit with the difference that the request and response messages flow through channels. The consumer has a point-to-point request channel from which it reads messages, while every producer has its dedicated response channel (see Figure 23.3). 

When a producer writes a message to the request channel, it decorates it with a request ID and a reference to its response channel. Then, after a consumer has read and processed the message, it writes a reply to the producer’s response channel, tagging it with the request’s ID, which allows the producer to identify the request it belongs to. 

## **Broadcast messaging** 

In this messaging style, the producer writes a message to a publishsubscribe channel to broadcast it to all consumer instances (see Figure 23.4). This style is generally used to notify a group of processes that a specific event has occurred. For example, we have already encountered this pattern when discussing the outbox pattern in section 13.1. 


221 


![](understanding-distributed-systems-github-pages/images/Roberto_Vitillo_-_Understanding_Distributed_Systems_-_2nd_Edition_-2022-.pdf-0239-02.png)


Figure 23.3: Request-response messaging style 


![](understanding-distributed-systems-github-pages/images/Roberto_Vitillo_-_Understanding_Distributed_Systems_-_2nd_Edition_-2022-.pdf-0239-04.png)


Figure 23.4: Broadcast messaging style 

## **23.1 Guarantees** 

A message channel is implemented by a messaging service, or broker, like AWS SQS[1] or Kafka, which buffers messages and decouples the producer from the consumer. Different message brokers offer different guarantees depending on the tradeoffs their implementations make. For example, you would think that a channel should respect the insertion order of its messages, but you will find that some implementations, like SQS standard queues[2] , don’t offer any strong ordering guarantees. Why is that? 

Because a message broker needs to scale horizontally just like 

> 1“Amazon Simple Queue Service,” https://aws.amazon.com/sqs/ 

> 2“Amazon SQS Standard queues,” https://docs.aws.amazon.com/AWSSimpl eQueueService/latest/SQSDeveloperGuide/standard-queues.html 


222 the applications that use it, its implementation is necessarily distributed. And when multiple nodes are involved, guaranteeing order becomes challenging, as some form of coordination is required. Some brokers, like Kafka, partition a channel into multiple sub-channels. So when messages are written to the channel, they are routed to sub-channels based on their partition key. Since each partition is small enough to be handled by a single broker process, it’s trivial to enforce an ordering of the messages routed to it. But to guarantee that the message order is preserved end-to-end, only a single consumer process is allowed to read from a sub-channel[3] . 

Because the channel is partitioned, all the caveats discussed in chapter 16 apply to it. For example, a partition could become hot enough (due to the volume of incoming messages) that the consumer reading from it can’t keep up with the load. In this case, the channel might have to be rebalanced by adding more partitions, potentially degrading the broker while messages are being shuffled across partitions. It should be clear by now why not guaranteeing the order of messages makes the implementation of a broker much simpler. 

Ordering is just one of the many tradeoffs a broker needs to make, such as: 

- delivery guarantees, like at-most-once or at-least-once; 

- message durability guarantees; 

- latency; 

- messaging standards supported, like AMQP[4] ; 

- support for competing consumer instances; 

- broker limits, such as the maximum supported size of messages. 

Because there are so many different ways to implement channels, in the rest of this section, we will make some assumptions for the sake of simplicity: 

> 3This is also referred to as the _competing consumer pattern_ , which is implemented using leader election. 

> 4“Advanced Message Queuing Protocol,” https://en.wikipedia.org/wiki/Ad vanced_Message_Queuing_Protocol 


223 

- Channels are point-to-point and support many producer and consumer instances. 

- Messages are delivered to the consumer at least once. 

- While a consumer instance is processing a message, the message remains in the channel, but other instances can’t read it for the duration of a visibility timeout. The _visibility timeout_ guarantees that if the consumer instance crashes while processing the message, the message will become visible to other instances when the timeout triggers. When the consumer instance is done processing the message, it deletes it from the channel, preventing it from being received by any other consumer instance in the future. 

The above guarantees are similar to the ones offered by managed services such as Amazon’s SQS and Azure Queue Storage[5] . 

## **23.2 Exactly-once processing** 

As mentioned before, a consumer instance has to delete a message from the channel once it’s done processing it so that another instance won’t read it. If the consumer instance deletes the message before processing it, there is a risk it could crash after deleting the message but before processing it, causing the message to be lost for good. On the other hand, if the consumer instance deletes the message only after processing it, there is a risk that it crashes after processing the message but before deleting it, causing the same message to be read again later on. 

Because of that, there is no such thing[6] as _exactly-once message delivery_ . So the best a consumer can do is to simulate _exactly-once message processing_ by requiring messages to be idempotent and deleting them from the channel only after they have been processed. 

> 5“Azure Queue Storage,” https://azure.microsoft.com/en-us/services/storag e/queues/ 

> 6“You Cannot Have Exactly-Once Delivery Redux,” https://bravenewgeek.c om/you-cannot-have-exactly-once-delivery-redux/ 


224 

## **23.3 Failures** 

When a consumer instance fails to process a message, the visibility timeout triggers, and the message is eventually delivered to another instance. What happens if processing a specific message consistently fails with an error, though? To guard against the message being picked up repeatedly in perpetuity, we need to limit the maximum number of times the same message can be read from the channel. 

To enforce a maximum number of retries, the broker can stamp messages with a counter that keeps track of the number of times the message has been delivered to a consumer. If the broker doesn’t support this functionality out of the box, the consumer can implement it. 

Once we have a way to count the number of times a message has been retried, we still have to decide what to do when the maximum is reached. A consumer shouldn’t delete a message without processing it, as that would cause data loss. But what it can do is remove the message from the channel after writing it to a _dead letter channel_ — a channel that buffers messages that have been retried too many times. 

This way, messages that consistently fail are not lost forever but merely put on the side so that they don’t pollute the main channel, wasting the consumer’s resources. A human can then inspect these messages to debug the failure, and once the root cause has been identified and fixed, move them back to the main channel to be reprocessed. 

## **23.4 Backlogs** 

One of the main advantages of using a message broker is that it makes the system more robust to outages. This is because the producer can continue writing messages to a channel even if the consumer is temporarily degraded or unavailable. As long as the arrival rate of messages is lower than or equal to their deletion rate, 


225 everything is great. However, when that is no longer true and the consumer can’t keep up with the producer, a backlog builds up. 

A messaging channel introduces a bimodal behavior in the system. In one mode, there is no backlog, and everything works as expected. In the other, a backlog builds up, and the system enters a degraded state. The issue with a backlog is that the longer it builds up, the more resources and/or time it will take to drain it. 

There are several reasons for backlogs, for example: 

- more producer instances come online, and/or their throughput increases, and the consumer can’t keep up with the arrival rate; 

- the consumer’s performance has degraded and messages take longer to be processed, decreasing the deletion rate; 

- the consumer fails to process a fraction of the messages, which are picked up again until they eventually end up in the dead letter channel. This wastes the consumer’s resources and delays the processing of healthy messages. 

To detect and monitor backlogs, we can measure the average time a message waits in the channel to be read for the first time. Typically, brokers attach a timestamp of when the message was first written to it. The consumer can use that timestamp to compute how long the message has been waiting in the channel by comparing it to the timestamp taken when the message was read. Although the two timestamps have been generated by two physical clocks that aren’t perfectly synchronized (see section 8.1), this measure generally provides a good warning sign of backlogs. 

## **23.5 Fault isolation** 

A single producer instance that emits “poisonous” messages that repeatedly fail to be processed can degrade the consumer and potentially create a backlog because these messages are processed multiple times before they end up in the dead-letter channel. Therefore, it’s important to find ways to deal with poisonous messages before that happens. 


226 

If messages are decorated with an identifier of the source that generated them, the consumer can treat them differently. For example, suppose messages from a specific user fail consistently. In that case, the consumer could decide to write these messages to an alternate low-priority channel and remove them from the main channel without processing them. The consumer reads from the slow channel but does so less frequently than the main channel, isolating the damage a single bad user can inflict to the others. 


## **Summary** 

Building scalable applications boils down to exploiting three orthogonal patterns: 

- breaking the application into separate services, each with its own well-defined responsibility ( _functional decomposition_ ); 

- splitting data into partitions and distributing them across nodes ( _partitioning_ ); 

- replicating functionality or data across nodes ( _replication_ ). 

We have seen plenty of applications of these patterns over the past few chapters. By now, you should have a feel for the pros and cons of each pattern. 

There is another message I subtly tried to convey: there is a small subset of managed services that you can use to build a surprisingly large number of applications. The main attraction of managed services is that someone else gets paged for them.[7] 

Depending on which cloud provider you are using, the name of the services and their APIs differ somewhat, but conceptually they serve the same use cases. You should be familiar with some way to run your application instances in the cloud (e.g., EC2) and loadbalance traffic to them (e.g., ELB). And since you want your applications to be stateless, you also need to be familiar with a file store (e.g., S3), a key-value/document store (e.g., DynamoDB), and a messaging service (e.g., SQS, Kinesis). I would argue that these technologies are reasonable enough defaults for building a large 

7As we will discuss in Part V, maintaining a service is no small feat. 


228 number of scalable applications. Once you have a scalable core, you can add optimizations, such as caching in the form of managed Redis/Memcached or CDNs. 


