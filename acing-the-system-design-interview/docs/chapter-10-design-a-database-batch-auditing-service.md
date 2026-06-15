<!-- PAGE 276 -->
 276 -->

# 10 Design a database batch auditing service
Summary
¡ During a system design interview, we can discuss auditing as a common approach 
to maintaining data integrity. This chapter discussed a possible system design for 
batch auditing. 
¡ We can periodically run database queries to detect data irregularities, which may 
be due to various problems like unexpected user activity, silent errors, or mali-
cious activity.
¡ We defined a common solution for detecting data irregularities that encom-
passes many use cases for these periodic database queries, and we designed a 
scalable, available, and accurate system.
¡ We can use task scheduling platforms like Airflow to schedule auditing jobs, 
rather than defining our own cron jobs, which are less scalable and more error 
prone. 
¡ We should define the appropriate monitoring and alerting to keep users 
informed of successful or failed audit jobs. The periodic database auditing ser-
vice also uses the alerting service, discussed in chapter 9, and OpenID Connect, 
discussed in appendix B.
¡ We can provide a query service for users to make ad hoc queries. 


<!-- PAGE 277 -->
 277 -->

Autocomplete/typeahead
This chapter covers
¡ Comparing autocomplete with search
¡ Separating data collection and processing from 	
	 querying
¡ Processing a continuous data stream
¡ Dividing a large aggregation pipeline into  
	 stages to reduce storage costs
¡ Employing the byproducts of data processing 	
	 pipelines for other purposes
We wish to design an autocomplete system. Autocomplete is a useful question to 
test a candidate’s ability to design a distributed system that continuously ingests and 
processes large amounts of data into a small (few MBs) data structure that users can 
query for a specific purpose. An autocomplete system obtains its data from strings 
submitted by up to billions of users and then processes this data into a weighted trie. 
When a user types in a string, the weighted trie provides them with autocomplete 
suggestions. We can also add personalization and machine learning elements to our 
autocomplete system. 


