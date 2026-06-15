 318 -->

# Chapter 12  Design Flickr
Summary
¡ Scalability, availability, and high download performance are required for a file- 
or image-sharing service. High upload performance and consistency are not 
required.
¡ Which services are allowed to write to our CDN? Use a CDN for static data, but 
secure and limit write access to sensitive services like a CDN. 
¡ Which processing operations should be put in the client vs. the server? One con-
sideration is that processing on a client can save our company hardware resources 
and cost, but may be considerably more complex and incur more costs from this 
### complexity.
¡ Client-side and server-side have their tradeoffs. Server-side is generally preferred 
where possible for ease of development/upgrades. Doing both allows the low 
computational cost of client-side and the reliability of server-side. 
¡ Which processes can be asynchronous? Use techniques like sagas for those pro-
cesses to improve scalability and reduce hardware costs.


 319 -->

Design a Content 
Distribution Network
This chapter covers
¡ Discussing the pros, cons, and unexpected 	
	 situations
¡ Satisfying user requests with frontend 
	 metadata storage architecture
¡ Designing a basic distributed storage system
A CDN (Content Distribution Network) is a cost-effective and geographically dis-
tributed file storage service that is designed to replicate files across its multiple data 
centers to serve static content to a large number of geographically distributed users 
quickly, serving each user from the data center that can serve them fastest. There 
are secondary benefits, such as fault-tolerance, allowing users to be served from 
other data centers if any particular data center is unavailable. Let’s discuss a design 
for a CDN, which we name CDNService.


