 174 -->

# 6 Common services for functional partitioning
### WebSocket
WebSocket is a communications protocol for full-duplex communication over a 
persistent TCP connection, unlike HTTP, which creates a new connection for every 
request and closes it with every response. REST, RPC, GraphQL, and Actor model are 
design patterns or philosophies, while WebSocket and HTTP are communication pro-
tocols. However, it makes sense to compare WebSocket to the rest as API architectural 
styles because we can choose to implement our API using WebSocket rather than the 
other four choices. 
To create a WebSocket connection, a client sends a WebSocket request to the server. 
WebSocket uses an HTTP handshake to create an initial connection and requests the 
server to upgrade to WebSocket from HTTP. Subsequent messages can use WebSocket 
over this persistent TCP connection. 
WebSocket keeps connections open, which increases overhead for all parties. This 
means that WebSocket is stateful (compared to REST and HTTP, which are stateless). 
A request must be handled by the host that contains the relevant state/connection, 
unlike in REST where any host can handle any request. Both the stateful nature of Web-
Socket and the resource overhead of maintaining connections means that WebSocket 
is less scalable. 
WebSocket allows p2p communication, so no backend is required. It trades off scal-
ability for lower latency and higher performance.
### Comparison
During an interview, we may need to evaluate the tradeoffs between these architec-
tural styles and the factors to consider in choosing a style and protocol. REST and 
RPC are the most common. Startups usually use REST for simplicity, while large 
organizations can benefit from RPC’s efficiency and backward and forward compat-
ibility. GraphQL is a relatively new philosophy. WebSocket is useful for bidirectional 
communication, including p2p communication. Other references include https://
apisyouwonthate.com/blog/picking-api-paradigm/ and https://www.baeldung.com/
### rest-vs-websockets.
Summary
¡ An API gateway is a web service designed to be stateless and lightweight yet fulfill 
many cross-cutting concerns across various services, which can be grouped into 
security, error-checking, performance and availability, and logging.
¡ A service mesh or sidecar pattern is an alternative pattern. Each host gets its own 
sidecar, so no service can consume an unfair share.
¡ To minimize network traffic, we can consider using a metadata service to store 
data that is processed by multiple components within a system.
¡ Service discovery is for clients to identify which service hosts are available.


 175 -->

	
Summary
¡ A browser app can have two or more backend services. One of them is a web 
server service that intercepts requests and responses from the other backend 
services.
¡ A web server service minimizes network traffic between the browser and data cen-
ter, by performing aggregation and filtering operations with the backend.
¡ Browser app frameworks are for browser app development. Server-side frame-
works are for web service development. Mobile app development can be done 
with native or cross-platform frameworks.
¡ There are cross-platform or full-stack frameworks for developing browser apps, 
mobile apps, and web servers. They carry tradeoffs, which may make them unsuit-
able for one’s particular requirements.
¡ Backend development frameworks can be classified into RPC, REST, and 
### GraphQL frameworks.
¡ Some components can be implemented as either libraries or services. Each 
approach has its tradeoffs.
¡ Most communication paradigms are implemented on top of HTTP. RPC is a low-
er-level protocol for efficiency.
¡ REST is simple to learn and use. We should declare REST resources as cacheable 
whenever possible.
¡ REST requires a separate documentation framework like OpenAPI.
¡ RPC is a binary protocol designed for resource optimization. Its schema modifi-
cation rules also allow backward- and forward-compatibility.
¡ GraphQL allows pinpoint requests and has an integrated API documentation 
tool. However, it is complex and more difficult to secure.
¡ WebSocket is a stateful communications protocol for full-duplex communica-
tion. It has more overhead on both the client and server than other communica-
tion paradigms.


 176 -->



 177 -->

Part 2
xxx
In part 1, we learned about common topics in system design interviews. We 
will now go over a series of sample system design interview questions. In each 
question, we apply the concepts we learned in part 1 as well as introducing con-
cepts relevant to the specific question.
We begin with chapter 7 on how to design a system like Craigslist, a system that 
is optimized for simplicity. 
Chapters 8–10 discuss designs of systems that are themselves common compo-
nents of many other systems. 
Chapter 11 discusses an autocomplete/typeahead service, a typical system that 
continuously ingests and processes large amounts of data into a few megabytes 
data structure that users query for a specific purpose. 
Chapter 12 discusses an image-sharing service. Sharing and interacting with 
images and video are basic functionalities in virtually every social application, 
and a common interview topic. This leads us to the topic of chapter 13, where we 
discuss a Content Distribution Network (CDN), a system that is commonly used 
to cost-efficiently serve static content like images and videos to a global audience. 
Chapter 14 discusses a text messaging app, a system that delivers messages sent 
from many users to many other users and should not accidentally deliver dupli-
cate messages. 
Chapter 15 discusses a room reservation and marketplace system. Sellers 
can offer rooms for rent, and renters can reserve and pay for them. Our system 
must also allow our internal operations staff to conduct arbitration and content 
moderation. 
Chapters 16 and 17 discuss systems that process data feeds. Chapter 16 dis-
cusses a news feed system that sorts data for distribution to many interested users, 
while chapter 17 discusses a data analytics service that aggregates large amounts 
of data into a dashboard that can be used to make decisions. 


 178 -->



 179 -->
# 7 Design Craigslist
This chapter covers
¡ Designing an application with two distinct types 	
	 of users
¡ Considering geolocation routing for partitioning 	
	 users
¡ Designing read-heavy vs. write-heavy 	
	
	 applications
¡ Handling minor deviations during the interview
We want to design a web application for classifieds posts. Craigslist is an example of 
a typical web application that may have more than a billion users. It is partitioned 
by geography. We can discuss the overall system, which includes browser and mobile 
apps, a stateless backend, simple storage requirements, and analytics. More use 
cases and constraints can be added for an open-ended discussion. This chapter is 
unique in that it is the only one in this book where we discuss a monolith architec-
ture as a possible system design. 


