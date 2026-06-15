<!-- PAGE 426 -->
 426 -->

# Chapter 17  Design a dashboard of top 10 products on Amazon by sales volume
Our browser app only displays the Top K list. We can extend our functional require-
ments, such as displaying sales trends or predicting future sales of current or new 
products. 
## 17.12	References
This chapter used material from the Top K Problem (Heavy Hitters) (https://youtu.be/ 
kx-XDoPjoHw) presentation in the System Design Interview YouTube channel by 
Mikhail Smarshchok.
Summary
¡ When accurate large-scale aggregation operations take too long, we can run a 
parallel streaming pipeline that uses approximation techniques to trade off accu-
racy for speed. Running a fast, inaccurate and a slow, accurate pipeline in parallel 
### is called Lambda architecture.
¡ One step in large-scale aggregation is to partition by a key that we will later aggre-
gate over.
¡ Data that is not directly related to aggregation should be stored in a different 
service, so it can be easily used by other services.
¡ Checkpointing is one possible technique for distributed transactions that involve 
both destinations with cheap read operations (e.g., Redis) and expensive read 
operations (e.g., HDFS).
¡ We can use a combination of heaps and multi-tier horizontal scaling for approxi-
mate large-scale aggregation operations.
¡ Count-min sketch is an approximation technique for counting.
¡ We can consider either Kappa or Lambda architecture for processing a large 
data stream. 


<!-- PAGE 427 -->
 427 -->

A
Monoliths 
vs. microservices
This appendix evaluates monoliths vs. microservices. The author’s personal expe-
rience is that it seems many sources describe the advantages of microservice over 
monolith architecture but do not discuss the tradeoffs, so we will discuss them here. 
We use the terms “service” and “microservice” interchangeably. 
Microservice architecture is about building a software system as a collection of loose-
ly-coupled and independently developed, deployed, and scaled services. Monoliths 
are designed, developed, and deployed as a single unit. 
A.1	
## Advantages of monoliths
Table A.1 discusses the advantages of monoliths over services. 


<!-- PAGE 428 -->
 428 -->

