<!-- PAGE 54 -->
 54 -->

# Chapter 1  A walkthrough of system design concepts
For these reasons, many companies adopt a multi-cloud strategy, using multiple 
cloud vendors instead of a single one, so these companies can migrate away from any 
particular vendor at short notice should the need suddenly arise.
### 1.4.10	 Serverless: Function as a Service (FaaS)
If a certain endpoint or function is infrequently used or does not have strict latency 
requirements, it may be cheaper to implement it as a function on a Function as a Ser-
vice (FaaS) platform, such as AWS Lambda or Azure Functions. Running a function 
only when needed means that there does not need to be hosts continuously waiting for 
requests to this function. 
OpenFaaS and Knative are open-source FaaS solutions that we can use to support 
FaaS on our own cluster or as a layer on AWS Lambda to improve the portability of our 
functions between cloud platforms. As of this book’s writing, there is no integration 
between open-source FaaS solutions and other vendor-managed FaaS such as Azure 
Functions. 
Lambda functions have a timeout of 15 minutes. FaaS is intended to process requests 
that can complete within this time. 
In a typical configuration, an API gateway service receives incoming requests and 
triggers the corresponding FaaS functions. The API gateway is necessary because there 
needs to be a continuously running service that waits for requests. 
Another benefit of FaaS is that service developers need not manage deployments 
and scaling and can concentrate on coding their business logic. 
Note that a single run of a FaaS function requires steps such as starting a Docker 
container, starting the appropriate language runtime (Java, Python, Node.js, etc.) and 
running the function, and terminating the runtime and Docker container. This is com-
monly referred to as cold start. Frameworks that take minutes to start, such as certain 
Java frameworks, may be unsuitable for FaaS. This spurred the development of JDKs 
with fast startups and low memory footprints such as GraalVM (https://www.graalvm 
.org/). 
Why is this overhead required? Why can’t all functions be packaged into a single 
package and run across all host instances, similar to a monolith? The reasons are the 
disadvantages of monoliths (refer to appendix A). 
Why not have a frequently-used function deployed to certain hosts for a certain 
amount of time, (i.e., with an expiry)? Such a system is similar to auto-scaling microser-
vices and can be considered when using frameworks that take a long time to start. 
The portability of FaaS is controversial. At first glance, an organization that has done 
much work in a proprietary FaaS like AWS Lambda can become locked in; migrating 
to another solution becomes difficult, time-consuming, and expensive. Open-source 
FaaS platforms are not a complete solution, because one must provision and maintain 
one’s own hosts, which defeats the scalability purpose of FaaS. This problem becomes 
especially significant at scale, when FaaS may become much more expensive than bare 
metal. 


<!-- PAGE 55 -->
 55 -->

	
Summary
However, a function in FaaS can be written in two layers: an inner layer/function that 
contains the main logic of the function, wrapped by an outer layer/function that con-
tains vendor-specific configurations. To switch vendors for any function, one only needs 
to change the outer function. 
Spring Cloud Function (https://spring.io/projects/spring-cloud-function) is an 
emerging FaaS framework that is a generalization of this concept. It is supported by 
AWS Lambda, Azure Functions, Google Cloud Functions, Alibaba Function Compute, 
and may be supported by other FaaS vendors in the future. 
### 1.4.11	 Conclusion: Scaling backend services
In the rest of part 1, we discuss concepts and techniques to scale a backend service. 
A frontend/UI service is usually a Node.js service, and all it does is serve the same 
browser app written in a JavaScript framework like ReactJS or Vue.js to any user, so 
it can be scaled simply by adjusting the cluster size and using GeoDNS. A backend 
service is dynamic and can return a different response to each request. Its scalability 
techniques are more varied and complex. We discussed functional partitioning in the 
previous example and will occasionally touch on it as needed.
Summary
¡ System design interview preparation is critical to your career and also benefits 
your company.
¡ The system design interview is a discussion between engineers about designing a 
software system that is typically provided over a network.
¡ GeoDNS, caching, and CDN are basic techniques for scaling our service.
¡ CI/CD tools and practices allow feature releases to be faster with fewer bugs. 
They also allow us to divide our users into groups and expose each group to a 
different version of our app for experimentation purposes.
¡ Infrastructure as Code tools like Terraform are useful automation tools for clus-
ter management, scaling, and feature experimentation.
### ¡ Functional partitioning and centralization of cross-cutting concerns are key ele-
ments of system design.
¡ ETL jobs can be used to spread out the processing of traffic spikes over a longer 
time period, which reduces our required cluster size.
¡ Cloud hosting has many advantages. Cost is often but not always an advantage. 
There are also possible disadvantages such as vendor lock-in and potential pri-
## vacy and security risks.
¡ Serverless is an alternative approach to services. In exchange for the cost 
advantage of not having to keep hosts constantly running, it imposes limited 
functionality.


<!-- PAGE 56 -->
 56 -->

A typical system 
design interview flow
This chapter covers
¡ Clarifying system requirements and optimizing 	
	 possible tradeoffs
¡ Drafting your system’s API specification
¡ Designing the data models of your system
¡ Discussing concerns like logging, monitoring, 	
## and alerting or search
¡ Reflecting on your interview experience and 	
	 evaluating the company
In this chapter, we will discuss a few principles of system design interviews that must 
be followed during your 1 hour system design interview. When you complete this 
book, refer to this list again. Keep these principles in mind during your interviews: 
1	 Clarify functional and non-functional requirements (refer to chapter 3), such 
as QPS (queries per second) and P99 latency. Ask whether the interviewer 
desires wants to start the discussion from a simple system and then scale up and 
design more features or start with immediately designing a scalable system. 
2	 Everything is a tradeoff. There is almost never any characteristic of a system 
that is entirely positive and without tradeoffs. Any new addition to a system to 


<!-- PAGE 57 -->
 57 -->

	
﻿
improve scalability, consistency, or latency also increases complexity and cost and 
requires security, logging, monitoring, and alerting. 
3	 Drive the interview. Keep the interviewer’s interest strong. Discuss what they 
want. Keep suggesting topics of discussion to them. 
4	 Be mindful of time. As just stated, there is too much to discuss in 1 hour. 
5	 Discuss logging, monitoring, alerting, and auditing. 
6	 Discuss testing and maintainability including debuggability, complexity, security, 
and privacy. 
7	 Consider and discuss graceful degradation and failure in the overall system and 
every component, including silent and disguised failures. Errors can be silent. 
Never trust anything. Don’t trust external or internal systems. Don’t trust your 
own system. 
8	 Draw system diagrams, flowcharts, and sequence diagrams. Use them as visual 
aids for your discussions. 
9	 The system can always be improved. There is always more to discuss. 
A discussion of any system design interview question can last for many hours. You will 
need to focus on certain aspects by suggesting to the interviewer various directions of 
discussion and asking which direction to go. You have less than 1 hour to communicate 
or hint the at full extent of your knowledge. You must possess the ability to consider 
and evaluate relevant details and to smoothly zoom up and down to discuss high-level 
architecture and relationships and low-level implementation details of every compo-
nent. If you forget or neglect to mention something, the interviewer will assume you 
don’t know it. One should practice discussing system design questions with fellow engi-
neers to improve oneself in this art. Prestigious companies interview many polished 
candidates, and every candidate who passes is well-drilled and speaks the language of 
system design fluently. 
The question discussions in this section are examples of the approaches you can take 
to discuss various topics in a system design interview. Many of these topics are common, 
so you will see some repetition between the discussions. Pay attention to the use of com-
mon industry terms and how many of the sentences uttered within the time-limited 
discussion are filled with useful information. 
The following list is a rough guide. A system design discussion is dynamic, and we 
should not expect it to progress in the order of this list: 
1	 Clarify the requirements. Discuss tradeoffs. 
## 2	 Draft the API specification.
3	 Design the data model. Discuss possible analytics. 
4	 Discuss failure design, graceful degradation, monitoring, and alerting. Other 
topics include bottlenecks, load balancing, removing single points of failure, 
high availability, disaster recovery, and caching.
5	 Discuss complexity and tradeoffs, maintenance and decommissioning processes, 
and costs. 


