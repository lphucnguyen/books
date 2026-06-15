<!-- PAGE 202 -->
 202 -->

Chapter 7  Design Craigslist
location, or do we also need to prevent users from viewing or posting about banned 
products and services?
An initial approach to selectively display sections will be to add logic in the clients to 
display or hide sections based on the country of the user’s IP address. Going further, if 
these regulations are numerous or frequently changing, we may need to create a regu-
lations service that Craigslist admins can use to configure regulations, and the clients 
will make requests to this service to determine which HTML to show or hide. Because 
this service will receive heavy read traffic and much lighter write traffic, we can apply 
CQRS techniques to ensure that writes succeed. For example, we can have separate 
regulation services for admins and viewers that scale separately and periodic synchroni-
zation between them.
If we need to ensure that no forbidden content is posted on our Craigslist, we may 
need to discuss systems that detect forbidden words or phrases, or perhaps machine 
learning approaches.
A final thought is that Craigslist does not attempt to customize its listings based on 
country. A good example was how it removed its Personals section in 2018 in response 
to new regulations passed in the United States. It did not attempt to keep this section in 
other countries. We can discuss the tradeoffs of such an approach.
Summary
¡ We discuss the users and their various required data types (like text, images, or 
video) to determine the non-functional requirements, which in our Craigslist 
system are scalability, high availability, and high performance. 
¡ A CDN is a common solution for serving images or video, but don’t assume it is 
always the appropriate solution. Use an object store if these media will be served 
to a small fraction of users.
¡ Functional partitioning by GeoDNS is the first step in discussing scaling up.
¡ Next are caching and CDN, mainly to improve the scalability and latency of serv-
ing posts. 
¡ Our Craigslist service is read-heavy. If we use SQL, consider leader-follower repli-
cation for scaling reads. 
¡ Consider horizontal scaling of our backend and message brokers to handle write 
traffic spikes. Such a setup can serve write requests by distributing them across 
many backend hosts, and buffer them in a message broker. A consumer cluster 
can consume requests from the message broker and process them accordingly. 
¡ Consider batch or streaming ETL jobs for any functionality that don’t require 
real-time latency. This is slower, but more scalability and lower cost. 
¡ The rest of the interview may be on new constraints and requirements. In this 
chapter, the new constraints and requirements we mentioned were reporting 
posts, graceful degradation, decreasing complexity, adding categories/tags of 
posts, analytics and recommendations, A/B testing, subscriptions and saved 
searches, rate limiting, serving more posts to each user, and local regulations.


<!-- PAGE 203 -->
 203 -->

Design a 
rate-limiting service
This chapter covers
¡ Using rate limiting
¡ Discussing a rate-limiting service
¡ Understanding various rate-limiting algorithms
Rate limiting is a common service that we should almost always mention during a 
system design interview and is mentioned in most of the example questions in this 
book. This chapter aims to address situations where 1) the interviewer may ask for 
more details when we mention rate limiting during an interview, and 2) the ques-
tion itself is to design a rate-limiting service. 
Rate limiting defines the rate at which consumers can make requests to API end-
points. Rate limiting prevents inadvertent or malicious overuse by clients, especially 
bots. In this chapter, we refer to such clients as “excessive clients”. 
Examples of inadvertent overuse include the following: 
¡ Our client is another web service that experienced a (legitimate or malicious) 
traffic spike.
¡ The developers of that service decided to run a load test on their production 
environment.
Such inadvertent overuse causes a “noisy neighbor” problem, where a client uti-
lizes too much resource on our service, so our other clients will experience higher 
latency or higher rate of failed requests. 


