# Chapter 17: Conclusion

Event-driven microservice architectures provide a powerful, flexible, and welldefined approach to solving business problems. Here is a quick recap of the things that have been covered in this book, as well as some final words.

## CHAPTER 17 Conclusion: Communication Layers

The data communication structure allows for universal access of important business events across the organization. Event brokers fulfill this need extremely well, as they permit the strict organization of data, can propagate updates in near–real time, and can operate at big-data scale. The communication of data remains strictly decoupled from the business logic that transforms and utilizes it, offloading these requirements into individual bounded contexts. This separation of concerns allows the event broker to remain largely agnostic of the business logic requirements (aside from supporting reads and writes), enabling it focus strictly on storing, preserving, and distributing the event data to consumers.

A mature data communication layer decouples the ownership and production of data from the access and consumption of it. Applications no longer need to perform double duty by serving internal business logic while also providing synchronization mechanisms and outside direct access for other services.

Any service can leverage the durability and resiliency of the event broker to makes its data highly available, including those that use the event broker to store changelogs of its internal state. A failed service instance no longer means that data is inaccessible, but simply that new data will be delayed until the producer is back online. Meanwhile, consumers are free to consume from the event broker during any producer outages, decoupling the failure modes between the services.


## Business Domains and Bounded Contexts

Businesses operate in a specific domain, which can be broken down into subdomains. Solutions to business problems are informed by bounded contexts, which identify the boundaries—including the inputs, outputs, events, requirements, processes, and data models—relevant to the subdomain.

Microservice implementations can be built to align with these bounded contexts. The resultant services and workflows thus align with the problems and business requirements. The universal data communication layer helps facilitate these alignments by ensuring that the microservice implementations are flexible enough to adapt to changes within the business domain and subsequent bounded contexts.

## Shareable Tools and Infrastructure

Event-driven microservices require an investment in the systems and tools that permit its operation at scale, known as the microservice tax. The event broker is at the heart of the system, as it provides the fundamental communication between services and absolves each service from managing its own data communication solution.

Microservice architectures amplify all of the issues surrounding creating, managing, and deploying applications, and benefit from a standardization and streamlining of these processes. This becomes more critical as the number of microservices grow, because while each new microservice incurs an overhead, the nonstandardized ones can incur significantly more than those following a protocol.

The essential services that make up the microservice tax include:

- The event broker

- Schema registry and data exploration service

- Container management system

- Continuous integration, delivery, and deployment service

- Monitoring and logging service

Paying the microservice tax is unlikely to be an all-or-nothing process. An organization will typically start with either an event broker service or a container management system, and work toward adding other pieces as needed. Fortunately, a number of computing service providers, such as Google, Microsoft, and Amazon, have created services that significantly reduce the overhead. You must weigh your options and choose between outsourcing these operations to a service provider or building your own systems in-house.


## Schematized Events

Schemas play a pivotal role in communicating the meaning of events. Strongly typed events force both producers and consumers to contend with the realities of the data. Producers must ensure that they produce events according to the schema, while consumers must ensure that they handle the types, ranges, and definitions of the consumed events. Strongly defined schemas significantly reduce the chance of consumers misinterpreting events and provide a contract for future changes.

Schema evolution provides a mechanism for events and entities to change in response to new business requirements. It enables the producer to generate data with new and altered fields, while also allowing consumers that don’t care about the change to continue using older schemas. This significantly reduces the frequency and risk of nonessential change. Meanwhile, the remaining consumers can independently upgrade their code to consume and process events using the latest schema format, enabling them to access the latest data fields.

Finally, schemas also allow for useful features such as code generation and data discovery. Code generators can create classes/structures relevant to producing and consuming applications. These strongly defined classes/structures can help detect formatting errors in production and consumption either at compile time or during local testing, ensuring that events can be seamlessly produced and consumed. This allows developers to focus strictly on the business logic of handling and transforming these events, and far less on the plumbing. Meanwhile, a schema registry provides a searchable means of figuring out which data is attributed to which event stream, enabling easier discovery of the stream’s contents.

## Data Liberation and the Single Source of Truth

Once the data communication layer is available, it’s time to get the business-critical data into it. Liberating data from the various services and data stores in your organization can be a lengthy process, and it will take some time to get all necessary data into the event broker. This is an essential step in decoupling systems from one another and for moving toward an event-driven architecture. Data liberation decouples the production and ownership of data from the accessing of it by downstream consumers.

Start by liberating the data that is most commonly used and most critical to your organization’s next major goals. There are various ways to extract information from the various services and data stores, and each method has benefits and drawbacks. It’s important to weigh the impact on the existing service against the risks of stale data, lack of schemas, and exposure of internal data models in the liberated event streams.


![](../images/event_driven_microservices_page_0306_0.png)

Having readily available business data in the form of event streams allows for services to be built by _composition_. A new service needs only to subscribe to the event streams of interest via the event broker, rather than directly connecting to each service that would otherwise provide the data.

## Microservices

As the implementation of the bounded context, microservices are focused on solving the _business_ problems of the bounded context, and aligned accordingly. Business requirement changes are the primary driver of updates to a microservice, with all other unrelated microservices remaining unchanged.

Avoid implementing microservices based on technical boundaries. These are generally created as a short-term optimization for serving multiple business workflows, but in doing so, they couple themselves to each workflow. The technical microservice becomes sensitive to business changes and couples otherwise unrelated workflows together. A failure or inadvertent change in the technical microservice can bring down multiple business workflows. Steer clear of technical alignment whenever possible, and focus instead on fulfilling the business’s bounded context.

Lastly, not all microservices need be “micro.” It is reasonable for an organization to instead use several larger services, particularly if it has not paid the microservice tax, in part or in full. This is a normal evolution of an organization’s architecture. If your business is using numerous large services, following these principles will help enable the creation of new, fine-grained services decoupled from the existing large services:

- Put important business entities and events into the event broker.

- Use the event broker as the single source of truth.

- Avoid using direct calls between services.

## Microservice Implementation Options

There’s a wide range of options available, all with pros and cons, for building eventdriven microservices. Currently, lightweight frameworks tend to have the greatest out-of-the-box functionality. Streams can be materialized to tables and maintained indefinitely. Joins, including those on foreign keys, can be performed for numerous streams and tables. Hot replicas, durable storage, and changelogs provide resiliency and scalability.

Heavyweight frameworks provide similar functionality to lightweight frameworks, but fall short in terms of processing independence because they require a separate dedicated cluster of resources. New cluster management options are becoming more popular, such as direct integration with Kubernetes, one of the leading container


management systems. Heavyweight frameworks are often already in use in mid-sized and larger organizations, typically by the individuals performing big-data analysis.

Basic producer/consumer (BPC) and Function-as-a-Service (FaaS) solutions provide flexible options for many languages and runtimes. Both options are limited to basic consumption and production patterns. Ensuring deterministic behavior is difficult, as neither option comes with built-in event scheduling, so complex operations require either a significant investment in your own custom libraries to provide that functionality, or limiting the usage to simple use-case patterns.

## Testing

Event-driven microservices lend themselves very well to full integration and unit testing. As the predominant form of inputs to an event-driven microservice, events can be easily composed to cover whatever cases may arise. Event schemas constrain the range of values that need to be tested and provide the necessary structure for composing input test streams.

Local testing can include both unit and integration testing, with the latter relying on the dynamic creation of an event broker, schema registry, and any other dependencies required by the service under test. For example, an event broker can be created to run within the same executable as the test, as is the case with numerous JVM-based solutions, or to run within its own container alongside the application under test. With full control of the event broker, you can simulate load, timing conditions, outages, failures, or any other broker-application interactions.

You can conduct production integration testing by dynamically creating a temporary event broker cluster, populating it with copies of production event streams and events (barring information-security concerns) and executing the application against it. This can provide a smoke test prior to production deployment to ensure that nothing has been overlooked. You can also execute performance tests in this environment, testing both the performance of a single instance and the ability of the application to horizontally scale. The environment can simply be discarded once testing is complete.

## Deploying

Deploying microservices at scale requires that microservice owners can quickly and easily deploy and roll back their services. This autonomy allows for teams to move and act independently and to eliminate bottlenecks that would otherwise exist in an infrastructural team responsible solely for deployments. Continuous integration, delivery, and deployment pipelines are essential in providing this functionality, as they allow a streamlined yet customizable deployment process that reduces manual steps and intervention, and can be scaled out to other microservices. Depending on


your selection, the container management system may provide additional functionality to help with deployments and rollbacks, further simplifying the process.

The deployment process must take into account service-level agreements (SLAs), rebuilding of state, and reconsumption of input event streams. SLAs are not simply matters of downtime, but also must take into account the impact of deployment on all downstream consumers, and the health of the event broker service. A microservice that must rebuild its entire state and propagate new output events may place a considerable load on the event broker, as well as cause downstream consumers to suddenly need to scale up to many more processing instances. It is not uncommon for a rebuilding service to process millions or billions of events in short order. Quotas can mitigate the impact, but depending on downstream service requirements, a rebuilding service may be in an inconsistent state for an unacceptable period of time.

There are always tradeoffs between SLAs, impact to downstream consumers, impact to the event broker, and impact to monitoring and alerting frameworks. For instance, a blue-green deployment requires two consumer groups, which must be considered for monitoring and alerting, including lag-based autoscaling. While you can certainly perform the work necessary to accommodate this deployment pattern, another option is to simply change the application’s design. An alternative to blue-green deployments is to use a thin, always-on serving layer to serve synchronous requests, while the backend event processor can be swapped out and reprocess in its own time. While your service layer may serve stale data for a period of time, it doesn’t require any augmentations to tooling or more complex swapping operations and can possibly still meet the SLAs of dependent services.

## Final Words

Event-driven microservices require you to rethink what data really is and how services go about accessing and using it. The amount of data attributed to any specific domain grows in leaps and bounds every year and shows no signs of stopping. Data is becoming larger and more ubiquitous, and gone are the days when it could simply be shoved into one large data store and used for all purposes. A robust and well-defined data communication layer relieves services of performing double duty and allows them to focus instead on serving just their own business functionality, not the data and querying needs of other bounded contexts.

Event-driven microservices are a natural evolution of computing to handle these large and diverse data sets. The compositional nature of event streams lends itself to unparalleled flexibility and allows individual business units to focus on using whatever data is necessary to accomplish their business goals. Organizations running a handful of services can benefit greatly from the data communications provided by the event broker, which paves the way for building new services, fully decoupled from old business requirements and implementations.


Regardless of the future of event-driven microservices themselves, this much is clear: The data communication layer extends the power of an organization’s data to any service or team that requires it, eliminates access boundaries, and reduces unnecessary complexity related to the production and distribution of important business information.


