## **CHAPTER 13 Integrating Event-Driven and Request-Response Microservices** 

As powerful as event-driven microservice patterns are, they cannot serve all of the business needs of an organization. Request-response endpoints provide the means to serve important data in real time, particularly when you are: 

- Collecting metrics from external sources, such as an application on a user’s cell phone or Internet of Things (IoT) devices 

- Integrating with existing request-response applications, particularly third-party ones outside of the organization 

- Serving content in real time to web and mobile device users 

- Serving dynamic requests based on real-time information, such as location, time, and weather 

Event-driven patterns still play a large role in this domain, and integrating them with request-response solutions will help you leverage the best features of both. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0229-07.png)


For the purposes of this chapter, the term _request-response services_ refers to services that communicate with each other directly, typically through a synchronous API. Two services communicating via HTTP is a prime example of request-response communication. 

## **Handling External Events** 

Due to history, precedence, familiarity, convenience, and a whole host of other reasons, external events are predominantly sent from the outside via a request-response API. While it is possible to expose an event broker and its streams to an external 


client, it is largely unreasonable to do so, as you would need to resolve a number of issues relating to access and security. And that is fine. Request-response APIs work wonderfully for these scenarios, just as they have for many decades before. There are two main types of externally generated events to consider. 

## **Autonomously Generated Events** 

The first type of events are those sent from client to server _autonomously_ by your products. These requests are usually defined as a metric or measurement from the product, such as information about what a user is doing, periodic measurements of activity, or sensor readings of some sort. Collectively known as _analytical events_ , these describe measurements and statements of fact about the operation of the product (“Example: Overloading event definitions” on page 48 shows such an event in action). An application installed on a customer’s cell phone is a good example of an external event source. Consider a media streaming service like Netflix, where analytical events can be independently sent back to measure things such as which movies you have started and how much of them you’ve watched. Any request from an external product, based on actions originating from that product, counts as an externally generated event. 

Now, you may be wondering if, say, requests to load the next 60s of the current movie count as an externally generated event. Absolutely, they do. But the real question to ask is, “Are these events important enough to the business such that they must go into their own event stream for additional processing?” In many cases the answer is no, and you would not collect and store those events in an event stream. But for those cases where the answer is yes, you can simply parse the request into an event and route it into its own event stream. 

## **Reactively Generated Events** 

The second type of externally generated event is a _reactive_ event, which is generated _in response_ to a request from one of your services. Your service composes a request, sends it to the endpoint, and awaits a response. In some cases, it’s really only important that the request is received, and the requesting client doesn’t need any other details from the response. For example, if you need to issue requests to send advertisement emails, collecting the response from the third-party service handling the requests may not be useful if turned into events. Once the request is successfully issued (HTTP 202 response), you can assume that the third-party email application will make it happen. Collecting the responses and converting them into events may not be necessary if there is no action to take from the results. 


On the other hand, your business requirements may expect significant detail from the response of the request. A prime example of this is the use of a third-party payment service, where the input event states the amount that is due to be paid by the customer. The response payload from the third-party API is _extremely_ important, as it specifies whether the payment succeeded or not, any error messages, and any additional details such as a unique, traceable number indicating the payment information. This data is important to put into an event stream, as it allows downstream accounting services to reconcile accounts payable with received payments. 

## **Handling Autonomously Generated Analytical Events** 

Analytical events may be bundled together and periodically sent in a batch or they may be sent as they occur. In either case, they will be sent to a request-response API, where they can then be routed on to the appropriate event streams. This is illustrated in Figure 13-1, where an external client application sends analytical events to an event receiver service that routes them to the correct output event stream. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0231-03.png)


_Figure 13-1. Collecting analytical events from an external source_ 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0231-05.png)


Use schemas to encode events when generating them on the client side. This ensures a high-fidelity source that reduces misinterpretation by downstream consumers, while giving producers detailed requirements for creating and populating their events. 

Schematized events are essential for consuming analytical events at scale. Schemas clarify exactly what is collected so users can make sense of the event at a later date. They also provide a mechanism for version control and evolution, and put the onus of populating, validating, and testing the event on the producer of that data (the application developers) and not the consumers (backend recipients and analysts). Ensuring that the event adheres to a schema _at creation time_ means that the receiver service no longer needs to interpret and parse the event, as could be the case with a format such as plain text. 


There are a number of restrictions that you must account for when ingesting analytical events from devices running multiple versions of code. For instance, this is a particularly common scenario for any application running on an end user’s moble device. Adding new fields to collect new data, or ceasing the collection of other event data is certainly reasonable. However, while you could force users to upgrade their applications by locking out older versions, it’s not realistic to make them update their application for every small change. Plan for multiple versions of analytical events, as shown in Figure 13-2. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0232-01.png)


_Figure 13-2. External sources generating analytical events with different versions_ 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0232-03.png)


Think of external event sources as a set of microservice instances. Each instance produces schematized events into the event stream via the event receiver service. 

Finally, it’s important to sort the incoming events into their own defined event streams based on their schemas and event definitions. Separate these events according to business purposes just as you would the event streams of any other microservice. 

## **Integrating with Third-Party Request-Response APIs** 

Event-driven microservices often need to communicate with third-party APIs via request-response protocols. The request-response pattern fits in nicely with eventdriven processing; the request and response are treated simply as a remote function call. The microservice calls the API based on the event-driven logic and awaits the reply. Upon receipt of the reply, the microservice parses it, ensures it adheres to an expected schema, and continues applying business logic as though it were any other event. A generalized example of this process is shown in Figure 13-3. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0233-00.png)


_Figure 13-3. Integrating request-response APIs into event-driven workflows_ 

The following source code illustrates the logical operation of the microservice using a blocking call: 

```
while(true){//endless processing loop
Event[]eventsToProcess=Consumer.consume("input-event-stream");
for(Eventevent:eventsToProcess){
// Apply business logic to current event to generate whatever
// request is necessary
Requestrequest=generateRequest(event,...);
// Make a request to the external endpoint. Indicate timeouts,
// retries, etc.
// This code uses a blocking call to wait for a response.
Responseresponse=
RequestService.makeBlockingRequest(request,timeout,retries,...);
// HTTP response. If success, parse + apply business logic.
if(response.code==200){
// Parse the results into an object for use in this application
<ClassType>parsedObj=parseResponseToObject(response);
// Apply any more business logic if necessary.
OutputEventoutEvent=applyBusinessLogic(parsedObj,event,...);
// Write results to the output event stream.
Producer.produce("output-stream-name",outEvent);
}else{
// Response is not 200.
// You must decide how to handle these conditions.
// Retry, fail, log, and skip, etc.
}
}
// Commit the offsets only when you are satisfied with the processing results.
consumer.commitOffsets();
}
```

**Integrating with Third-Party Request-Response APIs | 215** 


There are a number of benefits to using this pattern. For one, it allows you to mix event processing with request-response APIs while applying business logic. Second, your service can call whatever external APIs it needs, however it needs to. You can also process events in parallel by making many nonblocking requests to the endpoints. Only when each of the requests has been sent does the service wait for the results; once it obtains them, it updates the offsets and proceeds to the next event batch. Note that parallel processing is valid only for queue-style streams, since processing order is not preserved. 

There are also a number of drawbacks to this approach. As discussed in Chapter 6, making requests to an external service introduces nondeterministic elements into the workflow. Reprocessing events, even just a failed batch, may give different results than the call made during original processing. Make sure to account for this when designing the application. In cases where the request-response endpoint is controlled by a third party external to your organization, making changes to the API or the response format can cause the microservice to fail. 

Finally, consider the frequency at which you make requests to an endpoint. For instance, say that you discover a bug in your microservice and need to rewind the input stream for reprocessing. Event-driven microservices typically consume and process events as fast as they can execute the code, which could lead to a massive surge in requests going to the external API. This can cause the remote service to fail or perhaps reactively block traffic coming from your IP addresses, resulting in many failed requests and tight retry loops by your microservice. You can somewhat address this issue by using quotas (see “Quotas” on page 241) to limit consumption and processing rates, but it will also require tight throttling by the microservice handling the requests. In the case of an external API outside of your organization’s control, the throttling responsibility may lie with you and may need to be implemented in your microservice. This is particularly common when the external API is capable of providing high-volume burst service, but charges you disproportionately for the volume exceeding the baseline, as can be the case with some logging and metric services. 

## **Processing and Serving Stateful Data** 

You can also create event-driven microservices that provide a request-response endpoint for the random access of state by using the EDM principles discussed so far in this book. The microservice consumes events from input event streams, processes them, applies any business logic, and stores state either internally or externally according to application needs. The request-response API, which is often contained within the application (more on this later in the chapter), provides access to these underlying state stores. This approach can be broken down into two major sections: serving state from internal state stores, and serving state from external state stores. 


## **Serving Real-Time Requests with Internal State Stores** 

Microservices can serve the results sourced from their internal state, as demonstrated in Figure 13-4. The client’s request is delivered to a load balancer that routes the request on to one of the underlying microservice instances. In this case, there is only one microservice instance, and since it is materializing all of the state data for this application, all of its application data is available within the instance. This state is materialized via the consumption of the two input event streams (A and B), with the changelog backed up to the event broker. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0235-02.png)


_Figure 13-4. Overview of an EDM with a REST API serving content to a client_ 

Now, it is quite common that multiple microservice instances are required to handle the load and that internal state may be split up between instances. When using multiple microservice instances, you must route requests for state to the correct instance hosting that data, as all internal state is sharded according to key, and a keyed value can only ever be assigned to one partition. Figure 13-5 shows a client making a request that is then forwarded to the correct instance containing the necessary state. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0236-00.png)


_Figure 13-5. Using partition assignments to determine where materialized state for a given key is located_ 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0236-02.png)


Hot replicas of state stores (see “Using hot replicas” on page 116) may also be used to serve direct-call requests, should your framework support their use. Keep in mind that hot-replica data may be stale in proportion to the replication lag from the primary state store. 

There are two properties of event-driven processing that you can rely on to determine which instance contains a specific key/value pair: 

- A key can only be mapped to a single partition (see “Repartitioning Event Streams” on page 81) 

- A partition can only be assigned to a single consumer instance (see “Consuming as an event stream” on page 32) 

A microservice instance within a consumer group knows its partition assignments and those of its peers. All events of a given key must reside inside a single partition for an event stream to be materialized. By applying the partitioner logic to the key of the request, the microservice can generate the partition ID assignment of that key. It can then cross-reference that partition ID with the partition assignments of the 


consumer group to determine which instance contains the materialized data associated with the key (if the data for that key exists at all). 

For example, Figure 13-6 illustrates using the properties of the partitioner assignment to route a REST GET request. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0237-02.png)


_Figure 13-6. Workflow illustrating the routing of a request to the correct instance_ 

The partitioner indicates that the key is in P1, which is assigned to instance 1. If a new instance is added and the partitions are rebalanced, subsequent routing may need to go to a different instance, which is why the consumer group assignments are instrumental in determining the location of the partition assignments. 

One drawback of serving sharded internal state is that the larger the microservice instance count, the more spread out the state between individual instances. This reduces the odds of a request hitting the correct instance on the first try, without needing a redirect. If the load balancer is simply operating on a round-robin distribution pattern and assuming an even distribution of keys, then the chance of a request being a hit on the first try can be expressed as: 

_success‐rate_ = 1/ _number of instances_ 

In fact, for a very large number of instances, almost all requests will result in a miss followed by a redirect, increasing the latency of the response and load on the application (as each request will likely require up to two network calls to process it, instead of one). Luckily, a smart load balancer can perform the routing logic _before_ sending the initial request to the microservices, as demonstrated in Figure 13-7. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0238-00.png)


_Figure 13-7. Using the load balancer to correctly forward requests based on consumer group ownership and partitioner logic_ 

The smart load balancer applies the partitioner logic to obtain the partition ID, compares it against its internal table of consumer group assignments, and then forwards the request accordingly. Partition assignments will need to be inferred from the internal repartition streams or the changelog streams for a given state store. This approach _does_ entangle the logic of your application with the load balancer, such that renaming state stores or changing the topology will cause the forwarding to fail. It’s best if any smart load balancers are part of the single deployable and testing process of your microservice so that you can catch these errors prior to production deployment. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0238-03.png)


Using a smart load balancer is just a best effort to reduce latency. Due to race conditions and dynamic rebalancing of internal state stores, each microservice instance must still be able to redirect incorrectly forwarded requests. 

## **Serving Real-Time Requests with External State Stores** 

Serving from an external state store has two advantages over the internal state store approach. For one, all state is available to each instance, meaning that the request does not need to be forwarded to the microservice instance hosting the data as per the internal storage model. Second, consumer group rebalances also don’t require the microservice to rematerialize the internal state in the new instance, since again, all state is maintained external to the instance. This allows the microservice to provide seamless scaling and zero-downtime options that can be difficult to provide with internal state stores. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0239-00.png)


Ensure that state is accessed via the request-response API of the microservice and _not_ through a direct coupling with the state store. Failure to do so introduces a shared data store, resulting in tight coupling between services, and makes changes difficult and risky. 

## **Serving requests via the materializing event-driven microservice** 

Each microservice instance consumes and processes events from its input event streams and materializes the data to the external state store. Each instance also provides the request-response API for serving the materialized data back to the requesting client. This pattern, shown in Figure 13-8, mirrors that of serving state from an internal state store. Note that each microservice instance can serve the entire domain of keyed data from the state store and thus can handle any request passed to it. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0239-04.png)


_Figure 13-8. An all-in-one microservice serving from external state store; note that either instance could serve the request_ 

Both input event stream processing and request-response serving capacity scale by increasing or decreasing the instance count, as with internal state store microservices. The number of instances can be scaled beyond the count of the event stream partitions. These extra instances won’t be assigned partitions to process, but they can still process external requests from the request-response API. Furthermore, they exist as standby instances ready to be assigned a partition in the case that one of the other instances is lost. 

One of the main advantages of this pattern is that it doesn’t require much in the way of deployment coordination. This is a single all-in-one microservice that can continue to serve state from the external state store regardless of the current instance count. 


## **Serving requests via a separate microservice** 

In this pattern, the request-response API is completely separate from the executable of the event-driven microservice that materializes the state to the external state store. The request-response API remains independent from the event processor, though both have the same bounded context and deployment patterns. This pattern is exemplified in Figure 13-9. You can see how the requests are served via a single REST API endpoint, while events are processed using two event processing instances. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0240-02.png)


_Figure 13-9. A microservice composed of separate executables—one for serving requests, the other for processing events_ 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0240-04.png)


While this pattern has two microservices operating on a single data store, there’s still just a single bounded context. These two microservices are treated as a single _composite service_ . They reside within the same code repository and are tested, built, and deployed together. 

One of the main advantages of this model is that because the request-response API is fully independent of the event processor, you can choose the implementation languages and scaling needs independently. For instance, you could use a lightweight stream framework to populate the materialized state, but use a language and associated libraries that are already commonly used in your organization to deliver a consistent web experience to your customers. This approach can give you the best of both worlds, though it does come with the additional overhead of managing multiple components in your codebase. 

A second major advantage of this pattern is that it isolates any failures in the event processing logic from the request-response handling application. This eliminates the chance that any bugs or data-driven issues in the event processing code could bring down the request-response handling instance, thereby reducing downtime (note that the state will become stale). 


The main disadvantages of this pattern are complexity and risk. Coordinating changes between two otherwise independent applications is risky, as altering the data structures, topologies, and request patterns can necessitate dependent changes in both services. Additionally, coupling services invalidates some of the EDM principles, such as not sharing state via common data stores and using singular deployables for a bounded context. 

All that being said, this is still a useful pattern for serving data in real time, and it is often successfully used in production. Careful management of deployments and comprehensive integration testing is key for ensuring success. 

## **Handling Requests Within an Event-Driven Workflow** 

Request-response APIs form the basis of communications between many systems, and as a result, you need to ensure that your applications can handle these data inputs in a way that integrates with event-driven microservice principles. One way to handle requests is just as you would with any non-event-driven system: perform the requested operation immediately and return the response to the client. Alternately, you can also _convert_ the request into an event, inject it into its own event stream, and process it just as any other event in the system. Finally, the microservice may also perform a mix of these operations, by turning only requests that are important to the business into events (that can be shared outside the bounded context), while handling other requests synchronously. Figure 13-10 illustrates this concept, which will be expanded on shortly in “Example: Newspaper publishing workflow (approval pattern)” on page 225. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0241-04.png)


_Figure 13-10. Handling requests directly versus turning them into events first_ 

The leftmost portion of the preceding figure shows a traditional object creation operation being performed, with the results written directly to the database. Alternately, the rightmost portion shows an event-first solution, where the request is parsed into 

**Handling Requests Within an Event-Driven Workflow | 223** 


an event and published to a corresponding event stream, prior to the event-driven workflow consuming it, applying business logic, and storing it in the database. 

The major benefit of first writing to the event stream is that it provides a durable record of the event, and allows any service to materialize off of that data. The biggest tradeoff, however, is the latency incurred, and that the service must wait for the result to be materialized into the data store to be used (eventually-consistent read-afterwrite). One way to mitigate this delay is to keep the value in memory after successfully writing it to the object stream, allowing you to use it in application-side operations. This will not, however, work for operations that require the data to be present in the database (e.g., `join` s), as the event must be materialized first. 

## **Processing Events for User Interfaces** 

A user interface (UI) is the means by which people interact with the bounded context of a service. Request-response frameworks are exceedingly common for a UI application, with many options and languages available to serve users’ needs. Integrating these frameworks into the event-driven domain is important for unlocking their intrinsic value. 

There are a number of concerns to address when processing user input as an event stream. Application designs that process requests as events must incorporate an _asynchronous UI_ . You must also ensure that the application behavior manages user expectations. For example, in a synchronous system, a user that clicks a button may expect to receive a failure or success response in very short order, perhaps in 100 ms or less. In an asynchronous event processing system, it may take the processing service longer than 100 ms to process and handle the response, especially if the event stream has a large number of records to process. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0242-05.png)


Research and implement best practices for asynchronous UIs when handling user input as events. Proper UI design prepares the user to expect asynchronous results. 

There are certain asynchronous UI techniques you can use to help manage your users’ expectations. For example, you can update the UI to indicate that their request has been sent, while simultaneously discouraging them from performing any more actions until it has completed. Airline booking and automobile rental websites often display a “please wait” message with a spinning wheel symbol, blanking out the rest of the web page from user input. This informs users that the backend service is processing the event and that they can’t do anything else until it has completed. 

Another factor to consider is that the microservice may need to continually process incoming nonuser events while awaiting further user input. You must decide when 


the service’s event processing has progressed sufficiently for an update to be pushed to the UI. In fact, you must also decide when the _initial_ processing of events from the beginning of time has caught up to the present, despite the ongoing updates that most EDM services must handle. 

There are no hard-and-fast rules dictating when you must update your interface. The business rules of the bounded context can certainly guide you, predominantly around the impact of users making decisions based on the current state. Answering the following questions may help you decide how and when to update your UI: 

- What is the impact of the user making a decision based on stale state? 

- What is the performance/experience impact of pushing a UI update? 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0243-04.png)


Intermittent network failures causing request retries can introduce duplicate events. Ensure that your consumers can handle duplicates idempotently, as covered in “Generating duplicate events” on page 129. 

This next example demonstrates some of the benefits of converting requests directly to events prior to processing. 

## **Example: Newspaper publishing workflow (approval pattern)** 

A newspaper publisher has an application that manages the layout of its publications. Each publication relies upon customizable templates to determine how and where articles and advertisements are placed. 

A graphical user interface (GUI) allows the newspaper designers to arrange and place articles according to the publisher’s business logic. The hottest news is placed on the front pages, with less important articles placed further in. Advertisements are also positioned according to their own specific rules, usually dependent on size, content, budget, and placement agreements. For example, some advertisers may not want their ads placed next to specific types of stories (e.g., a children’s toy company would want to avoid having its ad placed alongside a story about a kidnapping). 

The newspaper designer is responsible for placing the articles and advertisements according to the layout template. The newspaper editor is responsible for ensuring that the newspaper is cohesive, that the articles are ordered by category and projected importance to the reader, and that the advertisements are placed according to the contracts. The newspaper editor must approve the work performed by the designer before it can be published, or reject the work in the case that a re-organization is required. Figure 13-11 illustrates this workflow. 

**Handling Requests Within an Event-Driven Workflow | 225** 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0244-00.png)


_Figure 13-11. Workflow for populating a newspaper, with gating based on approval by editor and advertiser_ 

Both the editor and the advertiser can reject a proposed newspaper, though the advertiser will get the chance to do so only if the editor has already approved the layout. Furthermore, the newspaper is interested only in obtaining approval from the most important advertisers, those whose ad spend is a significant source of revenue. 

The design and the approval of the newspaper are two separate bounded contexts, each concerned with its own business functionality. This can be mirrored by two microservices, as shown in Figure 13-12. For simplicity’s sake, the figure omits accounts, account management, authentication, and login details. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0244-04.png)


_Figure 13-12. Newspaper design and approval workflow as microservices_ 

There is a fair bit to unpack in this example, so let’s start with the newspaper populator microservice. This service consumes layout templates, advertisements, and articles streams into a relational database. Here, the employee responsible for layout performs their tasks, and when the newspaper is ready for approval, they compile the populated newspaper into a PDF, save it to an external store, and produce it to the populated newspaper event stream. The format for the populated newspaper event is as follows: 


```
//Populated newspaper event
```

```
Key: String pn_key        //Populated newspaper key
Value: {
  String pdf_uri          //Location of the stored PDF
  int version             //Version of the populated newspaper
  Pages[] page_metadata   //Metadata about what is on each page
    - int page_number
    - Enum content        //Ad, article
    - String id           //ID of the ad or article
}
```


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0245-02.png)


Because the PDF may be too large to store in an event, it can be stored in an external file store, with access provided via a universal resource identifier, or URI (see “Minimize the Size of Events” on page 51). 

You may have noticed that this microservice does _not_ translate the human interactions of the newspaper populator GUI into events—why is this? Despite “human interactions as events” being one of the main themes of this example, it is not necessary to convert _all_ human interaction into events. This particular bounded context is really only concerned with producing the final populated newspaper event, but it isn’t particularly important _how_ it came to be. This encapsulation of responsibility allows you to leverage a monolithic framework with synchronous GUI patterns for building this microservice, and to use patterns and software technologies that you or your developers may already be familiar with. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0245-05.png)


The populated newspaper stream might get out of sync with the state within the newspaper populator microservice. See “Data Liberation Patterns” on page 57 for details on atomic production from a monolith, particularly using the outbox table pattern or changedata capture logs. 

Approvals are handled by a separate microservice, where the populated newspaper event is loaded by the editor to view and approve. The editor can mark up a copy of the PDF as necessary, add comments, and provide tentative approval to move it on to the next step: advertiser approval. The editor may also reject it at any point of the workflow, before, during, or after obtaining advertiser review. The event structure is as follows: 

```
//Editor approval event
```

```
Key: String pn_key               //Populated newspaper key
Value: {
  String marked_up_pdf_uri       //Optional URI of the marked-up PDF
  int version                    //Version of the populated newspaper
```

**Handling Requests Within an Event-Driven Workflow | 227** 


```
  Enum status                    //awaiting_approval, approved, rejected
  String editor_id
  String editor_comments
  RejectedAdvertisements[] rejectedAds //Optional, if rejected
```

```
    - int page_number
```

```
    - String advertisement_id
```

- `String advertiser_id` 

- `String advertiser_comments }` 

Advertisers are provided with a UI for approving their advertisement size and placement. This service is responsible for determining _which_ advertisements require approval and which do not, and for cutting up the PDF into appropriate pieces for the advertiser to view. It is important to not leak information about news stories or competitors’ advertisements. Approval events are written to an advertiser’s approval stream, similar to that of the editor: 

## `//Advertiser approval event` 

```
Key: String pn_key          //Populated newspaper key
Value: {
  String advertiser_pdf_uri //The PDF piece shown to the advertiser
  int version               //Version of the populated newspaper
  int page_number
  boolean approved          //Approved or not
  String advertisement_id
  String advertiser_id      //ID of the approver
  String advertiser_comments
}
```

You may have noticed that the advertiser approvals are keyed on `pn_key` and that there will be multiple advertiser events with this same key per newspaper. In this case the advertiser approvals are being treated as _events_ and not _entities_ , and it is the _aggregate_ of these events that determines the complete approval by an advertiser for the newspaper. Keep in mind that each advertiser logs into their GUI and approves their ads separately, and it’s not until they have all replied (or perhaps, failed to reply in time) that the process can move on to the final approval. If you take a look at the editor approval event definition, you can see that the aggregation of rejected events is represented as an array of `RejectedAdvertisements` objects. 

One benefit of having populated newspaper, editor approval, and advertiser approval as events is that together they form the canonical narrative of newspapers, rejections, comments, and approvals. You can audit this narrative at any point in time to see the history of submissions and approvals, and pinpoint where things may have gone wrong. Another benefit is that by writing directly to events, the approval microservice can use a pure stream processing library, like Apache Kafka or Samza, to materialize the state directly from the event stream whenever the application starts up. There is no need to create an external state store for managing this data. 


## **Separating the editor and advertiser approval services** 

Business requirements demand that the editor approval service and advertiser approval service be separated. Each of these serves a related, though separate, business context. In particular, the advertiser components of the currently combined service are responsible for: 

- Determining which advertisers to ask for approval 

- Slicing up the PDF into viewable chunks 

- Managing advertiser-facing components, controls, and branding 

- Handling public-facing exposure to the wider internet, particularly around security practices and software patches 

The editor components of the combined service, on the other hand, do not need to address public-facing concerns such as image, branding, and security. It is primarily concerned with: 

- Approving overall layout, design, and flow 

- Assessing the _summary_ of retailer responses (not each one individually) 

- Providing suggestions to the newspaper designer on how to accommodate advertiser rejections 

A mock-up of the new microservice layout is shown in Figure 13-13. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0247-11.png)


_Figure 13-13. Independent advertiser and editor approval services_ 

**Handling Requests Within an Event-Driven Workflow | 229** 


There are _two_ new event streams to consider. The first is in step 2, the editorapproved p.n. stream. The format of this stream is identical to that of the populated newspaper stream, but this event is produced only after the editor is satisfied with the overall newspaper and releases it for advertiser approval. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0248-01.png)


The populated newspaper stream is the single source of truth for all _candidate_ newspapers. The editor-approved p.n. stream is the single source of truth _only for newspapers that have been approved for advertiser review_ , having been filtered by the editor system’s logic. The two event streams do not have the same business meaning. 

A major advantage of this design is that _all_ editor gating logic stays completely within the editor approval service. Note that updates to the populated newspaper stream are _not_ automatically forwarded on, but rely on the editor releasing them for approval. Multiple versions of the same newspaper ( `pn_key` ) are contained entirely within the editor service. This arrangement lets the editor control which versions are sent on for approval, while gating any further revisions until they are satisfied with the initial advertiser feedback. 

The second new event stream is in step 3, the ad-approvals summary stream. It contains the summaries of the results from the advertiser approval service, designed to provide both a historical record and the current status of each of the responses for a given newspaper. Keep in mind that as a separate service, the editor approval service has no way to know which advertisers have been sent instructions to approve their advertisements. That information is strictly the domain of the advertising approval system, though it can communicate a summary of the results to the editor. The format of the ad-approval summary event is as follows: 

```
//Ad-approval summary event
```

```
Key: String pn_key
Value: {
  int version              //Version of the populated newspaper
  AdApprovalStatus[] ad_app_status
    - Enum status          //Waiting, Approved, Rejected, Timedout
    - int page_number
```

- `String advertisement_id` 

- `String advertiser_id` 

- `String advertiser_comments }` 

This ad-approval summary event definition demonstrates the encapsulation of advertiser approval state into the advertiser approval service. The editor can make decisions on the approval of the newspaper based on the statuses of the ad-approval summary event, without having to manage or handle any of the work of obtaining those results. 


## **Micro-Frontends in Request-Response Applications** 

Frontend and backend services coordinate in three primary ways to bring business value to users. Monolithic backends are common in many organizations of any size. Microservice backends have become more popular with the growing adoption of microservices, both synchronous and event-driven. In both of these first two approaches, the frontend and backend services are owned and operated by separate teams, such that the end-to-end business functionality crosses team boundaries. In contrast, a microfrontends approach aligns implementations completely on business concerns, from backend to frontend. These three approaches are illustrated in Figure 13-14. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0249-02.png)


_Figure 13-14. Three main approaches to organizing products and teams for customerfacing content_ 

The monolithic backend approach is one that most software developers are familiar with, at least to some extent. In many cases, a dedicated backend team, usually composed of many subteams for very large monoliths, performs most of the work on the monolith. Head count increases as the monolith grows. 

The frontend team is completely separate from the backend, and they communicate via a request-response API to obtain the necessary data for rendering the customer’s UI. A product implemented in this architecture has to coordinate efforts between teams and across technical implementations, making it potentially one of the most expensive ways of delivering functionality. 

The microservice backend approach is one where many teams migrating to microservices eventually end up, and for better or worse, it is where many of them stay. The major advantage of this approach is that the backend is now composed of independent, _product-focused_ microservices, with each microservice (or set of productsupporting microservices) independently owned by a single team. Each microservice 

**Micro-Frontends in Request-Response Applications | 231** 


materializes the necessary data, performs its business logic, and exposes any necessary request-response APIs and event streams up to the aggregation layer. 

A major downside of the microservice backend approach is that it still depends heavily on an aggregation layer, where numerous problems can pop up. Business logic can creep into this layer due to attempts to resolve product boundary issues, or to achieve “quick wins” by merging features of otherwise separate products. This layer often suffers from the tragedy of the commons, whereby everyone relies on it but no one is responsible for it. While this can be resolved to some extent by a strict stewardship model, accumulations of minor, seemingly innocent changes can still let an inappropriate amount of business logic leak through. 

The third approach, the microfrontend, splits up the monolithic frontend into a series of independent components, each backed by supporting backend microservices. 

## **The Benefits of Microfrontends** 

Microfrontend patterns match up very well with event-driven microservice backends, and inherit many of their advantages, such as modularity; separation of business concerns; autonomous teams; and deployment, language, and code-base independence. 

Let’s look at some of the other notable benefits of microfrontends. 

## **Composition-Based Microservices** 

Microfrontends are a compositional pattern, meaning you can add services as needed to an existing UI. Notably, microfrontends pair extremely well with event-driven backends, which are also intrinsically composition-based. Event streams enable the microservice to pull in the events and entities needed to support the backend bounded context. The backend service can construct the necessary state and apply business logic specifically for the business needs of the product provided by the microfrontend. The state store implementation can be selected to specifically suit the requirements of the service. This form of composition provides tremendous flexibility in how frontend services can be built, as you’ll see in “Example: Experience Search and Review Application” on page 234. 

## **Easy Alignment to Business Requirements** 

By aligning microfrontends strictly on business bounded contexts, just as you’d do with other microservices operating in the backend, you can trace specific business requirements directly to their implementations. This way, you can easily inject experimental products into an application without adversely affecting the codebase of existing core services. And should their performance or user uptake not be as expected, you can just as easily remove them. This alignment and isolation ensures that product requirements from various workflows do not bleed into one another. 


## **Drawbacks of Microfrontends** 

While microfrontends enable separation of business concerns, you have to account for features that you may take for granted in a monolithic frontend, such as consistent UI elements and total control over each element’s layout. Microfrontends also inherit some of the issues common to all microservices, such as potential for duplicated code and the operational concerns of managing and deploying microservices. This section covers a few microfrontend-specific considerations. 

## **Potentially Inconsistent UI Elements and Styling** 

It’s important that the applications’ visual style remains consistent, and this can be challenging when a frontend experience is composed of many independent microfrontends. Each microfrontend is another potential point of failure—that is, where the UI design might be inconsistent with the desired user experience. One method to remedy this is to provide a strong style guide, in conjunction with a lean library of common UI elements to be used in each microfrontend. 

The downside to this approach is that it requires closely maintaining ownership of both the style guide and the elements. Adding new elements and modifying existing ones can be a bit difficult to coordinate across multiple teams using the element library in their products. Accommodating these assets using a stewardship model, similar to that used in many popular open source projects, can help ensure that changes are done in a measured and deliberate way. This requires participation and dialogue between the asset users and, as a result, incurs an overhead cost. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0251-05.png)


Ensure common UI element libraries are free of any boundedcontext-specific business logic. Keep all business logic encapsulated within its own proper bounded context. 

Finally, making changes to the common UI elements of the application may require that each microfrontend be recompiled and redeployed. This can be operationally expensive, as each microfrontend team will need to update its application, test to ensure that the UI adheres to the new requirements, and verify that it integrates as expected with the UI layer that stitches it together (more on this next). This expense is somewhat mitigated by the infrequency of sweeping UI changes. 

## **Varying Microfrontend Performance** 

Microfrontends, as pieces of a composite framework, can be problematic at times. These separate frontends may load at different rates, or worse, may not load anything at all during a failure. You must ensure that the composite frontend can handle these 


scenarios gracefully and still provide a consistent experience for the parts of it that are still working. For example, you may want to use spinning “loading” signs for elements that are still awaiting results from slow microfrontends. Stitching these microfrontends together is an exercise in proper UI design, but the deeper details and nuances of this process are beyond the scope of this book. 

## **Example: Experience Search and Review Application** 

“An experience is something you’ll never forget!” claim the makers of the application, which connects vacationers with local guides, attractions, entertainment, and culinary delights. Users can search for local experiences, obtain details and contact information, and leave reviews. 

The first version of this application has a single service that materializes both the experience entities and customer reviews into a single endpoint. Users can input their city name to see a list of available experiences in their area. Once they select an option, the experience information along with any associated reviews are displayed, as in the simple mockup in Figure 13-15. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0252-04.png)


_Figure 13-15. Experiences search and review application, GUI mockup version 1 with monolithic frontend_ 

In the first version of the application, data is stored in a basic key/value state store that offers only limited searching capabilities. Searching based on the user’s geolocation is not yet available, though it is something your users have been requesting. Additionally, it would be a good idea for version 2 to split off reviews into their own microservice, as they have sufficiently distinct business responsibilities to form their own bounded context. Finally, you should create the product microfrontend to stitch these two products together and act as the aggregation layer for each business service. Each of these three microfrontends may be owned and managed by their own team, or the same team, though the separation of concerns allows for scaling ownership just 


as in backend microservices. A new mockup of the GUI showing the separated frontend responsibilities is shown in Figure 13-16. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0253-01.png)


_Figure 13-16. Experiences search and review application, GUI mockup version 2 with microfrontends_ 

Now the product boundary encapsulates both the search and review microfrontends and contains all the logic necessary to stitch these two services together. It does not, however, contain any business logic pertaining to these services. This updated UI also illustrates how the microfrontend’s responsibilities have changed, as it must now support geolocation search functionality. The user’s address is transposed into lat-lon coordinates, which can be used to compute the distance to nearby experiences. Meanwhile, the review microfrontend’s responsibilities remain the same, but it is freed of its coupling to the search service. Figure 13-17 shows how this migration into microfrontends could look. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0254-00.png)


_Figure 13-17. The flexibility of microfrontends paired with backend event-driven microservices_ 

There are a few notable points about this figure. First, as discussed earlier in this chapter, the reviews are being published _first_ as events to the review event stream, and _then_ subsequently ingested back into the data store. This is true for both versions of the service, and it illustrates the importance of keeping core business data external to the implementation. In this way you can easily break out the review service into its own microservice, without performing unnecessary and error-prone operations with data synchronization. 

If the reviews were kept internal to version 1’s data store, you would instead have to look into liberating them for version 2’s use (Chapter 4) and then come up with a migration plan for its long-term storage in an event stream. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0254-04.png)


The ability to materialize and consume any stream of business events, however the service needs them, is what makes event-driven microservice backends pair so effectively with microfrontends. 

Second, the review service has been broken out into its own microservice, fully separating its bounded context and implementation from those of search. Third, the search service has replaced its state store with one capable of both plain-text and geolocation search functionality. This change supports the business requirements of the search service, which can now be addressed independently of the review service business requirements. This solution illustrates how composition-based backends 


give development teams the flexibility to use the best tools to support the microfrontend product. 

In this new version, the search microservice consumes events from the user profile entity stream to personalize search results. While version 1 of the backend service could certainly also consume and use this data, the increased granularity of the services in version 2 clarifies which business functions are using the user data. An observer can tell which streams are consumed and used for each part of the frontend just by looking at the input streams for the bounded contexts. Conversely, in version 1, without digging into the code, an observer would have no idea whether it’s the search or the review portion using the user events. 

Finally, note that all necessary data for both the old and new versions are sourced from the exact same event streams. Because these event streams are the single source of truth you can change the application backends without having to worry about maintaining a specific state store implementation or about migrating data. This is in stark contrast to a monolithic backend, where the database also plays the role of data communication layer and cannot be easily swapped out. The combination of an event-driven backend paired with a microfrontend is limited only by the granularity and detail of the available event data. 

## **Summary** 

This chapter has covered the integration of event-driven microservices with requestresponse APIs. External systems predominantly communicate via request-response APIs, be they human or machine driven, and their requests and responses may have to be converted into events. Machine input can be schematized ahead of time, to emit events that can be collected server-side via the request-response API. Third-party APIs typically require parsing and wrapping the responses into their own event definition and tend to be more brittle with change. 

Human interactions can also be converted into events, to be processed asynchronously by the consuming event-driven microservice. This requires an integrated design, where the user interface cues the user that their request is being handled asynchronously. By treating all essential user inputs as streams of events, the implementation of the bounded context is effectively decoupled from the user data. This allows for significant flexibility in the architectural evolution of the design and permits components to be altered without undue hardship. 

Finally, microfrontends provide an architecture for full-stack development of products based on event-driven microservices. Backend event-driven microservices are compositional by nature, drawing together events and entities to apply business logic. This pattern is extended to the frontend, where user experiences need not be one large monolithic application, but instead can compromise a number of purpose-built 


microfrontends. Each microfrontend serves its particular business logic and functionality, with an overall compositional layer to stitch the various applications together. This architectural style mirrors the autonomy and deployment patterns of the backend microservices, providing full product alignment and allowing flexible frontend options for experimentation, segmentation, and delivery of custom user experiences. 


