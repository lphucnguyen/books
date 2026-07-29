# Part II: Diving Deep into AWS Services

## PART II Diving Deep into AWS Services

_Big and dumb is better._ —Mark Hill

Part II of this book covers the common AWS network, storage, compute, orchestration, big data and analytics, and machine learning (ML) services. We’ll explore the inherent designs and benefits of these managed services. This part also provides guidance for how these services need to be structured in a well-architected framework to build secure, high-performing, resilient, and efficient infrastructure for a variety of applications and workloads.

At the end of Part II, you will:

- Understand the network services offered by AWS and how to use them to build a • resilient cloud infrastructure

- Be able to identify the appropriate AWS storage services for different data man‐• agement needs and use cases

- Learn about the compute services offered by AWS and how to identify the • right size and type of resource while keeping the variable cost in check using containers and other serverless offerings for different kinds of workloads

- Use the orchestration services offered by AWS to properly decouple and scale the • application on AWS, improving flexibility and performance


- Know what big data and analytics services are offered by AWS to run large-scale • jobs and answer queries on large datasets to derive value from your big data

- Discover the ML services offered by AWS and learn how to solve ML business • use cases and set up ML pipelines and operations for your business using the managed offerings

Chapter 9 will dive into the fully managed network services that AWS offers. You’ll discover how to use them to create a strong, resilient cloud infrastructure. We’ll begin with learning how to get started on the AWS cloud. Then, we’ll cover basic networking concepts, such as how the internet works, virtual private cloud (VPC), subnets, internet connectivity within and outside the AWS cloud, NAT gateways (a way for your cloud systems to communicate securely with the outside world), Amazon Route 53 (for managing domain names), Amazon CloudFront (to make your web services load faster), AWS Elastic Load Balancer (ELB), and Amazon API Gateway.

Chapter 10 will explore the managed storage services provided by AWS and help you understand how to choose the right storage services for different needs. The chapter will start with Amazon Elastic Block Store (EBS), Amazon Elastic File System (EFS), and Amazon Simple Storage Service (S3) object store and its different classes. The chapter will then cover databases, including Amazon Relational Database Service (RDS), Amazon Aurora, Amazon DynamoDB, Amazon DocumentDB, Amazon Keyspaces, Amazon Timestream, and Amazon Neptune, as well as Amazon ElastiCache, including ElastiCache for Redis and ElastiCache for Memcached.

Chapter 11 will introduce you to the compute services that AWS offers. We’ll figure out how to choose the right kind and size of compute resources for different jobs. We’ll look at services like Amazon Elastic Compute Cloud (EC2), which is like renting virtual computers in the cloud. Then we’ll talk about AWS Lambda, a special kind of on-demand computing that happens in response to events; Amazon Elastic Container Registry (ECR); AWS Fargate for Elastic Container Service (ECS), which manages and deploys containers; and ECS Elastic Kubernetes Service (EKS) cluster for running applications in containers.

Chapter 12 will cover the messaging, orchestration, monitoring, and access management services from AWS. These services help you manage and coordinate different tasks in your software system. We’ll talk about Amazon Simple Queue Service (SQS), a way for different parts of your system to communicate indirectly; Amazon Simple Notification Service (SNS) for sending messages; and Amazon Managed Streaming for Apache Kafka (MSK) and Amazon Kinesis, which enable different parts of your system to talk to one another. We’ll also explore AWS Step Functions to help you piece together workflows and AWS Managed Workflows to help you manage and monitor workflows. Last, we will cover Amazon CloudWatch for monitoring and debugging your cloud applications, AWS Identity and Access Management (IAM)


for authentication and authorization over AWS resources, Amazon Cognito for managing identity pools, and AWS AppSync to orchestrate all AWS services under one GraphQL endpoint.

Chapter 13 will explore AWS’s big data, analytics, and ML Services. These services help you work with huge amounts of data and find valuable insights. We’ll check out Amazon Redshift, a powerful tool for analyzing data; Amazon Elastic MapReduce (EMR) for processing big data; Amazon Athena for asking questions about your data; AWS Glue for preparing and transforming data; and Amazon QuickSight for creating visual reports. This chapter will also introduce you to the ML services offered by AWS, showing you how to solve ML business use cases and set up ML data pipelines and operations for your business using the managed offerings.

By the end of Part II, you’ll have a clear understanding of all these AWS services and how to use them effectively. You’ll know how to build a strong, secure cloud infrastructure that can handle different tasks and workloads.

Later, Part III provides several real-world examples of designing systems using AWS cloud computing services. We’ll break down different use cases step-by-step in an easy-to-understand way, using the concepts from Part I and the AWS services from Part II for practical implementation.


