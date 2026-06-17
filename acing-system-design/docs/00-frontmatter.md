Zhiyong Tan Forewords by Anthony Asta and Michael Elder


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0001-01.png)


**M A N N I N G**


This is a quick lookup guide for common considerations in system design. After you read the book, you can refer to the appropriate sections when you design or review a scalable/distributed system and need a refresher or reference on a particular concept.


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0002-01.png)




|Concept|Chapter(s)/section(s)|
|---|---|
|||
|Tradeoffs<br>A simple full stack design<br>Functional partitioning, centralization of cross-cutting concerns<br>Requirements<br>Logging, monitoring, alerting<br>Distributed databases<br>Sampling<br>Distributed transactions<br>Library vs. service<br>REST, RPC, GraphQL, WebSocket<br>Graceful degradation<br>Data migrations<br>Distributed rate limiting<br>Distributed notifcation service<br>Data quality<br>Exactly-once delivery<br>Personalization<br>Lambda architecture<br>Authentication and authorization|1.1, 2<br>1.4<br>1.4.6, 6<br>2, 3<br>2.5<br>4<br>4.5, 11.8-10<br>5<br>6.6, 12.6<br>6.7<br>2, 3.3<br>7.7<br>8<br>9<br>2.5.5, 10 (also covers auditing)<br>14<br>1.4, 16<br>17<br>13.3, appendix B|


# _Acing the System Design Interview_

ZHIYONG TAN

M A N N I N G Shelter ISland


For online information and ordering of this and other Manning books, please visit www.manning.com. The publisher offers discounts on this book when ordered in quantity.

For more information, please contact

Special Sales Department Manning Publications Co. 20 Baldwin Road PO Box 761 Shelter Island, NY 11964 Email: orders@manning.com

© 2024 Manning Publications Co. All rights reserved.

No part of this publication may be reproduced, stored in a retrieval system, or transmitted, in any form or by means electronic, mechanical, photocopying, or otherwise, without prior written permission of the publisher.

Many of the designations used by manufacturers and sellers to distinguish their products are claimed as trademarks. Where those designations appear in the book, and Manning Publications was aware of a trademark claim, the designations have been printed in initial caps or all caps.

> ∞ Recognizing the importance of preserving what has been written, it is Manning’s policy to have the books we publish printed on acid- free paper, and we exert our best efforts to that end. Recognizing also our responsibility to conserve the resources of our planet, Manning books are printed on paper that is at least 15 percent recycled and processed without the use of elemental chlorine.

The author and publisher have made every effort to ensure that the information in this book was correct at press time. The author and publisher do not assume and hereby disclaim any liability to any party for any loss, damage, or disruption caused by errors or omissions, whether such errors or omissions result from negligence, accident, or any other cause, or from any usage of the information herein.

|Manning Publications Co.|Development editor:  Katie Sposato Johnson|
|---|---|
|20 Baldwin Road|Technical editor:  Mohit Kumar|
|PO Box 761|Senior technical development editor:  Al Scherer|
|Shelter Island, NY 11964|Review editor:  Adriana Sabo|
||Production editor:  Aleksandar DragosavljeviÊ|
||Copy editor:  Katie Petito|
||Technical proofreader:  Victor Duran|
||Typesetter:  Tamara ŠveliÊSabljiÊ|
||Cover designer:  Marija Tudor|


ISBN: 9781633439108 Printed in the United States of America


_To Mom and Dad._


## _contents_

_foreword xvii preface xxi acknowledgments xxiii about this book xxv about the author xxviii about the cover illustration xxix_

**Part 1.... .......................................................................1**

_1_ _**A walkthrough of system design concepts 3**_ 1.1 It is a discussion about tradeoffs

- 1.1 It is a discussion about tradeoffs

- 1.2 Should you read this book? 4

- 1.3 Overview of this book

- 1.4 Prelude—A brief discussion of scaling the various services of a system

_The beginning—A small initial deployment of our app  6 Scaling with GeoDNS  7_[■] _Adding a caching service  8 Content Distribution Network (CDN) 9_[■] _A brief discussion of horizontal scalability and cluster management, continuous integration (CI) and continuous deployment (CD)  10 Functional partitioning and centralization of cross-cutting concerns  13_[■] _Batch and streaming extract, transform, and load (ETL)  17_[■] _Other common services  18_[■] _Cloud vs. bare metal  19_[■] _Serverless—Function as a Service (FaaS) 22 Conclusion—Scaling backend services  23_

**iv**

 contents

**v**

_2_

## _**A typical system design interview flow 24**_

- 2.1 Clarify requirements and discuss tradeoffs

- 2.2 Draft the API specification  28 _Common API endpoints  28_

- 2.3 Connections and processing between users and data

2.4 Design the data model  29 _Example of the disadvantages of multiple services sharing databases  30_[■] _A possible technique to prevent concurrent user update conflicts 31_ 2.5 Logging, monitoring, and alerting 34 _The importance of monitoring 34_[■] _Observability 34 Responding to alerts  36_[■] _Application-level logging tools  37 Streaming and batch audit of data quality  39_[■] _Anomaly detection to detect data anomalies  39_[■] _Silent errors and auditing  40_[■] _Further reading on observability 40_ 2.6 Search bar 40 _Introduction  40_[■] _Search bar implementation with Elasticsearch 41_[■] _Elasticsearch index and ingestion 42 Using Elasticsearch in place of SQL  43_[■] _Implementing search in our services  44_[■] _Further reading on search 44_

2.7 Other discussions  44 _Maintaining and extending the application  44_[■] _Supporting other types of users  45_[■] _Alternative architectural decisions  45 Usability and feedback  45_[■] _Edge cases and new constraints  46_[■] _Cloud native concepts  47_ 2.8 Post-interview reflection and assessment  47 _Write your reflection as soon as possible after the interview  47 Writing your assessment  49_[■] _Details you didn’t mention  49 Interview feedback  50_

- 2.9 Interviewing the company

_3_ _**Non-functional requirements 54**_ 3.1

- 3.1 Scalability 56 _Stateless and stateful services 57_[■] _Basic load balancer concepts 57_

- 3.2 Availability


**vi** contents

- 3.3 Fault-tolerance

_Replication and redundancy  60_[■] _Forward error correction (FEC) and error correction code (ECC)  61_[■] _Circuit breaker  61_[■] _Exponential backoff and retry  62_[■] _Caching responses of other services 62_[■] _Checkpointing  62 Dead letter queue  62_[■] _Logging and periodic auditing  63 Bulkhead  63_[■] _Fallback pattern 64_

- 3.4 Performance/latency and throughput

- 3.5 Consistency 66 _Full mesh  67_[■] _Coordination service 68_[■] _Distributed cache  69_[■] _Gossip protocol  70_[■] _Random Leader Selection  70_

- 3.6 Accuracy

- 3.7 Complexity and maintainability 71 _Continuous deployment (CD)  72_

- 3.8 Cost

- 3.9 Security

- 3.10 Privacy 73 _External vs. internal services 74_

- 3.11 Cloud native

- 3.12 Further reading

_4_ _**Scaling databases 77**_ 4.1

- 4.1 Brief prelude on storage services

- 4.2 When to use vs. avoid databases

- 4.3 Replication

   - _Distributing replicas 80_[■] _Single-leader replication  80 Multi-leader replication  84_[■] _Leaderless replication  85 HDFS replication  85_[■] _Further reading  87_

- 4.4 Scaling storage capacity with sharded databases   87 _Sharded RDBMS 88_

- 4.5 Aggregating events

   - _Single-tier aggregation 89_[■] _Multi-tier aggregation     89 Partitioning   90_[■] _Handling a large key space   91 Replication and fault-tolerance   92_


**vii** contents

- 4.6 Batch and streaming ETL 93

   - _A simple batch ETL pipeline 93_[■] _Messaging terminology 95 Kafka vs. RabbitMQ 96_[■] _Lambda architecture   98_

- 4.7 Denormalization

- 4.8 Caching  99 _Read strategies 100_[■] _Write strategies  101_

- 4.9 Caching as a separate service

- 4.10 Examples of different kinds of data to cache and how to cache them

- 4.11 Cache invalidation

   - _Browser cache invalidation 105_[■] _Cache invalidation in caching services 105_

- 4.12 Cache warming

- 4.13 Further reading 107 _Caching references  107_

_5_ _**Distributed transactions 109**_ 5.1

- 5.1 Event Driven Architecture (EDA) 110

- 5.2 Event sourcing

- 5.3 Change Data Capture (CDC) 112

- 5.4 Comparison of event sourcing and CDC 113

- 5.5 Transaction supervisor

- 5.6 Saga

   - _Choreography 115_[■] _Orchestration  117_[■] _Comparison  119_

- 5.7 Other transaction types

- 5.8 Further reading

_6_ _**Common services for functional partitioning 122**_ 6.1 Common functionalities of various services

- 6.1 Common functionalities of various services

   - _Security 123_[■] _Error-checking 124_[■] _Performance and availability 124_[■] _Logging and analytics 124_

- 6.2 Service mesh / sidecar pattern


**viii** contents

- 6.3 Metadata service

- 6.4 Service discovery

- 6.5 Functional partitioning and various frameworks 128 _Basic system design of an app 128_[■] _Purposes of a web server app 129_[■] _Web and mobile frameworks  130_

- 6.6 Library vs. service  134 _Language specific vs. technology-agnostic  135_[■] _Predictability of latency  136_[■] _Predictability and reproducibility of behavior  136_[■] _Scaling considerations for libraries  136 Other considerations  137_

6.7 Common API paradigms 137 _The Open Systems Interconnection (OSI) model  137 REST  138_[■] _RPC (Remote Procedure Call)  140 GraphQL  141_[■] _WebSocket  142_[■] _Comparison  142_

**Part 2.... ...................................................................145**

_7_ _**Design Craigslist 147**_ 7.1

- 7.1 User stories and requirements

- 7.2 API  149

- 7.3 SQL database schema

- 7.4 Initial high-level architecture

- 7.5 A monolith architecture

- 7.6 Using a SQL database and object store

- 7.7 Migrations are troublesome

- 7.8 Writing and reading posts

- 7.9 Functional partitioning

- 7.10 Caching

- 7.11 CDN  160

- 7.12 Scaling reads with a SQL cluster

- 7.13 Scaling write throughput

- 7.14 Email service

- 7.15 Search


**ix** contents

- 7.16 Removing old posts

- 7.17 Monitoring and alerting

- 7.18 Summary of our architecture discussion so far

- 7.19 Other possible discussion topics

   - _Reporting posts 164_[■] _Graceful degradation  164 Complexity  164_[■] _Item categories/tags  166_[■] _Analytics and recommendations  166_[■] _A/B testing  167_[■] _Subscriptions and saved searches  167_[■] _Allow duplicate requests to the search service  168_[■] _Avoid duplicate requests to the search service  168_[■] _Rate limiting  169_[■] _Large number of posts  169_[■] _Local regulations  169_

_8_ _**Design a rate-limiting service 171**_ 8.1

- 8.1 Alternatives to a rate-limiting service, and why they are infeasible

- 8.2 When not to do rate limiting

- 8.3 Functional requirements

- 8.4 Non-functional requirements

   - _Scalability  175_[■] _Performance  175_[■] _Complexity  175 Security and privacy  176_[■] _Availability and faulttolerance  176_[■] _Accuracy  176_[■] _Consistency  176_

- 8.5 Discuss user stories and required service components

- 8.6 High-level architecture

- 8.7 Stateful approach/sharding

- 8.8 Storing all counts in every host

_High-level architecture 182_[■] _Synchronizing counts 185_

- 8.9 Rate-limiting algorithms

_Token bucket  188_[■] _Leaky bucket  189_[■] _Fixed window counter 190_[■] _Sliding window log  192_[■] _Sliding window counter  193_

- 8.10 Employing a sidecar pattern

- 8.11 Logging, monitoring, and alerting

- 8.12 Providing functionality in a client library

- 8.13 Further reading contents

**x**

## _9_ _**Design a notification/alerting service 196**_ 9.1

- 9.1 Functional requirements

_Not for uptime monitoring 197_[■] _Users and data 197 Recipient channels 198_[■] _Templates 198_[■] _Trigger conditions 199_[■] _Manage subscribers, sender groups, and recipient groups 199_[■] _User features 199_[■] _Analytics 200_

- 9.2 Non-functional requirements

- 9.3 Initial high-level architecture

- 9.4 Object store: Configuring and sending notifications

- 9.5 Notification templates  207 _Notification template service 207_[■] _Additional features 209_

- 9.6 Scheduled notifications

- 9.7 Notification addressee groups

- 9.8 Unsubscribe requests

- 9.9 Handling failed deliveries

- 9.10 Client-side considerations regarding duplicate notifications

- 9.11 Priority

- 9.12 Search

- 9.13 Monitoring and alerting

- 9.14 Availability monitoring and alerting on the notification/ alerting service

- 9.15 Other possible discussion topics

- 9.16 Final notes

_10_ _**Design a database batch auditing service 223**_ 10.1

- 10.1 Why is auditing necessary? 224

- 10.2 Defining a validation with a conditional statement on a SQL query’s result

- 10.3 A simple SQL batch auditing service

   - _An audit script 229_[■] _An audit service 230_

- 10.4 Requirements


**xi** contents

- 10.5 High-level architecture 233 _Running a batch auditing job  234_[■] _Handling alerts 235_

- 10.6 Constraints on database queries 237 _Limit query execution time 238_[■] _Check the query strings before submission 238_[■] _Users should be trained early 239_

- 10.7 Prevent too many simultaneous queries

- 10.8 Other users of database schema metadata

- 10.9 Auditing a data pipeline

- 10.10 Logging, monitoring, and alerting

- 10.11 Other possible types of audits 242 _Cross data center consistency audits 242_[■] _Compare upstream and downstream data 243_

- 10.12 Other possible discussion topics

- 10.13 References

_11_

## _**Autocomplete/typeahead 245**_

- 11.1 Possible uses of autocomplete

- 11.2 Search vs. autocomplete

- 11.3 Functional requirements

_Scope of our autocomplete service 248_[■] _Some UX (user experience) details 248_[■] _Considering search history 249 Content moderation and fairness 250_

- 11.4 Nonfunctional requirements

- 11.5 Planning the high-level architecture

- 11.6 Weighted trie approach and initial high-level architecture

- 11.7 Detailed implementation

_Each step should be an independent task 255_[■] _Fetch relevant logs from Elasticsearch to HDFS 255_[■] _Split the search strings into words, and other simple operations 255_[■] _Filter out inappropriate words 256_[■] _Fuzzy matching and spelling correction 258_[■] _Count the words 259_[■] _Filter for appropriate words 259_[■] _Managing new popular unknown words 259 Generate and deliver the weighted trie 259_


**xii** contents

- 11.8 Sampling approach

- 11.9 Handling storage requirements

- 11.10 Handling phrases instead of single words 263 _Maximum length of autocomplete suggestions 263 Preventing inappropriate suggestions 263_

- 11.11 Logging, monitoring, and alerting

- 11.12 Other considerations and further discussion

_12_ _**Design Flickr 266**_

- 12.1 User stories and functional requirements

- 12.2 Non-functional requirements

- 12.3 High-level architecture

- 12.4 SQL schema

- 12.5 Organizing directories and files on the CDN  271

- 12.6 Uploading a photo

   - _Generate thumbnails on the client  272_[■] _Generate thumbnails on the backend  276_[■] _Implementing both server-side and clientside generation 281_

- 12.7 Downloading images and data  282 _Downloading pages of thumbnails 282_

- 12.8 Monitoring and alerting

- 12.9 Some other services

_Premium features 283_[■] _Payments and taxes service 283 Censorship/content moderation 283_[■] _Advertising 284 Personalization 284_

- 12.10 Other possible discussions

_13_ _**Design a Content Distribution Network (CDN) 287**_ 13.1

- 13.1 Advantages and disadvantages of a CDN  288

_Advantages of using a CDN  288_[■] _Disadvantages of using a CDN  289_[■] _Example of an unexpected problem from using a CDN to serve images  290_

- 13.2 Requirements


**xiii** contents

13.3 CDN authentication and authorization 291 _Steps in CDN authentication and authorization 292 Key rotation 294_

13.4 High-level architecture  294 13.5 Storage service  295 _In-cluster  296_[■] _Out-cluster  296_[■] _Evaluation  296_

13.6 Common operations  297 _Reads–Downloads  297_[■] _Writes–Directory creation, file upload, and file deletion  301_

13.7 Cache invalidation 306 13.8 Logging, monitoring, and alerting  306 13.9 Other possible discussions on downloading media files

_14_

## _**Design a text messaging app 308**_

14.1 Requirements 309 14.2 Initial thoughts  310 14.3 Initial high-level design 310 14.4 Connection service 312 _Making connections  312_[■] _Sender blocking 312_

14.5 Sender service

_Sending a message 316_[■] _Other discussions 319_

14.6 Message service 320 14.7 Message sending service 321 _Introduction 321_[■] _High-level architecture  322_[■] _Steps in sending a message  324_[■] _Some questions  325_[■] _Improving availability  325_ 14.8 Search  326 14.9 Logging, monitoring, and alerting

14.10 Other possible discussion points


**xiv** contents

_15_

## _**Design Airbnb 329**_

- 15.1 Requirements

- 15.2 Design decisions

   - _Replication  334_[■] _Data models for room availability  334 Handling overlapping bookings  335_[■] _Randomize search results  335_[■] _Lock rooms during booking flow  335_

- 15.3 High-level architecture

- 15.4 Functional partitioning

- 15.5 Create or update a listing

- 15.6 Approval service

- 15.7 Booking service

- 15.8 Availability service

- 15.9 Logging, monitoring, and alerting

- 15.10 Other possible discussion points  351 _Handling regulations  352_

_16_ _**Design a news feed 354**_ 16.1

- 16.1 Requirements

- 16.2 High-level architecture

- 16.3 Prepare feed in advance

- 16.4 Validation and content moderation

   - _Changing posts on users’ devices 365_[■] _Tagging posts 365 Moderation service 367_

- 16.5 Logging, monitoring, and alerting  368 _Serving images as well as text  368_[■] _High-level architecture   369_

- 16.6 Other possible discussion points

## _**Design a dashboard of top 10 products on Amazon by sales** 17_ _**volume 374**_

- 17.1 Requirements

- 17.2 Initial thoughts contents

**xv**

- 17.3 Initial high-level architecture

17.4 Aggregation service  378 _Aggregating by product ID  379_[■] _Matching host IDs and product IDs  379_[■] _Storing timestamps  380_[■] _Aggregation process on a host  380_

- 17.5 Batch pipeline

- 17.6 Streaming pipeline

_Hash table and max-heap with a single host  383 Horizontal scaling to multiple hosts and multi-tier aggregation  385_

- 17.7 Approximation  386 _Count-min sketch  388_

- 17.8 Dashboard with Lambda architecture

- 17.9 Kappa architecture approach

_Lambda vs. Kappa architecture 391_[■] _Kappa architecture for our dashboard 392_

- 17.10 Logging, monitoring, and alerting

- 17.11 Other possible discussion points

- 17.12 References

_A_ _**Monoliths vs. microservices 395**_ A.1

- A.1 Disadvantages of monoliths

- A.2 Advantages of monoliths

- A.3 Advantages of services

_Agile and rapid development and scaling of product requirements and business functionalities 397_[■] _Modularity and replaceability  397_[■] _Failure isolation and fault-tolerance  397 Ownership and organizational structure  398_

- A.4 Disadvantages of services

_Duplicate components  398_[■] _Development and maintenance costs of additional components  399_[■] _Distributed transactions  400_[■] _Referential integrity  400_[■] _Coordinating feature development and deployments that span multiple services  400_[■] _Interfaces  401_

- A.5 References


**xvi** contents

## _B_ _**OAuth 2.0 authorization and OpenID Connect   authentication 403**_

- B.1 Authorization vs. authentication

- B.2 Prelude: Simple login, cookie-based authentication

- B.3 Single sign-on (SSO)  404

- B.4 Disadvantages of simple login  404 _Complexity and lack of maintainability  405_[■] _No partial authorization  405_

- B.5 OAuth 2.0 flow  406 _OAuth 2.0 terminology  407_[■] _Initial client setup  407 Back channel and front channel  409_

- B.6 Other OAuth 2.0 flows

- B.7 OpenID Connect authentication

_C_ _**C4 Model 413**_

_D_ _**Two-phase commit (2PC) 418**_

_index 422_


## _foreword_

Over the course of the last 20 years, I have focused on building teams of distributed systems engineers at some of the largest tech companies in the industry (Google, Twitter, and Uber). In my experience, the fundamental pattern of building high-functioning teams at these companies is the ability to identify engineering talent that can demonstrate their mastery of system design through the interview process. _Acing the System Design Interview_ is an invaluable guide that equips aspiring software engineers and seasoned professionals alike with the knowledge and skills required to excel in one of the most critical aspects of technical interviews. In an industry where the ability to design scalable and reliable systems is paramount, this book is a treasure trove of insights, strategies, and practical tips that will undoubtedly help readers navigate the intricacies of the system design interview process.

As the demand for robust and scalable systems continues to soar, companies are increasingly prioritizing system design expertise in their hiring process. An effective system design interview not only assesses a candidate’s technical prowess but also evaluates their ability to think critically, make informed decisions, and solve complex problems. Zhiyong’s perspective as an experienced software engineer and his deep understanding of the system design interview landscape make him the perfect guide for anyone seeking to master this crucial skill set.

In this book, Zhiyong presents a comprehensive roadmap that takes readers through each step of the system design interview process. After an overview of the fundamental principles and concepts, he then delves into various design aspects, including scalability, reliability, performance, and data management. With clarity and precision, he breaks down each topic, providing concise explanations and real-world examples that illustrate their practical application. He is able to demystify the system design interview

**xvii**


**xviii** foreword process by drawing on his own experiences and interviews with experts in the field. He offers valuable insights into the mindset of interviewers, the types of questions commonly asked, and the key factors interviewers consider when evaluating a candidate’s performance. Through these tips, he not only helps readers understand what to expect during an interview but also equips them with the confidence and tools necessary to excel in this high-stakes environment.

By combining the theory chapters of part 1 with the practical application chapters of part 2, Zhiyong ensures that readers not only grasp the theoretical foundations but also cultivate the ability to apply that knowledge to real-world scenarios. Moreover, this book goes beyond technical know-how and emphasizes the importance of effective communication in the system design interview process. Zhiyong explores strategies for effectively articulating ideas, presenting solutions, and collaborating with interviewers. This holistic approach recognizes that successful system design is not solely dependent on technical brilliance but also on the ability to convey ideas and work collaboratively with others.

Whether you are preparing for a job interview or seeking to enhance your system design expertise, this book is an essential companion that will empower you to tackle even the most complex system design challenges with confidence and finesse.

So, dive into the pages ahead, embrace the knowledge and insights, and embark on a journey to master the art of building scalable and reliable systems. You will undoubtedly position yourself as an invaluable asset to any organization and pave the way for a successful career as a software engineer.

Start your path to acing the system design interview!

—Anthony Asta Director of Engineering at LinkedIn (ex-Engineering Management at Google, Twitter, and Uber)


Software development is a world of continuous _everything._ Continuous improvement, continuous delivery, continuous monitoring, and continuous re-evaluation of user needs and capacity expectations are the hallmarks of any significant software system. If you want to succeed as a software engineer, you must have a passion for continuous learning and personal growth. With passion, software engineers can literally change how our society connects with each other, how we share knowledge, and how we manage our lifestyles.

Software trends are always evolving, from the trendiest programming language or framework to programmable cloud-native infrastructure. If you stick with this industry for decades, you’ll see these transitions several times over, just like I have. However, one immutable constant remains through it all: understanding the systematic reasoning of how a software system manages work, organizes its data, and interacts with humans is critical to being an effective software engineer or technology leader.

As a software engineer and then IBM Distinguished Engineer, I’ve seen firsthand how design tradeoffs can make or break the successful outcomes of a software system. Whether you’re a new engineer seeking your first role or a seasoned technology veteran looking for a new challenge in a new company, this book can help you refine your approach to reasoning by explaining the tradeoffs inherent with any design choices.

_Acing the System Design Interview_ brings together and organizes the many dimensions of system design that you need to consider for any software system. Zhiyong Tan has brilliantly organized a crash course in the fundamentals of system design tradeoffs and presents many real-world case studies that you can use to reinforce your readiness for even the most challenging of system design interviews.

Part 1 of the book begins with an informative survey of critical aspects of system design. Starting with non-functional requirements, you’ll learn about many of the common dimensions that you must keep in mind while considering system design tradeoffs. Following an elaboration on , you will walk through how to organize the application programming interface (API) specification to explain how your system design addresses

**xix**

 foreword

**xx** the use cases of the interview problem statement. Behind the API, you’ll learn several industry best practices for organizing the system data model using industry-standard datastores and patterns for managing distributed transactions. And beyond addressing the prima facie use cases, you’ll learn about key aspects of system operation, including modern approaches to observability and log management.

In part 2, ride along for 11 distinct system design problems, from text messaging to Airbnb. In each interview problem, you can pick up new skills on how to tease out the right questions to organize the non-functional system requirements, followed by what tradeoffs to invest in further discussion. System design is a skill set often rooted in an experience that lends itself well to learning from prior art and examples based on others’ experiences. If you internalize the many lessons and wisdom from the examples presented in this book, you’ll be well prepared for even the most challenging system design interview problems.

I’m excited to see the contribution that Zhiyong Tan has made to the industry with the following work. Whether you are approaching the material after a recent graduation or after many years of already working in the industry, I hope you’ll find new opportunities for personal growth as I did when absorbing the experiences represented in _Acing the System Design Interview_ .

—Michael D. Elder Distinguished Engineer & Senior Director, PayPal Former IBM Distinguished Engineer and IBM Master Inventor, IBM


## _re ace py f_

It is Wednesday at 4 p.m. As you leave your last video interview for your dream company, you are filled with a familiar mix of feelings: exhaustion, frustration, and déjà vu. You already know that in one to two days you will receive the email that you have seen so many times in your years as an engineer. “Thank you for your interest in the senior software engineer role at XXX. While your experience and skill set are impressive, after much consideration, we regret to inform you that we will not be proceeding with your candidacy.”

It was the system design interview again. You had been asked to design a photosharing app, and you made a brilliant design that is scalable, resilient, and maintainable. It used the latest frameworks and employed software development lifecycle best practices. But you could see that the interviewer was unimpressed. They had that faraway look in their eyes and the bored, calm, polite tone that told you they believed they spent their time with you on this interview to be professional and to deliver “a great candidate experience.”

This is your seventh interview attempt at this company in four years, and you have also interviewed repeatedly at other companies you really want to join. It is your dream to join this company, which has a userbase of billions and develops some of the most impressive developer frameworks and programming languages that dominate the industry. You know that the people you will meet and what you will learn at this company will serve you well in your career and be a great investment of your time.

Meanwhile, you have been promoted multiple times at the companies you have worked at, and you’re now a senior software engineer, making it even harder when you don’t pass the interviews for the equivalent job at your dream companies. You have been a tech lead of multiple systems, led and mentored teams of junior engineers, and authored and discussed system designs with senior and staff engineers, making tangible and valuable contributions to multiple system designs. Before each interview at a dream company, you read through all the engineering blog posts and watched all their engineering talks published in the last three years. You have also read every highly rated

**xxi**


**xxii** preface book on microservices, data-intensive applications, cloud-native patterns, and domaindriven design. Why can’t you just nail those system design interviews?

Has it just been bad luck all these attempts? The supply versus demand of candidates versus jobs at those companies? The statistical unlikelihood of being selected? Is it a lottery? Do you simply have to keep trying every six months until you get lucky? Do you need to light incense and make more generous offerings to the interview/performance review/promotion gods (formerly known as the exam gods back in school)?

Taking a deep breath and closing your eyes to reflect, you realize that there is so much you can improve in those 45 minutes that you had to discuss your system design. (Even though each interview is one hour, between introductions and Q&A, you essentially have only 45 minutes to design a complex system that typically evolves over years.) Chatting with your fellow engineer friends confirms your hypothesis. You did not thoroughly clarify the system requirements. You assumed that what was needed was a minimum viable product for a backend that serves mobile apps in storing and sharing photos, and you started jotting down sample API specifications. The interviewer had to interrupt you to clarify that it should be scalable to a billion users. You drew a system design diagram that included a CDN, but you didn’t discuss the tradeoffs and alternatives of your design choices. You were not proactive in suggesting other possibilities beyond the narrow scope that the interviewer gave you at the beginning of the interview, such as analytics to determine the most popular photos or personalization to recommend photos to share with a user. You didn’t ask the right questions, and you didn’t mention important concepts like logging, monitoring, and alerting.

You realize that even with your engineering experience and your hard work in studying and reading to keep up with industry best practices and developments, the breath of system design is vast, and you lack much formal knowledge and understanding of many system design components that you’ll never directly touch, like load balancers or certain NoSQL databases, so you cannot create a system design diagram of the level of completeness that the interviewer expects, and you cannot fluently zoom in and out when discussing various levels of the system. Until you learn to do so, you cannot meet the hiring bar, and you cannot truly understand a complex system or ascend to a more senior engineering leadership or mentorship role.


## _acknowled ments g_

I thank my wife Emma for her consistent encouragement in my various endeavors, diving into various difficult and time-consuming projects at work, writing various apps, and writing this book. I thank my daughter Ada, my inspiration to endure the frustration and tedium of coding and writing.

I thank my brother Zhilong, who gave me much valuable feedback on my drafts and is himself an expert in system design and video encoding protocols at Meta. I thank my big sister Shumin for always being supportive and pushing me to achieve more.

Thank you, Mom and Dad, for your sacrifices that made it all possible.

I wish to thank the staff at Manning for all their help, beginning with my book proposal reviewers Andreas von Linden, Amuthan Ganeshan, Marc Roulleau, Dean Tsaltas, and Vincent Liard. Amuthan provided detailed feedback and asked good questions about the proposed topics. Katie Sposato Johnson was my guide for the 1.5-year process of reviewing and revising the manuscript. She proofread each chapter, and her feedback considerably improved the book’s presentation and clarity. My technical editor, Mohit Chilkoti, provided many good suggestions to improve clarity and pointed out errors. My review editor Adriana Sabo and her team organized the panel reviews, which gathered invaluable feedback that I used to substantially improve this book. To all the reviewers: Abdul Karim Memon, Ajit Malleri, Alessandro Buggin, Alessandro Campeis, Andres Sacco, Anto Aravinth, Ashwini Gupta, Clifford Thurber, Curtis Washington, Dipkumar Patel, Fasih Khatib, Ganesh Swaminathan, Haim Raman, Haresh Lala, Javid Asgarov, Jens Christian B. Madsen, Jeremy Chen, Jon Riddle, Jonathan Reeves, Kamesh Ganesan, Kiran Anantha, Laud Bentil, Lora Vardarova, Matt Ferderer, Max Sadrieh, Mike B., Muneeb Shaikh, Najeeb Arif, Narendran Solai Sridharan, Nolan To, Nouran Mahmoud, Patrick Wanjau, Peiti Li, Péter Szabó, Pierre-Michel Ansel, Pradeep

**xxiii**


**xxiv** acknowledgments

Chellappan, Rahul Modpur, Rajesh Mohanan, Sadhana Ganapathiraju, Samson Hailu, Samuel Bosch, Sanjeev Kilarapu, Simeon Leyzerzon, Sravanthi Reddy, Vincent Ngo, Zoheb Ainapore, Zorodzayi Mukuya, your suggestions helped make this a better book.

I’d like to thank Marc Roulleau, Andres von Linden, Amuthan Ganesan, Rob Conery, and Scott Hanselman for their support and their recommendations for additional resources.

I wish to thank the tough northerners (not softie southerners) Andrew Waldron and Ian Hough. Andy pushed me to fill in many useful gritty details across all the chapters and guided me on how to properly format the figures to fit the pages. He helped me discover how much more capable I am than I previously thought. Aira DučiÊ and Matko Hrvatin helped much with marketing, and Dragana Butigan-BerberoviÊ and Ivan MartinoviÊ did a great job on formatting. Stjepan JurekoviÊ and Nikola DimitrijeviÊ guided me through my promo video.


## _about this book_

This book is about web services. A candidate should discuss the system’s requirements and then design a system of reasonable complexity and cost that fulfills those requirements.

Besides coding interviews, system design interviews are conducted for most software engineering, software architecture, and engineering manager interviews.

The ability to design and review large-scale systems is regarded as more important with increasing engineering seniority. Correspondingly, system design interviews are given more weight in interviews for senior positions. Preparing for them, both as an interviewer and candidate, is a good investment of time for a career in tech.

The open-ended nature of system design interviews makes it a challenge to prepare for and know how or what to discuss during an interview. Moreover, there are few dedicated books on this topic. This is because system design is an art and a science. It is not about perfection. It is about making tradeoffs and compromises to design the system we can achieve with the given resources and time that most closely suits current and possible future requirements. With this book, the reader can build a knowledge foundation or identify and fill gaps in their knowledge.

A system design interview is also about verbal communication skills, quick thinking, asking good questions, and handling performance anxiety. This book emphasizes that one must effectively and concisely express one’s system design expertise within a lessthan-1-hour interview and drive the interview in the desired direction by asking the interviewer the right questions. Reading this book, along with practicing system design discussions with other engineers, will allow you to develop the knowledge and fluency required to pass system design interviews and participate well in designing systems in the organization you join. It can also be a resource for interviewers who conduct system design interviews.

**xxv**


**xxvi** about this book

## _Who should read this book_

This book is for software engineers, software architects, and engineering managers looking to advance their careers.

This is not an introductory software engineering book. This book is best used after one has acquired a minimal level of industry experience—perhaps a student doing a first internship may read the documentation websites and other introductory materials of unfamiliar tools and discuss them together with other unfamiliar concepts in this book with engineers at her workplace. This book discusses how to approach system design interviews and does not duplicate introductory material that we can easily find online or in other books. At least intermediate proficiency in coding and SQL are assumed.

## _How this book is organized: A roadmap_

This book has 17 chapters across two parts and four brief appendixes.

Part 1 is presented like a typical textbook, with chapters that cover various topics discussed in a system design interview.

Part 2 consists of discussions of sample interview questions that reference the concepts covered in part 1. Each chapter was chosen to use some or most of the concepts covered in part 1. This book focuses on general web services, and we exclude highly specialized and complex topics like payments, video streaming, location services, or database development. Moreover, in my opinion, asking a candidate to spend 10 minutes to discuss database linearizability or consistency topics like coordination services, quorum, or gossip protocols does not reveal any expertise other than having read enough to discuss the said topic for 10 minutes. An interview for a specialized role that requires expertise on a highly specialized topic should be the focus of the entire interview and deserves its own dedicated books. In this book, wherever such topics are referenced, we refer to other books or resources that are dedicated to these said topics.

## _liveBook discussion forum_

Purchase of _Acing the System Design Interview_ includes free access to liveBook, Manning’s online reading platform. Using liveBook’s exclusive discussion features, you can attach comments to the book globally or to specific sections or paragraphs. It’s a snap to make notes for yourself, ask and answer technical questions, and receive help from the author and other users. To access the forum, go to https://livebook.manning.com/book/acing-the-system-design-interview/discussion.Youcanalsolearnmoreabout Manning’s forums and the rules of conduct at https://livebook.manning.com/discussion.Manning’scommitmenttoourreadersisto provide a venue where a meaningful dialogue between individual readers and between readers and the author can take place. It is not a commitment to any specific amount of participation on the part of the author, whose contribution to the forum remains voluntary (and unpaid). We suggest you try


**xxvii** about this book asking the author some challenging questions lest his interest stray! The forum and the archives of previous discussions will be accessible from the publisher’s website as long as the book is in print.

## _Other online resources_

- https://github.com/donnemartin/system-design-primer-https://bigmachine.io/products/mission-interview/-http://geeksforgeeks.com-http://algoexpert.io-https://www.learnbay.io/-http://leetcode.com-https://bigmachine.io/products/mission-interview/##_abouttheauthor_

Zhiyong Tan is a manager at PayPal. Previously, he was a senior full-stack engineer at Uber, a software engineer at Teradata, and a data engineer at various startups. Over the years, he has been on both sides of the table in numerous system design interviews. Zhiyong has also received prized job offers from prominent companies such as Amazon, Apple, and ByteDance/TikTok.

## about the technical editor

Mohit Chilkoti is a Platform Architect at Chargebee. He is an AWS-certified Solutions Architect and has designed an Alternative Investment Trading Platform for Morgan Stanley and a Retail Platform for Tekion Corp.

**xxviii**


## _about the cover illustration_

The figure on the cover of _Acing the System Design Interview_ is “Femme Tatar Tobolsk,” or “A Tatar woman from the Tobolsk region,” taken from a collection by Jacques Grasset de Saint-Sauveur, published in 1784. The illustration is finely drawn and colored by hand.

In those days, it was easy to identify where people lived and what their trade or station in life was just by their dress. Manning celebrates the inventiveness and initiative of the computer business with book covers based on the rich diversity of regional culture centuries ago, brought back to life by pictures from collections such as this one.

**xxix**


