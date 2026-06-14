# **Part V** 

**Maintainability** 


# **Introduction** 

_“Everyone knows that debugging is twice as hard as writing a program in the first place. So if you’re as clever as you can be when you write it, how will you ever debug it?”_ 

– Brian Kernighan 

It’s a well-known fact that the majority of the cost of software is spent after its initial development in maintenance activities, such as fixing bugs, adding new features, and operating it. Thus, we should aspire to make our systems easy to modify, extend and operate so that they are easy to maintain. 

Good testing — in the form of unit, integration, and end-to-end tests — is a minimum requirement to be able to modify or extend a system without worrying it will break. And once a change has been merged into the codebase, it needs to be released to production safely without affecting the application’s availability. Also, the operators need to be able to monitor the system’s health, investigate degradations and restore the service when it gets into a bad state. This requires altering the system’s behavior without code changes, e.g., toggling a feature flag or scaling out a service with a configuration change. 

Historically, developers, testers, and operators were part of different teams. First, the developers handed over their software to a team of QA engineers responsible for testing it. Then, when the software passed that stage, it moved to an operations team responsible for deploying it to production, monitoring it, and responding 


278 to alerts. However, this model is being phased out in the industry. Nowadays, it’s common for developers to be responsible for testing and operating the software they write, which requires embracing an end-to-end view of the software’s lifecycle. 

In this part, we will explore some of the best practices for testing and operating large distributed applications. 

Chapter 29 describes the different types of tests — unit, integration, and end-to-end tests — that we can leverage to increase the confidence that a distributed application works as expected. This chapter also explores the use of formal verification methods to verify the correctness of an application before writing a single line of code. 

Chapter 30 dives into continuous delivery and deployment pipelines to release changes safely and efficiently to production. 

Chapter 31 discusses how to use metrics, service-level indicators, and dashboards to monitor the health of distributed applications. It then talks about how to define and enforce service-level objectives that describe how the service should behave when it’s functioning correctly. 

Chapter 32 introduces the concept of observability and its relation to monitoring. Later, it describes how to debug production issues using logs and traces. 

Chapter 33 describes how to modify a system’s behavior without changing its code, which is a must-have to enable operators to quickly mitigate failures in production when everything else fails. 


