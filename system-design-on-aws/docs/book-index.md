# Index

# Index

### Symbols 80/20 rule, 96

### A abstract syntax tree (AST), 48 abstraction, 6 access control Cognito, 323-326 IAM, 320-323 access control lists (ACLs), 262 accounts (AWS), creating, 222 ACID model, 43-44, 70 ACLs (access control lists), 262 active cache invalidation, 100 active-active failover pattern, 16 active-passive failover pattern, 16 activities (in Step Functions), 310 actor model, 507-509 ADCs (application delivery controllers), 123 Advanced Message Queuing Protocol (AMQP),

189 AI (artificial intelligence), 344 Airflow, 313-314 alarm conditions, 317 alarms, 317-318 ALB (application load balancer), 131, 248 algorithms for load balancing, 125-127 allowlist policies, 99 Amazon Machine Image (AMI), 281-282 Amazon States Language (ASL), 310 Amazon VPC (see VPC service) Amazon Web Services (see AWS) Amdahl’s law, 96 AMI (Amazon Machine Image), 281-282

Amplify, 374 AMQP (Advanced Message Queuing Protocol),

189 analytics (see big data analytics) anticorruption layer, 205 AOFs (append-only files), 115-116 Apache Airflow, 313-314 Apache Cassandra, 88-89 Apache Kafka (see Kafka) API Gateway (AWS), 121, 250-251 API gateways, 121, 204 API routing patterns, 204-205 API servers, 175 APIs (application programming interfaces), 154

GraphQL, 157-159 RESTful, 155-157 for URL shortener service, 365-367 WebRTC, 159-160 App Runner, 375, 378 append-only files (AOFs), 115-116 application caching, 107 application code, 167 application delivery controllers (ADCs), 123 application deployment CI/CD pipeline, 180-182 container deployment strategies, 178-180 evolution of, 164-166 application layer protocols, 143-150 application load balancer (ALB), 131, 248 application logs, 315 application processes, 172 application programming interfaces (see APIs) AppSync, 326-327, 516 architectural designs and patterns


big data, 193-196 CDC (change data capture), 186-188 choreography, 190, 193 cloud, 202-206 distributed systems, 206-215

HDFS, 206-209, 215 Kafka, 211-215 EDA (event-driven architecture), 199-202 orchestration, 191-193 pub/sub model, 188-189 solution, 196-199 archived objects storage class, 260 artificial intelligence (AI), 344 ASGs (autoscaling groups), 284 ask prices (stocks), 546 ASL (Amazon States Language), 310 AST (abstract syntax tree), 48 asynchronous checkpointing, 23 asynchronous communication, 8, 150-153 asynchronous invocation, 288 asynchronous orchestration patterns, 192 asynchronous replication, 62-63 at-least-once delivery, 214 at-most-once delivery, 214 Athena, 338-339 atomicity, 43 audit-column-based CDC, 187 Aurora, 263, 470, 493-497 Aurora DSQL, 264 Aurora Limitless Database, 494-496 authentication Cognito, 323-326 IAM, 320-323 for social network, 431-433 auto-increment feature (databases), 364 autoscaling, 284-285 autoscaling groups (ASGs), 284 availability, 13-18

consistency versus, 28-30 in document stores, 80 ensuring, 15 in key-value stores, 76-77 measuring, 13-14 of nonrelational databases, 69 patterns, 16-18 in Redis, 114-115 reliability and, 20 sequential systems versus parallel systems,

14-15

in social network use case, 437 availability zones (AWS), 223 AWS (Amazon Web Services) account creation, 222 availability zones, 223 cloud storage services, 256-262 compute services choosing, 295-296 containerization (see containerization) EC2, 279-285 Lambda, 286-289 database services, 262-277

Aurora, 263, 470, 493-497 DocumentDB, 268-269 DynamoDB, 265-268 ElastiCache, 272-274 Keyspaces, 276-277 Neptune, 269-272 OpenSearch, 274-275 RDS, 262-264 Timestream, 276 edge locations, 224 Hadoop ecosystem versus, 209-211 local zones, 224 networking services (see networking services (AWS)) regions, 223 shared responsibility model, 221, 223

### B B+ trees, 51-52 back queue routers, 395 back queue selectors, 396 back queues, 395 backend for frontend (BFF), 206 bandwidth, 27, 445 bare-metal servers, 280 base image, 167 BASE principles, 69-70 base62 encoding, 362 Belady’s algorithm, 97 benchmarking, 52 BFF (backend for frontend), 206 bid prices (stocks), 546 big data analytics Athena, 338-339 EMR (Elastic MapReduce), 330-333 Glue, 333-338 QuickSight, 339-340


Redshift, 340-343 big data architectures, 193-196 bitrate, 529 block-based storage, 36, 37-38, 256-257 blocks (HDFS), 208 Bloom filters, 87 blue-green deployments, 179 boundaries, system, 389 bounded stream processing, 302 branch management, 180 Brewer’s theorem (see CAP theorem) brokers, 212 bucket policies, 262 buckets, 259 buffer managers, 48

### C cache hit, 95 cache layer, 450 cache managers, 49 cache miss, 95 cache warm-up, 104 cache, definition of, 95 cache-aside caching strategy, 103 caching benefits of, 96-97 CDNs (content delivery networks), 108-111 deployment strategies, 105-106 with ElastiCache, 272-274 eviction policies, 97-99 invalidation policies, 100-101 mechanisms for, 107-108 in Neptune, 271 in online game leaderboard, 448 open source solutions, 111-118 strategies for, 102-105 callbacks, 8 canary deployments, 179 candidate keys, 46 CAP theorem, 28-30 capacity modes (DynamoDB), 266 Cassandra, 88-89 catalogs, 50 causal consistency, 11 CD (continuous deployment), 182 CDC (change data capture), 186-188, 202 CDN-based GSLB, 123 CDNs (content delivery networks), 107,

108-111, 532

cell-based architecture, 370 cellular architecture, 206 change data capture (CDC), 186-188, 202 chaos engineering, 409 chat applications use case, 501-523

architecture design, 503-511 Day 0 architecture, 516-520 Day N architecture, 520-522 direct messaging, 505-509 media content storage, 510-511 message storage, 509-510 protocol selection, 504-505 system requirements, 501-503 WhatsApp architecture, 511-516 with WebSockets, 151-152 XMPP, 148-149, 504-505 checkpointing, 23-24 choosing compute services, 295-296 databases, 93

for chat application, 509-510 for hotel reservation system, 479-480 for URL shortener service, 368-369 for user post service, 420-422 protocols for chat application, 504-505 choreographed asynchronous events, 190 choreography, 190, 193 CI (continuous integration), 181 CI/CD pipeline, 180-182 CIDR (Classless Inter-Domain Routing), 228 CIDR blocks, 230-231 circuit breaker pattern, 203 classic load balancer (CLB), 248 classifiers (Glue), 333 Classless Inter-Domain Routing (CIDR), 228 CLB (classic load balancer), 248 client multiplexing, 110 client-side caching, 107 clients, 279 cloud architecture patterns, 202-206 cloud computing services (see networking services (AWS)) cloud storage services (AWS), 256-262

EBS (Elastic Block Store), 256-257 EFS (Elastic File System), 257-258 S3 (Simple Storage Service), 259-262 cloud-managed services, self-hosting versus,

566


CloudFront, 111, 224, 251-253, 538-539 CloudWatch, 315-320

alarms, 317-318 application logs, 315 events, 319-320 metrics, 316-317 cluster endpoints, 271 clustering keys in column-family stores, 84 clusters, 176, 331-333 codecs, 529 CodeWhisperer, 346 Cognito, 323-326, 431 cold start, 104, 288 collections, 79 collisions, 360-361 column-family stores, 69, 83-90

advantages and trade-offs, 88 Apache Cassandra, 88-89 architecture, 86-88 consistency levels, 84-86 data model, 83-84 Keyspaces, 276-277 columns (in relational databases), 40 command query responsibility segregation (CQRS), 202 comment publication (social network use case),

430-431 commit logs, 86 communication, 6-8, 137, 221

(see also networking services (AWS)) asynchronous, 8, 150-153 OSI model, 138-139 protocol standards, 154-160

GraphQL, 157-159 REST, 155-157 RPC, 154-155 WebRTC, 159-160 protocols, 138 pub/sub model, 188-189

Kinesis, 299-305 MSK (Managed Streaming for Apache Kafka), 297-299 SNS (Simple Notification Service),

307-309 SQS (Simple Queue Service), 305-306 pull-based mechanisms, 150 push-based mechanisms, 151-153 synchronous, 7, 150 TCP/IP model, 139-150

application layer protocols, 143-150 network layer protocols, 140 transport layer protocols, 140-143 compaction strategies, 87 complexity of distributed systems, 12 composite alarms, 318 Comprehend, 346 compression, 403-404 compute services (AWS) choosing, 295-296 containerization (see containerization) EC2, 279-285 Lambda, 286-289 for online game leaderboard, 455 for URL shortener service, 378-379 concurrency control managers, 49 concurrency in hotel reservation system,

480-482 ConfigMaps, 177 configurable alarm actions, 318 configuration files, 168 configuration levels (Kafka), 213 configuration-based load balancers, 132-133 conflict resolution, 9 congestion, 517 congestion avoidance, 141, 145, 518-519, 539 consensus protocols, 9 consistency, 8-12, 44

availability versus, 28-30 in CDNs, 110 in column-family stores, 84-86 consistency spectrum model, 10-12 in data storage systems, 9-10 in distributed systems, 8 in online game leaderboard, 447 consistency spectrum model, 10-12 consistent hashing, 75 constraints, 42 consumers, 212, 241 container images, 167-169 container registries, 169-171 containerd, 173 containerization, 163

deployment strategies, 178-180 Docker, 166-174

container lifecycle, 171-172 Docker engine, 172-174 images, 167-169 registries, 169-171


ECS (Elastic Container Service), 290-293 EKS (Elastic Kubernetes Service), 293-295 Kubernetes, 174-177 containers, 163

deployment strategies, 178-180 lifecycle, 171-172 orchestration, 174-177 VMs versus, 164-166 content consistency in CDNs, 110 content delivery networks (see CDNs) content distribution, 532 content fragmentation, 109 content indexing, 531-532 content personalization, 110 continuous deployment (CD), 182 continuous integration (CI), 181 control plane nodes, 174 controller managers, 175 cookie-based session affinity, 128 cooldown periods, 285 coprocessors, 347 copy-on-write (CoW), 116-118 core nodes, 332 CoW (copy-on-write), 116-118 CQRS (command query responsibility segregation), 202 cross-VPC connectivity, 239-242 custom domain support for URL shortener service, 369-370

### D DAGs (Directed Acyclic Graphs), 313 dashboards (QuickSight), 339-340 data catalogs, 334 data compression, 403-404 data control language (DCL), 43 data copying, 343 data crawlers, 334 data definition language (DDL), 43 data dictionaries, 50 data engines, 335 data ingestion, 343 data lakes, 195-196 data manipulation language (DML), 43 data modeling, 446 data processing units (DPUs), 336 data replication, 9 data retrieval, 456 data security (S3), 261-262

data sharing, 343 data storage systems cloud storage services (AWS), 256-262 consistency in, 9-10 formats of, 36-39 for hotel reservation system, 479-480 for media content, 510-511 nonrelational databases (see nonrelational databases) relational databases (see relational databases) data streaming KDA (Kinesis Data Analytics), 302-303 KDF (Kinesis Data Firehose), 303-304 KDS (Kinesis Data Streams), 299-301 KVS (Kinesis Video Streams), 304-305 data tiering, 272 data versioning, 10 database caching, 108 database management systems (DBMS), 39-40

open source RDBMS, 63-65 RDBMS architecture, 47-50 databases, 39-40

auto-increment feature, 364 AWS, 262-277

DocumentDB, 268-269 DynamoDB, 265-268 ElastiCache, 272-274 Keyspaces, 276-277 Neptune, 269-272 OpenSearch, 274-275 RDS, 262-264 Timestream, 276 choosing, 93

for chat application, 509-510 for hotel reservation system, 479-480 for URL shortener service, 368-369 for user post service, 420-422 Glue, 334 migration, 435 nonrelational (see nonrelational databases) for online game leaderboard, 449-450 for order management system, 552 for property onboarding architecture,

470-471 relational (see relational databases) for WhatsApp, 514-516 DataNodes, 208 DAX (DynamoDB Accelerator), 274


Day 0 architecture for chat application, 516-520 for hotel reservation system, 490-497 for online game leaderboard, 451-460 for social network, 427-436 for stockbroker application, 557-562 for URL shortener service, 371-379 for video processing, 534-540 for web crawler/search engine, 405-409 Day N architecture for chat application, 520-522 for hotel reservation system, 497-498 for online game leaderboard, 460-463 for social network, 436-439 for stockbroker application, 562-566 for URL shortener service, 379-383 for video processing, 540-542 for web crawler/search engine, 409-413 DBMS (database management systems), 39-40

open source RDBMS, 63-65 RDBMS architecture, 47-50 DCL (data control language), 43 DDD (domain-driven design), 203 DDL (data definition language), 43 dead letter queue (DLQ), 306 decompose by subdomains pattern, 204 dedicated tenancy, 230 delegation, 323 DELETE method, 144 DeleteItem operation (key-value stores), 73 deleting indexes, 474 denormalization, 53-54 dependencies, 168 deployment CI/CD pipeline, 180-182 container deployment strategies, 178-180 evolution of, 164-166 Kubernetes, 176 deployment packages, 287 deployment strategies for caches, 105-106 Kubernetes, 178-180 for load balancers, 123-125 designs (see architectural designs and patterns) destinations (Lambda), 287 digital rights management (DRM), 532 dimensions (of metrics), 316 Direct Connect, 244-246, 535 direct messaging, 505-509

Directed Acyclic Graphs (DAGs), 313 disaster recovery, 59 distributed systems, 206-215

complexity and consistency, 12 consistency in, 8 fallacies of, 24-26 HDFS, 206-209, 215 Kafka, 211-215 distribution styles (Redshift), 342 DLQ (dead letter queue), 306 DML (data manipulation language), 43 DNS (Domain Name System), 246-247 DNS load balancers, 129 DNS redirection, 110 DNS-based GSLB, 123 Docker, 163, 166-174

container lifecycle, 171-172 images, 167-169 registries, 169-171 Docker CLI, 173 Docker Client, 170 Docker daemon, 173 Docker engine, 172-174 Docker Host, 170 Docker Registry, 170 Dockerfiles, 166 document stores, 68, 79-83

advantages and trade-offs, 81 availability, 80 data model, 79-80 DocumentDB, 83, 268-269 MongoDB, 82-83 DocumentDB, 83, 268-269 documents, 79 Domain Name System (DNS), 246-247 domain-based patterns, 203 domain-driven design (DDD), 203 DPUs (data processing units), 336 DRM (digital rights management), 532 duplicate detection for URLs, 397-398 durability, 44

in Redis, 115-116 dynamic content caching optimization, 109 dynamic load balancing algorithms, 126-127 dynamic pricing, 486-488 Dynamo, 78 DynamoDB, 265-268

for chat application, 517 limitations of, 422


for online game leaderboard, 453, 455 for property onboarding architecture, 471 scaling, 368 for social network, 428-429 for social network, 427 for URL shortener service, 368, 376 for user post service, 421 for web crawler/search engine, 407 DynamoDB Accelerator (DAX), 274

### E EBS (Elastic Block Store), 38, 256-257 EC2 (Elastic Compute Cloud), 279-285

AMIs, 281-282 autoscaling, 284-285 block-based storage, 38 file-based storage, 37 instance types, 282-284 for machine learning, 347 placement groups, 560 for URL shortener service, 371-373 ECMP (equal-cost multipath) routers, 130 ECR (Elastic Container Registry), 291 ECS (Elastic Container Service), 290-293, 455 EDA (event-driven architecture), 199-202 edge locations (AWS), 224, 252 edge side include (ESI) tags, 109 EFS (Elastic File System), 37, 257-258 Ejabberd, 511 EKS (Elastic Kubernetes Service), 177, 293-295 Elastic Block Store (EBS), 38, 256-257 Elastic Compute Cloud (see EC2) Elastic Container Registry (ECR), 291 Elastic Container Service (ECS), 290-293, 455 Elastic File System (EFS), 37, 257-258 elastic IP addresses, 229 Elastic Kubernetes Service (EKS), 177, 293-295 Elastic Load Balancers (ELBs), 121, 248-250 Elastic MapReduce (EMR), 207, 330-333, 338 ElastiCache, 118, 272-274, 376, 453 Elasticsearch, 472-475 ELBs (Elastic Load Balancers), 121, 248-250 Elemental MediaConvert, 534 Elemental MediaLive, 535 Elemental MediaPackage, 535 Elemental MediaStore, 536 email communications (SMTP), 146-148 EMR (Elastic MapReduce), 207, 330-333, 338 EMRFS (EMR File System), 330-331

encoding, 529-530 encryption, 261, 273, 308 EOS (exactly-once semantics), 214 ephemeral ports, 142 equal-cost multipath (ECMP) routers, 130 ER model, 45 Erlang, 511-516 Erlang term storage (ETS), 514 ESI (edge side include) tags, 109 ETags, 101, 394 etcd, 175 ETS (Erlang term storage), 514 event sourcing, 200-202 event stores, 200 event-driven architecture (EDA), 199-202 event-driven state machines, 200 EventBridge, 319-320 events, 199, 286, 319-320 eventual consistency, 11, 85, 447 eviction policies for caches, 97-99 exactly-once semantics (EOS), 214 execution engines, 48 execution environment, 286 execution plans, 48 Extensible Messaging and Presence Protocol (XMPP), 148-149, 504-505

### F FaaS (function as a service), 179 failover patterns, 16 failure-tolerant patterns, 203 fault tolerance, 15, 22-24, 69 federated query, 339, 343 fields (in relational databases), 40 FIFO (first-in, first-out) caching policy, 97 FIFO (first-in, first-out) queues, 306, 396 file-based storage, 36, 257 filesystems EMRFS, 330-331 HDFS, 206-209, 215 first-in, first-out (FIFO) caching policy, 97 first-in, first-out (FIFO) queues, 306, 396 fixed topology fallacy, 25 flexible schema design in column-family stores, 84 nonrelational databases, 68 Flink, 302-303 Forecast, 347 foreign keys, 41, 47


forking, 116-118 forward indexes, 392 forward proxies, 121 fragmentation, 140 frequency-based cache eviction policies, 98-99 frequently accessed objects storage class, 259 front queue selectors, 395 front queues, 395 frontend API, 450 FSx for Lustre, 258 FSx for Windows File Server, 258 function (Lambda), 286 function as a service (FaaS), 179 functional requirements chat application, 502 hotel reservation system, 466-467 online game leaderboard, 442-443 social network, 416 stockbroker application, 544 URL shortener service, 356 video processing, 526 web crawler/search engine, 388 functionality-based load balancers, 129-131

### G game use case (see online game leaderboard use case) gateway load balancer (GWLB), 248 gateways, 147 Geohash, 477 GET method, 144 GetItem operation (key-value stores), 73 Gitflow, 180 global secondary indexes (GSIs), 267 global server load balancing (GSLB), 123 Glue, 333-338 graph databases, 69, 90-93, 269-272 GraphQL, 157-159, 326-327, 475-476 GSIs (global secondary indexes), 267 GSLB (global server load balancing), 123 GWLB (gateway load balancer), 248

### H Hadoop Distributed File System (HDFS),

206-209, 215, 330-331 Hadoop ecosystem AWS versus, 209-211 HDFS integration, 207 handshake process, 152

hard disk drives (HDDs), 257 hardware load balancers, 132 hash partitioning, 55-56 hash-based algorithms, 126 hashing, 360-361 HDDs (hard disk drives), 257 HDFS (Hadoop Distributed File System),

206-209, 215, 330-331 heartbeat mechanism, 81 HFT (high-frequency trading), 545, 553-555 high availability, 28, 59, 69 high-frequency trading (HFT), 545, 553-555 hinted handoff, 77 historical stock tick service, 549-550 homogeneous network fallacy, 26 horizontal partitioning, 55 horizontal scaling, 21 host ID, 226 hostname routing, 204 hot partitions/hot keys, 267 hot spots, 56 hot-swap deployment, 512 hotel reservation system use case, 465-499

architecture design, 469-490

payment processing architecture,

482-485 property booking architecture, 478-488 property onboarding architecture,

469-471 property reviews architecture, 488-490 property search architecture, 471-478 Day 0 architecture, 490-497 Day N architecture, 497-498 system requirements, 465-469 HTTP (Hypertext Transfer Protocol), 143-146 HTTP header routing, 204 HTTP headers, 145 HTTP polling, 151 HTTP response status codes, 145-146, 366 HTTP/1.1, 145 HTTP/2, 145 HTTP/3, 145 hybrid connectivity, 243-246 hybrid orchestration and choreography pattern,

192 Hypertext Transfer Protocol (HTTP), 143-146 hypervisors, 164, 280


### I IaC (infrastructure-as-code), 179, 231 IAM (Identity and Access Management), 262,

320-323 ICE (Interactive Connectivity Establishment),

159 ICMP (Internet Control Message Protocol), 140 idempotence, 214, 484-485 Identity and Access Management (IAM), 262,

320-323 identity pools, 324 identity providers (IdPs), 323 IDL (interface definition language), 155 IdPs (identity providers), 323 IGW (Internet Gateway), 232, 237-238 images (Docker), 167-169 IMAP (Internet Message Access Protocol), 147 in-memory databases (see caching) in-process caching, 105 inbound rules, 235 incident management, 182 index aliases, 475 index support, 267 indexes, 42, 50-52

deleting, 474 key-value stores, 71 search engine use case, 399-404 video processing, 531-532 inference, 348 Inferentia, 348 infinite bandwidth fallacy, 25 infrastructure-as-code (IaC), 179, 231 infrequently accessed objects storage class, 260 ingestion system (see video processing use case) init process, 172 initial costs (in TCO), 457-459 instance endpoints, 271 instance stores, 256 instances, 280

autoscaling, 284-285 launching, 281-282 types of, 282-284 intelligence, 344 intelligent tiering, 261 Interactive Connectivity Establishment (ICE),

159 interface definition language (IDL), 155 internet connectivity NACLs, 236-237

route tables, 233-234 security groups, 234-235 to VPC service, 237-239 Internet Control Message Protocol (ICMP), 140 Internet Gateway (IGW), 232, 237-238 Internet Message Access Protocol (IMAP), 147 Internet Protocol (IP), 140 internet protocol suite (see TCP/IP model) interprocess caching, 106 invalidation policies for caches, 100-101 inverted indexes, 392, 402-404 IP (Internet Protocol), 140 IP addresses, 140, 226-230

elastic, 229 IPv4, 226-228 IPv6, 228 private, 229 public, 229 IP datagrams, 140 IP headers, 140 IPv4, 226-228 IPv6, 228 IRLBot research paper, 396 islands (in Erlang clusters), 514 isolation, 31, 44

### J Jabber ID (JID), 149 jobs (Kubernetes), 177

### K Kafka, 189, 211-215, 297 kappa architecture, 194 KDA (Kinesis Data Analytics), 302-303 KDF (Kinesis Data Firehose), 303-304 KDS (Kinesis Data Streams), 299-301 Kendra, 346, 406, 407 key generation service, 364-365, 369 key-value stores, 69, 71-78

access and retrieval operations, 73 advantages and trade-offs, 77 availability, 76-77 data model, 71-73 Dynamo, 78 DynamoDB, 265-268 scaling, 73-75 keys, 46-47

candidate, 46 in column-family stores, 84


in DynamoDB, 265 foreign, 41, 47 Kafka, 213 in key-value stores, 71-73 primary, 41, 46 Keyspaces, 90, 276-277 Kinesis, 215, 299-305 Kinesis Data Analytics (KDA), 302-303 Kinesis Data Firehose (KDF), 303-304 Kinesis Data Streams (KDS), 299-301 Kinesis Video Streams (KVS), 304-305 KISS (Keep It Simple, Silly), 32 KRaft (Apache Kafka Raft), 212 kube-proxy, 175 kubelets, 175 Kubernetes, 174-177

deployment strategies, 178-180 EKS (Elastic Kubernetes Service), 293-295 KVS (Kinesis Video Streams), 304-305

### L Lambda, 286-289

for online game leaderboard, 453, 455 for URL shortener service, 374, 378 for web crawler/search engine, 407 lambda architecture, 193-194 Landing Zone, 222 last in, first out (LIFO), 98 last write wins (LWW), 76 latency, 59

in online game leaderboard, 446 programming languages and, 554 in search engine, 402-404 in stockbroker application, 559-561 throughput versus, 27-28 ultra-low, 545, 553-555 launching ECS launch types, 291 instances, 281-282 layers (Lambda), 287 LBaaS (load balancer as a service), 132 LBs (load balancers), 120

ALB (application load balancer), 131, 248 CLB (classic load balancer), 248 deployment and placement strategies,

123-125 ELB (Elastic Load Balancer), 248-250 GWLB (gateway load balancer), 248 Nginx, 133-135

NLB (network load balancer), 130-131, 248 session persistence, 127-129 types of, 129-133 leaderboard service, 449 leaderboards (see online game leaderboard use case) leaderless replication, 74-75 least connections algorithms, 126 least frequently recently used (LFRU), 99 least frequently used (LFU), 98 least loaded algorithms, 126 least recently used (LRU), 98 least response time algorithms, 126 leveled compaction, 87 Lex, 346 LFRU (least frequently recently used), 99 LFU (least frequently used), 98 lifecycle configurations, 260 LIFO (last in, first out), 98 listeners, 248 live stock ticks architecture, 547-549 live streaming services (see video processing use case) load balancer as a service (LBaaS), 132 load balancers (LBs), 120

ALB (application load balancer), 131, 248 CLB (classic load balancer), 248 deployment and placement strategies,

123-125 GWLB (gateway load balancer), 248 Nginx, 133-135 NLB (network load balancer), 130-131, 248 session persistence, 127-129 types of, 129-133 load balancing, 15

algorithms, 125-127 benefits of, 122-123 deployment and placement strategies,

123-125 in Neptune, 271 with Nginx, 133-135 session persistence, 127-129 types of load balancers, 129-133 load distribution, 59 local load balancing, 123-125 local quorum, 85 local secondary indexes (LSIs), 267 local zones (AWS), 224, 560 locality, 95


location searches, 477-478 locking, 10, 480-482 locks, 481 log-based CDC, 187 logical database schema design, 40-42 logs, 315 LRU (least recently used), 98 LSI (local secondary indexes), 267 lucidity, 22 LWW (last write wins), 76

### M machine learning, 343-348 Macie, 262 magnetic disks, 257 mail transfer agents (MTAs), 147 maintainability, 21 maintenance costs (in TCO), 459 Make it Work, Make it Right, Make it Fast prin‐ ciple, 351, 371 Managed Streaming for Apache Kafka (MSK),

215, 297-299, 300 Managed Workflow for Apache Airflow (MWAA), 313-314 manager nodes, 174 materialized views, 342 maximum message size, 306 maximum transmission unit (MTU), 140 mean time between failures (MTBF), 19 mean time to repair (MTTR), 19 measuring availability, 13-14 performance, 32-33 reliability, 19-20 media content storage, 510-511, 513 Memcached, 111-112, 272 memory capacity, time-space trade-offs, 27 memory management in Redis, 116-118 MemoryDB, 116 memtables, 86 Merkle trees, 75, 394 message attributes, 308 message brokers, 188-189 message delivery failure handling, 308 message durability, 308 message filtering, 308 message ordering, 309 message queues, 189

Kafka, 211-215

SQS (Simple Queue Service), 305-306 Message Queuing Telemetry Transport (MQTT), 149-150, 504-505 message security, 308 messaging guarantees (Kafka), 214 messaging system, 450, 501

(see also chat applications) metadata, 334 metadata repositories, 50 metrics, 32, 316-317 microservices, 198-199 migration costs (in TCO), 460 migration of social network system, 433-436 MIME (Multipurpose Internet Mail Extensions), 147 minions, 175 ML (machine learning), 343-348 Mnesia, 514 modifiability, 22 modification, invalidation on, 100 modular systems, 31 MongoDB, 82-83, 269 monitoring, 182

with CloudWatch, 315-320 URL shortener service, 376 monoliths, 196-197 monotonic read consistency, 10, 11 most recently used (MRU), 98 MQTT (Message Queuing Telemetry Transport), 149-150, 504-505 MRU (most recently used), 98 MSK (Managed Streaming for Apache Kafka),

215, 297-299, 300 MTAs (mail transfer agents), 147 MTBF (mean time between failures), 19 MTTR (mean time to repair), 19 MTU (maximum transmission unit), 140 multileader replication, 17, 60 Multipurpose Internet Mail Extensions (MIME), 147 multiregion deployments in chat application, 519 in social network use case, 438-439 multitenant systems for URL shortener service,

369-370 multithreading, 273 multitier CDN architecture, 110 mutations, 158


MWAA (Managed Workflow for Apache Airflow), 313-314 MySQL, 63-65

### N N-tier architectures, 197 NACLs (network access control lists), 236-237 NameNodes, 208 namespaces, 316 NAT gateways, 238-239 Neo4j, 91-92 Neptune, 93, 269-272 network access control lists (NACLs), 236-237 network ID, 226 network layer protocols, 140 network load balancers (NLBs), 130-131, 248 networking components, 120-122 networking services (AWS) API Gateway, 250-251 CloudFront, 251-253 ELB (Elastic Load Balancer), 248-250 in high-frequency trading (HFT), 553-554 internet connectivity NACLs, 236-237 route tables, 233-234 security groups, 234-235 to VPC service, 237-239 Route 53 (DNS services), 246-247 VPC service, 225-233

creating VPC, 230-231 cross-VPC connectivity, 239-242 hybrid connectivity, 243-246 internet connectivity to, 237-239 IP addresses, 226-230 subnets, 231-233 newsfeeds, 415

(see also social network use case) NFRs (see nonfunctional requirements) Nginx, 133-135 NLBs (network load balancers), 130-131, 248 nodes, 174 nonfunctional requirements chat application, 502 hotel reservation system, 467 online game leaderboard, 443 social network, 416 stockbroker application, 544-545 URL shortener service, 357 video processing, 526

web crawler/search engine, 388-389 nonrelational databases availability and fault tolerance, 69 BASE principles, 69-70 column-family stores, 69, 83-90

advantages and trade-offs, 88 Apache Cassandra, 88-89 architecture, 86-88 consistency levels, 84-86 data model, 83-84 Keyspaces, 276-277 document stores, 68, 79-83

advantages and trade-offs, 81 availability, 80 data model, 79-80 DocumentDB, 268-269 MongoDB, 82-83 graph databases, 69, 90-93, 269-272 key-value stores, 69, 71-78

access and retrieval operations, 73 advantages and trade-offs, 77 availability, 76-77 data model, 71-73 Dynamo, 78 DynamoDB, 265-268 scaling, 73-75 relational databases, compared, 94 scalability, 69 schema flexibility, 68 normalization, 45-46 NoSQL databases (see nonrelational databases) notebooks, 303

### O object lock, 261 object-based storage, 36, 38-39, 259-262 object-level caching, 108 objects (S3), 259 observability, 33, 376 online game leaderboard use case, 441-463

architecture design, 446-451 Day 0 architecture, 451-460 Day N architecture, 460-463 system requirements, 442-445 open source caching solutions, 111-118 open source distributed systems architecture,

206-215 HDFS, 206-209, 215 Kafka, 211-215


open source load balancers, 133-135 open source RDBMS, 63-65 Open Systems Interconnection (see OSI model) OpenSearch, 274-275 operability, 22 operational costs (in TCO), 459 operators, 80 optimistic locking, 481 optimistic replication, 76 optimizing CDNs, 109-110 relational databases, 50-54 orchestration, 174-177, 191-193, 297

Kinesis, 299-305 MSK (Managed Streaming for Apache Kafka), 297-299 SNS (Simple Notification Service), 307-309 in social network use case, 420, 423 SQS (Simple Queue Service), 305-306 workflow orchestration, 309-314 orchestrators, 191 order management system design, 550-553,

564-565 Origin Shield, 538-539 OSI model, 121, 138-139 outbound rules, 235 Outposts, 561

### P P&L dashboard design, 555-556 PACELC theorem, 29 pages (in Memcached), 112 parallel systems, availability, 14-15 Pareto distribution, 96 partition keys in column-family stores, 84 in DynamoDB, 265 in key-value stores, 72 partitioning, 54-56, 334, 447 partitions (Kafka), 213 path routing, 204 patterns (see architectural designs and patterns) patterns of availability, 16-18 payload, 140 payment processing architecture (hotel reserva‐ tion system), 482-485 peer-to-peer connections, 159-160 performance, 50

(see also optimizing)

measuring, 32-33 replication and, 59 scalability versus, 28 persistence, 273

in event sourcing, 201 in load balancers, 127-129 in Redis, 115-116 in stock tick system, 548 WebSockets, 151-152 personally identifiable information (PII), 315 pessimistic locking, 481 physical separation, 369 PII (personally identifiable information), 315 placement strategies for load balancers, 123-125 Pods, 176 politeness, 394 polling invocation, 288 Polly, 347 POP (Post Office Protocol), 147 ports, 142 POST method, 144 Post Office Protocol (POP), 147 post workflow orchestration (social network use case), 420, 423 PostgreSQL, 63-65 posts, handling in social network use case,

418-424 primary indexes, 51 primary keys in DynamoDB, 265 in key-value stores, 72 in relational databases, 41, 46 primary nodes, 332 primary-secondary node clusters, 81 prioritizers, 395 priority queues, 396 private IP addresses, 229 private subnets, 231-233, 238-239 PrivateLink, 241-242 procedures, 154 processing time, 27 producers, 212 profiling, 52 Profit & Loss dashboard design, 555-556 programming languages, latency and, 554 projection, 80 property booking architecture (hotel reservation system), 478-488, 492-493


property onboarding architecture (hotel reservation system), 469-471, 491 property reviews architecture (hotel reservation system), 488-490 property search architecture (hotel reservation system), 471-478, 491-492 protocols, 137, 138

application layer, 143-150 choosing for chat application, 504-505 communications standards, 154-160

GraphQL, 157-159 REST, 155-157 RPC, 154-155 WebRTC, 159-160 network layer, 140 transport layer, 140-143 provisioned concurrency, 288 pub/sub (publisher-subscriber) architecture,

188-189 Kinesis, 299-305 MSK (Managed Streaming for Apache Kafka), 297-299 SNS (Simple Notification Service), 307-309 SQS (Simple Queue Service), 305-306 public access (S3), 261 public IP addresses, 229 public subnets, 231-233, 237-238 pull CDNs, 109 pull-based communication mechanisms, 150,

418 push CDNs, 109 push-based communication mechanisms,

151-153, 307-309, 418 PUT method, 144 PutItem operation (key-value stores), 73

### Q QoS (quality of service) levels (in MQTT), 149 quadtree, 477 quality of service (QoS) levels (in MQTT), 149 query federation, 54 query optimizers, 48 query parsers, 48 query processors, 48 query-level caching, 108 queue-based cache eviction policies, 97-98 queues, 488 QUIC (Quick UDP Internet Connections), 145 QuickSight, 339-340

quorums, 74, 85

### R range keys in key-value stores, 72 range partitioning, 56 ranking service, 449 rate limiter pattern, 203 RCUs (read capacity units), 266 RDB (Redis database) files, 115-116 RDBMS (relational database management sys‐ tems) architecture, 47-50 open source, 63-65 RDS (Relational Database Service), 65, 262-264 re-creating deployments, 178 read capacity units (RCUs), 266 read, invalidation on, 100-101 read-intensive caching strategies, 102-104 read-through caching strategy, 103 readiness probes, 178 real-time communications, 501

(see also chat applications) MQTT, 149-150, 504-505 WebRTC, 159-160 XMPP, 148-149, 504-505 recency-based cache eviction policies, 98 records (in relational databases), 40 recovery managers, 49 recovery point objective (RPO), 23 recovery time objective (RTO), 24 RECs (regional edge caches), 538 Redis, 113-118, 272

availability in, 114-115 benefits of, 113 durability in, 115-116 memory management in, 116-118 scaling, 461-462 in social network use case, 423 Redshift, 340-343 Redshift Managed Storage (RMS), 342 Redshift Spectrum, 342 redundancy, 15, 273 refresh intervals, 399 refresh-ahead caching strategy, 103 regional edge caches (RECs), 538 regions (AWS), 223 registered ports, 142 registries (Docker), 169-171 Rekognition, 347


Relational Database Service (RDS), 65, 262-264 relational databases ACID model, 43-44 database management system architecture,

47-50 ER model, 45 keys, 46-47 logical schema design, 40-42 nonrelational databases, compared, 94 object-level caching, 108 optimizing, 50-54 for property onboarding architecture,

470-471 query optimizers, 48 query parsers, 48 query processors, 48 query-level caching, 108 RDS, 262-264 relationships in, 40, 45 scaling, 54-63 schema normalization, 45-46 SQL, 42-43 for user post service, 422 relational model, 40 relationships (in relational databases), 40, 45 relay servers, 147 relevance of search results, 404 reliability, 19-20 reliable network fallacy, 24 remote caching, 106 Remote Procedure Call (RPC), 154-155 replica nodes, 8 replica sets, 81 ReplicaSets, 176 replication, 59-63, 273 replication patterns, 17-18 replication-based fault tolerance, 22 Representational State Transfer (REST),

155-157 resiliency, 59, 565 resolution (of metrics), 316 resources (Kubernetes), 177 response time, 27 REST (Representational State Transfer),

155-157 retention periods, 306 retirement costs (in TCO), 460 retry with backoff pattern, 203 reverse proxies, 121

RMS (Redshift Managed Storage), 342 rolling deployments, 178 root users, 321 rosters, 148 round robin algorithms, 125 Route 53, 246-247 route tables, 233-234 rows (in relational databases), 40 RPC (Remote Procedure Call), 154-155 RPO (recovery point objective), 23 RTO (recovery time objective), 24 runc, 173 runtime dependencies, 168

### S S3 (Simple Storage Service), 39, 259-262 sagas, 202 SageMaker, 344-346 SASL/SCRAM (Simple Authentication and Security Layer/Salted Challenge Response Authentication Mechanism), 298 scalability, 20-21, 351

with AppSync, 326-327 autoscaling, 284-285 horizontal scaling, 21 of nonrelational databases, 69 performance versus, 28 replication and, 59 vertical scaling, 20 scale (of system) chat application, 503 hotel reservation system, 467-469 online game leaderboard, 444-445 search engine, 390 social network, 417 stockbroker application, 545 URL shortener service, 357-358 video processing, 527 web crawler, 389-390 scaling Day 0 architecture (see Day 0 architecture) Day N architecture (see Day N architecture) in DynamoDB, 368 Elasticsearch, 473-475 key-value stores, 73-75 Redis, 461-462 relational databases, 54-63 for URL shortener service, 383 scaling costs (in TCO), 459


schedulers, 175 schema design in chat application, 503-516 in column-family stores, 84 in hotel reservation system, 469-490 key-value stores, 71 nonrelational databases, 68 in online game leaderboard, 446-451 relational databases, 40-42 in social network system, 417-427 in stockbroker application, 545-556 in URL shortener service, 360 in video processing, 528-533 in web crawler/search engine, 391-404 schema normalization, 45-46 Schema Registry, 212 score submission service, 448-449 SDP (Session Description Protocol), 160 search databases (OpenSearch), 274-275 search engine use case, 387-414

architecture design, 398-404 Day 0 architecture, 405-409 Day N architecture, 412-413 system requirements, 388-391 search engines, 387 search result relevance, 404 search service in hotel reservation system, 471-478 in social network use case, 425-427 in video processing use case, 531-532 secondary indexes, 51 secondary NameNodes, 208 secrets, 177 Secrets Manager, 298 secure network fallacy, 25 security of messages, 308 S3, 261-262 security groups, 234-235 security managers, 50 seed URLs, 393 self-hosting, cloud-managed services versus,

566 sequential systems, availability, 14-15 server pools, 119 server-sent events (SSEs), 153 serverless deployments, 179 servers, 279 service mesh architecture, 205

service providers, 241 service-level objectives (SLOs), 20 services (Kubernetes), 176 session affinity, 127 Session Description Protocol (SDP), 160 session persistence in load balancers, 127-129 Session Traversal Utilities for NAT (STUN) protocol, 159-160 sharding, 57, 447, 473 shards, 299-300, 399 shared responsibility model, 221, 223 shared tenancy, 230 sidecar pattern, 205 Simple Authentication and Security Layer/Salted Challenge Response Authentication Mechanism (SASL/SCRAM), 298 Simple Mail Transfer Protocol (SMTP),

146-148 Simple Notification Service (SNS), 307-309, 454 Simple Object Access Protocol (SOAP), 155 Simple Queue Service (SQS), 305-306, 454 Simple Storage Service (S3), 39, 259-262 simplicity, 32 single administrator fallacy, 25 single-leader replication, 17, 60 size-tiered compaction, 87 slabs (in Memcached), 112 sloppy quorum, 76 SLOs (service-level objectives), 20 slow start, 141 SLTS (stock live ticker service), 547-549 SMTP (Simple Mail Transfer Protocol),

146-148 SnapStart, 289 Snowflake, 365 SNS (Simple Notification Service), 307-309, 454 SOAP (Simple Object Access Protocol), 155 social network use case, 415-440

Day 0 architecture, 427-436 Day N architecture, 436-439 migration for scalability, 433-436 search service, 425-427 system requirements, 415-417 user post service design, 418-424 user relationship design, 417-418, 424-425 soft deletes, 87 soft limit, 230 software deployment (see application deployment)


software load balancers, 132 solid-state drives (SSDs), 257 solution architecture, 196-199 sort keys in DynamoDB, 265 in key-value stores, 72 sorting algorithms, 447 source IP affinity, 128 sources (KDS), 299 spot instances, 283 SQL (structured query language), 42-43 SQL tuning, 52-53 SQS (Simple Queue Service), 305-306, 454 SSDs (solid-state drives), 257 SSEs (server-sent events), 153 SSTables, 87 standard queues, 306 stanzas, 148 state, 199 state machines, 199, 310-312 state-oriented EDA implementations, 200 stateful load balancers, 127-128 StatefulSet deployments, 178 stateless load balancers, 128-129 static initialization optimization (Lambda), 289 static load balancing algorithms, 125-126 statistics, 317 STCS (stock tick consumer service), 547 Step Functions, 310-313, 407, 536 sticky sessions, 127 stock exchanges, 543 stock live ticker service (SLTS), 547-549 stock tick consumer service (STCS), 547 stock tick system design, 546-550, 563 stockbroker application use case, 543-566

Day 0 architecture, 557-562 Day N architecture, 562-566 order management system design, 550-553,

564-565 P&L dashboard design, 555-556 stock tick system design, 546-550, 563 system requirements, 544-545 ultra-low latency system design, 553-555 storage capacity online game leaderboard, 444-445, 455 time-space trade-offs, 27 URL shortener service, 358-360 storage classes EFS, 258

S3, 259-261 storage drivers, 36 storage engines, 48 storage systems (see data storage systems) strangler fig pattern, 205 stream-based CDC, 187 streaming services (see video processing use case) strong consistency, 10, 28, 85 structured query language (SQL), 42-43 stub functions, 155 STUN (Session Traversal Utilities for NAT) protocol, 159-160 subnet masks, 227 subnets, 227, 231-233, 272 support costs (in TCO), 459 supporting processes, 172 synchronous checkpointing, 23 synchronous communication, 7, 150 synchronous invocation, 287 synchronous orchestration patterns, 191-192 synchronous replication, 61-62 system boundaries, 389 system design, 185

(see also architectural designs and patterns) AWS Well-Architected Framework, 26 concepts availability, 13-18 communication, 6-8 consistency, 8-12 fault tolerance, 22-24 maintainability, 21 reliability, 19-20 scalability, 20-21 fallacies of distributed systems, 24-26 goals of, 352 guidelines, 31-34 trade-offs, 26-30 use cases (see use cases)

### T table deltas, 187 table partitioning, 334 tables (in relational databases), 40 target groups, 249 task nodes, 332 tasks (ECS), 290-291 tasks (Step Functions), 310 TCL (transaction control language), 43


TCO (total cost of ownership), 456-460 TCP (Transmission Control Protocol), 140-142 TCP/IP model, 139-150

application layer protocols, 143-150 network layer protocols, 140 transport layer protocols, 140-143 tenancy, 230 “there is no such thing as a free lunch”, 33 throughput latency versus, 27-28 online game leaderboard, 445 time synchronization, 496 time to live (TTL), 101, 394 time-space trade-offs, 27 time-window compaction, 87 Timestream, 276, 549 tombstones, 87 topics (Kafka), 213 total cost of ownership (TCO), 456-460 trade-offs guideline, 33 Trainium, 348 transaction control language (TCL), 43 transaction managers, 49 transaction support, 267 transactional outbox pattern, 205 transactions, 42 Transcribe, 347 Transit Gateway, 240-241 transitions, 199 Transmission Control Protocol (TCP), 140-142 transport layer protocols, 140-143 Traversal Using Relays around NAT (TURN) servers, 160 trigger-based CDC, 187 triggers, 286, 324 TTL (time to live), 101, 394 tunable consistency, 11 TURN (Traversal Using Relays around NAT) servers, 160

### U UDFs (user-defined functions), 339 UDP (User Datagram Protocol), 142-143 ultra-low latency, 545, 553-555 unbounded stream processing, 302 unique ID generation, 361-363 UpdateItem operation (key-value stores), 73 URL duplicate detection, 397-398 URL frontier, 395-397

URL shortener service use case, 355-383

algorithms for, 360-365 APIs for, 365-367 architecture design, 360 custom domain support, 369-370 database selection, 368-369 Day 0 architecture, 371-379 Day N architecture, 379-383 scaling overview, 383 system requirements, 355-360 use cases chat application, 501-523

architecture design, 503-511 Day 0 architecture, 516-520 Day N architecture, 520-522 direct messaging, 505-509 media content storage, 510-511 message storage, 509-510 protocol selection, 504-505 system requirements, 501-503 WhatsApp architecture, 511-516 hotel reservation system, 465-499

architecture design, 469-490 Day 0 architecture, 490-497 Day N architecture, 497-498 system requirements, 465-469 online game leaderboard, 441-463

architecture design, 446-451 Day 0 architecture, 451-460 Day N architecture, 460-463 system requirements, 442-445 social network, 415-440

Day 0 architecture, 427-436 Day N architecture, 436-439 migration for scalability, 433-436 search service, 425-427 system requirements, 415-417 user post service design, 418-424 user relationship design, 417-418,

424-425 stockbroker application, 543-566

Day 0 architecture, 557-562 Day N architecture, 562-566 order management system design,

550-553, 564-565 P&L dashboard design, 555-556 stock tick system design, 546-550, 563 system requirements, 544-545 ultra-low latency system design, 553-555


as system design guideline, 33 URL shortener service, 355-383

algorithms for, 360-365 APIs for, 365-367 architecture design, 360 custom domain support, 369-370 database selection, 368-369 Day 0 architecture, 371-379 Day N architecture, 379-383 scaling overview, 383 system requirements, 355-360 video processing, 525-542

architecture design, 528-529, 533 content distribution, 532 content indexing, 531-532 Day 0 architecture, 534-540 Day N architecture, 540-542 scaling architecture, 536-540 system requirements, 525-527 video encoding process, 529-530 video-quality validation, 531 web crawler/search engine, 387-414

architecture design, 391-404 Day 0 architecture, 405-409 Day N architecture, 409-413 system requirements, 388-391 user connections, 505-509 User Datagram Protocol (UDP), 142-143 user gateway service, 418 user graph service, 418, 425 user pool hosted UIs, 324 user pools, 324 user post service design (social network use case), 418-424 user relationship design (social network use case), 417-418, 424-425 user timeline service, 420, 424 user timelines, 415

(see also social network use case) user-defined functions (UDFs), 339

### V versioning, 169, 259 vertical partitioning, 55 vertical scaling, 20 video encoding, 529-530 Video Multimethod Assessment Fusion (VMAF), 531 video processing use case, 525-542

(see also media content storage) architecture design, 528-529, 533 content distribution, 532 content indexing, 531-532 Day 0 architecture, 534-540 Day N architecture, 540-542 scaling architecture, 536-540 system requirements, 525-527 video encoding process, 529-530 video-quality validation, 531 video streaming, 304-305 video-quality validation, 531 views, 42 VIF (virtual interface), 246 VIP (virtual IP) addresses, 124 virtual interface (VIF), 246 virtual machines (VMs), containers versus,

164-166 virtual private clouds (see VPC service) virtual private networks (VPNs), 243 virtual separation, 369 virtualization, 164 visibility timeouts, 306 VMAF (Video Multimethod Assessment Fusion), 531 VMs (virtual machines), containers versus,

164-166 volumes (EBS), 257 volumes (Kubernetes), 177 VPC Lattice, 242 VPC peering, 239-240 VPC service, 225-233

creating VPC, 230-231 cross-VPC connectivity, 239-242 hybrid connectivity, 243-246 internet connectivity to, 237-239 IP addresses, 226-230 subnets, 231-233 for URL shortener service, 379 VPNs (virtual private networks), 243

### W warm start, 104, 288 Wavelength, 561 WCUs (write capacity units), 266 weak consistency, 85 web crawler use case, 387-414

architecture design, 393-398 Day 0 architecture, 405-409


Day N architecture, 409-412 system requirements, 388-391 web crawlers, 387 web server caching, 107 webhooks, 476 WebRTC (Web Real-Time Communication),

159-160 WebSockets, 148, 151-152, 519 weighted round robin algorithms, 126 Well-Architected Framework (AWS), 26 well-known ports, 142 WhatsApp, 511-516 wide-column stores (see column-family stores) WLM (workload management) tools, 343 worker nodes, 175 workflow orchestration, 309-314 workload management (WLM) tools, 343

write capacity units (WCUs), 266 write-ahead logging, 9 write-around caching strategy, 104 write-back caching strategy, 105 write-through caching strategy, 104

### X X-Ray, 376 XMPP (Extensible Messaging and Presence Protocol), 148-149, 504-505

### Z zero latency fallacy, 24 zero transport cost fallacy, 25 zone maps, 341 ZooKeeper, 212

