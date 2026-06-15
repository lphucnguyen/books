 254 -->

# 9 Design a notification/alerting service
Summary
¡ A service that must serve the same functionality to many different platforms 
can consist of a single backend that centralizes common processing and directs 
requests to the appropriate component (or another service) for each platform.
¡ Use a metadata service and/or object store to reduce the size of messages in a 
message broker queue.
¡ Consider how to automate user actions using templates.
¡ We can use a task scheduling service for periodic notifications.
¡ One way to deduplicate messages is on the receiver’s device.
¡ Communicate between system components via asynchronous means like sagas.
¡ We should create monitoring dashboards for analytics and tracking errors.
¡ Do periodic auditing and anomaly detection to detect possible errors that our 
other metrics missed.


 255 -->

# 10 Design a database batch auditing service
This chapter covers
¡ Auditing database tables to find invalid data
¡ Designing a scalable and accurate solution to 	
	 audit database tables
¡ Exploring possible features to answer an  
	 unusual question
Let’s design a shared service for manually defined validations. This is an unusually 
open-ended system design interview question, even by the usual standards of system 
design interviews, and the approach discussed in this chapter is just one of many 
possibilities. 
We begin this chapter by introducing the concept of data quality. There are many 
definitions of data quality. In general, data quality can refer to how suitable a dataset 
is to serve its purpose and may also refer to activities that improve the dataset’s suit-
ability for said purpose. There are many dimensions of data quality. We can adopt 
the dimensions from https://www.heavy.ai/technical-glossary/data-quality: 
¡ Accuracy—How close a measurement is to the true value. 
¡ Completeness—Data has all the required values for our purpose.
¡ Consistency—Data in different locations has the same values, and the different 
locations start serving the same data changes at the same time. 


