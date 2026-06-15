<!-- PAGE 384 -->
 384 -->

Chapter 15  Design Airbnb
15.10.1	Handling regulations 
We can consider designing and implementing a dedicated regulation service to provide 
a standard API for communicating regulations. All other services must be designed to 
interact with this API, so they are flexible to changing regulations or at least be more 
easily redesigned in response to unforeseen regulations. 
In the author’s experience, designing services to be flexible to changing regulations 
is a blind spot in many companies, and considerable resources are spent on re-architec-
ture, implementation, and migration each time regulations change.
Exercise
A possible exercise is to discuss differences in regulations requirements between Airbnb 
and Craigslist. 
Data privacy laws are a relevant concern to many companies. Examples include COPPA 
(https://www.ftc.gov/enforcement/rules/rulemaking-regulatory-reform-proceedings/ 
childrens-online-privacy-protection-rule), GDPR (https://gdpr-info.eu/), and CCPA 
(https://oag.ca.gov/privacy/ccpa). Some governments may require companies to 
share data on activities that occur in their jurisdictions or that data on their citizens 
cannot leave the country. 
Regulations may affect the core business of the company. In the case of Airbnb, there 
are regulations directly on hosts and guests. Examples of such regulations may include 
¡ A listing may only be hosted for a maximum number of days in a year. 
¡ Only properties constructed before or after a certain year can be listed. 
¡ Bookings cannot be made on certain dates, such as certain public holidays. 
¡ Bookings may have a minimum or maximum duration in a specific city. 
¡ Listings may be disallowed altogether in certain cities or addresses. 
¡ Listing may require safety equipment such as carbon monoxide detectors, fire 
detectors, and fire escapes. 
¡ There may be other livability and safety regulations. 
Within a country, certain regulations may be specific to listings that meet certain con-
ditions, and the specifics may differ by each specific country, state, city, or even address 
(e.g., certain apartment complexes may impose their own rules).


<!-- PAGE 385 -->
 385 -->

	
Summary
Summary
¡ Airbnb is a reservation app, a marketplace app, and a customer support and 
operations app. Hosts, guests, and Ops are the main user groups.
¡ Airbnb’s products are localized, so listings can be grouped in data centers by 
geography.
¡ The sheer number of services involved in listing and booking is impossible to 
comprehensively discuss in a system design interview. We can list a handful of 
main services and briefly discuss their functionalities.
¡ Creating a listing may involve multiple requests from the Airbnb host to ensure 
the listing complies with local regulations.
¡ After an Airbnb host submits a listing request, it may need to be manually 
approved by an Ops/admin member. After approval, it can be found and booked 
by guests.
¡ Interactions between these various services should be asynchronous if low latency 
is unnecessary. We employ distributed transactions techniques to allow asynchro-
nous interactions.
¡ Caching is not always a suitable strategy to reduce latency, especially if the cache 
quickly becomes stale.
¡ Architecture diagrams and sequence diagrams are invaluable in designing a 
complex transaction.


<!-- PAGE 386 -->
 386 -->

Design a news feed
This chapter covers
¡ Designing a personalized scalable system
¡ Filtering out news feed items
¡ Designing a news feed to serve images and text
Design a news feed that provides a user with a list of news items, sorted by approx-
imate reverse chronological order that belong to the topics selected by the user. A 
news item can be categorized into 1–3 topics. A user may select up to three topics of 
interest at any time. 
This is a common system design interview question. In this chapter, we use the 
terms “news item” and “post” interchangeably. In social media apps like Facebook or 
Twitter, a user’s news feed is usually populated by posts from friends/connections. 
However, in this news feed, users get posts written by other people in general, rather 
than by their connections. 


<!-- PAGE 387 -->
 387 -->

	
Requirements 
16.1	 Requirements 
These are the functional requirements of our news feed system, which as usual we can 
discuss/uncover via an approximately five-minute Q&A with the interviewer. 
¡ A user can select topics of interest. There are up to 100 tags. (We will use the term 
“tag” in place of “news topic” to prevent ambiguity with the term “Kafka topic.”)
¡ A user can fetch a list of English-language news items 10 at a time, up to 1,000 
items. 
¡ Although a user need only fetch up to 1,000 items, our system should archive all 
items. 
¡ Let’s first allow users to get the same items regardless of their geographical 
location and then consider personalization, based on factors like location and 
language.
¡ Latest news first; that is, news items should be arranged in reverse chronological 
order, but this can be an approximation.
¡ Components of a news item: 
–	 A new item will usually contain several text fields, such as a title with perhaps a 
150-character limit and a body with perhaps a 10,000-character limit. For sim-
plicity, we can consider just one text field with a 10,000-character limit. 
–	 UNIX timestamp that indicates when the item was created. 
–	 We initially do not consider audio, images, or video. If we have time, we can 
consider 0–10 image files of up to 1 MB each. 
TIP    The initial functional requirements exclude images because images add 
considerable complexity to the system design. We can first design a system that 
handles only text and then consider how we can expand it to handle images and 
other media. 
¡ We can consider that we may not want to serve certain items because they contain 
inappropriate content.
The following are mostly or completely out of scope of the functional requirements: 
¡ Versioning is not considered because an article can have multiple versions. An 
author may add additional text or media to an article or edit the article to correct 
errors. 
¡ We initially do not need to consider analytics on user data (such as their topics of 
interest, articles displayed to them, and articles they chose to read) or sophisti-
cated recommender systems. 
¡ We do not need any other personalization or social media features like sharing 
or commenting. 
¡ We need not consider the sources of the news items. Just provide a POST API 
endpoint to add news items. 


