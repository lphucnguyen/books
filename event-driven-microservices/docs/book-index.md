# Index

# Index

### A ACLs (access control lists) for event streams,

244, 250 AFTER trigger, 70 aggregation layer, challenges of, 232, 234 Akidau, Tyler Streaming Systems, 96 Amazon Web Services (see AWS) analytical events, 212-214 Apache Avro, 45 Apache Beam, 177, 179, 194, 257 Apache Flink, 177, 179, 184, 191, 257 Apache Gobblin, 58 Apache Hadoop, 178 Apache Heron, 177, 179, 191 Apache Kafka, 31, 33, 45, 58, 62, 84, 125, 153,

242 Apache NiFi, 58 Apache Pulsar, 33, 45, 84, 125, 153 Apache Samza, 94, 99, 204 Apache Spark, 177, 179, 184, 189, 194, 257 Apache Storm, 177, 179, 191 Apache Zookeeper, 177, 180, 192 API versioning and dependency management,

18 application layer, testing, 261 asynchronous direct-function calling, 162-163 asynchronous microservices, 15-17, 224 asynchronous triggers, FaaS, 156 asynchronous UI, 224 autoincrementing ID, 59, 64 autonomously generated events, 212-214 autonomy, microservices’ role in providing design, 5

autoscaling applications, 192 AWS (Amazon Web Services) ECS, 35 AWS (Amazon Web Services) Firecracker, 36 AWS (Amazon Web Services) Kinesis, 263 AWS (Amazon Web Services) Lambda, 263

### B backend and frontend services, coordination of,

231-237 backward compatibility, schema evolution rules, 42 basic full-stop deployment pattern, 276-278 basic producer and consumer (BPC) microservices (see BPC) batch event-processing parameters, tuning your functions, 166 batch size and batch window in event-stream listener triggers, 157 big data, 178 binary logs, 61, 63 blue-green deployment pattern, 282-283, 290 bootstrapping, 62 bounded contexts, 4

ACLs as enforcers of, 244 aligning microservice implementation to, 5,

151, 286, 288 business domains, 3-6, 286 consumer responsibilities in communication structure, 14 FaaS and designing solutions as microservices, 151 function access permissions, 160 introduction, 4 leveraging domain models, 4


loose coupling of, 5, 6, 16 bounded versus unbounded data sets, out-oforder event processing, 100 BPC (basic producer and consumer) microservices, 169-176, 289 branching of event streams, 81 breaking schema change pattern, 43-45,

279-282 broker ingestion time, 91 bulk loading of data by query, 59 business domains and bounded contexts, 3-6, 286, 288 centralized frameworks for CDC, 76-77 communication structures, 7-15, 40, 285 FaaS advantages for, 159, 289 topology of, 22 business logic in event processing, 80 freeing UI element libraries from boundedcontext-specific, 233 not reliant on event order, 171 windowing, 103-105 business requirements aligning bounded contexts with, 5-6 BPC microservices’ capabilities, 171-173 data definitions and triggering logic, 39 EDM’s flexibility and, 16 mapping to microservices, 251 out-of-order and late event handling, 105 rebuilding state stores, 124 request-response and EDM integration, 232 schema evolution rules for, 41 temporal order, 93

### C CDC (change data capture), 61-77

business considerations, 76-77 change-data capture logs, 61-63 change-data tables, 75 data definition changes, 74-75 data liberation benefits and drawbacks, 63 outbox tables, 64-73 strategy tradeoffs, 77 changelogs, 112

lightweight framework, 201 recording state to, 112-113 restoring and scaling internal state from,

119

scaling and recovery with external state stores, 123 sourcing data for, 62 checkpoints changelog progress, 62 in heavyweight framework, 186 Chernyak, Slava Streaming Systems, 96 choreography design pattern, 136-139

asynchronous function calling, 162-163 distributed systems, 138, 145-146 multifunction solutions, 161 transactions, 145-146 CI (continuous integration), 275, 289 cluster mode, for heavyweight cluster, 186 clusters application submission modes, 186 in heavyweight framework, 177-192 multicluster management, 248 replication with cross-cluster event data,

249, 266 setup options and execution modes,

183-185 supportive tooling, 248-250 CMSes (container management systems), 35

deployment role of, 276 in heavyweight framework, 183-185 in lightweight framework, 177, 199 as supportive tool, 247 code generator support for event schema, 42 cold start and warm start, FaaS, 155 comments, in schema definition, 41 committing code, deployment, 276 commodity hardware in deployment, 276 communication structures, 6-15, 40, 285 community support, function of, 31 compaction of changelogs, 112 compatibility types, schema evolution rules, 41 compensation workflows, 149 composite service, multiple microservices as,

222 composition-based microservices, 232, 288 compute resources, programmatic bringup of,

248 Confluent KSQL, 175, 204 consumer group, 33 consumer group lag, 157 consumer ingestion time, 91 consumer offset lag monitoring, 246


consumers, 21

access data limitations in data model, 66 assigning partitions to consumer instance,

84-87 in BPC microservices, 169-176 breaking schema changes, 44 and communication layers, 285 data access and modeling requirements based on, 14 decoupling of services, 136 in EDM process, 79 implicit versus explicit data contracts, 40 involvement in designing events, 51 negotiating breaking changes with, 274 notifications of schema creation and modification, 243 in queue-based consumption, 31, 33, 216 responsibilities for using event stream, 32 timestamp extraction by, 95 container management systems (see CMSes) continuous delivery, 275, 289 continuous deployment, 275, 289 continuous integration (see CI) Conway’s Law, 9 copartitioning event streams, 83, 85 Couchbase, 62 created-at timestamp, 64 cross-cluster event data replication, 249, 266 cross-cutting versus sole ownership of application, 5 curated testing source, 267 custom event schedulers, 94 custom partition assignment strategy, 87 custom querying of data, 59 custom tags, metadata tag, 241 Custom transforms, 81

### D data access, EDM versus request-response microservices, 18 data communication structure, 6-15, 40, 285 data contracts, 39-45 data definition language (see DDL) data definitions, 39, 74

changing, 40, 40, 57, 74-75 events, 27 in schema, 40, 44 updating, 41 data dependency, 18, 61, 63, 250-254

data layer performing business logic, using BPC, 172 data liberation, 54-73

change-data capture logs, 61-63 converting to events, 57 data definition changes, 74-75 frameworks, 58 outbox tables, 64-73 patterns of, 57 query-based, 58-61 and single source of truth, 60, 287 sinking event data to data stores, 76-77 data lineage, determining, 250 data models benefit of event-production with outbox tables, 69 exposure from change-data log data liberation pattern, 58, 63 graph, 2 isolating with outbox tables, 66 data source discovery, determining, 251 data stores change-data capture logs for data liberation,

61 in EDM topology, 22 mocked external data store, for testing, 256 sinking event data to, 76-77 testing, 260 data types keeping single purpose, 47-50 maintaining respect for, 42 database logs (see CDC) DDL (data definition language), 74 Debezium, 62, 75 decoupling of producer and consumer services,

136 dedicated versus shared databases, 10 dedup ID (deduplication ID), 130 deduplication of events, 129-131 deletions database log updating pattern, 63 tracking with query-based updating, 61 denormalization, 63, 66, 69 dependency, data, 18, 61, 63, 250-254 dependent scaling, request-response microservices, 18 dependent service changes deployment considerations, 278 minimizing, 274


deployment considerations, 273-283

architectural components, 274-276 basic full-stop deployment pattern, 276-278 blue-green deployment pattern, 282-283 breaking schema change pattern, 279-282 heavyweight framework cluster, 182, 184 principles, 273-274 rolling update pattern, 278 summary, 289 deprecation, metadata tag, 241 designing events, 46-51 deterministic processing, 89-109

connectivity issues, 108-109 event scheduling and, 93-95 FaaS caution, 159 late-arriving events, 101, 105 out-of-order events, 99-100, 101-103 reprocessing historical data, 106-107 stream time, 97-99 timestamps, 90-93 watermarks, 95-97 DevOps capabilities, 239 direct coupling, avoiding, 54, 120, 221 direct-call communication pattern functions calling other functions, 162-164 microservice architectures, 137 orchestration workflow, 142-143 distributed systems choreographed workflows, 138, 145-146 heavyweight framework, 180 lightweight framework, 199 monoliths, request-response microservices,

19 orchestrated workflows, 146-149 timestamps, 90, 92, 92 transactions, 136, 144-149 Docker, 35 Docker Engine, 35 domain, 3 domain models, 4, 4 domain-driven design, 3, 15 Domain-Driven Design (Evans), 3 driver mode, heavyweight cluster, 186 duplicate events, processing, 128-131, 225 durable and immutable log, consuming from,

32-33, 93 durable stateful function support, 160

### E EDM (event-driven microservice) architecture,

2-3 advantages of, 15 asynchronous, 15-17, 224 BPC microservices, 169-176 communication structures, 6-15, 40, 285 costs of, 36 data contracts, 39-45 deployment, 273-283 designing events, 46-51 deterministic stream processing, 89-109 versus direct-call, 142-144 event format, 45 existing systems, integrating with, 53-77 FaaS, 151-167 fundamentals, 21-37 heavyweight framework, 177-197 implementation options, 288 lightweight framework, 199-209 processing basics, 79-87 request-response, integrating with, 211-237 stateful streaming, 111-133 supportive tooling, 239-254 synchronous, 17-19, 19 testing, 255-270 workflows, building, 135-149 effectively once processing, 125-133 emergent behavior, 136 encapsulation, 14, 227, 233, 279 entities, accommodating breaking schema changes for, 44, 279 entity events, 24, 25-27 ESS (external shuffle service), 189 Evans, Eric, 3 event brokers, 21

client libraries and processing frameworks,

30 community support, 31 connectivity issues for, 108-109 deployment impacts, 290 differences in queue support, 33 features for running EDM ecosystem, 28-29 heavyweight versus lightweight frameworks,

177, 199, 204 hosted services, 30 ingestion time in deterministic processing,

94 long-term and tiered storage, 31


versus message brokers, 31-34 programmatic bringup of, 248 and quotas, 241 role of, 285 as single sources of truth for all data, 34 storage and serving of events, 29 support tooling, 30 testing, 260, 265 transactional support and effectively once processing, 125, 127-128 event keys in repartitioning, 81 selecting, 96-97 event streams ACLs and permissions for, 244, 250 assigning partitions to a consumer instance,

84-87 branching and merging stateless topologies,

81 consumer role in using, 32 creating and modifying, 240 data liberation, 55 deterministic processing, 89-109 joining with external stream processing,

174-176 materializing a state from, 25-27, 55,

113-123, 182, 199, 221, 236 metadata tagging, 240 migration of, 280, 281 partitioning of, 29, 81-87, 101, 188-192 processing basics, 79-87 repartitioning of, 81-83, 97, 98, 101-103 reprocessing historical data from, 106-107 role in microservice processes, 21 as single source of truth, 14 single writer principle, 28 singular event definition per stream, 46 sinking event data to data stores, 76 state stores from, 111-125 validating, 277 event time, 91, 93, 94, 97 event-driven communication pattern, 161 event-driven microservices (see EDM) event-stream listener, 155-157 eventification, 66 events accommodating breaking schema changes for, 45 as basis of communication, 14, 39

contents of, 23 converting liberated data to, 57 converting requests into, 223, 225-230 data definitions, 27, 46-51 designing, 46-51 formatting, 45 materializing state from entity events, 25-27 mock events using schemas, 267 scheduling, 93-95, 106-107 shuffling, 96, 99, 102, 200, 202 as single source of truth, 14, 23, 34, 46, 287 storage and serving of, 29 structure of, 23-25 types of, 24 evolution rules, schema, 41-42, 50, 287 exactly once processing (see effectively once processing) executor, heavyweight stream processing cluster, 179 existing systems, integration with, 53-77

BPC microservices, 170 data liberation, 54-73 sinking event data to data stores, 76-77 explicit versus implicit data contracts, 40 external events, handling with requestresponse, 211-213 external services, nondeterministic, 90 external shuffle service (see ESS) external state store, 112

application reset, 245 BPC microservices, 170 lightweight framework, 201 materializing state from an event stream,

120-123 serving real-time requests, 220-223 external systems, request-response calls to, 95 external to test code, temporary environment,

262

### F FaaS (Function-as-a-Service), 151-167

building microservices out of functions,

153-155 business solutions with, 159, 289 choosing a provider, 153 cold start and warm start, 155 designing solutions as microservices,

151-153 functions calling other functions, 160-164


maintaining state, 160 scaling your solutions, 166 termination and shutdown, 165 testing libraries, 264 triggering logic, starting functions with,

155-159 tuning your functions, 165 Filter transformations, 80 financial cost of materializing state from external store, 122 financial information, metadata tag, 240 formatting events, 23, 45 forward compatibility, schema evolution rules,

41 frontend and backend services, coordination of,

231-237 full compatibility, schema evolution rules, 42 full date locality in materializing state from external store, 120, 122 full remote integration testing, 265-270 function, 151 Function-as-a-Service (see FaaS) function-trigger map, 154 functional testing, 255, 258-265

### G gating pattern, 171 GCP (Google Cloud Platform), 153, 263 global state store, 114 global window, 182 Google Cloud Platform (see GCP) Google Dataflow, 179, 191 Google gVisor, 36 Google PubSub, 263 GPS and NTP synchronization, 92 graph data models, 2 groupByKey operation, 96

### H HDFS (Hadoop Distributed File System), 76 heavyweight framework, 177-197

application submission modes, 186 benefits and limitations, 181-183, 288 choosing a framework, 193 clusters, 177-192 history, 178 inner workings, 179-181 languages and syntax, 193 multitenancy considerations, 192

recovering from failures, 192 scaling applications, 188-192 session windowing example, 194-197 state and checkpoints, 186-188 testing, 257 testing applications, 264 high availability cluster task manager’s role in providing, 180 enforcing static master node assignment in cluster, 184 event broker’s role in providing, 28 high performance in disk-based options, 115 event broker’s role in providing, 28 historical event processing, 90, 99 hosted services (see managed services) hot replicas, 116-119, 203, 218 hybrid BPC applications with external stream processing, 174-176 hybrid integration testing, 258 hybrid microservice architectures, 19

### I idempotent writes, 125, 129 immutability of event data, 29

(see also durable and immutable log) implementation communication structures,

7-10, 13, 15 implicit versus explicit data contracts, 40 incremental timestamp data loading by query,

59 incremental updating of data sets, 59 indexing of events, 29, 32 infinite retention of events, 29 ingestion time, 94 integrations capturing DDL changes, 74 CMS in heavyweight framework, 184-185 continuous, 275, 289 with existing systems, 53-77, 170 with request-response, 211-237 testing environment, 258-270, 276, 282, 289 interconnectedness and complexity measurement, 251 intermittent capture, query-based updating, 61 intermittent failures and late events, 107 intermonolith communication, 2 internal data model, isolating with outbox, 66 internal state store, 111


application reset, 245 lightweight framework, 201 materializing state from an event stream,

113-120 serving real-time requests, 217-220

### J Java (JVM) microservice, 182, 193, 203, 204

### K Kafka Connect, 75, 76, 156 Kafka Streams, 98, 116, 203, 261 Kata Containers, 36 key state, checkpointing mechanism, 187 key/value format for events, 23, 114 keyed event, 24 Kubernetes, 36, 184

### L lag monitoring/triggering, 157, 246 late-arriving events, 101, 105 Lax, Reuven Streaming Systems, 96 legacy systems, integration with EDMs, 53-77,

170 lightweight framework, 199-209

benefits and limitations, 199, 288 changelog usage, 201 choosing a framework, 203 languages and syntax, 204 processing, 200 scaling applications, 201-203 state handling, 201 stream-table-table join, 205-209 testing, 257, 262 load balancers, 217 local integration testing, 258, 289 LocalStack, 263 log-based data liberation, 57 long-term tiered storage, function of, 31 loose coupling of bounded contexts, 5, 6, 16

### M managed services (hosted services) cloud computing, 248 function of, 30 heavyweight framework cluster setup, 183 mocking and simulator options, 263

Map transformations, 81 mapping of business requirements to microservices, 251 MapReduce, 178, 193 MapValue transformations, 81 master node, heavyweight stream processing cluster, 179, 184, 192 materialized state, 111 materializing state from an event stream data liberation compromise, 55 external state store, 120-123 from entity events, 25-27 frontend/backend coordination, 236 heavyweight framework, 182 internal state store, 113-120 lightweight framework, 199 serving requests via, 221 Maxwell, 62 MemoryStream class, 257 merging of event streams, 81 Mesos Marathon, 35 message brokers versus event brokers, 31-34 message-passing architectures, 2 MessageChooser class, 94 metadata tagging of event streams, 240 metadata, in schema definition, 41 micro-frontends in request-response applications, 231-237 microservice tax, 36, 275, 286 microservice-to-team assignment system, 239 microservices (see EDM) Microsoft Azure, 153, 160, 263 Microsoft Azure Event Hub, 263, 264 migration, 287

(see also data liberation) data definition changes to data sets, 74 eventual migration via two event streams,

280 versus rebuilding state stores, 124-125 synchronized migration to new event stream, 281 Mills, David, 92 mock events using schemas, 267 mocked external data store, 256 mocking and simulator options for hosted services, 263 MongoDB, 62 monolith communication, 2, 11, 227, 231 multicluster management, 248


multilanguage support, outbox tables, 69 multitenancy considerations, 92, 192 MySQL, 62, 75

### N namespace, metadata tag, 240 namespacing, heavyweight framework clusters,

193 near-real-time event processing, 90 network latency, performance loss due to, 121 Network Time Protocol (see NTP) network-attached disk, materializing state to internal state store, 115 Nomad, 35 nondeterministic workflows, 90 nonentity events, accommodating breaking schema changes for, 280 nonfunctional testing, 255 notifications of schema creation and modification, 243 NTP (Network Time Protocol) synchronization, 92

### O offsets, 32

batch event-processing with FaaS, 166 choreographed asynchronous function calls,

162 committing offsets, timing of, 152 deterministic processing, 90, 93 manual adjustment of, 243 offset lag monitoring, 246 reprocessing event streams, 107 operator state, checkpointing mechanism, 187 orchestration design pattern, 139-144

direct-call workflow in request-response,

142-144 multifunction solutions, 161 synchronous function calling, 163 transactions, 146-149 orphaned streams and microservices, 245 out-of-order events, 33, 99-100, 101-103, 162 overlay team boundaries, determining, 250

### P partition assignment to consumer instance, 84-87 deterministic processing, 93, 96, 97

lightweight framework, 202 request-response microservices integration,

217, 220 scaling of FaaS solutions, 167 partition assignor, 84 partition count, 82 partitioning of event streams, 81-87

copartitioning, 83, 85 out-of-order events and multiple partitions,

101 repartitioning, 81-83, 97, 98, 101-103 scaling in heavyweight framework, 188-192 strict ordering of partitions, 29 permissions for event streams, 244, 250 PII (personally identifiable information), metadata tag, 240 point-to-point couplings, request-response microservices, 18 post-deployment validation tests, 277 PostgreSQL, 62, 71 predeployment validation tests, 277 processing logic (see topologies) processing of events, 21

(see also event streams) deterministic, 89-109 duplicate events, 128-131, 225 effectively once processing, 125-133 overview, 79-87 versus reprocessing, 106-107, 216, 274 testing framework, 260 for user interface, 224-230 processing time, 91 producers, 21

BPC microservices, 169-176 breaking schema changes, 44, 279 connectivity issues for, 108-109 decoupling of services, 136 duplicate event generation, 129 event-driven role of, 14, 79 implicit versus explicit data contracts, 40 out-of-order event impact for multiple, 101 product-focused microservices, 231 production environment, for testing, 266, 269,

289 Protobuf, 45 Python, 193

### Q query-based data liberation, 57, 58-61


after-the-fact data definition changes in, 75 autoincrementing ID, 59 benefits of, 60 bulk loading of data by query, 59 custom querying of data, 59 drawbacks of, 61 timestamp data loading by query, 59 updating of data sets, 59 queue-based event consumption, 32, 33, 216 queue-triggered event processing, 164 quotas, 216, 241, 290

### R reactive architectures (see choreography design pattern) reactively generated events, 212 rebuilding versus migrating state stores,

124-125, 290 recovery (see scaling and scalability) refactoring of legacy systems, challenges of, 56 relational databases events in, 26 sourcing of data options for, 62 remote integration testing, 258, 264-270 repartitioning event streams, 81-83, 97, 98,

101-103 replayability of events, 29 replication cross-cluster event data, 249, 266 event broker’s role in, 28 hot replicas, 116-119, 203, 218 reprocessing, 106-107, 216, 274 request-response microservices, 211-237

autonomously generated events, 212-214 calls to external systems in event scheduling,

95 direct-call orchestration workflow, 142-144 versus event-driven structures, 13, 17, 19 event-driven workflow to handle requests,

223-230 external event handling, 211-213 integrations with, 214-216 local testing of logic, 260 microfrontends, 231-237 stateful data processing and serving,

216-223 testing, 19 resources allocating function, 165

production challenges in query-based updating, 61 programmatic bringup of, 248 specifying for CMS heavyweight framework job, 184 triggering logic, starting functions with, 159 restarting applications for scaling, 191 reusable event streams, 136 rollback command, orchestrated transactions,

147 rolling update pattern, 278 round-robin partition assignment strategy, 85 runtime of test code, temporary environment within, 261

### S sagas (distributed transactions), 136, 144-149 Scala, 193 scaling and scalability dependent scaling, 18 event broker’s role in, 28 FaaS, 166 heavyweight framework cluster, 183,

188-192 independent scaling of processing and data layer, 173 with internal state stores, 114, 116-120 lightweight framework, 201-203 managing microservices at scale, 15, 34-36 materializing state to internal state store,

114 offset lag monitoring, 246 recovery with external state stores, 122-123 request-response API and EDM, 18, 221 as trigger disadvantage, 73 scheduling events, 93-95, 106-107 functions for triggering logic, 158 schema registry, 58, 241-243, 258, 260 schemas breaking schema change pattern, 43-45,

279-282 brittle dependency consideration, 61, 63 code generator support for, 42, 287 creating mock events using, 267 creation and modification notifications, 243 data definitions and, 27, 287 defining for data contracts, 40-45 for event encoding in generating events, 213


evolution rules, 41-42, 50, 287 merged event streams, 81 outbox table compatibility, 67-70 serializing, 67-69 summary, 287 testing, 72, 258 validating, 67-69, 277 semaphores or signals, avoiding events as, 51 separate microservices and request-response API, 222 serialization options for events, 45 serializing schemas, 67-69 service failure handling, request-response microservices, 18 service-level agreements (see SLAs) service-oriented architectures (see SOAs) session windows, 104, 194-197 Shannon, Claude, 39 shared environment for testing, 268, 270 shared versus dedicated databases, 10 shuffling, event, 96, 99, 102, 200, 202 sidecar pattern, 170 single source of truth contents of event, 23, 46 designing events, 46 event broker as, 34 legacy database challenge for, 57 liberated data as, 60, 287 single writer principle, 28, 239 singular event definition per stream, 46 sinking event data to data stores, 76-77 SLAs (service-level agreements), 274, 290 sliding windows, 104 smart load balancer, 219 snapshots, in scaling and recovery with external state stores, 123 SOAs (service-oriented architectures), 2, 17 sole versus cross-cutting ownership of application, 5 source streams, in scaling and recovery with external state stores, 123 spark-fast-tests, 257 SQL and related languages, 61, 71, 75, 175, 193,

204 SQL Server, 64 state changelogs, 112-113, 119, 123, 201 consistency of, 132-133

handling in heavyweight framework,

186-188 maintaining, 27, 55, 160 management and application reset, 245 replication, 203 scaling applications and recovering from failures, 202 state stores, 111

effectively once processing to maintain state, 132 external, 112, 120-123, 170, 201, 220-223,

245 global, 114 internal, 111, 113-120, 201, 217-220, 245 rebuilding versus migrating, 124-125 stateful streaming, 111-133

business logic not reliant on event order, use of BPC for, 171 effectively once processing of transactions,

125-133 FaaS, 160 heavyweight framework, 186-192 lightweight framework, 202 materializing from event stream, 25-27, 55,

113-123, 182, 199, 221, 236 request-response microservices, 216-223 state stores from an event stream, 111-125 testing, 256 stateless streaming composing topologies, 80-82 limitations of, 27 recovering from processing instance failures, 87 scaling of, 188 testing functions, 256 transformations, 80 static partition assignment strategy, 87 stream owner (service), metadata tag, 240 stream time, 97-99, 101, 122 stream-table-table join, 205-209 streaming frameworks, 177-197, 199-209 Streaming Systems (O’Reilly), 96 StreamingSuiteBase, 257 streamlined microservice creation process, 247 strict ordering of partitions, 29 subdomain, 3, 4 supportive tooling, 239-254

cluster creation and management, 248-250 consumer offset lag monitoring, 246


container management controls, 247 dependency tracking and topology visualization, 250-254 event streams, creating and modifying, 240 function of, 30 metadata tagging event streams, 240 and microservice deployment, 273 microservice-to-team assignment system,

239 offset management, 243 permissions and ACLs for event streams,

244 quotas, 241 schema creation and modification notifications, 243 schema registry, 241-243 state management and application reset, 245 streamlined microservice creation process,

247 synchronized migration to new event stream,

281 synchronizing distributed timestamps, 92 synchronous function calling, 163 synchronous microservices, 17-19, 19 synchronous triggers, FaaS, 156

### T table-based data liberation, 57 table-stream duality, 25-27 task manager, heavyweight stream processing cluster, 180 tax, microservice, 36, 275, 286 technological versus business requirements, 5 temporary integration testing environment,

261-263, 265-268 termination and shutdown of functions, 165 testing, 255-270

deployment pattern, 276, 282 high testability characteristic of EDM, 16 local integration, 259-264 remote integration, 258, 265-270 schemas, 72, 258 summary, 289 topology (as a whole), 257 unit-testing of topology functions, 256-257 third-party request-response APIs, integrating with, 214-216 tight coupling, avoiding, 6, 11, 120, 143, 221

time-based aggregations, heavyweight framework, 182 time-sensitive functions and windowing, latearriving events, 103-105 timestamp extractor, 95 timestamps deterministic stream processing, 90-93 in distributed systems, 90, 92, 92 incremental data loading by query, 59 outbox pattern, 64 topologies, 21

business, 22 composing stateless, 80-82 microservice, 21 processing topology, 80 recovering from instance failures, 87 testing of, 256-258 visualization tool, 250-254 transactional support for event processing distributed systems, 136, 144-149 effectively once processing, 125, 127-128,

132 transformations, stateless topologies, 80 triggering logic, 39

capturing change-data using triggers, 70-73 comments in, 41 consumer group lag, 157 event-stream listener pattern, 155-157 orchestration function calling, 164 on resource events, 159 on schedule, 158 with webhooks, 159 tumbling windows, 103

### U UI (user interface) inconsistent elements or styling in micro‐ frontend, 233 processing events for, 224-230 unit-testing of topology functions, 256-257, 276 unkeyed event, 24 updated-at timestamp, 59, 61 upserting, 25

### V validation of data outbox tables, 67-69 testing, 277 trigger execution challenge to, 71, 73


version accommodation, analytical events, 213 visibility system, workflow, 139, 144, 148 VMs (virtual machines), 35-36

### W warm start and cold start, FaaS, 155 wasted disk space, materializing state to inter‐ nal state store, 116 watermarks, 95-97, 101 webhooks, 159

worker nodes, heavyweight stream processing cluster, 179-181, 192 workflows, 135-149

choreography pattern, 136-139, 145-146 compensation, 149 distributed transactions, 144-149 orchestration pattern, 139-144, 146-149, 163 request-response, 142-144, 223-230 write-ahead logs, 62

