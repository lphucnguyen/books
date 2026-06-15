<!-- PAGE 404 -->
 404 -->

Chapter 16  Design a news feed
We may discuss the tradeoffs of handling and storing text and media in separate 
services vs. a single service. We can refer to chapter 13 to discuss more details of hosting 
images on a CDN, such as the tradeoffs of hosting media on a CDN. 
Taking this a step further, we can also host complete articles on our CDN, including 
all text and media. The Redis values can be reduced to article IDs. Although an article’s 
text is usually much smaller than its media, there can still be performance improve-
ments from placing it on a CDN, particularly for frequent requests of popular articles. 
Redis is horizontally scalable but inter data center replication is complex. 
In the approval service, should the images and text of an article be reviewed sepa-
rately or together? For simplicity, reviewing an article can consist of reviewing both its 
text and accompanying media as a single article. 
How can we review media more efficiently? Hiring review staff is expensive, and a 
staff will need to listen to an audio clip or watch a video completely before making a 
review decision. We can consider transcribing audio, so a reviewer can read rather than 
listen to audio files. This will allow us to hire hearing-impaired staff, improving the com-
pany’s inclusivity culture. A staff can play a video file at 2x or 3x speed when they review 
it and read the transcribed audio separately from viewing the video file. We can also 
consider machine learning solutions to review articles. 
16.6	 Other possible discussion topics 
Here are other possible discussion topics that may come up as the interview progresses, 
which may be suggested by either the interviewer or candidate: 
¡ Create hashtags, which are dynamic, rather than a fixed set of topics. 
¡ Users may wish to share news items with other users or groups. 
¡ Have a more detailed discussion on sending notifications to creators and readers. 
¡ Real-time dissemination of articles. ETL jobs must be streaming, not batch. 
¡ Boosting to prioritize certain articles over others. 
We can consider the items that were out-of-scope in the functional requirements 
discussion: 
¡ Analytics. 
¡ Personalization. Instead of serving the same 1,000 news items to all users, serve 
each user a personalized set of 100 news items. This design will be substantially 
more complex. 
¡ Serving articles in languages other than English. Potential complications, such as 
handling UTF or language transations. 
¡ Monetizing the news feed. Topics include: 
–	 Design a subscription system. 
–	 Reserve certain posts for subscribers. 
–	 An article limit for non-subscribers. 
–	 Ads and promoted posts. 


<!-- PAGE 405 -->
 405 -->

	
Summary
Summary
¡ When drawing the initial high-level architecture of the news feed system, con-
sider the main data of interest and draw the components that read and write this 
data to the database.
¡ Consider the non-functional requirements of reading and writing the data and 
then select the appropriate database types and consider the accompanying ser-
vices, if any. These include the Kafka service and Redis service. 
¡ Consider which operations don’t require low latency and place them in batch 
and streaming jobs for scalability.
¡ Determine any processing operations that must be performed before and after 
writes and reads and wrap them in services. Prior operations may include com-
pression, content moderation, and lookups to other services to get relevant IDs 
or data. Post operations may include notifications and indexing. Examples of 
such services in our news feed system include the ingestor service, consumer ser-
vice, ETL jobs, and backend service.
¡ Logging, monitoring, and alerting should be done on failures and unusual 
events that we may be interested in.


<!-- PAGE 406 -->
 406 -->

Design a dashboard 
of top 10 products on 
Amazon by sales volume
This chapter covers
¡ Scaling an aggregation operation on a large 	
	 data stream
¡ Using a Lambda architecture for fast  
	 approximate results and slow accurate results
¡ Using Kappa architecture as an alternative to 	
	 Lambda architecture 
¡ Approximating an aggregation operation for 	
	 faster speed
Analytics is a common discussion topic in a system design interview. We will always 
log certain network requests and user interactions, and we will perform analytics 
based on the data we collect. 
The Top K Problem (Heavy Hitters) is a common type of dashboard. Based on the 
popularity or lack thereof of certain products, we can make decisions to promote 
or discontinue them. Such decisions may not be straightforward. For example, if a 
product is unpopular, we may decide to either discontinue it to save the costs of sell-
ing it, or we may decide to spend more resources to promote it to increase its sales.


<!-- PAGE 407 -->
 407 -->

	
Requirements 
The Top K Problem is a common topic we can discuss in an interview when discuss-
ing analytics, or it may be its own standalone interview question. It can take on endless 
forms. Some examples of the Top K Problem include 
¡ Top-selling or worst-selling products on an ecommerce app by volume (this ques-
tion) or revenue. 
¡ The most-viewed or least-viewed products on an ecommerce app. 
¡ Most downloaded apps on an apps store. 
¡ Most watched videos on a video app like YouTube. 
¡ Most popular (listened to) or least popular songs on a music app like Spotify. 
¡ Most traded stocks on an exchange like Robinhood or E*TRADE. 
¡ Most forwarded posts on a social media app, such as the most retweeted Twitter 
tweets or most shared Instagram post. 
17.1	 Requirements 
Let’s ask some questions to determine the functional and non-functional require-
ments. We assume that we have access to the data centers of Amazon or whichever 
ecommerce app we are concerned with 
¡ How do we break ties? 
High accuracy may not be important, so we can choose any item in a tie: 
¡ Which time intervals are we concerned with? 
Our system should be able to aggregate by certain specified intervals such as hour, day, 
week, or year: 
¡ The use cases will influence the desired accuracy (and other requirements like 
scalability). What are the use cases of this information? What is the desired accu-
racy and desired consistency/latency? 
That’s a good question. What do you have in mind? 
It will be resource-intensive to compute accurate volumes and ranking in real time. 
Perhaps we can have a Lambda architecture, so we have an eventually consistent solu-
tion that offers approximate sales volumes and rankings within the last few hours and 
accurate numbers for time periods older than a few hours. 
We can also consider trading off accuracy for higher scalability, lower cost, lower 
complexity, and better maintainability. We expect to compute a particular Top K list 
within a particular period at least hours after that period has passed, so consistency is 
not a concern. 
Low latency is not a concern. We can expect that generating a list will require many 
minutes: 
¡ Do we need just the Top K or top 10, or the volumes and ranking of an arbitrary 
number of products? 


