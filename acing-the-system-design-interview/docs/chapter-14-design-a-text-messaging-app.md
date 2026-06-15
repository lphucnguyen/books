<!-- PAGE 360 -->
 360 -->

# Chapter 14  Design a text messaging app
¡ Discuss a system design for user onboarding. How can a new user join our mes-
saging app? How may a new user add or invite contacts? A user can manually type 
in contacts or add contacts using Bluetooth or QR codes. Or our mobile app can 
access the phone’s contact list, which will require the corresponding Android or 
iOS permissions. Users may invite new users by sending them a URL to download 
or sign on to our app. 
¡ Our architecture is a centralized approach. Every message needs to go through 
our backend. We can discuss decentralized approaches, such as P2P architecture, 
where every device is a server and can receive requests from other devices. 
Summary
¡ The main discussion of a simple text messaging app system design is about how to 
route large numbers of messages between a large number of clients.
¡ A chat system is similar to a notification/alerting service. Both services send mes-
sages to large numbers of recipients.
¡ A scalable and cost-efficient technique to handle traffic spikes is to use a message 
queue. However, latency will suffer during traffic spikes.
¡ We can decrease latency by assigning fewer users to a host, with the tradeoff of 
## higher costs.
¡ Either solution must handle host failures and reassign a host’s users to other 
hosts.
¡ A recipient’s device may be unavailable, so provide a GET endpoint to retrieve 
messages. 
¡ We should log requests between services and the details of message sent events 
and error events.
¡ We can monitor usage metrics to adjust cluster size and monitor for fraud.


<!-- PAGE 361 -->
 361 -->

**Design Airbnb**
This chapter covers
¡ Designing a reservation system
¡ Designing systems for operations staff to  
	 manage items and reservations
¡ Scoping a complex system
The question is to design a service for landlords to rent rooms for short-term stays 
to travelers. This may be both a coding and system design question. A coding discus-
sion will be in the form of coding and object-oriented programming (OOP) solu-
tion of multiple classes. In this chapter, we assume this question can be applied to 
reservation systems in general, such as 
¡ Movie tickets 
¡ Air tickets 
¡ Parking lots 
¡ Taxis or ridesharing, though this has different non-functional requirements 
and different system design. 


