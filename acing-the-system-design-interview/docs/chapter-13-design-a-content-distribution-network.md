<!-- PAGE 338 -->
 338 -->

Chapter 13  Design a Content Distribution Network 
5	 The storage service produces an event to the response topic to inform the meta-
data service that the file writes were successfully completed.
6	 The metadata service consumes this event.
7	 The metadata service produces an event to the file deletion topic to request the 
storage service to delete the file from its old locations.
8	 The storage service consumes this event and deletes the file from its old locations.
13.7	 Cache invalidation
As a CDN is for static files, cache invalidation is much less of a concern. We can finger-
print the files as discussed in section 4.11.1. We discussed various caching strategies 
(section 4.8) and designing a system to monitor the cache for stale files. This system 
will have to anticipate high traffic. 
13.8	 Logging, monitoring, and alerting 
In section 2.5, we discussed key concepts of logging, monitoring, and alerting that one 
must mention in an interview. Besides what was discussed in section 2.5, we should 
monitor and send alerts for the following: 
¡ Uploaders should be able to track the state of their files, whether the upload is in 
progress, completed, or failed.
¡ Log CDN misses and then monitors and triggers low-urgency alerts for them. 
¡ The frontend service can log the request rate for files. This can be done on a 
shared logging service. 
¡ Monitor for unusual or malicious activity. 
13.9	 Other possible discussions on downloading media files 
We may wish media files to be playable before they are fully downloaded. A solution 
is to divide the media file into smaller files, which can be downloaded in sequence 
and assembled into a media file that is a partial version of the original. Such a system 
requires a client-side media player that can do such assembly while playing the partial 
version. The details may be beyond the scope of a system design interview. It involves 
piercing together the files’ byte strings. 
As the sequence is important, we need metadata that indicates which files to down-
load first. Our system splits a file into smaller files and assigns each small file with a 
sequence number. We also generate a metadata file that contains information on the 
order of the files and their total number. How can the files be efficiently downloaded in 
a particular sequence? We can also discuss other possible video streaming optimization 
strategies. 


<!-- PAGE 339 -->
 339 -->

	
Summary
Summary
¡ A CDN is a scalable and resilient distributed file storage service, which is a utility 
that is required by almost any web service that serves a large or geographically 
distributed user base. 
¡ A CDN is geographically distributed file storage service that allows each user to 
access a file from the data center that can serve them the fastest.
¡ A CDN’s advantages include lower latency, scalability, lower unit costs, higher 
throughput, and higher availability.
¡ A CDN’s disadvantages include additional complexity, high unit costs for low 
traffic and hidden costs, expensive migration, possible network restrictions, secu-
rity and privacy concerns, and insufficient customization capabilities.
¡ A storage service can be separate from a metadata service that keeps track of 
which storage service hosts store particular files. The storage service’s implemen-
tation can focus on host provisioning and health.
¡ We can log file accesses and use this data to redistribute or replicate files across 
data centers to optimize latency and storage.
¡ CDNs can use third-party token-based authentication and authorization with key 
rotation for secure, reliable, and fine-grained access control. 
¡ A possible CDN high-level architecture can be a typical API gateway-metada-
ta-storage/database architecture. We customize and scale each component to 
suit our specific functional and non-functional requirements. 
¡ Our distributed file storage service can be managed in-cluster or out-cluster. 
Each has its tradeoffs. 
¡ Frequently accessed files can be cached on the API gateway for faster reads.
¡ For encryption at rest, a CDN can use a secrets management service to manage 
encryption keys. 
¡ Large files should be uploaded with a multipart upload process that divides the 
file into chunks and manages the upload of each chunk separately. 
¡ To maintain low latency of downloads while managing costs, a periodic batch job 
can redistribute files across data centers and replicate them to the appropriate 
number of hosts.


<!-- PAGE 340 -->
 340 -->

Design a text 
messaging app
This chapter covers
¡ Designing an app for billions of clients to send 	
	 short messages 
¡ Considering approaches that trade off latency 	
	 vs. cost
¡ Designing for fault-tolerance
Let’s design a text messaging app, a system for 100K users to send messages to each 
other within seconds. Do not consider video or audio chat. Users send messages at 
an unpredictable rate, so our system should be able to handle these traffic surges. 
This is the first example system in this book that considers exactly-once delivery. 
Messages should not be lost, nor should they be sent more than once. 


<!-- PAGE 341 -->
 341 -->

	
Requirements
14.1	 Requirements
After some discussion, we determined the following functional requirements: 
¡ Real-time or eventually-consistent? Consider either case. 
¡ How many users may a chatroom have? A chatroom can contain between two to 
1,000 users. 
¡ Is there a character limit for a message? Let’s make it 1000 UTF-8 characters. At 
up to 32 bits/character, a message is up to 4 KB in size. 
¡ Notification is a platform-specific detail that we need not consider. Android, 
iOS, Chrome, and Windows apps each have their platform-specific notification 
library. 
¡ Delivery confirmation and read receipt. 
¡ Log the messages. Users can view and search up to 10 MB of their past messages. 
With one billion users, this works out to 10 PB of storage.
¡ Message body is private. We can discuss with the interviewer if we can view any 
message information, including information like knowing that a message was 
send from one user to another. However, error events such as failure to send a 
message should trigger an error that is visible to us. Such error logging and moni-
toring should preserve user privacy. End-to-end encryption will be ideal. 
¡ No need to consider user onboarding (i.e., the process of new users signing on to 
our messaging app). 
¡ No need to consider multiple chatrooms/channels for the same group of users. 
¡ Some chat apps have template messages that users can select to quickly create 
and send, such as “Good morning!” or “Can’t talk now, will reply later.” This can 
be a client-side feature that we do not consider here. 
¡ Some messaging apps allow users to see if their connections are online. We do 
not consider this. 
¡ We consider sending text only, not media like voice messages, photos, or videos. 
Non-functional requirements: 
¡ Scalability: 100K simultaneous users. Assume each user sends a 4 KB message 
every minute, which is a write rate of 400 MB/min. A user can have up to 1,000 
connections, and a message can be sent to up to 1,000 recipients, each of whom 
may have up to five devices. 
¡ High availability: Four nines availability. 
¡ High performance: 10-second P99 message delivery time. 
¡ Security and privacy: Require user authentication. Messages should be private. 
¡ Consistency: Strict ordering of messages is not necessary. If multiple users send 
messages to each other more or less simultaneously, these messages can appear 
in different orders to different users. 


