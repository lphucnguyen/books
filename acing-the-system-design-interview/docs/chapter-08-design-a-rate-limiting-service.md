 226 -->

# 8 Design a rate-limiting service
¡ Signs of possible malicious activity, such as users, which continue to make 
requests at a high rate despite being shadow-banned.
¡ Signs of possible DDoS attempts, such as an unusually high number of users 
being rate limited in a short interval.
## Providing functionality in a client library
Does a user service need to query the rate limiter service for every request? An alterna-
tive approach is for the user service to aggregate user requests and then query the rate 
limiter service in certain circumstances such as when it
¡ Accumulates a batch of user requests
¡ Notices a sudden increase in request rate
Generalizing this approach, can rate limiting be implemented as a library instead of 
a service? Section 6.7 is a general discussion of a library vs. service. If we implement it 
entirely as a library, we will need to use the approach in section 8.7, where a host can 
contain all user requests in memory and synchronize the user requests with each other. 
Hosts must be able to communicate with each other to synchronize their user request 
timestamps, so the developers of the service using our library must configure a config-
uration service like ZooKeeper. This may be overly complex and error-prone for most 
developers, so as an alternative, we can offer a library with features to improve the per-
formance of the rate limiting service, by doing some processing on the client, thereby 
allowing a lower rate of requests to the service. 
This pattern of splitting processing between client and server can generalize to 
any system, but it may cause tight coupling between the client and server, which is, in 
general, an antipattern. The development of the server application must continue to 
support old client versions for a long time. For this reason, a client SDK (software devel-
opment kit) is usually just a layer on a set of REST or RPC endpoints and does not do 
any data processing. If we wish to do any data processing in the client, at least one of the 
following conditions should be true: 
¡ The processing should be simple, so it is easy to continue to support this client 
library in future versions of the server application.
¡ The processing is resource-intensive, so the maintenance overhead of doing such 
processing on the client is a worthy tradeoff for the significant reduction in the 
monetary cost of running the service.
¡ There should be a stated support lifecycle that clearly informs users when the 
client will no longer be supported.
Regarding batching of requests to the rate limiter, we can experiment with batch size 
to determine the best balance between accuracy and network traffic.
What if the client also measures the request rate and only uses the rate limiting ser-
vice if the request rate exceeds a set threshold? A problem with this is that since clients 
do not communicate with each other, a client can only measure the request rate on the 


 227 -->

	
Summary
specific host it’s installed on and cannot measure the request rate of specific users. This 
means that rate limiting is activated based on the request rate across all users, not on 
specific users. Users may be accustomed to a particular rate limit and may complain if 
they are suddenly rate limited at a particular request rate where they were not rate lim-
ited before.
An alternative approach is for the client to use anomaly detection to notice a sudden 
increase in the request rate, then start sending rate-limiting requests to the server.
## Further reading
¡ Smarshchok, Mikhail, 2019. System Design Interview YouTube channel, https://
youtu.be/FU4WlwfS3G0. 
¡ The discussions of fixed window counter, sliding window log, and sliding win-
dow counter were adapted from https://www.figma.com/blog/an-alternative 
### -approach-to-rate-limiting/.
¡ Madden, Neil, 2020. API Security in Action. Manning Publications.
¡ Posta, Christian E. and Maloku, Rinor, 2022. Istio in Action. Manning Publications.
¡ Bruce, Morgan and Pereira, Paulo A., 2018. Microservices in Action, chapter 3.5. 
Manning Publications.
Summary
¡ Rate limiting prevents service outages and unnecessary costs.
¡ Alternatives such as adding more hosts or using the load balancer for rate lim-
iting are infeasible. Adding more hosts to handle traffic spikes may be too slow, 
while using a level 7 load balancer just for rate limiting may add too much cost 
### and complexity.
¡ Do not use rate limiting if it results in poor user experience or for complex use 
cases such as subscriptions.
¡ The non-functional requirements of a rate limiter are scalability, performance, 
and lower complexity. To optimize for these requirements, we can trade off avail-
ability, fault-tolerance, accuracy, and consistency.
¡ The main input to our rate-limiter service is user ID and service ID, which will be 
processed according to rules defined by our admin users to return a “yes” or “no” 
### response on rate limiting.
¡ There are various rate limiting algorithms, each with its own tradeoffs. Token 
bucket is easy to understand and implement and is memory-efficient, but syn-
chronization and cleanup are tricky. Leaky bucket is easy to understand and 
implement but is slightly inaccurate. A fixed window log is easy to test and debug, 
but it is inaccurate and more complicated to implement. A sliding window log is 
accurate, but it requires more memory. A sliding window counter uses less mem-
ory than sliding window log, but it is less accurate than sliding window log. 
¡ We can consider a sidecar pattern for our rate-limiting service.


 228 -->

Design a notification/ 
alerting service
This chapter covers
¡ Limiting the feature scope and discussion of a 	
	 service
¡ Designing a service that delegates to  
	 platform-specific channels
¡ Designing a system for flexible configurations 	
### and templates
¡ Handling other typical concerns of a service
We create functions and classes in our source code to avoid duplication of coding, 
debugging, and testing, to improve maintainability, and to allow reuse. Likewise, we 
generalize common functionalities used by multiple services (i.e. centralization of 
cross-cutting concerns). 
Sending user notifications is a common system requirement. In any system design 
discussion, whenever we discuss sending notifications, we should suggest a common 
notification service for the organization.  
## Functional requirements
Our notification service should be as simple as possible for a wide range of users, 
which causes considerable complexity in the functional requirements. There are 
many possible features that a notification service can provide. Given our limited 
time, we should clearly define some use cases and features for our notification 


 229 -->

## Functional requirements
service that will make it useful to our anticipated wide user base. A well-defined feature 
scope will allow us to discern and optimize for its non-functional requirements. After 
we design our initial system, we can discuss and design for further possible features. 
This question can also be a good exercise in designing an MVP. We can anticipate 
possible features and design our system to be composed of loosely coupled components 
to be adaptable to adding new functionality and services and evolve in response to user 
feedback and changing business requirements. 
### Not for uptime monitoring
Our notification service will likely be a layer on top of various messaging services (e.g., 
email, SMS, etc.). A service to send such a message (e.g., an email service) is a complex 
service in itself. In this question, we will use shared messaging services, but we will not 
design them. We will design a service for users to send messages via various channels.
Generalizing this approach beyond shared messaging services, we will also use other 
shared services for functionalities like storage, event streaming, and logging. We will 
also use the same shared infrastructure (bare metal or cloud infrastructure) that our 
organization uses to develop other services.
QUESTION    Can uptime monitoring be implemented using the same shared 
infrastructure or services as the other services that it monitors? 
Based on this approach, we assume that this service should not be used for uptime 
monitoring (i.e., trigger alerts on outages of other services). Otherwise, it cannot be 
built on the same infrastructure or use the same shared services as other services in our 
organization because outages that affect them will also affect this service, and outage 
alerts will not be triggered. An uptime monitoring service must run on infrastructure 
that is independent of the services that it monitors. This is one key reason external 
uptime monitoring services like PagerDuty are so popular.
All this being said, section 9.14 discusses a possible approach to using this service for 
uptime monitoring. 
### Users and data
Our notification service has three types of users:
¡ Sender: A person or service who CRUDs (create, read, update, and delete) notifi-
cations and sends them to recipients.
¡ Recipient: A user of an app who receives notifications. We also refer to the devices 
or apps themselves as recipients. 
¡ Admin: A person who has admin access to our notification service. An admin has 
various capabilities. They can grant permissions to other users to send or receive 
notifications, and they can also create and manage notification templates (sec-
tion 9.5). We assume that we as developers of the notification service have admin 
access, although, in practice, only some developers may have admin access to the 
production environment. 


