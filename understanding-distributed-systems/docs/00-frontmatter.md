## UNDERSTANDING DISTRIBUTED SYSTEMS 

What every developer should know about large distributed applications 

**ROBERTO VITILLO** 


Understanding Distributed Systems Version 2.0.0 

Roberto Vitillo 

March 2022 


## **Contents** 

|**Copyright**|**Copyright**|**Copyright**|||**ix**|
|---|---|---|---|---|---|
|**About the author**|||||**xi**|
|**Acknowledgements**|||||**xiii**|
|**Preface**|||||**xv**|
|**1**|**Introduction**||||**1**|
||1.1|Communication . . . . . . . . . . . . . . . . . . . .|||2|
||1.2|Coordination||. . . . . . . . . . . . . . . . . . . . .|3|
||1.3|Scalability .|.|. . . . . . . . . . . . . . . . . . . . .|3|
||1.4|Resiliency .|.|. . . . . . . . . . . . . . . . . . . . .|5|
||1.5|Maintainability . . . . . . . . . . . . . . . . . . . .|||6|
||1.6|Anatomy of a distributed system<br>. . . . . . . . . .|||7|
|**I**|**Communication**||||**11**|
|**2**|**Reliable links**||||**17**|
||2.1|Reliability .|.|. . . . . . . . . . . . . . . . . . . . .|18|
||2.2|Connection lifecycle<br>. . . . . . . . . . . . . . . . .|||18|
||2.3|Flow control|.|. . . . . . . . . . . . . . . . . . . . .|20|
||2.4|Congestion control . . . . . . . . . . . . . . . . . .|||21|
||2.5|Custom protocols . . . . . . . . . . . . . . . . . . .|||23|
|**3**|**Secure links**||||**25**|
||3.1|Encryption .|.|. . . . . . . . . . . . . . . . . . . . .|25|
||3.2|Authentication||. . . . . . . . . . . . . . . . . . . .|26|
||3.3|Integrity . .|.|. . . . . . . . . . . . . . . . . . . . .|28|
||3.4|Handshake|.|. . . . . . . . . . . . . . . . . . . . .|29|


|CONTENTS|CONTENTS|CONTENTS||iv|
|---|---|---|---|---|
|**4**|**Discovery**|||**31**|
|**5**|**APIs**|||**35**|
||5.1|HTTP<br>. . . . . . .|. . . . . . . . . . . . . . . . . .|37|
||5.2|Resources . . . . .|. . . . . . . . . . . . . . . . . .|39|
||5.3|Request methods .|. . . . . . . . . . . . . . . . . .|41|
||5.4|Response status codes<br>. . . . . . . . . . . . . . . .||42|
||5.5|OpenAPI<br>. . . . .|. . . . . . . . . . . . . . . . . .|43|
||5.6|Evolution<br>. . . . .|. . . . . . . . . . . . . . . . . .|45|
||5.7|Idempotency<br>. . .|. . . . . . . . . . . . . . . . . .|46|
|**II**|**Coordination**|||**53**|
|**6**|**System models**|||**57**|
|**7**|**Failure detection**|||**61**|
|**8**|**Time**|||**63**|
||8.1|Physical clocks<br>. .|. . . . . . . . . . . . . . . . . .|63|
||8.2|Logical clocks . . .|. . . . . . . . . . . . . . . . . .|65|
||8.3|Vector clocks<br>. . .|. . . . . . . . . . . . . . . . . .|67|
|**9**|**Leader election**|||**71**|
||9.1|Raft leader election|. . . . . . . . . . . . . . . . . .|72|
||9.2|Practical considerations . . . . . . . . . . . . . . . .||73|
|**10 **|**Replication**|||**77**|
||10.1|State machine replication . . . . . . . . . . . . . . .||78|
||10.2|Consensus . . . . .|. . . . . . . . . . . . . . . . . .|81|
||10.3|Consistency models|. . . . . . . . . . . . . . . . . .|83|
||10.4|Chain replication .|. . . . . . . . . . . . . . . . . .|90|
|**11 **|**Coordination avoidance**|||**95**|
||11.1|Broadcast protocols|. . . . . . . . . . . . . . . . . .|96|
||11.2|Confict-free replicated data types . . . . . . . . . .||98|
||11.3|Dynamo-style data stores . . . . . . . . . . . . . . .||103|
||11.4|The CALM theorem|. . . . . . . . . . . . . . . . . .|105|
||11.5|Causal consistency|. . . . . . . . . . . . . . . . . .|106|
||11.6|Practical considerations . . . . . . . . . . . . . . . .||110|
|**12 **|**Transactions**|||**111**|
||12.1|ACID<br>. . . . . . .|. . . . . . . . . . . . . . . . . .|112|
||12.2|Isolation . . . . . .|. . . . . . . . . . . . . . . . . .|113|


|CONTENTS|CONTENTS|||v|
|---|---|---|---|---|
||12.3 Atomicity . . .|.|.|. . . . . . . . . . . . . . . . . . 119|
||12.4 NewSQL . . . .|.|.|. . . . . . . . . . . . . . . . . . 122|
|**13 **|**Asynchronous transactions**<br>**127**||||
||13.1 Outbox pattern|.|.|. . . . . . . . . . . . . . . . . . 128|
||13.2 Sagas . . . . . .|.|.|. . . . . . . . . . . . . . . . . . 130|
||13.3 Isolation . . . .|.|.|. . . . . . . . . . . . . . . . . . 133|
|**III**|**Scalability**|||**137**|
|**14 **|**HTTP caching**|||**145**|
||14.1 Reverse proxies|.|.|. . . . . . . . . . . . . . . . . . 148|
|**15 **|**Content delivery networks**<br>**151**||||
||15.1 Overlay network||.|. . . . . . . . . . . . . . . . . . 151|
||15.2 Caching . . . .|.|.|. . . . . . . . . . . . . . . . . . 153|
|**16 **|**Partitioning**|||**155**|
||16.1 Range partitioning|||. . . . . . . . . . . . . . . . . . 157|
||16.2 Hash partitioning||.|. . . . . . . . . . . . . . . . . . 158|
|**17 **|**File storage**|||**163**|
||17.1 Blob storage architecture . . . . . . . . . . . . . . . 163||||
|**18 **|**Network load balancing**|||**169**|
||18.1 DNS load balancing|||. . . . . . . . . . . . . . . . . . 174|
||18.2 Transport layer load|||balancing . . . . . . . . . . . . 175|
||18.3 Application layer load balancing . . . . . . . . . . . 178||||
|**19 **|**Data storage**|||**181**|
||19.1 Replication<br>. .|.|.|. . . . . . . . . . . . . . . . . . 181|
||19.2 Partitioning . .|.|.|. . . . . . . . . . . . . . . . . . 184|
||19.3 NoSQL . . . . .|.|.|. . . . . . . . . . . . . . . . . . 185|
|**20 **|**Caching**|||**191**|
||20.1 Policies<br>. . . .|.|.|. . . . . . . . . . . . . . . . . . 192|
||20.2 Local cache<br>. .|.|.|. . . . . . . . . . . . . . . . . . 193|
||20.3 External cache .|.|.|. . . . . . . . . . . . . . . . . . 194|
|**21 **|**Microservices**|||**197**|
||21.1 Caveats<br>. . . .|.|.|. . . . . . . . . . . . . . . . . . 199|
||21.2 API gateway . .|.|.|. . . . . . . . . . . . . . . . . . 202|


|CONTENTS|CONTENTS||vi|
|---|---|---|---|
|**22 **|**Control planes and data planes**<br>**209**|||
||22.1 Scale imbalance|. .|. . . . . . . . . . . . . . . . . . 211|
||22.2 Control theory .|. .|. . . . . . . . . . . . . . . . . . 214|
|**23 **|**Messaging**||**217**|
||23.1 Guarantees<br>. .|. .|. . . . . . . . . . . . . . . . . . 221|
||23.2 Exactly-once processing<br>. . . . . . . . . . . . . . . 223|||
||23.3 Failures<br>. . . .|. .|. . . . . . . . . . . . . . . . . . 224|
||23.4 Backlogs . . . .|. .|. . . . . . . . . . . . . . . . . . 224|
||23.5 Fault isolation .|. .|. . . . . . . . . . . . . . . . . . 225|
|**IV**|**Resiliency**||**229**|
|**24 **|**Common failure causes**||**233**|
||24.1 Hardware faults|. .|. . . . . . . . . . . . . . . . . . 233|
||24.2 Incorrect error handling<br>. . . . . . . . . . . . . . . 234|||
||24.3 Confguration changes . . . . . . . . . . . . . . . . 234|||
||24.4 Single points of failure . . . . . . . . . . . . . . . . 235|||
||24.5 Network faults|. .|. . . . . . . . . . . . . . . . . . 236|
||24.6 Resource leaks .|. .|. . . . . . . . . . . . . . . . . . 237|
||24.7 Load pressure .|. .|. . . . . . . . . . . . . . . . . . 238|
||24.8 Cascading failures||. . . . . . . . . . . . . . . . . . 238|
||24.9 Managing risk .|. .|. . . . . . . . . . . . . . . . . . 240|
|**25 **|**Redundancy**||**243**|
||25.1 Correlation<br>. .|. .|. . . . . . . . . . . . . . . . . . 244|
|**26 **|**Fault isolation**||**247**|
||26.1 Shuffe sharding|. .|. . . . . . . . . . . . . . . . . . 248|
||26.2 Cellular architecture||. . . . . . . . . . . . . . . . . 250|
|**27 **|**Downstream resiliency**||**253**|
||27.1 Timeout . . . .|. .|. . . . . . . . . . . . . . . . . . 253|
||27.2 Retry . . . . . .|. .|. . . . . . . . . . . . . . . . . . 255|
||27.3 Circuit breaker|. .|. . . . . . . . . . . . . . . . . . 258|
|**28 **|**Upstream resiliency**||**261**|
||28.1 Load shedding|. .|. . . . . . . . . . . . . . . . . . 261|
||28.2 Load leveling .|. .|. . . . . . . . . . . . . . . . . . 262|
||28.3 Rate-limiting<br>.|. .|. . . . . . . . . . . . . . . . . . 263|
||28.4 Constant work|. .|. . . . . . . . . . . . . . . . . . 269|


|CONTENTS|CONTENTS|vii|
|---|---|---|
|**V**|**Maintainability**|**275**|
|**29 **|**Testing**|**279**|
||29.1 Scope<br>. . . . .|. . . . . . . . . . . . . . . . . . . . 280|
||29.2 Size<br>. . . . . .|. . . . . . . . . . . . . . . . . . . . 281|
||29.3 Practical considerations . . . . . . . . . . . . . . . . 283||
||29.4 Formal verifcation . . . . . . . . . . . . . . . . . . 285||
|**30 **|**Continuous delivery**|**and deployment**<br>**289**|
||30.1 Review and build . . . . . . . . . . . . . . . . . . . 290||
||30.2 Pre-production|. . . . . . . . . . . . . . . . . . . . 292|
||30.3 Production . . .|. . . . . . . . . . . . . . . . . . . . 293|
||30.4 Rollbacks<br>. . .|. . . . . . . . . . . . . . . . . . . . 293|
|**31 **|**Monitoring**|**297**|
||31.1 Metrics . . . . .|. . . . . . . . . . . . . . . . . . . . 298|
||31.2 Service-level indicators . . . . . . . . . . . . . . . . 301||
||31.3 Service-level objectives . . . . . . . . . . . . . . . . 304||
||31.4 Alerts<br>. . . . .|. . . . . . . . . . . . . . . . . . . . 306|
||31.5 Dashboards . .|. . . . . . . . . . . . . . . . . . . . 308|
||31.6 Being on call . .|. . . . . . . . . . . . . . . . . . . . 312|
|**32 **|**Observability**|**315**|
||32.1 Logs . . . . . .|. . . . . . . . . . . . . . . . . . . . 316|
||32.2 Traces<br>. . . . .|. . . . . . . . . . . . . . . . . . . . 319|
||32.3 Putting it all together . . . . . . . . . . . . . . . . . 321||
|**33 **|**Manageability**|**323**|
|**34 **|**Final words**|**327**|


## **Copyright** 

**Understanding Distributed Systems** by Roberto Vitillo Copyright © Roberto Vitillo. All rights reserved. 

The book’s diagrams have been created with Excalidraw. 

While the author has used good faith efforts to ensure that the information and instructions in this work are accurate, the author disclaims all responsibility for errors or omissions, including without limitation responsibility for damages resulting from the use of or reliance on this work. The use of the information and instructions contained in this work is at your own risk. If any code samples or other technology this work contains or describes is subject to open source licenses or the intellectual property rights of others, it is your responsibility to ensure that your use thereof complies with such licenses and/or rights. 


## **About the author** 

Authors generally write this page in the third person as if someone else is writing about them, but I like to do things a little bit differently. 

I have over 10 years of experience in the tech industry as a software engineer, technical lead, and manager. 

After getting my master’s degree in computer science from the University of Pisa, I worked on scientific computing applications at the Berkeley Lab. The software I contributed is used to this day by the ATLAS experiment at the Large Hadron Collider. 

Next, I worked at Mozilla, where I set the direction of the data platform from its very early days and built a large part of it, including the team. 

In 2017, I joined Microsoft to work on an internal SaaS for telemetry. Since then, I have helped launch multiple public SaaS products, like Playfab and Customer Insights. The data ingestion platform I am responsible for is one of the largest in the world, ingesting millions of events per second from billions of devices worldwide. 


## **Acknowledgements** 

I am very thankful for the colleagues and mentors who inspired me and believed in me over the years. Thanks to Chiara Roda, Andrea Dotti, Paolo Calafiura, Vladan Djeric, Mark Reid, Pawel Chodarcewicz, and Nuno Cerqueira. 

Rachael Churchill, Doug Warren, Vamis Xhagjika, Alessio Placitelli, Stefania Vitillo, and Alberto Sottile provided invaluable feedback on early drafts. Without them, the book wouldn’t be what it is today. 

A very special thanks to the readers of the first edition who reached out with feedback and suggestions over the past year and helped me improve the book: Matthew Williams, Anath B Chatterjee, Ryan Carney, Marco Vocialta, Curtis Washington, David Golden, Radosław Rusiniak, Sankaranarayanan Viswanathan, Praveen Barli, Abhijit Sarkar, Maki Pavlidis, Venkata Srinivas Namburi, Andrew Myers, Aaron Michaels, Jack Henschel, Ben Gummer, Luca Colantonio, Kofi Sarfo, Mirko Schiavone, and Gaurav Narula. 

I am also very thankful for all the readers who left reviews or reached out to me and let me know they found the book useful. They gave me the motivation and energy to write a second edition. 

Finally, and above all, thanks to my family: Rachell and Leonardo. Without your unwavering support, this book wouldn’t exist. 


## **Preface** 

Learning to build distributed systems is hard, especially if they are large scale. It’s not that there is a lack of information out there. You can find academic papers, engineering blogs, and even books on the subject. The problem is that the available information is spread out all over the place, and if you were to put it on a spectrum from theory to practice, you would find a lot of material at the two ends but not much in the middle. 

That is why I decided to write a book that brings together the core theoretical and practical concepts of distributed systems so that you don’t have to spend hours connecting the dots. This book will guide you through the fundamentals of large-scale distributed systems, with just enough details and external references to dive deeper. This is the guide I wished existed when I first started out. 

If you are a developer working on the backend of web or mobile applications (or would like to be!), this book is for you. When building distributed applications, you need to be familiar with the network stack, data consistency models, scalability and reliability patterns, observability best practices, and much more. Although you can build applications without knowing much of that, you will end up spending hours debugging and re-architecting them, learning hard lessons that you could have acquired in a much faster and less painful way. 

However, if you have several years of experience designing and building highly available and fault-tolerant applications that scale to millions of users, this book might not be for you. As an expert, 


CONTENTS xvi you are likely looking for depth rather than breadth, and this book focuses more on the latter since it would be impossible to cover the 

The second edition is a complete rewrite of the previous edition. Every page of the first edition has been reviewed and where appropriate reworked, with new topics covered for the first time. 

This book is available both in a physical and digital format. The digital version is updated occasionally, which is why the book has a version number. You can subscribe to receive updates from the book’s landing page[1] . 

As no book is ever perfect, I’m always happy to receive feedback. So if you find an error, have an idea for improvement, or simply want to comment on something, always feel free to write me[2] . I love connecting with readers! 

> 1https://understandingdistributed.systems/ 

> 2roberto@understandingdistributed.systems 


