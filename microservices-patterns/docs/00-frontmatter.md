
![](../images/Microservices_Patterns_With_examples_in_Java_-Chris_Richardson-_-Z-Library--0001-00.png)


![](../images/Microservices_Patterns_With_examples_in_Java_-Chris_Richardson-_-Z-Library--0001-01.png)


![](../images/Microservices_Patterns_With_examples_in_Java_-Chris_Richardson-_-Z-Library--0001-02.png)


Chris Richardson 


![](../images/Microservices_Patterns_With_examples_in_Java_-Chris_Richardson-_-Z-Library--0001-04.png)


![](../images/Microservices_Patterns_With_examples_in_Java_-Chris_Richardson-_-Z-Library--0001-05.png)


**M A N N I N G** 


## _List of Patterns_ 

_Application architecture patterns_ Monolithic architecture (40) Microservice architecture (40) 

## _External API patterns_ 

API gateway (259) Backends for frontends (265) 

## _Decomposition patterns_ 

Decompose by business capability (51) Decompose by subdomain (54) 

## _Messaging style patterns_ 

Messaging (85) Remote procedure invocation (72) _Reliable communications patterns_ Circuit breaker (78) 

## _Testing patterns_ 

Consumer-driven contract test (302) Consumer-side contract test (303) Service component test (335) 

## _Security patterns_ 

Access token (354) 

_Cross-cutting concerns patterns_ Externalized configuration (361) Microservice chassis (379) 

## _Service discovery patterns_ 

3rd party registration (85) Client-side discovery (83) Self-registration (82) Server-side discovery (85) 

## _Transactional messaging patterns_ 

Polling publisher (98) Transaction log tailing (99) Transactional outbox (98) 

_Data consistency patterns_ Saga (114) 

## _Business logic design patterns_ 

Aggregate (150) Domain event (160) Domain model (150) Event sourcing (184) Transaction script (149) 

## _Observability patterns_ 

Application metrics (373) Audit logging (377) Distributed tracing (370) Exception tracking (376) Health check API (366) Log aggregation (368) 

## _Deployment patterns_ 

Deploy a service as a container (393) Deploy a service as a VM (390) Language-specific packaging format (387) Service mesh (380) Serverless deployment (416) Sidecar (410) 

## _Refactoring to microservices patterns_ 

Anti-corruption layer (447) Strangler application (432) 

_Querying patterns_ 

API composition (223) Command query responsibility segregation (228) 


_Microservices Patterns_ 


_Microservices Patterns_ **WITH EXAMPLES IN JAVA** 

CHRIS RICHARDSON 

M A N N I N G SHELTER ISLAND 


For online information and ordering of this and other Manning books, please visit www.manning.com. The publisher offers discounts on this book when ordered in quantity. For more information, please contact 

Special Sales Department Manning Publications Co. 20 Baldwin Road PO Box 761 Shelter Island, NY 11964 Email: orders@manning.com 

©2019 by Chris Richardson. All rights reserved. 

No part of this publication may be reproduced, stored in a retrieval system, or transmitted, in any form or by means electronic, mechanical, photocopying, or otherwise, without prior written permission of the publisher. 

Many of the designations used by manufacturers and sellers to distinguish their products are claimed as trademarks. Where those designations appear in the book, and Manning Publications was aware of a trademark claim, the designations have been printed in initial caps or all caps. 

Recognizing the importance of preserving what has been written, it is Manning’s policy to have the books we publish printed on acid-free paper, and we exert our best efforts to that end. Recognizing also our responsibility to conserve the resources of our planet, Manning books are printed on paper that is at least 15 percent recycled and processed without the use of elemental chlorine. 

Manning Publications Co. 20 Baldwin Road PO Box 761 Shelter Island, NY 11964 

Development editor: Marina Michaels Technical development editor: Christian Mennerich Review editor: Aleksandar Dragosavljevic´ Project editor: Lori Weidert Copy editor: Corbin Collins Proofreader: Alyson Brener Technical proofreader: Andy Miles Typesetter: Dennis Dalinnik Cover designer: Marija Tudor 

ISBN: 9781617294549 Printed in the United States of America 1 2 3 4 5 6 7 8 9 10 – DP – 23 22 21 20 19 18 


_Where you see wrong or inequality or injustice, speak out, because this is your country. This is your democracy. Make it. Protect it. Pass it on._ 

— Thurgood Marshall, Justice of the Supreme Court 


## _brie contents f_ 

|_1_|■|Escaping monolithic hell<br>1||||||
|---|---|---|---|---|---|---|---|
|_2_|■|Decomposition strategies<br>33||||||
|_3_|■|Interprocess communication in a microservice||||||
|||architecture<br>65||||||
|_4_|■|Managing transactions with sagas||110||||
|_5_|■|Designing business logic in a microservice||||||
|||architecture<br>146||||||
|_6_|■|Developing business logic with|event sourcing|||183||
|_7_|■|Implementing queries in a microservice|||architecture||220|
|_8_|■|External API patterns<br>253||||||
|_9_|■|Testing microservices: Part 1|292|||||
|_10_|■|Testing microservices: Part 2|318|||||
|_11_|■|Developing production-ready services|||348|||
|_12_|■|Deploying microservices<br>383||||||
|_13_|■|Refactoring to microservices|428|||||




## _contents_ 

_preface xvii acknowledgments xx about this book xxii about the cover illustration xxvi_ 

## _1_ _**Escaping monolithic hell 1**_ 

1.1 The slow march toward monolithic hell 2 

_The architecture of the FTGO application 3_ ■ _The benefits of the monolithic architecture 4_ ■ _Living in monolithic hell 4_ 

1.2 Why this book is relevant to you 7 

- 1.3 What you’ll learn in this book 7 

1.4 Microservice architecture to the rescue 8 

_Scale cube and microservices 8_ ■ _Microservices as a form of modularity 11_ ■ _Each service has its own database 12 The FTGO microservice architecture 12_ ■ _Comparing the microservice architecture and SOA 13_ 

- 1.5 Benefits and drawbacks of the microservice 

architecture 14 

_Benefits of the microservice architecture 14_ ■ _Drawbacks of the microservice architecture 17_ 



CONTENTS 


1.6 The Microservice architecture pattern language 19 _Microservice architecture is not a silver bullet 19_ ■ _Patterns and pattern languages 20_ ■ _Overview of the Microservice architecture pattern language 23_ 

1.7 Beyond microservices: Process and organization 29 

_Software development and delivery organization 29_ ■ _Software development and delivery process 30_ ■ _The human side of adopting microservices 31_ 

## _2_ _**Decomposition strategies 33**_ 

2.1 What is the microservice architecture exactly? 34 _What is software architecture and why does it matter? 34 Overview of architectural styles 37_ ■ _The microservice architecture is an architectural style 40_ 

2.2 Defining an application’s microservice architecture 44 

_Identifying the system operations 45_ ■ _Defining services by applying the Decompose by business capability pattern 51 Defining services by applying the Decompose by sub-domain pattern 54_ ■ _Decomposition guidelines 56_ ■ _Obstacles to decomposing an application into services 57_ ■ _Defining service APIs 61_ 

_3_ _**Interprocess communication in a microservice architecture 65**_ 

3.1 Overview of interprocess communication in a microservice architecture 66 _Interaction styles 67_ ■ _Defining APIs in a microservice architecture 68_ ■ _Evolving APIs 69_ ■ _Message formats 71_ 

3.2 Communicating using the synchronous Remote procedure invocation pattern 72 _Using REST 73_ ■ _Using gRPC 76_ ■ _Handling partial failure using the Circuit breaker pattern 77_ ■ _Using service discovery 80_ 

- 3.3 Communicating using the Asynchronous messaging pattern 85 

_Overview of messaging 86_ ■ _Implementing the interaction styles using messaging 87_ ■ _Creating an API specification for a messaging-based service API 89_ ■ _Using a message broker 90 Competing receivers and message ordering 94_ ■ _Handling duplicate messages 95_ ■ _Transactional messaging 97 Libraries and frameworks for messaging 100_ 


CONTENTS 


3.4 Using asynchronous messaging to improve availability 103 _Synchronous communication reduces availability 103 Eliminating synchronous interaction 104_ 

## _4_ _**Managing transactions with sagas 110**_ 

4.1 Transaction management in a microservice architecture 111 _The need for distributed transactions in a microservice architecture 112_ ■ _The trouble with distributed transactions 112_ ■ _Using the Saga pattern to maintain data consistency 114_ 4.2 Coordinating sagas 117 _Choreography-based sagas 118_ ■ _Orchestration-based sagas 121_ 4.3 Handling the lack of isolation 126 _Overview of anomalies 127_ ■ _Countermeasures for handling the lack of isolation 128_ 

4.4 The design of the Order Service and the Create Order Saga 132 _The OrderService class 133_ ■ _The implementation of the Create Order Saga 135_ ■ _The OrderCommandHandlers class 142 The OrderServiceConfiguration class 143_ 

## _5_ _**Designing business logic in a microservice architecture 146**_ 

5.1 Business logic organization patterns 147 

_Designing business logic using the Transaction script pattern 149 Designing business logic using the Domain model pattern 150 About Domain-driven design 151_ 

5.2 Designing a domain model using the DDD aggregate pattern 152 _The problem with fuzzy boundaries 153_ ■ _Aggregates have explicit boundaries 154_ ■ _Aggregate rules 155_ ■ _Aggregate granularity 158_ ■ _Designing business logic with aggregates 159_ 5.3 Publishing domain events 160 _Why publish change events? 160_ ■ _What is a domain event? 161_ ■ _Event enrichment 161_ ■ _Identifying domain events 162_ ■ _Generating and publishing domain events 164 Consuming domain events 167_ 


CONTENTS 


5.4 Kitchen Service business logic 168 

_The Ticket aggregate 169_ 

5.5 Order Service business logic 173 

_The Order Aggregate 175_ ■ _The OrderService class 180_ 

## _6_ _**Developing business logic with event sourcing 183**_ 

6.1 Developing business logic using event sourcing 184 

_The trouble with traditional persistence 185_ ■ _Overview of event sourcing 186_ ■ _Handling concurrent updates using optimistic locking 193_ ■ _Event sourcing and publishing events 194 Using snapshots to improve performance 195_ ■ _Idempotent message processing 197_ ■ _Evolving domain events 198 Benefits of event sourcing 199_ ■ _Drawbacks of event sourcing 200_ 

- 6.2 Implementing an event store 202 

_How the Eventuate Local event store works 203_ ■ _The Eventuate client framework for Java 205_ 

- 6.3 Using sagas and event sourcing together 209 

_Implementing choreography-based sagas using event sourcing 210 Creating an orchestration-based saga 211_ ■ _Implementing an event sourcing-based saga participant 213_ ■ _Implementing saga orchestrators using event sourcing 216_ 

## _7_ _**Implementing queries in a microservice architecture 220**_ 

7.1 Querying using the API composition pattern 221 

_The findOrder() query operation 221_ ■ _Overview of the API composition pattern 222_ ■ _Implementing the findOrder() query operation using the API composition pattern 224_ ■ _API composition design issues 225_ ■ _The benefits and drawbacks of the API composition pattern 227_ 

7.2 Using the CQRS pattern 228 

_Motivations for using CQRS 229_ ■ _Overview of CQRS 232 The benefits of CQRS 235_ ■ _The drawbacks of CQRS 236_ 

7.3 Designing CQRS views 236 

_Choosing a view datastore 237_ ■ _Data access module design 239 Adding and updating CQRS views 241_ 

7.4 Implementing a CQRS view with AWS DynamoDB 242 

_The OrderHistoryEventHandlers module 243 Data modeling and query design with DynamoDB 244 The OrderHistoryDaoDynamoDb class 249_ 


CONTENTS 


## _8_ _**External API patterns 253**_ 

8.1 External API design issues 254 _API design issues for the FTGO mobile client 255_ ■ _API design issues for other kinds of clients 258_ 

8.2 The API gateway pattern 259 _Overview of the API gateway pattern 259_ ■ _Benefits and drawbacks of an API gateway 267_ ■ _Netflix as an example of an API gateway 267_ ■ _API gateway design issues 268_ 8.3 Implementing an API gateway 271 _Using an off-the-shelf API gateway product/service 271 Developing your own API gateway 273_ ■ _Implementing an API gateway using GraphQL 279_ 

## _9_ _**Testing microservices: Part 1 292**_ 

9.1 Testing strategies for microservice architectures 294 

_Overview of testing 294_ ■ _The challenge of testing microservices 299_ ■ _The deployment pipeline 305_ 9.2 Writing unit tests for a service 307 _Developing unit tests for entities 309_ ■ _Writing unit tests for value objects 310_ ■ _Developing unit tests for sagas 310_ ■ _Writing unit tests for domain services 312_ ■ _Developing unit tests for controllers 313_ ■ _Writing unit tests for event and message handlers 315_ 

## _10_ _**Testing microservices: Part 2 318**_ 

10.1 Writing integration tests 319 

_Persistence integration tests 321_ ■ _Integration testing REST-based request/response style interactions 322_ ■ _Integration testing publish/subscribe-style interactions 326_ ■ _Integration contract tests for asynchronous request/response interactions 330_ 

- 10.2 Developing component tests 335 

_Defining acceptance tests 336_ ■ _Writing acceptance tests using Gherkin 337_ ■ _Designing component tests 339_ ■ _Writing component tests for the FTGO Order Service 340_ 

- 10.3 Writing end-to-end tests 345 

_Designing end-to-end tests 345_ ■ _Writing end-to-end tests 346 Running end-to-end tests 346_ 


CONTENTS 


## _11_ _**Developing production-ready services 348**_ 

11.1 Developing secure services 349 

_Overview of security in a traditional monolithic application 350 Implementing security in a microservice architecture 353_ 

## 11.2 Designing configurable services 360 

_Using push-based externalized configuration 362_ ■ _Using pullbased externalized configuration 363_ 

- 11.3 Designing observable services 364 

_Using the Health check API pattern 366_ ■ _Applying the Log aggregation pattern 368_ ■ _Using the Distributed tracing pattern 370_ ■ _Applying the Application metrics pattern 373 Using the Exception tracking pattern 376_ ■ _Applying the Audit logging pattern 377_ 

11.4 Developing services using the Microservice chassis pattern 378 

_Using a microservice chassis 379_ ■ _From microservice chassis to service mesh 380_ 

## _12_ _**Deploying microservices 383**_ 

12.1 Deploying services using the Language-specific packaging format pattern 386 

_Benefits of the Service as a language-specific package pattern 388 Drawbacks of the Service as a language-specific package pattern 389_ 

12.2 Deploying services using the Service as a virtual machine pattern 390 _The benefits of deploying services as VMs 392_ ■ _The drawbacks of deploying services as VMs 392_ 

12.3 Deploying services using the Service as a container pattern 393 

_Deploying services using Docker 395_ ■ _Benefits of deploying services as containers 398_ ■ _Drawbacks of deploying services as containers 399_ 

- 12.4 Deploying the FTGO application with Kubernetes 399 

_Overview of Kubernetes 399_ ■ _Deploying the Restaurant service on Kubernetes 402_ ■ _Deploying the API gateway 405 Zero-downtime deployments 406_ ■ _Using a service mesh to separate deployment from release 407_ 


CONTENTS 


12.5 Deploying services using the Serverless deployment pattern 415 _Overview of serverless deployment with AWS Lambda 416 Developing a lambda function 417_ ■ _Invoking lambda functions 417_ ■ _Benefits of using lambda functions 418 Drawbacks of using lambda functions 419_ 

12.6 Deploying a RESTful service using AWS Lambda and AWS Gateway 419 _The design of the AWS Lambda version of Restaurant Service 419 Packaging the service as ZIP file 424_ ■ _Deploying lambda functions using the Serverless framework 425_ 

## _13_ _**Refactoring to microservices 428**_ 

13.1 Overview of refactoring to microservices 429 

_Why refactor a monolith? 429_ ■ _Strangling the monolith 430_ 

13.2 Strategies for refactoring a monolith to microservices 433 _Implement new features as services 434_ ■ _Separate presentation tier from the backend 436_ ■ _Extract business capabilities into services 437_ 

13.3 Designing how the service and the monolith collaborate 443 

_Designing the integration glue 444_ ■ _Maintaining data consistency across a service and a monolith 449_ ■ _Handling authentication and authorization 453_ 

13.4 Implementing a new feature as a service: handling misdelivered orders 455 

_The design of Delayed Delivery Service 456_ ■ _Designing the integration glue for Delayed Delivery Service 457_ 

13.5 Breaking apart the monolith: extracting delivery management 459 _Overview of existing delivery management functionality 460 Overview of Delivery Service 462_ ■ _Designing the Delivery Service domain model 463_ ■ _The design of the Delivery Service integration glue 465_ ■ _Changing the FTGO monolith to interact with Delivery Service 467_ 

_index 473_ 


## _re ace p f_ 

One of my favorite quotes is 

_The future is already here—it’s just not very evenly distributed._ 

—William Gibson, science fiction author 

The essence of that quote is that new ideas and technology take a while to diffuse through a community and become widely adopted. A good example of the slow diffusion of ideas is the story of how I discovered microservices. It began in 2006, when, after being inspired by a talk given by an AWS evangelist, I started down a path that ultimately led to my creating the original Cloud Foundry. (The only thing in common with today’s Cloud Foundry is the name.) Cloud Foundry was a Platform-as-a-Service (PaaS) for automating the deployment of Java applications on EC2. Like every other enterprise Java application that I’d built, my Cloud Foundry had a monolith architecture consisting of a single Java Web Application Archive (WAR) file. 

Bundling a diverse and complex set of functions such as provisioning, configuration, monitoring, and management into a monolith created both development and operations challenges. You couldn’t, for example, change the UI without testing and redeploying the entire application. And because the monitoring and management component relied on a Complex Event Processing (CEP) engine which maintained in-memory state we couldn’t run multiple instances of the application! That’s embarrassing to admit, but all I can say is that I am a software developer, and, “let he who is without sin cast the first stone.” 



PREFACE 


Clearly, the application had quickly outgrown its monolith architecture, but what was the alternative? The answer had been out in the software community for some time at companies such as eBay and Amazon. Amazon had, for example, started to migrate away from the monolith around 2002 (https://plus.google.com/110981030061712822816/ posts/AaygmbzVeRq). The new architecture replaced the monolith with a collection of loosely coupled services. Services are owned by what Amazon calls two-pizza teams— teams small enough to be fed by two pizzas. 

Amazon had adopted this architecture to accelerate the rate of software development so that the company could innovate faster and compete more effectively. The results are impressive: Amazon reportedly deploys changes into production every 11.6 seconds! 

In early 2010, after I’d moved on to other projects, the future of software architecture finally caught up with me. That’s when I read the book _The Art of Scalability: Scalable Web Architecture, Processes, and Organizations for the Modern Enterprise_ (AddisonWesley Professional, 2009) by Michael T. Fisher and Martin L. Abbott. A key idea in that book is the scale cube, which, as described in chapter 2, is a three-dimensional model for scaling an application. The Y-axis scaling defined by the scale cube functionally decomposes an application into services. In hindsight, this was quite obvious, but for me at the time, it was an a-ha moment! I could have solved the challenges I was facing two years earlier by architecting Cloud Foundry as a set of services! 

In April 2012, I gave my first talk on this architectural approach, called “Decomposing Applications of Deployability and Scalability” (www.slideshare.net/chris.e .richardson/decomposing-applications-for-scalability-and-deployability-april-2012). At the time, there wasn’t a generally accepted term for this kind of architecture. I sometimes called it modular, polyglot architecture, because the services could be written in different languages. 

But in another example of how the future is unevenly distributed, the term _microservice_ was used at a software architecture workshop in 2011 to describe this kind of architecture (https://en.wikipedia.org/wiki/Microservices). I first encountered the term when I heard Fred George give a talk at Oredev 2013, and I liked it! 

In January 2014, I created the https://microservices.io website to document architecture and design patterns that I had encountered. Then in March 2014, James Lewis and Martin Fowler published a blog post about microservices (https://martinfowler .com/articles/microservices.html). By popularizing the term microservices, the blog post caused the software community to consolidate around the concept. 

The idea of small, loosely coupled teams, rapidly and reliably developing and delivering microservices is slowly diffusing through the software community. But it’s likely that this vision of the future is quite different from your daily reality. Today, businesscritical enterprise applications are typically large monoliths developed by large teams. Software releases occur infrequently and are often painful for everyone involved. IT often struggles to keep up with the needs of the business. You’re wondering how on earth you can adopt the microservice architecture. 


PREFACE 


The goal of this book is to answer that question. It will give you a good understanding of the microservice architecture, its benefits and drawbacks, and when to use it. The book describes how to solve the numerous design challenges you’ll face, including how to manage distributed data. It also covers how to refactor a monolithic application to a microservice architecture. But this book is not a microservices manifesto. Instead, it’s organized around a collection of patterns. A pattern is a reusable solution to a problem that occurs in a particular context. The beauty of a pattern is that besides describing the benefits of the solution, it also describes the drawbacks and the issues you must address in order to successfully implement a solution. In my experience, this kind of objectivity when thinking about solutions leads to much better decision making. I hope you’ll enjoy reading this book and that it teaches you how to successfully develop microservices. 


## _acknowled ments g_ 

Although writing is a solitary activity, it takes a large number of people to turn rough drafts into a finished book. 

First, I want to thank Erin Twohey and Michael Stevens from Manning for their persistent encouragement to write another book. I would also like to thank my development editors, Cynthia Kane and Marina Michaels. Cynthia Kane got me started and worked with me on the first few chapters. Marina Michaels took over from Cynthia and worked with me to the end. I’ll be forever grateful for Marina’s meticulous and constructive critiques of my chapters. And I want to thank the rest of the Manning team who’s been involved in getting this book published. 

I’d like to thank my technical development editor, Christian Mennerich, my technical proofreader, Andy Miles, and all my external reviewers: Andy Kirsch, Antonio Pessolano, Areg Melik-Adamyan, Cage Slagel, Carlos Curotto, Dror Helper, Eros Pedrini, Hugo Cruz, Irina Romanenko, Jesse Rosalia, Joe Justesen, John Guthrie, Keerthi Shetty, Michele Mauro, Paul Grebenc, Pethuru Raj, Potito Coluccelli, Shobha Iyer, Simeon Leyzerzon, Srihari Sridharan, Tim Moore, Tony Sweets, Trent Whiteley, Wes Shaddix, William E. Wheeler, and Zoltan Hamori. 

I also want to thank everyone who purchased the MEAP and provided feedback in the forum or to me directly. 

I want to thank the organizers and attendees of all of the conferences and meetups at which I’ve spoken for the chance to present and revise my ideas. And I want to thank my consulting and training clients around the world for giving me the opportunity to help them put my ideas into practice. 



ACKNOWLEDGMENTS 


I want to thank my colleagues Andrew, Valentin, Artem, and Stanislav at Eventuate, Inc., for their contributions to the Eventuate product and open source projects. Finally, I’d like to thank my wife, Laura, and my children, Ellie, Thomas, and Janet for their support and understanding over the last 18 months. While I’ve been glued to my laptop, I’ve missed out on going to Ellie’s soccer games, watching Thomas learning to fly on his flight simulator, and trying new restaurants with Janet. Thank you all! 


## _about this book_ 

The goal of this book is to teach you how to successfully develop applications using the microservice architecture. 

Not only does it discuss the benefits of the microservice architecture, it also describes the drawbacks. You’ll learn when you should consider using the monolithic architecture and when it makes sense to use microservices. 

## _Who should read this book_ 

The focus of this book is on architecture and development. It’s meant for anyone responsible for developing and delivering software, such as developers, architects, CTOs, or VPs of engineering. 

The book focuses on explaining the microservice architecture patterns and other concepts. My goal is for you to find this material accessible, regardless of the technology stack you use. You only need to be familiar with the basics of enterprise application architecture and design. In particular, you need to understand concepts like three-tier architecture, web application design, relational databases, interprocess communication using messaging and REST, and the basics of application security. The code examples, though, use Java and the Spring framework. In order to get the most out of them, you should be familiar with the Spring framework. 



ABOUT THIS BOOK 


## _Roadmap_ 

This book consists of 13 chapters: 

- Chapter 1 describes the symptoms of monolithic hell, which occurs when a monolithic application outgrows its architecture, and advises on how to escape by adopting the microservice architecture. It also provides an overview of the microservice architecture pattern language, which is the organizing theme for most of the book. 

- Chapter 2 explains why software architecture is important and describes the patterns you can use to decompose an application into a collection of services. It also explains how to overcome the various obstacles you typically encounter along the way. 

- Chapter 3 describes the different patterns for robust, interprocess communication in a microservice architecture. It explains why asynchronous, messagebased communication is often the best choice. 

- Chapter 4 explains how to maintain data consistency across services by using the Saga pattern. A saga is a sequence of local transactions coordinated using asynchronous messaging. 

- Chapter 5 describes how to design the business logic for a service using the domain-driven design (DDD) Aggregate and Domain event patterns. 

- Chapter 6 builds on chapter 5 and explains how to develop business logic using the Event sourcing pattern, an event-centric way to structure the business logic and persist domain objects. 

- Chapter 7 describes how to implement queries that retrieve data scattered across multiple services by using either the API composition pattern or the Command query responsibility segregation (CQRS) pattern. 

- Chapter 8 covers the external API patterns for handling requests from a diverse collection of external clients, such as mobile applications, browser-based JavaScript applications, and third-party applications. 

- Chapter 9 is the first of two chapters on automated testing techniques for microservices. It introduces important testing concepts such as the test pyramid, which describes the relative proportions of each type of test in your test suite. It also shows how to write unit tests, which form the base of the testing pyramid. 

- Chapter 10 builds on chapter 9 and describes how to write other types of tests in the test pyramid, including integration tests, consumer contract tests, and component tests. 

- Chapter 11 covers various aspects of developing production-ready services, including security, the Externalized configuration pattern, and the service observability patterns. The service observability patterns include Log aggregation, Application metrics, and Distributed tracing. 

- Chapter 12 describes the various deployment patterns that you can use to deploy services, including virtual machines, containers, and serverless. It also 


ABOUT THIS BOOK 

discusses the benefits of using a service mesh, a layer of networking software that mediates communication in a microservice architecture. 

- Chapter 13 explains how to incrementally refactor a monolithic architecture to a microservice architecture by applying the Strangler application pattern: implementing new features as services and extracting modules out of the monolith and converting them to services. 

As you progress through these chapters, you’ll learn about different aspects of the microservice architecture. 

## _About the code_ 

This book contains many examples of source code both in numbered listings and inline with normal text. In both cases, source code is formatted in a fixed-width font like this to separate it from ordinary text. Sometimes code is also **in bold** to highlight code that has changed from previous steps in the chapter, such as when a new feature adds to an existing line of code. In many cases, the original source code has been reformatted; the publisher has added line breaks and reworked indentation to accommodate the available page space in the book. In rare cases, even this was not enough, and listings include line-continuation markers (➥). Additionally, comments in the source code have often been removed from the listings when the code is described in the text. Code annotations accompany many of the listings, highlighting important concepts. 

Every chapter, except chapters 1, 2, and 13, contains code from the companion example application. You can find the code for this application in a GitHub repository: https://github.com/microservices-patterns/ftgo-application. 

## _Book forum_ 

The purchase of Microservices Patterns includes free access to a private web forum run by Manning Publications where you can make comments about the book, ask technical questions, share your solutions to exercises, and receive help from the author and from other users. To access the forum and subscribe to it, point your web browser to https://forums.manning.com/forums/microservices-patterns. You can also learn more about Manning’s forums and the rules of conduct at https://forums .manning.com/forums/about. 

Manning’s commitment to our readers is to provide a venue where a meaningful dialogue between individual readers and between readers and the author can take place. It’s not a commitment to any specific amount of participation on the part of the author, whose contribution to the forum remains voluntary (and unpaid). We suggest you try asking the author some challenging questions lest his interest stray! The forum and the archives of previous discussions will be accessible from the publisher’s website as long as the book is in print. 


ABOUT THIS BOOK 


## _Other online resources_ 

Another great resource for learning the microservice architecture is my website http:// microservices.io. 

Not only does it contain the complete pattern language, it also has links to other resources such as articles, presentations, and example code. 

## _About the author_ 

Chris Richardson is a developer and architect. He is a Java Champion, a JavaOne rock star, and the author of _POJOs in Action_ (Manning, 2006), which describes how to build enterprise Java applications with frameworks such as Spring and Hibernate. 

Chris was also the founder of the original CloudFoundry.com, an early Java PaaS for Amazon EC2. 

Today, he is a recognized thought leader in microservices and speaks regularly at international conferences. Chris is the creator of Microservices.io, a pattern language for microservices. He provides microservices consulting and training to organizations around the world that are adopting the microservice architecture. Chris is working on his third startup: Eventuate.io, an application platform for developing transactional microservices. 


## _about the cover illustration_ 

## _Jefferys_ 

The figure on the cover of Microservices Patterns is captioned “Habit of a Morisco Slave in 1568.” The illustration is taken from Thomas Jefferys’ _A Collection of the Dresses of Different Nations, Ancient and Modern_ (four volumes), London, published between 1757 and 1772. The title page states that these are hand-colored copperplate engravings, heightened with gum arabic. 

Thomas Jefferys (1719–1771) was called “Geographer to King George III.” He was an English cartographer who was the leading map supplier of his day. He engraved and printed maps for government and other official bodies and produced a wide range of commercial maps and atlases, especially of North America. His work as a map maker sparked an interest in local dress customs of the lands he surveyed and mapped, which are brilliantly displayed in this collection. Fascination with faraway lands and travel for pleasure were relatively new phenomena in the late 18th century, and collections such as this one were popular, introducing both the tourist as well as the armchair traveler to the inhabitants of other countries. 

The diversity of the drawings in Jefferys’ volumes speaks vividly of the uniqueness and individuality of the world’s nations some 200 years ago. Dress codes have changed since then, and the diversity by region and country, so rich at the time, has faded away. It’s now often hard to tell the inhabitants of one continent from another. Perhaps, trying to view it optimistically, we’ve traded a cultural and visual diversity for a more varied personal life—or a more varied and interesting intellectual and technical life. 



ABOUT THE COVER ILLUSTRATION 


At a time when it’s difficult to tell one computer book from another, Manning celebrates the inventiveness and initiative of the computer business with book covers based on the rich diversity of regional life of two centuries ago, brought back to life by Jeffreys’ pictures. 


