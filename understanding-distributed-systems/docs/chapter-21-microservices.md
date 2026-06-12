## **Chapter 21** 

## **Microservices** 

If _Cruder_ is successful in the market, we can safely assume that we will continue to add more components to it to satisfy an evergrowing list of business requirements, as shown in Figure 21.1. 


![](understanding-distributed-systems-github-pages/images/Roberto_Vitillo_-_Understanding_Distributed_Systems_-_2nd_Edition_-2022-.pdf-0215-03.png)


Figure 21.1: A monolithic application composed of multiple components 

The components will likely become increasingly coupled in time, causing developers to step on each other’s toes more frequently. Eventually, the codebase becomes complex enough that nobody 


198 fully understands every part of it, and implementing new features or fixing bugs becomes a lot more time-consuming than it used to be. 

Also, a change to a component might require the entire application to be rebuilt and deployed. And if the deployment of a new version introduces a bug, like a memory or socket leak, unrelated components might also be affected. Moreover, reverting a deployment affects the velocity of every developer, not just the one that introduced a bug. 

One way to mitigate the growing pains of a _monolithic_ application is to functionally decompose it into a set of independently deployable services that communicate via APIs, as shown in Figure 21.2. The APIs decouple the services from each other by creating boundaries that are hard to violate, unlike the ones between components running in the same process. 


![](understanding-distributed-systems-github-pages/images/Roberto_Vitillo_-_Understanding_Distributed_Systems_-_2nd_Edition_-2022-.pdf-0216-05.png)


Figure 21.2: An application split into independently deployable services that communicate via APIs 

Each service can be owned and operated by a small team. Smaller teams collaborate more effectively than larger ones, since the com199 munication overhead grows quadratically[1] with the team’s size. And because each team controls its own codebase and dictates its own release schedule, less cross-team communication is required overall. Also, the surface area of a service is smaller than the whole application, making it more digestible to developers, especially new hires. 

Each team is also free in principle to adopt the tech stack and hardware that fits their specific needs. After all, the consumers of the APIs don’t care how the functionality is implemented. This makes it easy to experiment and evaluate new technologies without affecting other parts of the system. As a result, each service can have its own independent data model and data store(s) that best fit its use cases. 

This architectural style is also referred to as the _microservice architecture_ . The term _micro_ is misleading, though — there doesn’t have to be anything micro about services.[2] If a service doesn’t do much, it only adds operational overhead and complexity. As a rule of thumb, APIs should have a small surface area and encapsulate a significant amount of functionality.[3] 

## **21.1 Caveats** 

To recap, splitting an application into services adds a great deal of complexity to the overall system, which is only worth paying if it can be amortized across many development teams. Let’s take a closer look at why that is. 

## **Tech stack** 

While nothing forbids each microservice to use a different tech stack, doing so makes it more difficult for a developer to move 

> 1“The Mythical Man-Month,” https://en.wikipedia.org/wiki/The_Mythica l_Man-Month 

> 2A more appropriate name for the microservices architecture is service-oriented architecture, but unfortunately, that name comes with some baggage as well. 

> 3 This idea is described well in John Ousterhout’s _A Philosophy of Software Design_ , which I highly recommend. 


200 from one team to another. And think of the sheer number of libraries — one for each language adopted — that need to be supported to provide common functionality that all services need, like logging. 

It’s only reasonable, then, to enforce a certain degree of standardization. One way to do that, while still allowing some degree of freedom, is to loosely encourage specific technologies by providing a great development experience for the teams that stick with the recommended portfolio of languages and technologies. 

## **Communication** 

Remote calls are expensive and introduce non-determinism. Much of what is described in this book is about dealing with the complexity of distributed processes communicating over the network. That said, a monolith doesn’t live in isolation either, since it serves external requests and likely depends on third-party APIs as well, so these issues need to be tackled there as well, albeit on a smaller scale. 

## **Coupling** 

Microservices should be loosely coupled so that a change in one service doesn’t require changing others. When that’s not the case, you can end up with a dreaded distributed monolith, which has all the downsides of a monolith while being an order of magnitude more complex due to its distributed nature. 

There are many causes of tight coupling, like fragile APIs that require clients to be updated whenever they change, shared libraries that have to be updated in lockstep across multiple services, or the use of static IP addresses to reference external services. 

## **Resource provisioning** 

To support a large number of independent services, it should be simple to provision new machines, data stores, and other commodity resources — you don’t want every team to come up with their own way of doing it. And, once these resources have been provisioned, they have to be configured. To pull this off efficiently, a 


201 fair amount of automation is needed. 

## **Testing** 

While testing individual microservices is not necessarily more challenging than testing a monolith, testing the integration of microservices is a lot harder. This is because very subtle and unexpected behaviors will emerge only when services interact with each other at scale in production. 

## **Operations** 

Just like with resource provisioning, there should be a common way of continuously delivering and deploying new builds safely to production so that each team doesn’t have to reinvent the wheel. 

Additionally, debugging failures, performance degradations, and bugs is a lot more challenging with microservices, as you can’t just load the whole application onto your local machine and step through it with a debugger. This is why having a good observability platform becomes crucial. 

## **Eventual consistency** 

As a side effect of splitting an application into separate services, the data model no longer resides in a single data store. However, as we have learned in previous chapters, atomically updating data spread in different data stores, and guaranteeing strong consistency, is slow, expensive, and hard to get right. Hence, this type of architecture usually requires embracing eventual consistency. 

So to summarize, it’s generally best to start with a monolith and decompose it only when there is a good reason to do so[4] . As a bonus, you can still componentize the monolith, with the advantage that it’s much easier to move the boundaries as the application grows. Once the monolith is well matured and growing pains start to arise, you can start to peel off one microservice at a time from it. 

> 4“MicroservicePremium,” https://martinfowler.com/bliki/MicroservicePre mium.html 


202 

## **21.2 API gateway** 

After decomposing _Cruder_ into a group of services, we need to rethink how the outside world communicates with the application. For example, a client might need to perform multiple requests to different services to fetch all the information it needs to complete a specific operation. This can be expensive on mobile devices, where every network request consumes precious battery life. 

Moreover, clients need to be aware of implementation details, such as the DNS names of all the internal services. This makes it challenging to change the application’s architecture as it requires changing the clients as well, which is hard to do if you don’t control them. Once a public API is out there, you had better be prepared to maintain it for a very long time. 

As is common in computer science, we can solve almost any problem by adding a layer of indirection. We can hide the internal APIs behind a public one that acts as a facade, or proxy, for the internal services (see Figure 21.3). The service that exposes this public API is called the _API gateway_ (a reverse proxy). 

## **21.2.1 Core responsibilities** 

Let’s have a look at some of the most common responsibilities of an API gateway. 

## **Routing** 

The most obvious function of an API gateway is routing inbound requests to internal services. One way to implement that is with the help of a routing map, which defines how the public API maps to the internal APIs. This mapping allows internal APIs to change without breaking external clients. For example, suppose there is a 1:1 mapping between a specific public endpoint and an internal one — if in the future the internal endpoint changes, the external clients can continue to use the public endpoint as if nothing had changed. 

## **Composition** 


203 


![](understanding-distributed-systems-github-pages/images/Roberto_Vitillo_-_Understanding_Distributed_Systems_-_2nd_Edition_-2022-.pdf-0221-02.png)


Figure 21.3: The API gateway hides the internal APIs from its clients. 

The data of a monolithic application generally resides in a single data store, but in a distributed system, it’s spread across multiple services, each using its own data store. As such, we might encounter use cases that require stitching data together from multiple sources. The API gateway can offer a higher-level API that queries multiple services and composes their responses. This relieves the client from knowing which services to query and reduces the number of requests it needs to perform to get the data it needs. 

Composing APIs is not simple. The availability of the composed API decreases as the number of internal calls increases, since each has a non-zero probability of failure. Moreover, the data might be inconsistent, as updates might not have propagated to all services yet; in that case, the gateway will have to resolve this discrepancy 


204 somehow. 

## **Translation** 

The API gateway can translate from one IPC mechanism to another. For example, it can translate a RESTful HTTP request into an internal gRPC call. 

It can also expose different APIs to different clients. For example, the API for a desktop application could potentially return more data than the one for a mobile application, as the screen estate is larger and more information can be presented at once. Also, network calls are more expensive for mobile clients, and requests generally need to be batched to reduce battery usage. 

To meet these different and competing requirements, the gateway can provide different APIs tailored to different use cases and translate these to internal calls. Graph-based APIs are an increasingly popular solution for this. A _graph-based API_ exposes a schema composed of types, fields, and relationships across types, which describes the data. Based on this schema, clients send queries declaring precisely what data they need, and the gateway’s job is to figure out how to translate these queries into internal API calls. 

This approach reduces the development time as there is no need to introduce different APIs for different use cases, and clients are free to specify what they need. There is still an API, though; it just happens that it’s described with a graph schema, and the gateway allows to perform restricted queries on it. GraphQL[5] is the most popular technology in this space at the time of writing. 

## **21.2.2 Cross-cutting concerns** 

As the API gateway is a reverse proxy, it can also implement crosscutting functionality that otherwise would have to be part of each service. For example, it can cache frequently accessed resources or rate-limit requests to protect the internal services from being overwhelmed. 

5“GraphQL,” https://graphql.org/ 


205 

Authentication and authorization are some of the most common and critical cross-cutting concerns. _Authentication_ is the process of validating that a so-called _principal_ — a human or an application — issuing a request is who it says it is. _Authorization_ is the process of granting the authenticated principal permissions to perform specific operations, like creating, reading, updating, or deleting a particular resource. Typically, this is implemented by assigning one or more roles that grant specific permissions to a principal. 

A common way for a monolithic application to implement authentication and authorization is with sessions. Because HTTP is a stateless protocol, the application needs a way to store data between HTTP requests to associate a request with any other request. When a client first sends a request to the application, the application creates a session object with an ID (e.g., a cryptographicallystrong random number) and stores it in an in-memory cache or an external data store. The session ID is returned in the response through an HTTP cookie so that the client will include it in all future requests. That way, when the application receives a request with a session cookie, it can retrieve the corresponding session object. 

So when a client sends its credentials to the application API’s login endpoint, and the credential validation is successful, the principal’s ID and roles are stored in the session object. The application can later retrieve this information and use it to decide whether to allow the principal to perform a request or not. 

Translating this approach to a microservice architecture is not that straightforward. For example, it’s not obvious which service should be responsible for authenticating and authorizing requests, as the handling of requests can span multiple services. 

One approach is to have the API gateway authenticate external requests, since that’s their point of entry. This allows centralizing the logic to support different authentication mechanisms into a single component, hiding the complexity from internal services. In contrast, _authorizing_ requests is best left to individual services to avoid coupling the API gateway with domain logic. 


206 

When the API gateway has authenticated a request, it creates a _security token_ . The gateway passes this token with the request to the internal services, which in turn pass it downstream to their dependencies. Now, when an internal service receives a request with a security token attached, it needs to have a way to validate it and obtain the principal’s identity and roles. The validation differs depending on the type of token used, which can be _opaque_ and not contain any information, or _transparent_ and embed the principal’s information within the token itself. The downside of an opaque token is that it requires calling an external auth service to validate it and retrieve the principal’s information. Transparent tokens eliminate that call at the expense of making it harder to revoke compromised tokens. 

The most popular standard for transparent tokens is the _JSON Web Token_[6] (JWT). A JWT is a JSON payload that contains an expiration date, the principal’s identity and roles, and other metadata. In addition, the payload is signed with a certificate trusted by the internal services. Hence, no external calls are needed to validate the token. 

Another common mechanism for authentication is the use of API keys. An _API key_ is a custom key that allows the API gateway to identify the principal making a request and limit what they can do. This approach is popular for public APIs, like the ones of, e.g., Github or Twitter. 

We have barely scratched the surface of the topic, and there are entire books[7] written on the subject that you can read to learn more about it. 

## **21.2.3 Caveats** 

One of the drawbacks of using an API gateway is that it can become a development bottleneck. Since it’s tightly coupled with the APIs of the internal services it’s shielding, whenever an internal 

> 6“Introduction to JSON Web Tokens,” https://jwt.io/introduction 

> 7“Microservices Security in Action,” https://www.manning.com/books/micr oservices-security-in-action 


207 

API changes, the gateway needs to be modified as well. Another downside is that it’s one more service that needs to be maintained. It also needs to scale to whatever the request rate is for all the services behind it. 

That said, if an application has many services and APIs, the pros outweigh the cons, and it’s generally a worthwhile investment. So how do you go about implementing a gateway? You can roll your own API gateway, using a reverse proxy as a starting point, like NGINX, or use a managed solution, like Azure API Management[8] or Amazon API Gateway[9] . 

> 8“Azure API Management,” https://azure.microsoft.com/en-gb/services/apimanagement/ 

> 9“Amazon API Gateway,” https://aws.amazon.com/api-gateway/ 


