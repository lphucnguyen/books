## **CHAPTER 16** 

## **Deploying Event-Driven Microservices** 

Deploying event-driven microservices can be challenging. As the number of microservices within an organization increases, so does the importance of having standardized deployment processes in place. An organization managing only a few dozen services can get away with a few custom deployment processes, but any organization seriously invested in microservices, event-driven or otherwise, must invest in standardization and streamlining its deployment processes. 

## **Principles of Microservice Deployment** 

There are a number of principles that drive deployment processes: 

## _Give teams deployment autonomy_ 

Teams should control their own testing and deployment process and have the autonomy to deploy their microservices at their discretion. 

## _Implement a standardized deployment process_ 

The deployment process should be consistent between services. A new microservice should be created with a deployment process already available to it. This is commonly accomplished with a _continuous integration_ framework, as is discussed shortly. 

## _Provide necessary supportive tooling_ 

Deployments may require teams to reset consumer group offsets, purge state stores, check and update schema evolution, and delete internal event streams. Supportive tooling provides these functions to enable further automation of deployment and support team autonomy. 


## _Consider event stream reprocessing impacts_ 

Reconsuming input event streams can be time-consuming, leading to stale results for downstream consumers. Additionally, this microservice may subsequently generate a large volume of output events, causing another high load for downstream consumers. Very large event streams and those with large amounts of consumers may see nontrivial surges in processing power requirements. You must also consider side effects, particularly those that can be disruptive to customers (e.g., resending multiple years’ worth of promotional emails). 

## _Adhere to service-level agreements (SLAs)_ 

Deployments may be disruptive to other services. For instance, rebuilding state stores can result in a significant amount of downtime, while reprocessing input event streams may generate a significant number of events. Ensure that all SLAs are honored during the deployment process. 

## _Minimize dependent service changes_ 

Deployments may require that other services change their APIs or data models, such as when interacting with a REST API or introducing a domain schema change. These changes should be minimized whenever possible, as they violate the other team’s autonomy for deploying their services only when required by shifting business requirements. 

## _Negotiate breaking changes with downstream consumers_ 

Breaking schema changes may be inevitable in some circumstances, requiring the creation of new event streams and a renegotiation of the data contract with downstream consumers. Ensure that these discussions happen before any deployment and that a migration plan for consumers is in place. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0292-08.png)


Microservices should be independently deployable, and it is an anti-pattern if they are not. If a particular microservice deployment regularly requires other microservices to synchronize their deployments, it is an indicator that their bounded contexts are ill-defined and should be reviewed. 

## **Architectural Components of Microservice Deployment** 

There are several major components of the microservice deployment architecture, each of which plays a pivotal role. This architecture can be roughly broken down into two main components: the system used to build and deploy the code, and the compute resources used by the microservices. 


## **Continuous Integration, Delivery, and Deployment Systems** 

Continuous integration, delivery, and deployment systems allow for microservices to be built, tested, and deployed as code changes are committed to the repository. This is part of the microservice tax that you must pay to successfully manage and deploy microservices at scale. These systems allow microservice owners to decide when to deploy their microservices, which is essential for scaling up the number of microservices used in an organization. 

_Continuous integration_ (CI) is the practice of automating the integration of code changes from multiple contributors into a single software project. Changes from code are integrated at the discretion of the team managing the microservice, with the intent of reducing the amount of time between when code changes are made to when they are deployed in production. CI frameworks allow for processes to be executed automatically when code is merged into the main branch, including build operations, unit testing, and integration testing operations. Other CI processes may include validating code style and performing schema evolution validation. A ready-to-deploy container or virtual machine is the final output of the CI pipeline. 

_Continuous delivery_ is the practice of keeping your codebase deployable. Microservices that adhere to continuous delivery principles use a CI pipeline to validate that the build is ready for deployment. The deployment itself is _not_ automated, however, and requires some manual intervention on the service owner’s part. 

_Continuous deployment_ is the automated deployment of the build. In an end-to-end continuous deployment, a committed code change propagates through the CI pipeline, reaches a deliverable state, and is automatically deployed to production according to the deployment configuration. This contributes to a tight development loop with a short turnaround time, as committed changes quickly enter production. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0293-05.png)


_Figure 16-1. A CI pipeline showcasing the difference between continuous delivery and continuous deployment_ 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0293-07.png)


Continuous deployment is difficult to do in practice. Stateful services are particularly challenging, as deployments may require rebuilding state stores and reprocessing event streams, which are especially disruptive to dependent services. 


## **Container Management Systems and Commodity Hardware** 

The container management system (CMS) provides the means of managing, deploying, and controlling the resource use of containerized applications (see “Managing Containers and Virtual Machines” on page 35). The container built during the CI process is deposited into a repository, where it awaits deployment instructions from the CMS. Integration between your CI pipeline and the CMS is essential to a streamlined deployment process and is usually provided by all of the leading CMS providers, as discussed in Chapter 2. 

Commodity hardware is typically used for the deployment of event-driven microservices, as it is inexpensive, performs reliably, and enables horizontal scaling of services. You can add and remove hardware to and from the resource pools as required, while recovery from failed instances requires only that you redeploy the failed microservice instances to the new hardware. Though your microservice implementations may vary, many event-driven microservices do not require any specialized hardware to operate. For those that do, you can allocate specialized resources into their own independent pools, such that the associated microservices can be deployed accordingly. Examples might include memory-intensive computing instances for caching purporses, or processor-intensive computing instances for applications demanding significant processing power. 

## **The Basic Full-Stop Deployment Pattern** 

The basic full-stop deployment pattern is the basis of all other patterns, and this section outlines the steps involved (illustrated in Figure 16-1). You may have additional steps in your pipeline depending on the specific requirements of your domain, but I am keeping these steps lean for space purposes. Use your own judgment and domain knowledge to insert any steps specific to your use cases. 

1. **Commit code.** Merge the latest code into the master branch, kicking off the CI pipeline. The specifics depend upon your repository and CI pipeline, but you typically do this using commit hooks that can execute arbitrary logic when code is committed to the repository. 

2. **Execute automated unit and integration tests.** This step is part of the CI pipeline to validate that the committed code passes all the unit and integration tests necessary for merging. Integration tests may require that you spin up transient environments and populate them with data to perform more complex tests. This requires integration of the CI pipeline with the tooling described in “Local Integration Testing” on page 259 so that each service can bring up its own integration testing environment. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0295-00.png)


It’s best to have independent integration testing environments for any sort of automated integration, as it allows you to run tests for a given service in isolation from other services. This significantly reduces multitenancy issues that arise from having a long-running and shared integration test environment. 

3. **Run predeployment validation tests.** This step ensures that your microservice will deploy properly by validating common issues before release. Validations may include: 

## _Event stream validation_ 

- Validate that input event streams exist, output streams exist (or can be created, if automatic creation is enabled), and your microservice has the proper read/write permissions to access them. 

## _Schema validation_ 

      - Validate that both the input and output schemas follow schema evolution rules. A simple way to do this is by convention, with your input and output schemas contained within a specific directory structure, along with a map of schemas to event streams. This step of the pipeline can simply ingest the schemas and run the comparisons for you, detecting any incompatibilities. 

4. **Deployment.** The currently deployed microservice needs to be halted before the new one can be deployed. This process consists of two major steps: 

   - a. **Stop instances and perform any clean-up before deploying.** Stop the microservice instances. Perform any necessary state store resets and/or consumer group resets, and delete any internal streams. If rebuilding state in the case deployment failure is expensive, you may instead want to leave your state, consumer group, and internal topics alone, and instead deploy as a new service. This will enable you to roll back quickly in the case of a failure. 

   - b. **Deploy.** Perform the actual deployment. Deploy the containerized code and start the required number of microservice instances. Wait for them to boot up and signal that they are ready before moving on to the next step. In the case of a failure, abandon this step and deploy the previous working version of the code. 

5. **Run post-deployment validation tests.** Validate that the microservice is operating normally, that consumer lag is returning to normal, that there are no logging errors, and that endpoints are working as expected. 

**The Basic Full-Stop Deployment Pattern | 277** 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0296-00.png)


Consider the impacts to all dependent services, including SLAs, downtime, stream processing catch-up time, output event load, new event streams, and breaking schema changes. Communicate with dependent service owners to ensure that the impacts are acceptable. 

## **The Rolling Update Pattern** 

The rolling update pattern can be used to keep a service running while updating the individual microservice instances. Its prerequisites include the following: 

- No breaking changes to any state stores 

- No breaking changes to the internal microservice topology (particularly relevant for implementations using lightweight frameworks) 

- No breaking changes to internal event schemas 

So long as the prerequisites are met, this deployment pattern works well for scenarios such as when: 

- New fields have been added to the input events and need to be reflected in the business logic 

- New input streams are to be consumed 

- Bugs need to be fixed but don’t require reprocessing 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0296-11.png)


Inadvertently altering the internal microservice topology is one of the most common mistakes people make when trying to use this deployment pattern. Doing so is a breaking change and will require a full application reset instead of a rolling update. 

During a rolling update, only step 4 of “The Basic Full-Stop Deployment Pattern” on page 276 is changed. Instead of stopping each instance at the same time, only one instance at a time is stopped. The stopped instance is then updated and started back up, such that a mixture of new and old instances are running during the deployment process. This rolling update means that for a short period of time, both old and new logic will be operating simultaneously. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0296-14.png)


Smart implementations will run a test that checks compatibility of a release to notify you if the rolling update is valid. Doing this manually is quite error-prone and should be avoided. 


The main benefit of this pattern is that services can be updated while near-real-time processing continues uninterrupted, eliminating downtime. The main drawback of this pattern is its prerequisites, which limits its usage to specific scenarios. 

## **The Breaking Schema Change Pattern** 

A breaking schema change is sometimes inevitable, as covered in “Breaking Schema Changes” on page 43. Deployments involving breaking schema changes must take into account a number of dependencies, including both consumer and producer responsibilities, coordination of migration efforts, and reprocessing downtime. 

Deploying a breaking schema change is a fairly straightforward technical process. The difficult part is renegotiating the schema definition, communicating that with stakeholders, and coordinating deployment and migration plans. Each of these steps requires clear communication between parties and well-defined timelines for action. 

The impacts of a breaking schema change vary depending on the type of event. Breaking _entity_ schema changes are more complex than those of _nonentity events_ , as entities require a consistent definition for consumer materialization. Entities are also, by definition, _durable_ units of data that will be reconsumed whenever a consumer rematerializes the entity stream from its source. Entity streams must be re-created under the new schema, incorporating both the new business logic and schema definitions. 

Re-creating the entities for the new stream will require reprocessing the necessary source data for the producer, whether a batch source or its own input event streams. This logic can be built into the same producer, or a new producer can be built and deployed alongside it. The former option keeps all logic encapsulated within its own service, whereas the latter option allows the original producer to continue its operations uninterrupted, reducing impact to downstream consumers. These options are illustrated in Figure 16-2. 

Breaking schema changes often reflect a fundamental shift in the domain of an entity or event. These usually don’t happen too often, but when they do, the change is usually significant enough that consumers must be updated to reflect the shifted business meaning of the domain. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0298-00.png)


_Figure 16-2. Breaking schema change producer options for re-creating events with new schema_ 

Breaking changes for _nonentity events_ , on the other hand, may not require reprocessing. This is predominantly because many event streaming applications don’t regularly reprocess event streams in the same way that a service may need to rematerialize its entity streams. Consumers can often simply add the new event definition as a new event stream and modify their business logic to handle both old and new events. Once the old events expire out of the event stream, the old event stream can simply be dropped from the business logic. 

There are two main options for migrating a breaking schema change: 

- Eventual migration via two event streams, one with the old schema and one with the new schema 

- Synchronized migration to a single new stream, with the old one removed 

## **Eventual Migration via Two Event Streams** 

Eventual migration via two event streams requires that the producer write events with both the old and new format, each to its respective stream. The old stream is marked as deprecated, and the consumers of it will, in their own time, migrate to the new 


stream instead. Once all of the consumers have migrated, the old stream can be removed or offloaded into long-term data storage. 

This strategy makes a couple of assumptions: 

- **Events can be produced to both the old and new streams.** The producer must have the necessary data available to create events of both the old and new format. The domain of the produced event will have changed significantly enough to require a breaking change, while remaining similar enough that a 1:1 mapping of old to new event format still makes sense. This may not be the case with all breaking schema changes. 

- **Eventual migration will not cause downstream inconsistencies.** Downstream services will continue consuming two different definitions, but there will not be consequential effects, or those effects will be limited. Again, the breaking change in the schema suggests the domain has been altered enough that the redefinition was necessary to the organization. It is seldom the case that the breaking change is necessary for the business but largely inconsequential to the consumers that use the events. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0299-04.png)


One of the main risks of eventual migration is that the migration is never finished, and similar-yet-different data streams remain in use indefinitely. Additionally, new services created during the migration may inadvertently register themselves as consumers on the old stream instead of the new one. Use metadata tagging (see “Event Stream Metadata Tagging” on page 240) to mark streams as deprecated and keep migration windows small. 

## **Synchronized Migration to the New Event Stream** 

Another option is to update the producer to create events strictly with the new format and to cease providing updates to the old stream. This is a simpler option—technologically speaking—than maintaining two event streams, but it requires more intensive communication between the producer and consumers of the data. Consumers must update their definitions to accommodate breaking changes introduced by the producer. 

This strategy also makes a few assumptions: 

- **The event definition change is significant enough that the old format is no longer usable.** The domain of the entity or event has changed so much that the old and new format cannot be maintained concurrently. 

- **Migration must happen synchronously to eliminate downstream inconsistencies.** The domain has changed so significantly that services need to update to 


ensure that business requirements can be met. Downstream services could have major inconsistencies otherwise. For example, consider an entity where the selection criteria for creation of the event has changed. 

The biggest risk of this deployment plan is that consumers may fail in their migration to the new event stream, but be unable to gracefully fall back to the old source of data as they would using the eventual migration strategy. Integration testing (preferably using programmatically generated environments and source data) can reduce this risk by providing an environment in which to completely exercise the migration process. You can create and register the producer and the consumers together in the test environment to validate the migration prior to performing it in production. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0300-02.png)


Synchronized migrations tend to be rare in practice, as they require significant breaking changes or even the destruction of the event’s previous domain model. Core business entities usually have very stable domain models, but when major breaking changes occur, a synchronous migration may be unavoidable. 

## **The Blue-Green Deployment Pattern** 

The main goal of blue-green deployment is to provide zero downtime while deploying new functionality. This pattern is predominantly used in synchronous requestresponse microservice deployments, as it allows for synchronous requests to continue while the service is updated. An example of this pattern is shown in Figure 16-3. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0300-06.png)


_Figure 16-3. Blue-green deployment pattern_ 


In this example, a full copy of the new microservice (blue) is brought up in parallel with the old microservice (green). The blue service has a fully isolated instance of its external data store, its own event stream consumer group, and its own IP addresses for remote access. It consumes input events until monitoring indicates that it is sufficiently caught up to the green service, at which point traffic from the green instances can begin to be rerouted. 

The switchover of traffic is performed by the router in front of the services. A small amount of traffic can be diverted to the new blue instance, such that the deployment can be validated in real time. If the deployment process detects no failures or abnormalities, more and more traffic can be diverted until the green side is no longer receiving any traffic. 

At this point, depending on the sensitivity of your application and the need to provide a quick fallback, the green instances can be turned off immediately or left to idle until sufficient time without incident has passed. In the case that an error occurs during this cooldown period, the router can quickly reroute the traffic back to the green instances. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0301-03.png)


Monitoring and alerting—including resource usage metrics, consumer group lag, autoscaling triggers, and system alerts—need to be integrated as part of the color switching process. 

Blue-green deployments work well for microservices that consume from event streams. They can also work well when events are produced _only_ due to requestresponse activity, such as when the request is converted directly into an event (see “Handling Requests Within an Event-Driven Workflow” on page 223). 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0301-06.png)


Blue-green deployments _do not work_ when the microservice produces events to an output stream in reaction to an input event stream. The two microservices will overwrite each other’s results in the case of entity streams or will create duplicated events in the case of event streams. Use either the rolling update pattern or the basic full-stop deployment pattern instead. 

## **Summary** 

Streamlining the deployment of microservices requires your organization to pay the microservice tax and invest in the necessary deployment systems. Due to the large number of microservices that may need to be managed, it is best to delegate deployment responsibilities to the teams that own the microservices. These teams will need supportive tooling to control and manage their deployments. 


Continuous integration pipelines are an essential part of the deployment process. They provide the framework for setting up and executing tests, validating builds, and ensuring that the containerized services are ready to deploy to production. The container management system provides the means for managing the deployment of the containers into the compute clusters, allocating resources, and providing scalability. 

There are a number of ways to deploy services, with the simplest being to stop the microservice fully and redeploy the newest code. This can incur significant downtime, however, and may not be suitable depending on the SLAs. There are several other deployment patterns, each with its own benefits and drawbacks. The patterns discussed in this chapter are by no means a comprehensive list, but should give you a good starting point for determining the needs of your own services. 


