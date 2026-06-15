<!-- PAGE 296 -->
 296 -->

Chapter 11  Autocomplete/typeahead
¡ Discrimination or negative stereotypes on religion, gender, and other groups.
¡ Misinformation, including political misinformation such as conspiracy theories 
on climate change or vaccination or misinformation driven by business agendas. 
¡ Libel against prominent individuals, or defendants in legal proceedings where 
no verdict has been reached. 
Current solutions use a combination of heuristics and machine learning. 
11.11	Logging, monitoring, and alerting 
Besides the usual actions in chapter 9, we should log searches that don’t return any 
autocomplete results, which is indicative of bugs in our trie generator. 
11.12	Other considerations and further discussion
Here are other possible requirements and discussion points that may come up as the 
interview progresses: 
¡ There are many common words longer than three letters, such as “then,” “con-
tinue,” “hold,” “make,” “know,” and “take.” Some of these words may consistently 
be in the list of most popular words. It may be a waste of computational resources 
to keep counting popular words. Can our Autocomplete System keep a list of 
such words, and use approximation techniques to decide which ones to return 
when a user enters an input?
¡ As mentioned earlier, these user logs can be used for many other purposes 
besides autocomplete. For example, this can be a service that provides trending 
search terms, with applications to recommender systems. 
¡ Design a distributed logging service. 
¡ Filtering inappropriate search terms. Filtering inappropriate content is a general 
consideration of most services. 
¡ We can consider other data inputs and processing to create personalized 
autocomplete.
¡ We can consider a Lambda architecture. A Lambda architecture contains a fast 
pipeline, so user queries can quickly propagate to the weighted trie generator, 
such as in seconds or minutes, so the autocomplete suggestions are updated 
quickly with a tradeoff in accuracy. A Lambda architecture also contains a slow 
pipeline for accurate but slower updates. 
¡ Graceful degradation for returning outdated suggestions if upstream compo-
nents are down. 
¡ A rate limiter in front of our service to prevent DoS attacks.
¡ A service that is related but distinct from autocomplete is a spelling suggestion 
service, where a user receives word suggestions if they input a misspelled word. 
We can design a spelling suggestion service that uses experimentation techniques 
such as A/B testing or multi-armed bandit to measure the effect of various fuzzy 
matching functions on user churn. 


<!-- PAGE 297 -->
 297 -->

	
Summary
Summary
¡ An autocomplete system is an example of a system that continuously ingests and 
processes large amount of data into a small data structure that users query for a 
specific purpose. 
¡ Autocomplete has many use cases. An autocomplete service can be a shared ser-
vice, used by many other services.
¡ Autocomplete has some overlap with search, but they are clearly for different 
purposes. Search is for finding documents, while autocomplete is for suggesting 
what the user intends to input. 
¡ This system involves much data preprocessing, so the preprocessing and que-
rying should be divided into separate components and then they can be inde-
pendently developed and scaled. 
¡ We can use the search service and logging service as data inputs for our auto-
complete service. Our autocomplete service can process the search strings that 
these services record from users and offer autocomplete suggestions from these 
strings. 
¡ Use a weighted trie for autocomplete. Lookups are fast and storage requirements 
are low. 
¡ Break up a large aggregation job into multiple stages to reduce storage and pro-
cessing costs. The tradeoff is high complexity and maintenance. 
¡ Other considerations include other uses of the processed data, sampling, filter-
ing content, personalization, Lambda architecture, graceful degradation, and 
rate limiting.


<!-- PAGE 298 -->
 298 -->

Design Flickr
This chapter covers
¡ Selecting storage services based on  
	 non-functional requirements
¡ Minimizing access to critical services
¡ Utilizing sagas for asynchronous processes
In this chapter, we design an image sharing service like Flickr. Besides sharing files/
images, users can also append metadata to files and other users, such as access con-
trol, comments, or favorites. 
Sharing and interacting with images and video are basic functionalities in virtually 
every social application and is a common interview topic. In this chapter, we discuss 
a distributed system design for image-sharing and interaction among a billion users, 
including both manual and programmatic users. We will see that there is much more 
than simply attaching a CDN. We will discuss how to design the system for scalable 
preprocessing operations that need to be done on uploaded content before they are 
ready for download. 


<!-- PAGE 299 -->
 299 -->

	
Non-functional requirements 
12.1	 User stories and functional requirements 
Let’s discuss user stories with the interviewer and scribble them down: 
¡ A user can view photos shared by others. We refer to this user as a viewer.
¡ Our app should generate and display thumbnails of 50 px width. A user should 
view multiple photos in a grid and can select one at a time to view the full-resolu-
tion version. 
¡ A user can upload photos. We refer to this user as a sharer. 
¡ A sharer can set access control on their photos. A question we may ask is whether 
access control should be at the level of individual photos or if a sharer may only 
allow a viewer to view either all the former’s photos or none. We choose the latter 
option for simplicity. 
¡ A photo has predefined metadata fields, which have values provided by the 
sharer. Example fields are location or tags. 
¡ An example of dynamic metadata is the list of viewers who have read access to the 
file. This metadata is dynamic because it can be changed. 
¡ Users can comment on photos. A sharer can toggle commenting on and off. A 
user can be notified of new comments. 
¡ A user can favorite a photo. 
¡ A user can search on photo titles and descriptions. 
¡ Photos can be programmatically downloaded. In this discussion, “view a photo” 
and “download a photo” are synonymous. We do not discuss the minor detail of 
whether users can download photos onto device storage. 
¡ We briefly discuss personalization. 
These are some points that we will not discuss:
¡ A user can filter photos by photo metadata. This requirement can be satisfied by 
a simple SQL path parameter, so we will not discuss it. 
¡ Photo metadata that is recorded by the client, such as location (from hardware 
such as GPS), time (from the device’s clock), and details of the camera (from the 
operating system). 
¡ We will not discuss video. Discussions of many details of video (such as codecs) 
require specialized domain knowledge that is outside the scope of a general sys-
tem design interview. 
12.2	 Non-functional requirements 
Here are some questions we may discuss on non-functional requirements: 
¡ How many users and downloads via API do we expect? 
–	 Our system must be scalable. It should serve one billion users distributed 
across the world. We expect heavy traffic. Assume 1% of our users (10 million) 


