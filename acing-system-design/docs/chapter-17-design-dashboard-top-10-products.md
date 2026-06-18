# _Design a dashboard of top 10 products on Amazon by sales volume_

## _This chapter covers_

- Scaling an aggregation operation on a large data stream

- Using a Lambda architecture for fast approximate results and slow accurate results

- Using Kappa architecture as an alternative to Lambda architecture

- Approximating an aggregation operation for faster speed

Analytics is a common discussion topic in a system design interview. We will always log certain network requests and user interactions, and we will perform analytics based on the data we collect.

The _Top K Problem (Heavy Hitters)_ is a common type of dashboard. Based on the popularity or lack thereof of certain products, we can make decisions to promote or discontinue them. Such decisions may not be straightforward. For example, if a product is unpopular, we may decide to either discontinue it to save the costs of selling it, or we may decide to spend more resources to promote it to increase its sales.


The Top K Problem is a common topic we can discuss in an interview when discussing analytics, or it may be its own standalone interview question. It can take on endless forms. Some examples of the Top K Problem include

- Top-selling or worst-selling products on an ecommerce app by volume (this question) or revenue.

- The most-viewed or least-viewed products on an ecommerce app.

- Most downloaded apps on an apps store.

- Most watched videos on a video app like YouTube.

- Most popular (listened to) or least popular songs on a music app like Spotify.

- Most traded stocks on an exchange like Robinhood or E*TRADE.

- Most forwarded posts on a social media app, such as the most retweeted Twitter tweets or most shared Instagram post.

## _17.1 Requirements_

Let’s ask some questions to determine the functional and non-functional requirements. We assume that we have access to the data centers of Amazon or whichever ecommerce app we are concerned with

- How do we break ties?

High accuracy may not be important, so we can choose any item in a tie:

- Which time intervals are we concerned with?

Our system should be able to aggregate by certain specified intervals such as hour, day, week, or year:

- The use cases will influence the desired accuracy (and other requirements like scalability). What are the use cases of this information? What is the desired accuracy and desired consistency/latency?

That’s a good question. What do you have in mind?

It will be resource-intensive to compute accurate volumes and ranking in real time. Perhaps we can have a Lambda architecture, so we have an eventually consistent solution that offers approximate sales volumes and rankings within the last few hours and accurate numbers for time periods older than a few hours.

We can also consider trading off accuracy for higher scalability, lower cost, lower complexity, and better maintainability. We expect to compute a particular Top K list within a particular period at least hours after that period has passed, so consistency is not a concern.

Low latency is not a concern. We can expect that generating a list will require many minutes:

- Do we need just the Top K or top 10, or the volumes and ranking of an arbitrary number of products?


Similar to the previous question, we can accept a solution that provides the approximate volumes and ranking of the top 10 products within the last few hours, and volumes and ranking of any arbitrary number of products for time periods older than a few hours, potentially up to years. It’s also fine if our solution can display more than 10 products:

- Do we need to show the sale counts on the Top K list or just the product sales rankings?

We will show both the rankings and counts. This seems like a superfluous question, but there might be possible design simplifications if we don’t need to display certain data:

- Do we need to consider events that occur after a sale? A customer may request a refund, an exchange for the same or different product(s), or a product may be recalled.

This is a good question that demonstrates one’s industry experience and attention to detail. Let’s assume we can consider only the initial sales events and disregard subsequent events like disputes or product recalls:

- Let’s discuss scalability requirements. What is the sales transaction rate? What is the request rate for our Heavy Hitters dashboard? How many products do we have?

Assume 10 billion sales events per day (i.e., heavy sales transaction traffic). At 1 KB/ event, the write rate is 10 TB/day. The Heavy Hitters dashboard will only be viewed by employees, so it will have low request rate. Assume we have ~1M products.

We do not have other non-functional requirements. High availability or low latency (and the corresponding complexities they will bring to our system design) are not required.

## _17.2 Initial thoughts_

Our first thought may be to log the events to a distributed storage solution, like HDFS or Elasticsearch, and run a MapReduce, Spark, or Elasticsearch query when we need to compute a list of Top K products within a particular period. However, this approach is computationally intensive and may take too long. It may take hours or days to compute a list of Top K products within a particular month or year.

If we don’t have use cases for storing our sales event logs other than generating this list, it will be wasteful to store these logs for months or years just for this purpose. If we log millions of requests per second, it can add up to PBs/year. We may wish to store a few months or years of raw events for various purposes, including serving customer disputes and refunds, for troubleshooting or regulatory compliance purposes. However, this retention period may be too short for generating our desired Top K list.

We need to preprocess our data prior to computing these Top K lists. We should periodically perform aggregation and count the sales of our products, bucketing by hour, day, week, month, and year. Then we can perform these steps when we need a Top K list:


- 1 If needed, sum the counts of the appropriate buckets, depending on the desired period. For example, if we need the Top K list of a period of one month, we simply use that month’s bucket. If we need a particular three-month period, we sum the counts of the one-month buckets of that period. This way, we can save storage by deleting events after we sum the counts.

- 2 Sort these sums to obtain the Top K list.

We need to save the buckets because the sales can be very uneven. In an extreme situation, a product “A” may have 1M sales within a particular hour during a particular year, and 0 sales at all other times during that year, while sales of all other products may sum to far less than 1M total sales in that year. Product A will be in the Top K list of any period that includes that hour.

The rest of this chapter is about performing these operations at scale in a distributed manner.

## _17.3 Initial high-level architecture_

We first consider Lambda architecture. _Lambda architecture_ is an approach to handling massive quantities of data by using both batch and streaming methods (Refer to https://www.databricks.com/glossary/lambda-architectureorhttps://www.snowflake.com/guides/lambda-architecture.) Referring to figure 17.1, our lambda architecture consists of two parallel data processing pipelines and a serving layer that combines the results of these two pipelines:

- 1 A streaming layer/pipeline that ingests events in real time from all data centers where sales transactions occur and uses an approximation algorithm to compute the sales volumes and rankings of the most popular products.

- 2 A batch layer, or batch pipelines that run periodically (hourly, daily, weekly, and yearly) to compute accurate sales volumes and rankings. For our users to see the accurate numbers as they become available, our batch pipeline ETL job can contain a task to overwrite the results of the streaming pipeline with the batch pipeline’s whenever the latter are ready.


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0409-10.png)




Figure 17.1    A high-level sketch of our Lambda architecture. Arrows indicate the direction of requests. Data flows through our parallel streaming and batch pipelines. Each pipeline writes its final output to a table in a database. The streaming pipeline writes to the speed_table while the batch pipeline writes to the batch_table. Our dashboard combines data from the speed_table and batch_table to generate the Top K lists.


Following an EDA (Event Driven Architecture) approach, the sales backend service sends events to a Kafka topic, which can be used for all downstream analytics such as our Top K dashboard.

## _17.4 Aggregation service_

An initial optimization we can make to our Lambda architecture is to do some aggregation on our sales events and pass these aggregated sales events to both our streaming and batch pipelines. Aggregation can reduce the cluster sizes of both our streaming and batch pipelines. We sketch a more detailed initial architecture in figure 17.2. Our streaming and batch pipelines both write to an RDBMS (SQL), which our dashboard can query with low latency. We can also use Redis if all we need is simple key-value lookups, but we will likely desire filter and aggregation operations for our dashboard and other future services.


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0410-05.png)




Figure 17.3    Simplified flow diagram of the rollup tasks in our batch pipeline. We have a rollup job that progressively rolls up by increasing time intervals to reduce the number of rows processed in each stage.

Let’s estimate the storage requirements. 400M rows each with 10 64-bit columns occupy 32 GB. This can easily fit into a single host. The hourly rollup job may need to process billions of sales events, so it can use a Hive query to read from HDFS and then write the resulting counts to the SQL batch_table. The rollups for other intervals use the vast reduction of the number of rows from the hourly rollup, and they only need to read and write to this SQL batch_table.

In each of these rollups, we can order the counts by descending order, and write the Top K (or perhaps K*2 for flexibility) rows to our SQL database to be displayed on our dashboard.

Figure 17.4 is a simple illustration of our ETL DAG for one stage in our batch pipeline (i.e., one rollup job). We will have one DAG for each rollup (i.e., four DAG in total). An ETL DAG has the following four tasks. The third and fourth are siblings. We use Airflow terminology for DAG, task, and run:

- 1 For any rollup greater than hourly, we need a task to verify that the dependent rollup runs have successfully completed. Alternatively, the task can verify that the required HDFS or SQL data is available, but this will involve costly database queries.

- 2 Run a Hive or SQL query to sum the counts in descending order and write the result counts to the batch_table.

- 3 Delete the corresponding rows on the speed_table. This task is separate from task 2 because the former can be rerun without having to rerun the latter. Should task 3 fail while it is attempting to delete the rows, we should rerun the deletion without having to rerun the expensive Hive or SQL query of step 2.

- 4 Generate or regenerate the appropriate Top K lists using these new batch_table rows. As discussed later in section 17.5, these Top K lists most likely have already been generated using both our accurate batch_table data and inaccurate speed_ table table, so we will be regenerating these lists with only our batch_table. This task is not costly, but it can also be rerun independently if it fails, so we implement it as its own task.


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0415-02.png)




Figure 17.4    An ETL DAG for one rollup job. The constituent tasks are to verify that dependent rollups have completed, perform the rollup/counting and persist the counts to SQL, and then delete the appropriate speed_table rows because they are no longer needed.

Regarding task 1, the daily rollup can only happen if all its dependent hourly rollups have been written to HDFS, and likewise for the weekly and monthly rollups. One daily rollup run is dependent on 24 hourly rollup runs, one weekly rollup run is dependent on seven daily rollup runs, and one monthly rollup run is dependent on 28–30 daily rollup runs depending on the month. If we use Airflow, we can use `ExternalTaskSensor` (https://airflow.apache.org/docs/apache-airflow/stable/howto/operator/external_task_sensor.html#externaltasksensor)instanceswiththeappropriate `execution_date` parameter values in our daily, weekly, and monthly DAGs to verify that the dependent runs have successfully completed.

## _17.6 Streaming pipeline_

A batch job may take many hours to complete, which will affect the rollups for all intervals. For example, the Hive query for the latest hourly rollup job may take 30 minutes to complete, so the following rollups and by extension their Top K lists will be unavailable:

- The Top K list for that hour.

- The Top K list for the day that contains that hour will be unavailable.

- The Top K lists for the week and month that contains that day will be unavailable.

The purpose of our streaming pipeline is to provide the counts (and Top K lists) that the batch pipeline has not yet provided. The streaming pipeline must compute these counts much faster than the batch pipeline and may use approximation techniques.

After our initial aggregation, the next steps are to compute the final counts and sort them in descending order, and then we will have our Top K lists. In this section, we approach this problem by first considering an approach for a single host and then find how to make it horizontally scalable.

### _17.6.1 Hash table and max-heap with a single host_

Our first attempt is to use a hash table and sort by frequency counts using a max-heap of size K. Listing 17.1 is a sample top K Golang function with this approach.


Listing 17.1    Sample Golang function to compute Top K list

```go
type HeavyHitter struct {
    identifier string frequency  int
}
 func topK(events []String, int k) (HeavyHitter) {
    frequencyTable := make(map[string]int)
    for _, event := range events {
        value := frequencyTable[event]
        if value == 0 {
            frequencyTable[event] = 1
        } else {
            frequencyTable[event] = value + 1
        }
    }
    pq = make(PriorityQueue, k)
    i := 0 for key, element := range frequencyTable {
        pq[i++] = &HeavyHitter{
            identifier: key, frequency:  element,
        }
        if pq.Len() > k {
            pq.Pop(&pq).(*HeavyHitter)
        }
    }
    /*
     * Write the heap contents to your destination.
     * Here we just return them in an array.
     */
    var result [k]HeavyHitter i := 0 for pq.Len() > 0 {
        result[i++] = pq.Pop(&pq).(*HeavyHitter)
    }
    return result
}
```

In our system, we can run multiple instances of the function in parallel for our various time buckets (i.e., hour, day, week, month, and year). At the end of each period, we can store the contents of the max-heap, reset the counts to 0, and start counting for the new period.


### _17.6.2 Horizontal scaling to multiple hosts and multi-tier aggregation_

Figure 17.5 illustrates horizontal scaling to multiple hosts and multi-tier aggregation. The two hosts in the middle column sum the (product, hour) counts from their upstream hosts in the left column, while the max-heaps in the right column aggregate the (product, hour) counts from their upstream hosts in the middle column.


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0417-04.png)




Figure 17.5    If the traffic to the final hash table host is too high, we can use a multi-tier approach for our streaming pipeline. For brevity, we display a key in the format (product, hour). For example, “(A, 0)” refers to product A at hour 0. Our final layer of hosts can contain max heaps, one for each rollup interval. This design is very similar to a multi-tier aggregation service discussed in section 4.5.2. Each host has an associated Kafka topic, which we don’t illustrate here.

In this approach, we insert more tiers between the first layer of hosts and the final hash table host, so no host gets more traffic than it can process. This is simply shifting the complexity of implementing a multi-tier aggregation service from our aggregation service to our streaming pipeline. The solution will introduce latency, as also described in section 4.5.2. We also do partitioning, following the approach described in section 4.5.3 and illustrated in figure 4.6. Note the discussion points in that section about addressing hot partitions. We partition by product ID. We may also partition by sales event timestamp.

#### Aggregation

Notice that we aggregate by the combination of product ID and timestamp. Before reading on, think about why.


Why do we aggregate by the combination of product ID and timestamp? This is because a Top K list has a period, with a start time and an end time. We need to ensure that each sales event is aggregated in its correct time ranges. For example, a sales event that occurred at 2023-01-01 10:08 UTC should be aggregated in

- 1 The hour range of [2023-01-01 10:08 UTC, 2023-01-01 11:00 UTC).

- 2 The day range of [2023-01-01, 2023-01-02).

- 3 The week range of [2022-12-28 00:00 UTC, 2023-01-05 00:00 UTC). 2022-12-28 and 2023-01-05 are both Mondays.

- 4 The month range of [2023-01-01, 2013-02-01).

- 5 The year range of [2023, 2024).

Our approach is to aggregate by the smallest period (i.e., hour). We expect any event to take only a few seconds to go through all the layers in our cluster, so it is unlikely for any key in our cluster that is more than an hour old. Each product ID has its own key. With the hour range appended to each key, it is unlikely that the number of keys will be greater than the number of product IDs times two.

One minute after the end of a period—for example, at 2023-01-01 11:01 UTC for [2023-01-01 10:08 UTC, 2023-01-01 11:00 UTC) or 2023-01-02 00:01 UTC for [202301-01, 2023-01-02)—the respective host in the final layer (whom we can refer to as _final hosts_ ) can write its heap to our SQL speed_table, and then our dashboard is ready to display the corresponding Top K list for this period. Occasionally, an event may take more than a minute to go through all the layers, and then the final hosts can simply write their updated heaps to our speed_table. We can set a retention period of a few hours or days for our final hosts to retain old aggregation keys, after which they can delete them.

An alternative to waiting one minute is to implement a system to keep track of the events as they pass through the hosts and trigger the final hosts to write their heaps to the speed_table only after all the relevant events have reached the final hosts. However, this may be overly complex and also prevents our dashboard from displaying approximations before all events have been fully processed.

## _17.7 Approximation_

To achieve lower latency, we may need to limit the number of layers in our aggregation service. Figure 17.6 is an example of such a design. We have layers that consist of just max-heaps. This approach trades off accuracy for faster updates and lower cost. We can rely on the batch pipeline for slower and highly accurate aggregation.

Why are max-heaps in separate hosts? This is to simplify provisioning new hosts when scaling up our cluster. As mentioned in section 3.1, a system is considered scalable if it can be scaled up and down with ease. We can have separate Docker images for hash table hosts and the max-heap host, since the number of hash table hosts may change frequently while there is never more than one active max-heap host (and its replicas).


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0419-02.png)




Figure 17.6    Multi-tier with max-heaps. The aggregation will be faster but less accurate. For brevity, we don’t display time buckets in this figure.

However, the Top K list produced by this design may be inaccurate. We cannot have a max-heap in each host and simply merge the max-heaps because if we do so, the final max-heap may not actually contain the Top K products. For example, if host one had a hash table {A: 7, B: 6, C: 5}, and host B had a hash table {A: 2, B: 4, C: 5}, and our maxheap is of size 2, host 1’s max-heap will contain {A: 7, B: 6} and host 2’s max-heap will contain {B: 4, C: 5}. The final combined max-heap will be {A: 7, B: 10}, which erroneously leaves C out of the top two list. The correct final max-heap should be {B: 10, C: 11}.


### _17.7.1 Count-min sketch_

The previous example approaches require a large amount of memory on each host for a hash table of the same size as the number of products (in our case ~1M). We can consider trading off accuracy for lower memory consumption by using approximations.

Count-min sketch is a suitable approximation algorithm. We can think of it as a two-dimensional (2D) table with a width and a height. The width is usually a few thousand while the height is small and represents a number of hash functions (e.g., 5). The output of each hash function is bounded to the width. When a new item arrives, we apply each hash function to the item and increment the corresponding cell.

Let’s walk through an example of using count-min sketch with a simple sequence “A C B C C.” C is the most common letter and occurs three times. Tables 17.1–17.5 illustrate a count-min sketch table. We bold the hashed value in each step to highlight it.

- 1 Hash the first letter “A” with each of the five hash functions. Table 17.1 illustrates that each hash function hashes “A” to a different value.

Table 17.1    Sample count-min sketch table after adding a single letter “A”

1 1 1 1 1

- 2 Hash the second letter “C.” Table 17.2 illustrates that the first four hash functions hash “C” to a different value than “A.” The fifth hash function has a collision. The hashed values of “A” and “C” are identical, so that value is incremented.

Table 17.2    Sample count-min sketch table after adding “A C”

|1||||1||
|---|---|---|---|---|---|
||1||1|||
|1||||1||
||1||1|||
||2 (collision)|||||


- 3 Hash the third letter “B.” Table 17.3 illustrates that the fourth and fifth hash functions have collisions.


Table 17.3    Sample count-min sketch table after adding “A C B”

|1||1||1||
|---|---|---|---|---|---|
||1||1||1|
|1|1|||1||
||2 (collision)||1|||
||3 (collision)|||||


- 4 Hash the fourth letter “C.” Table 17.4 illustrates that only the fifth hash function has a collision.

Table 17.4    Sample count-min sketch table after adding “A C B C”

|1||1||2||
|---|---|---|---|---|---|
||1||2||1|
|2|1|||1||
||2||2|||
||4 (collision)|||||


- 5 Hash the fifth letter “C.” The operation is identical to the previous step. Table 17.5 is the count-min sketch table after a sequence “A C B C C.”

Table 17.5    Sample count-min sketch table after a sequence “A C B C C”

|1||1||3||
|---|---|---|---|---|---|
||1||3||1|
|3|1|||1||
||2||3|||
||5 (collision)|||||


To find the item with the highest number of occurrences, we first take the maximum of each row {3, 3, 3, 3, 5} and then the minimum of these maximums “3.” To find the item with the second highest number of occurrences, we first take the second highest number in each row {1, 1, 1, 2, 5} and then the minimum of these numbers “1.” And so on. By taking the minimum, we decrease the chance of overestimation.

There are formulas that help to calculate the width and height based on our desired accuracy and the probability we achieve that accuracy. This is outside the scope of this book.

The count-min sketch 2D array replaces the hash table in our previous approaches. We will still need a heap to store a list of heavy hitters, but we replace a potentially big hash table with a count-min sketch 2D array of predefined size that remains fixed regardless of the data set size.


## _17.8 Dashboard with Lambda architecture_

Referring to figure 17.7, our dashboard may be a browser app that makes a GET request to a backend service, which in turn runs a SQL query. The discussion so far has been about a batch pipeline that writes to batch_table and a streaming pipeline that writes to speed_table, and the dashboard should construct the Top K list from both tables.


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0422-04.png)




Figure 17.7    Our dashboard has a simple architecture, consisting of a browser app that makes GET requests to a backend service, which in turn makes SQL requests. The functional requirements of our browser app may grow over time, from simply displaying the top 10 lists of a particular period (e.g., the previous month), to include larger lists, more periods, filtering, or aggregation (like percentile, mean, mode, max, min).

However, SQL tables do not guarantee order, and filtering and sorting the batch_table and speed_table may take seconds. To achieve P99 of <1 second, the SQL query should be a simple SELECT query against a single view that contains the list of rankings and counts, which we refer to as the `top_1000` view. This view can be constructed by selecting the top 1,000 products from the speed_table and batch_table in each period. It can also contain an additional column that indicates whether each row is from the speed_table or batch_table. When a user requests a Top K dashboard for a particular interval, our backend can query this view to obtain as much data from the batch table as possible and fill in the blanks with the speed table. Referring to section 4.10, our browser app and backend service can also cache the query responses.

#### Exercise

As an exercise, define the SQL query for the top_1000 view.

## _17.9 Kappa architecture approach_

_Kappa architecture_ is a software architecture pattern for processing streaming data, performing both batch and streaming processing with a single technology stack (https:// hazelcast.com/glossary/kappa-architecture). It uses an append-only immutable log like Kafka to store incoming data, followed by stream processing and storage in a database for users to query.

In this section, we compare Lambda and Kappa architecture and discuss a Kappa architecture for our dashboard.


### _17.9.1 Lambda vs. Kappa architecture_

Lambda architecture is complex because the batch layer and streaming layer each require their own code base and cluster, along with associated operational overhead and the complexity and costs of development, maintenance, logging, monitoring, and alerting.

Kappa architecture is a simplification of Lambda architecture, where there is only a streaming layer and no batch layer. This is akin to performing both streaming and batch processing on a single technology stack. The serving layer serves the data computed from the streaming layer. All data is read and transformed immediately after it is inserted into the messaging engine and processed by streaming techniques. This makes it suitable for low-latency and near real-time data processing like real-time dashboards or monitoring. As discussed earlier regarding the Lambda architecture streaming layer, we may choose to trade off accuracy for performance. But we may also choose not to make this tradeoff and compute highly accurate data.

Kappa architecture originated from the argument that batch jobs are never needed, and streaming can handle all data processing operations and requirements. Refer to https://www.oreilly.com/radar/questioning-the-lambda-architecture/andhttps://www.kai-waehner.de/blog/2021/09/23/real-time-kappa-architecture-mainstream-replacing-batch-lambda/,whichdiscussthedisadvantagesofbatch and how streaming does not have them.

In addition to the points discussed in these reference links, another disadvantage of batch jobs compared to streaming jobs is the former’s much higher development and operational overheads because a batch job that uses a distributed file system like HDFS tends to take at least minutes to complete even when running on a small amount of data. This is due to HDFS’s large block size (64 or 128 MB compared to 4 KB for UNIX file systems) to trade off low latency for high throughput. On the other hand, a streaming job processing a small amount of data may only take seconds to complete.

Batch job failures are practically inevitable during the entire software development lifecycle from development to testing to production, and when a batch job fails, it must be rerun. One common technique to reduce the amount of time to wait for a batch job is to divide it into stages. Each stage outputs data to intermediate storage, to be used as input for the next stage. This is the philosophy behind Airflow DAGs. As developers, we can design our batch jobs to not take more than 30 minutes or one hour each, but developers and operations staff will still need to wait 30 minutes or one hour to see if a job succeeded or failed. Good test coverage reduces but does not eliminate production problems.

Overall, errors in batch jobs are more costly than in streaming jobs. In batch jobs, a single bug crashes an entire batch job. In streaming, a single bug only affects processing of that specific event.

Another advantage of Kappa vs. Lambda architecture is that the relative simplicity of the former, which uses a single processing framework while the latter may require different frameworks for its batch and streaming pipelines. We may use frameworks like Redis, Kafka, and Flink for streaming.


One consideration of Kappa architecture is that storing a large volume of data in an event-streaming platform like Kafka is costly and not scalable beyond a few PBs, unlike HDFS, which is designed for large volumes. Kafka provides infinite retention with _log compaction_ (https://kafka.apache.org/documentation/#compaction),soa Kafka topic saves storage by only storing the latest value for each message key and delete all earlier values for that key. Another approach is to use object storage like S3 for longterm storage of data that is seldom accessed. Table 17.6 compares Lambda and Kappa architecture.

Table 17.6    Comparison between Lambda and Kappa architecture


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0424-04.png)




|Lambda|Kappa|
|---|---|
|||
|Separate batch and streaming<br>pipelines. Separate clusters,<br>code bases, and processing<br>frameworks. Each needs its own<br>infrastructure, monitoring, logs,<br>and support.<br>Batch pipelines allow faster per-<br>formance with processing large<br>amounts of data.<br>An error in a batch job may<br>require all the data to be repro-<br>cessed from scratch.|Single pipeline, cluster, code<br>base, and processing framework.<br>Processing large amounts of<br>data is slower and more expen-<br>sive than Lambda architecture.<br>However, data is processed as<br>soon as it is ingested, in contrast<br>to batch jobs which run on a<br>schedule, so the latter may pro-<br>vide data sooner.<br>An error in a streaming job only<br>requires reprocessing of its<br>affected data point.|


### _17.9.2 Kappa architecture for our dashboard_

A Kappa architecture for our Top K dashboard can use the approach in section 17.3.2, where each sales event is aggregated by its product ID and time range. We do not store the sales event in HDFS and then perform a batch job. A count of 1M products can easily fit in a single host, but a single host cannot ingest 1B events/day; we need multi-tier aggregation.

A serious bug may affect many events, so we need to log and monitor errors and monitor the rate of errors. It will be difficult to troubleshoot such a bug and difficult to rerun our streaming pipeline on a large number of events, so we can define a critical error rate and stop the pipeline (stop the Kafka consumers from consuming and processing events) if the error rate exceeded this defined critical error rate.

Figure 17.8 illustrates our high-level architecture with Kappa architecture. It is simply our Lambda architecture illustrated in figure 17.2 without the batch pipeline and aggregation service.


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0425-02.png)




Figure 17.8    Our high-level architecture that uses Kappa architecture. It is simply our Lambda architecture in figure 17.2 without the batch pipeline and aggregation service.

## _17.10 Logging, monitoring, and alerting_

Besides what was discussed in section 2.5, we should monitor and send alerts for the following.

Our shared batch ETL platform should already be integrated with our logging, monitoring, and alerting systems. We will be alerted to unusually long run time or failures of any of the tasks within our rollup job.

The rollup tasks write to HDFS tables. We can use the data quality monitoring tools described in chapter 10 to detect invalid datapoints and raise alerts.

## _17.11 Other possible discussion topics_

Partition these lists by other characteristics, such as country or city. What design changes will we need to return the Top K products by revenue instead of sales volume? How can we track the Top K products by change in sales volume and/or revenue?

It may be useful to look up rankings and statistics of certain products with names or descriptions that match patterns. We can design a search system for such use cases.

We may discuss programmatic users of the Top K lists, such as machine learning and experimentation services. We had assumed a low request rate and that high availability and low latency were not required. These assumptions will no longer hold as programmatic users introduce new non-functional requirements.

Can our dashboard display approximations for the Top K lists before the events are fully counted, or perhaps even before the events occur?

A considerable complication with counting sales is disputes, such as customer requests for refunds or exchanges. Should sale numbers include disputes in progress? Do we need to correct the past data to consider refunds, returns, or exchanges? How do we recount sales events if refunds are granted or rejected or if there are exchanges for the same product or other product(s)?

We may offer a warranty of several years, so a dispute may occur years after the sale. Database queries may need to search for sales events that occurred years before. Such jobs may run out of memory. This is a challenging problem that is still faced by many engineers to this day.

There may be drastic events, such as a product recall. For example, we may need to recall a toy because it was suddenly found to be unsafe to children. We may discuss whether the counts of sales events should be adjusted if such problems occur.

Besides regenerating the Top K lists for the previous reasons, we may generalize this to regenerating the Top K lists from any data change.


Our browser app only displays the Top K list. We can extend our functional requirements, such as displaying sales trends or predicting future sales of current or new products.

## _17.12 References_

This chapter used material from the Top K Problem (Heavy Hitters) (https://youtu.be/kx-XDoPjoHw)presentationinthe System Design Interview YouTube channel by Mikhail Smarshchok.

## _Summary_

- When accurate large-scale aggregation operations take too long, we can run a parallel streaming pipeline that uses approximation techniques to trade off accuracy for speed. Running a fast, inaccurate and a slow, accurate pipeline in parallel is called Lambda architecture.

- One step in large-scale aggregation is to partition by a key that we will later aggregate over.

- Data that is not directly related to aggregation should be stored in a different service, so it can be easily used by other services.

- Checkpointing is one possible technique for distributed transactions that involve both destinations with cheap read operations (e.g., Redis) and expensive read operations (e.g., HDFS).

- We can use a combination of heaps and multi-tier horizontal scaling for approximate large-scale aggregation operations.

- Count-min sketch is an approximation technique for counting.

- We can consider either Kappa or Lambda architecture for processing a large data stream.


## _Monoliths vs. microservices_ ~~_A_~~

This appendix evaluates monoliths vs. microservices. The author’s personal experience is that it seems many sources describe the advantages of microservice over monolith architecture but do not discuss the tradeoffs, so we will discuss them here. We use the terms “service” and “microservice” interchangeably.

_Microservice architecture_ is about building a software system as a collection of loosely-coupled and independently developed, deployed, and scaled services. _Monoliths_ are designed, developed, and deployed as a single unit.

#### _A.1 Advantages of monoliths_

Table A.1 discusses the advantages of monoliths over services.

 appendix a _**Monoliths vs. microservices**_

Table A.1    Advantages of monoliths over services


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0428-03.png)




|Monolith|Service|
|---|---|
|Faster and easier to develop at frst|Developers need to handle serialization and deserialization in|
|because it is a single application.<br>A single database means it uses less<br>storage, but this comes with tradeoffs.<br>With a single database and fewer data<br>storage locations in general, it may<br>be easier to comply with data privacy<br>regulations.<br>Debugging may be easier. A developer<br>can use breakpoints to view the func-<br>tion call stack at any line of code and<br>understand all logic that is happening<br>at that line.<br>Related to the previous point, being<br>able to easily view all the code in a<br>single location and trace function calls<br>may make the application/system as a<br>whole generally easier to understand<br>than in a service architecture.<br>Cheaper to operate and better perfor-<br>mance. All processing occurs within the<br>memory of a single host, so there are<br>no data transfers between hosts, which<br>are much slower and more expensive.|every service, and handle requests and responses between the<br>services.<br>Before we begin development, we frst need to decide where the<br>boundaries between the services should be, and our chosen<br>boundaries may turn out to be wrong. Redeveloping services to<br>change their boundaries is usually impractical.<br>Each service should have its own database, so there may be<br>duplication of data and overall greater storage requirements.<br>Data is scattered in many locations, which makes it more diff-<br>cult to ensure that data privacy regulations are complied with<br>throughout the organization.<br>Distributed tracing tools like Jaegar or Zipkin are used to under-<br>stand request fan-out, but they do not provide many details,<br>such as the function call stack of the services involved in the<br>request. Debugging across services is generally harder than in a<br>monolith or individual service.<br>A service’s API is presented as a black box. While not having to<br>understand an API’s details may make it easier to use, it may<br>become diffcult to understand many of the fne details of the<br>system.<br>A system of services that transfer large amounts of data<br>between each other can incur very high costs from the data<br>transfers between hosts and data centers. Refer tohttps://<br>www.primevideotech.com/video-streaming/scaling-up-the<br>-prime-video-audio-video-monitoring-service-and-reducing<br>-costs-by-90foradiscussiononhowan Amazon Prime Video<br>reduced the infrastructure costs of a system by 90% by merging<br>most (but not all) of their services in a distributed microservices<br>architecture into a monolith.|


#### _A.2 Disadvantages of monoliths_

Monoliths have the following disadvantages compared to microservices:

- Most capabilities cannot have their own lifecycles, so it is hard to practice Agile methodologies.

- Need to redeploy the entire application to apply any changes.

- Large bundle size. High resource requirements. Long startup time.

- Must be scaled as a single application.

- A bug or instability in any part of a monolith can cause failures in production.


- Must be developed with a single language, so it cannot take advantage of the capabilities offered by other languages and their frameworks in addressing requirements of various use cases.

#### _A.3 Advantages of services_

The advantages of services over monoliths include the following:

- 1 Agile and rapid development and scaling of product requirements/business functionalities.

- 2 Modularity and replaceability.

- 3 Failure isolation and fault-tolerance.

- 4 More well-defined ownership and organizational structure.

#### _A.3.1 Agile and rapid development and scaling of product requirements and business functionalities_

Designing, implementing, and deploying software to satisfy product requirements is slower with a monolith than a service because the monolith has a much bigger codebase and more tightly coupled dependencies.

When we develop a service, we can focus on a small set of related functionalities and the service’s interface to its users. Services communicate via network calls through the service interfaces. In other words, services communicate via their defined APIs over industry-standard protocols such as HTTP, gRPC, and GraphQL. Services have obvious boundaries in the form of their APIs, while monoliths do not. In a monolith, it is far more common for any particular piece of code to have numerous dependencies scattered throughout the codebase, and we may have to consider the entire system when developing in a monolith.

With cloud-based container native-infrastructure, a service can be developed and deployed much quicker than comparable features in a monolith. A service that provides a well-defined and related set of capabilities may be CPU-intensive or memory-intensive, and we can select the optimal hardware for it, cost-efficiently scaling it up or down as required. A monolith that provides many capabilities cannot be scaled in a manner to optimize for any individual capability.

Changes to individual services are deployed independently of other services. Compared to a monolith, a service has a smaller bundle size, lower resource requirements, and faster startup time.

#### _A.3.2 Modularity and replaceability_

The independent nature of services makes them modular and easier to replace. We can implement another service with the same interface and swap out the existing service with the new one. In a monolith, other developers may be changing code and interfaces at the same time as us, and it is more difficult to coordinate such development vs. in a service.

 appendix a _**Monoliths vs. microservices**_

We can choose technologies that best suit the service’s requirements (e.g., a specific programming language for a frontend, backend, mobile, or analytics service).

#### _A.3.3 Failure isolation and fault-tolerance_

Unlike a monolith, a microservices architecture does not have a single point of failure. Each service can be separately monitored, so any failure can be immediately narrowed down to a specific service. In a monolith, a single runtime error may crash the host, affecting all other functionalities. A service that adopts good practices for fault-tolerance can adapt to high latency and unavailability of the other services that it is dependent on. Such best practices are discussed in section 3.3, including caching other services’ responses or exponential backoff and retry. The service may also return a sensible error response instead of crashing.

Certain services are more important than others. For example, they may have a more direct effect on revenue or are more visible to users. Having separate services allows us to categorize them by importance and allocate development and operations resources accordingly.

#### _A.3.4 Ownership and organizational structure_

With their well-defined boundaries, mapping the ownership of services to teams is straightforward compared to monoliths. This allows concentration of expertise and domain knowledge; that is, a team that owns a particular service can develop a strong understanding of it and expertise in developing it. The flip side is that developers are less likely to understand other services and possess less understanding and ownership of the overall system, while a monolith may force developers to understand more of the system beyond the specific components that they are responsible to develop and maintain. For example, if a developer requires some changes in another service, they may request the relevant team to implement those changes rather than doing so themselves, so development time and communication overhead are higher. Having those changes done by developers familiar with the service may take less time and have a lower risk of bugs or technical debt.

The nature of services with their well-defined boundaries also allows various service architectural styles to provide API definition techniques, including OpenAPI for REST, protocol buffers for gRPC, and Schema Definition Language (SDL) for GraphQL.

#### _A.4 Disadvantages of services_

The disadvantages of services compared to monoliths include duplicate components and the development and maintenance costs of additional components.

#### _A.4.1 Duplicate components_

Each service must implement inter-service communication and security, which is mostly duplicate effort across services. A system is as strong as its weakest point, and the large number of services exposes a large surface area that must be secured, compared to a monolith.


Developers in different teams who are developing duplicate components may also duplicate mistakes and the efforts needed to discover and fix these mistakes, which is development and maintenance waste. This duplication of effort and waste of time also extends to users and operations staff of the duplicate services who run into the bugs caused by these mistakes, and expend duplicate effort into troubleshooting and communicating with developers.

Services should not share databases, or they will no longer be independent. For example, a change to a database schema to suit one service will break other services. Not sharing databases may cause duplicate data and lead to an overall higher amount and cost of storage in the system. This may also make it more complex and costly to comply with data privacy regulations.

#### _A.4.2 Development and maintenance costs of additional components_

To navigate and understand the large variety of services in our organization, we will need a service registry and possibly additional services for service discovery.

A monolithic application has a single deployment lifecycle. A microservice application has numerous deployments to manage, so CI/CD is a necessity. This includes infrastructure like containers (Docker), container registry, container orchestration (Kubernetes, Docker Swarm, Mesos), CI tools such as Jenkins, and CD tools, which may support deployment patterns like blue/green deployment, canary, and A/B testing.

When a service receives a request, it may make requests to downstream services in the process of handling this request, which in turn may make requests to further downstream services. This is illustrated in figure A.1. A single request to Netflix’s homepage causes a request to fan out to numerous downstream services. Each such request adds networking latency. A service’s endpoint may have a one-second P99 SLA, but if multiple endpoints are dependencies of each other (e.g., service A calls service B, which calls service C, and so on), the original requester may experience high latency.


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0431-08.png)


Figure A.1    Illustration of request fan-out to downstream services that occurs on a request to get Netflix’s homepage. Image from https://www.oreilly.com/content/application-caching-at-netflix-the-hidden-microservice/.appendixa_**Monolithsvs.microservices**_

Caching is one way to mitigate this, but it introduces complexity, such as having to consider cache expiry and cache refresh policies to avoid stale data, and the overhead of developing and maintaining a distributed cache service.

A service may need the additional complexity and development and maintenance costs of implementing exponential backoff and retry (discussed in section 3.3.4) to handle outages of other services that it makes requests to.

Another complex additional component required by microservices architecture is distributed tracing, which is used for monitoring and troubleshooting microservices-based distributed systems. Jaeger and Zipkin are popular distributed tracing solutions.

Installing/updating a library on a monolith involves updating a single instance of that library on the monolith. With services, installing/updating a library that is used in multiple services will involve installing/updating it across all these services. If an update has breaking changes, each service’s developers manually update their libraries and update broken code or configurations caused by backward incompatibility. Next, they must deploy these updates using their CI/CD (continuous integration/continuous deployment) tools, possibly to several environments one at a time before finally deploying to the production environment. They must monitor these deployments. Along the way in development and deployment, they must troubleshoot any unforeseen problems. This may come down to copying and pasting error messages to search for solutions on Google or the company’s internal chat application like Slack or Microsoft Teams. If a deployment fails, the developer must troubleshoot and then retry the deployment and wait for it again to succeed or fail. Developers must handle complex scenarios (e.g., persistent failures on a particular host) All of this is considerable developer overhead. Moreover, this duplication of logic and libraries may also add up to a non-trivial amount of additional storage.

#### _A.4.3 Distributed transactions_

Services have separate databases, so we may need distributed transactions for consistency across these databases, unlike a monolith with a single relational database that can make transactions against that database. Having to implement distributed transactions is yet another source of cost, complexity, latency, and possible errors and failures. Chapter 5 discussed distributed transactions.

#### _A.4.4 Referential integrity_

_Referential integrity_ refers to the accuracy and consistency of data within a relationship. If a value of one attribute in a relation references a value of another attribute and then the referenced value must exist.

Referential integrity in a monolith’s single database can be easily implemented using foreign keys. Values in a foreign key column must either be present in the primary key that is referenced by the foreign key, or they must be null (https://www.interfacett.com/blogs/referential-integrity-options-cascade-set-null-and-set-default).Referentialintegrityismorecomplicatedif the databases are distributed across services. For referential integrity in a distributed system, a write request that involves multiple services must succeed in every service or fail/abort/rollback in every service. The write process must include steps such as retries or rollbacks/compensating transactions. Refer to chapter 5 for more discussion of distributed transactions. We may also need a periodic audit across the services to verify referential integrity.

#### _A.4.5 Coordinating feature development and deployments that span multiple services_

If a new feature spans multiple services, development and deployment need to be coordinated between them. For example, one API service may be dependent on others. In another example, the developer team of a Rust Rocket (https://rocket.rs/) RESTful API service may need to develop new API endpoints to be used by a React UI service, which is developed by a separate team of UI developers. Let’s discuss the latter example.

In theory, feature development can proceed in parallel on both services. The API team need only provide the specification of the new API endpoints. The UI team can develop the new React components and associated node.js or Express server code. Since the API team has not yet provided a test environment that returns actual data, the server code or mock or stub responses from the new API endpoints and use them for development. This approach is also useful for authoring unit tests in the UI code, including spy tests (refer to https://jestjs.io/docs/mock-function-apiformoreinformation).Teamscanalsousefeatureflags to selectively expose incomplete features to development and staging environments, while hiding them from the production environment. This allows other developers and stakeholders who rely on these new features to view and discuss the work in progress.

In practice, the situation can be much more complicated. It can be difficult to understand the intricacies of a new set of API endpoints, even by developers and UX designers with considerable experience in working with that API. Subtle problems can be discovered by both the API developers and UI developers during the development of their respective services, the API may need to change, and both teams must discuss a solution and possibly waste some work that was already done:

- The data model may be unsuitable for the UX. For example, if we develop a version control feature for templates of a notifications system (refer to section 9.5), the UX designer may design the version control UX to consider individual templates. However, a template may actually consist of subcomponents that are versioned separately. This confusion may not be discovered until both UI and API development are in progress.

- During development, the API team may discover that the new API endpoints require inefficient database queries, such as overly large SELECT queries or JOIN operations between large tables.

- For REST or RPC APIs (i.e., not GraphQL), users may need to make multiple API requests and then do complex post-processing operations on the responses before the data can be returned to the requester or displayed on the UI. Or the appendix a _**Monoliths vs. microservices**_ provided API may fetch much more data than required by the UI, which causes unnecessary latency. For APIs that are developed internally, the UI team may wish to request some API redesign and rework for less complex and more efficient API requests.

#### _A.4.6 Interfaces_

Services can be written in different languages and communicate with each other via a text or binary protocol. In the case of text protocols like JSON or XML, these strings need to be translated to and from objects. There is additional code required for validation and error and exception handling for missing fields. To allow graceful degradation, our service may need to process objects with missing fields. To handle the case of our dependent services returning such data, we may need to implement backup steps such as caching data from dependent services and returning this old data, or perhaps also return data with missing fields ourselves. This may cause implementation to differ from documentation.

#### _A.5 References_

This appendix uses material from the book _Microservices for the Enterprise: Designing, Developing, and Deploying_ by Kasun Indrasiri and Prabath Siriwardena (2018, Apress).


## _OAuth 2.0 authorization and OpenID Connect authentication[1]_ ~~_B_~~

#### _B.1 Authorization vs. authentication_

_Authorization_ is the process of giving a user (a person or system) permission to access a specific resource or function. _Authentication_ is identity verification of a user. _OAuth 2.0_ is a common authorization algorithm. (The OAuth 1.0 protocol was published in April 2010, while OAuth 2.0 was published in October 2012.) _OpenID Connect_ is an extension to OAuth 2.0 for authentication. Authentication and authorization/ access control are typical security requirements of a service. OAuth 2.0 and OpenID Connect may be briefly discussed in an interview regarding authorization and authentication.

A common misconception online is the idea of “login with OAuth2.” Such online resources mix up the distinct concepts of authorization and authentication. This section is an introduction to authorization with OAuth2 and authentication with OpenID Connect and makes their authorization versus authentication distinction clear.

> 1 This section uses material from the video “OAuth 2.0 and OpenID Connect (in plain English),” http:// oauthacademy.com/talk, an excellent introductory lecture by Nate Barbettini, and https://auth0.com/docs.Alsorefertohttps://oauth.net/2/formoreinformation.appendixb_**OAuth2.0authorization and OpenID Connect authentication**_

#### _B.2 Prelude: Simple login, cookie-based authentication_

The most basic type of authentication is commonly referred to as _simple login_ , _basic authentication_ , or _forms authentication_ . In simple login, a user enters an (identifier, password) pair. Common examples are (username, password) and (email, password). When a user submits their username and password, the backend will verify that the password is correct for the associated username. Passwords should be salted and hashed for security. After verification, the backend creates a session for this user. The backend creates a cookie that will be stored in both the server’s memory and in the user’s browser. The UI will set a cookie in the user’s browser, such as Set-Cookie: sessionid=f00b4r; Max-Age: 86400;. This cookie contains a session ID. Further requests from the browser will use this session ID for authentication, so the user does not have to enter their username and password again. Each time the browser makes a request to the backend, the browser will send the session ID to the backend, and the backend will compare this sent session ID to its own copy to verify the user’s identity.

This process is called _cookie-based authentication_ . A session has a finite duration, after which it expires/times out and the user must reenter their username and password. Session expiration has two types of timeouts: absolute and inactivity. _Absolute timeout_ terminates the session after a specified period has elapsed. _Inactivity timeout_ terminates the solution after a specified period during which a user has not interacted with the application.

#### _B.3 Single sign-on_

_Single sign-on_ (SSO) allows one to log in to multiple systems with a single master account, such as an Active Directory account. SSO is typically done with a protocol called Security Assertion Markup Language (SAML). The introduction of mobile apps in the late 2000s necessitated the following:

- Cookies are unsuitable for devices, so a new mechanism was needed for longlived sessions, where a user remains logged into a mobile app even after they close the app.

- A new use case called _delegated authorization_ . The owner of a set of resources can delegate access to some but not all of these resources to a designated client. For example, one may grant a certain app permission to see certain kinds of their Facebook user information, such as their public profile and birthday, but not post on your wall.

#### _B.4 Disadvantages of simple login_

The disadvantages of simple login include complexity, lack of maintainability, and no partial authorization.


#### _B.4.1 Complexity and lack of maintainability_

Much of a simple login (or session-based authentication in general) is implemented by the application developer, including the following:

- The login endpoint and logic, including the salting and hashing operations

- The database table of usernames and salted+hashed passwords

- Password creation and reset, including 2FA operations such as password reset emails

This means that the application developer is responsible for observing security best practices. In OAuth 2.0 and OpenID Connect, passwords are handled by a separate service. (This is true of all token-based protocols. OAuth 2.0 and OpenID Connect are token-based protocols.) The application developer can use a third-party service that has good security practices, so there is less risk of passwords being hacked.

Cookies require a server to maintain state. Each logged-in user requires the server to create a session for it. If there are millions of sessions, the memory overhead may be too expensive. Token-based protocols have no memory overhead.

The developer is also responsible for maintaining the application to stay in compliance with relevant user privacy regulations such as the General Data Protection Regulation (GDPR), California Consumer Privacy Act (CCPA), and the Health Insurance Portability and Accountability Act (HIPAA).

#### _B.4.2 No partial authorization_

Simple login does not have the concept of partial access control permissions. One may wish to grant another party partial access to the former’s account for specific purposes. Granting complete access is a security risk. For example, one may wish to grant a budgeting app like Mint permission to see their bank account balance, but not other permissions like transferring money. This is impossible if the bank app only has simple login. The user must pass their bank app account’s username and password to Mint, giving Mint complete access to their bank account, just for Mint to view their bank balance.

Another example was Yelp before the development of OAuth. As illustrated in figure B.1, at the end of one’s Yelp user registration, Yelp will request the user for their Gmail login, so it can send a referral link or invite link to their contact list. The user has to grant Yelp complete access to their Gmail account just to send a single referral email to each of their contacts.

 appendix b _**OAuth 2.0 authorization and OpenID Connect authentication**_


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0438-02.png)


Figure B.1    Screenshot of Yelp’s browser app referral feature prior to OAuth, reflecting a shortcoming of no partial authorization in simple login. The user is requested to enter their email address and password, granting Yelp full permissions to their email account even though Yelp only wishes to send a single email to each of their contacts. Image from http://oauthacademy.com/talk.OAuth2.0adoptionisnowwidespread,somost apps do not use such practices anymore. A significant exception is the banking industry. As of 2022, most banks have not adopted OAuth.

#### _B.5_

#### _OAuth 2.0 flow_

This section describes an OAuth 2.0 flow, how an app like Google can use OAuth 2.0 for users to authorize apps like Yelp to access resources belonging to a Google user, such as send emails to a user’s Google contacts.

Figure B.2 illustrates the steps in an OAuth 2.0 flow between Yelp and Google. We closely follow figure B.2 in this chapter.


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0438-09.png)




Figure B.2    Illustration of OAuth2 flow, discussed in detail through this section. Front-channel communications are represented by solid lines. Back-channel communications are represented by dashed lines.


#### _B.5.1 OAuth 2.0 terminology_

- _Resource owner—_ The user who owns the data or controls certain operations that the application is requesting for. For example, if you have contacts in your Google account, you are the resource owner of that data. You can grant permission to an application to access that data. In this section, we refer to a resource owner as a user for brevity.

- _Client—_ The application that is requesting the resources.

- _Authorization server—_ The system the user uses to authorize the permission, such as accounts.google.com.

- _Resource server—_ API of the system that holds the data the client wants, such as the Google Contacts API. Depending on the system, the authorization server and resource server may be the same or separate systems.

- _Authorization grant—_ The proof of the user’s consent to the permission necessary to access the resources.

- _Redirect URI_ , _also called callback—_ The URI or destination when the authorization server redirects back to the client.

- _Access token—_ The key that the client uses to get the authorized resource.

- _Scope—_ The authorization server has a list of scopes that it understands (e.g., read a user’s Google contacts list, read emails, or delete emails). A client may request a certain set of scopes, depending on its required resources.

#### _B.5.2 Initial client setup_

An app (like Mint or Yelp) has to do a one-time setup with the authorization server (like Google) to become a client and enable users to use OAuth. When Mint requests Google to create a client Google provides:

- Client ID, which is typically a long, unique string identifier. This is passed with the initial request on the front channel.

- Client secret, which is used during token exchange.

#### 1. get authorization from the user

The flow begins with the (Google) resource owner on the client app (Yelp). Yelp displays a button for a user to grant access to certain data on their Google account. Clicking that button puts the user through an OAuth flow, a set of steps that results in the application having authorization and being able to access only the requested information.

When the user clicks on the button, the browser is redirected to the authorization server (e.g., a Google domain, which may be accounts.google.com, or a Facebook or Okta authorization server). Here, the user is prompted to log in (i.e., enter their email and password and click Login). They can see in their browser’s navigation bar that they appendix b _**OAuth 2.0 authorization and OpenID Connect authentication**_ is in a Google domain. This is a security improvement, as they provide their email and password to Google, rather than another app like Mint or Yelp.

In this redirect, the client passes configuration information to the authorization server via a query with a URL like “https://accounts.google.com/o/oauth2/v2/auth?client_id=yelp&redirect_uri=https%3A%2F%2Foidcdebugger.com%2Fdebug&scope=openid&response_type=code&response_mode=query&state=foobar&nonce=uwtukpm946m”.Thequeryparametersare:-_client_id—_ Identifies the client to the authorization server; for example, tells Google that Yelp is the client.

- _redirect_uri (also called callback URI)—_ The redirect URI.

- _scope—_ The list of requested scopes.

- _response_type—_ The type of authorization grant the client wants. There are a few different types, to be described shortly. For now, we assume the most common type, called an authorization code grant. This is a request to the authorization server for a code.

- _state—_ The state is passed from the client to the callback. As discussed in step 4 below, this prevents cross-site request forgery (CSRF) attacks.

- _nonce—_ Stands for “number used once.” A server-provided random value used to uniquely label a request to prevent replay attacks (outside the scope of this book).

#### 2. user consents to client’s scope

After they log in, the authorization server prompts the user to consent to the client’s requested list of scopes. In our example, Google will present them with a prompt that states the list of resources that the other app is requesting (such as their public profile and contact list) and a request for confirmation that they consent to granting these resources to that app. This ensures they are not tricked into granting access to any resource that they did not intend to grant.

Regardless of whether they click “no” or “yes,” the browser is redirected back to the app’s callback URI with different query parameters depending on the user’s decision. If they click “no,” the app is not granted access. The redirect URI may be something like “https://yelp.com/callback?error=access_denied&error_description=Theuserdidnotconsent.” If they click “yes,” the app can request the user’s granted resources from a Google API such as the Google Contacts API. The authorization server redirects to the redirect URI with the authorization code. The redirect URI may be something like https://yelp.com/callback?code=3mPDQbnIOyseerTTKPV&state=foobar,wherethequeryparameter “code” is the authorization code.

#### 3. reQuest access token

The client sends a POST request to the authorization server to exchange the authorization code for an access token, which includes the client’s secret key (that only the client and authorization server know). Example:


POST www.googleapis.com/oauth2/v4/token Content-Type: application/x-www-form-urlencoded code=3mPDQbnIOyseerTTKPV&client_id=yelp&client_secret=secret123&grant_ type=authorization_code

The authorization server validates the code and then responds with the access token, and the state that it received from the client.

#### 4. reQuest resources

To prevent CSRF attacks, the client verifies that the state it sent to the server is identical to the state in the response. Next, the client uses the access token to request the authorized resources from the resource server. The access token allows the client to access only the requested scope (e.g., read-only access to the user’s Google contacts). Requests for other resources outside the scope or in other scopes will be denied (e.g., deleting contacts or accessing the user’s location history):

ET api.google.com/some/endpoint Authorization: Bearer h9pyFgK62w1QZDox0d0WZg

#### _B.5.3 Back channel and front channel_

Why do we get an authorization code and then exchange it for the access token? Why don’t we just use the authorization code, or just get the access token immediately?

We introduce the concepts of a back channel and a front channel, which are network security terminology.

_Front-channel communication_ is communication between two or more parties that are observable within the protocol. _Back-channel communication_ is communication that is not observable to at least one of the parties within the protocol. This makes back channel more secure than front channel.

An example of a back channel or highly secure channel is a SSL-encrypted HTTP request from the client’s server to a Google API server. An example of a front channel is a user’s browser. A browser is secure but has some loopholes or places where data may leak from the browser. If you have a secret password or key in your web application and put it in the HTML or JavaScript of a web app, this secret is visible to someone who views the page source. The hacker can also open the network console or Chrome Developer Tools and see and modify the JavaScript. A browser is considered to be a front channel because we do not have complete trust in it, but we have complete trust in the code that is running on our backend servers.

Consider a situation where the client is going over to the authorization server. This is happening in the front channel. The full-page redirects, outgoing requests, redirect to the authorization server, and content of the request to the authorization server are all being passed through the browser. The authorization code is also transmitted through the browser (i.e., the front channel). If this authorization code was intercepted, for example, by a malicious toolbar or a mechanism that can log the browser requests, the hacker cannot obtain the access code because the token exchange happens on the back channel.

 appendix b _**OAuth 2.0 authorization and OpenID Connect authentication**_

The token exchange happens between the backend and the authorization channel, not the browser. The backend also includes its secret key in the token exchange, which the hacker does not know. If the transmission of this secret key is via the browser, the hacker can steal it, so the transmission happens via the back channel.

The OAuth 2.0 flow is designed to take advantage of the best characteristics of the front channel and back channel to ensure it is highly secure. The front channel is used to interact with the user. The browser presents the user the login screen and consent screen because it is meant to interact directly with the user and present these screens. We cannot completely trust the browser with secret keys, so the last step of the flow (i.e., the exchange, happens on the back channel, which is a system we trust).

The authorization server may also issue a refresh token to allow a client to obtain a new access token if the access token is expired, without interacting with the user. This is outside the scope of this book.

#### _B.6_

#### _Other OAuth 2.0 flows_

We described the authorization code flow, which involves both back channel and front channel. The other flows are the implicit flow (front channel only), resource owner password credentials (back channel only), and client credentials (back channel only).

An implicit flow is the only way to use OAuth 2.0 if our app does not have a backend. Figure B.3 illustrates an example of implicit flow. All communications are front channel only. The authorization server returns the access code directly, with no authorization code and no exchange step.


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0442-09.png)




Figure B.3    Illustration of an OAuth2 implicit flow. All communications are front channel. Note that the request to the authorization server has response type “token” instead of “code.”


Implicit flow carries a security tradeoff because the access token is exposed to the browser.

The resource owner password flow or resource owner password credentials flow is used for older applications and is not recommended for new applications. The backend server uses its credentials to request the authorization server for an access token. The client credentials flow is sometimes used when you’re doing a machine-to-machine or service communications.

#### _B.7 OpenID Connect authentication_

The Login with Facebook button was introduced in 2009, followed by the Login with Google button and similar buttons by many other companies like Twitter, Microsoft, and LinkedIn. One could login to a site with your existing credentials with Facebook, Google, or other social media. These buttons became ubiquitous across the web. The buttons served the login use cases well and were built with OAuth 2.0 even though OAuth 2.0 was not designed to be used for authentication. Essentially, OAuth 2.0 was being used for its purpose beyond delegated authorization.

However, using OAuth for authentication is bad practice because there is no way of getting user information in OAuth. If you log in to an app with OAuth 2.0, there is no way for that app to know who just logged in or other information like your email address and name. OAuth 2.0 is designed for permissions scopes. All it does is verify that your access token is scoped to a particular resource set. It doesn’t verify who you are.

When the various companies built their social login buttons, using OAuth under the hood, they all had to add custom hacks on top of OAuth to allow clients to get the user’s information. If you read about these various implementations, keep in mind that they are different and not interoperable.

To address this lack of standardization, OpenID Connect was created as a standard for adopting OAuth 2.0 for authentication. OpenID Connect is a thin layer on top of OAuth 2.0 that allows it to be used for authentication. OpenID Connect adds the following to OAuth 2.0:

- _ID token_ —The ID token represents the user’s ID and has some user information. This token is returned by the authorization server during token exchange.

- _User info endpoint_ —If the client wants more information than contained in the ID token returned by the authorization server, the client can request more user information from the user info endpoint.

- _Standard set of scopes._

So, the only technical difference between OAuth 2.0 and OpenID Connect is that OpenID Connect returns both an access code and ID token, and OpenID Connect provides a user info endpoint. A client can request the authorization server for an OpenID scope in addition to its desired OAuth 2.0 scopes and obtain both an access code and ID token.

 appendix b _**OAuth 2.0 authorization and OpenID Connect authentication**_

Table B.1 summarizes the use cases of OAuth 2.0 (authorization) vs. OpenID Connect (authentication).

Table B.1    Use cases of OAuth 2.0 (authorization) vs. OpenID Connect (authentication)

|OAuth2 (authorization)|OpenID Connect (authentication)|
|---|---|
|Grant access to your API.<br>Get access to user data in other systems.|User login<br>Make your accounts available in other systems.|


An ID token consists of three parts:

- _Header_ —Contains several fields, such as the algorithm used to encode the signature.

- _Claims_ —The ID token body/payload. The client decodes the claims to obtain the user information.

- _Signature_ —The client can use the signature to verify that the ID token has not been changed. That is, the signature can be independently verified by the client application without having to contact the authorization server.

The client can also use the access token to request the authorization server’s user info endpoint for more information about the user, such as the user’s profile picture. Table B.2 describes which grant type to use for your use case.

Table B.2    Which grant type to use for your use case


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0444-11.png)




|Web application with server backend|Authorization code fow|
|---|---|
|Native mobile app|Authorization code fow with PKCE|
|JavaScript Single-Page App (SPA) with<br>API backend<br>Microservices and APIs|(Proof Key for Code Exchange) (outside<br>the scope of this book)<br>Implicit fow<br>Client credentials fow|


## _C4 Model_ ~~_C_~~

The C4 model (https://c4model.com/)isasystemarchitecturediagram technique created by Simon Brown to decompose a system into various levels of abstraction. This section is a brief introduction to the C4 model. The website has good introductions and in-depth coverage of the C4 model, so we will only briefly go over the C4 model here; readers should refer to the website for more details. The C4 model defines four levels of abstraction.

A _context diagram_ represents the system as a single box, surrounded by its users and other systems that it interacts with. Figure C.1 is an example context diagram of a new internet banking system that we wish to design on top of our existing mainframe banking system. Its users will be our personal banking customers, who will use our internet banking system via UI apps we develop for them. Our internet banking system will also use our existing email system. In figure C.1, we draw our users and systems as boxes and connect them with arrows to represent the requests between them.

 appendix c _**C4 Model**_


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0446-02.png)




Gets account information from, and makes payments using

Figure C.1    A context diagram. Image from https://c4model.com/,licensedunderhttps://creativecommons.org/licenses/by/4.0/.Inthiscase,wewantto design an internet banking system. Its users are our personal banking customers, who are people using our internet banking system via the latter’s UI apps. Our internet banking system makes requests to our legacy mainframe banking system. It also uses our existing email system to email our users. Many of the other shared services it may use are not available yet, and may be discussed as part of this design.

A _container diagram_ is defined on c4model.com as “a separately runnable/deployable unit that executes code or stores data.” We can also understand containers as the services that make up our system. Figure C.2 is an example container diagram. We break up our internet banking system that we represented as a single box in figure C.1.

A web/browser user can download our single-page (browser) app from our web application service and then make further requests through this single-page app. A mobile user can download our mobile app from an app store and make all requests through this app.

Our browser and mobile apps make requests to our (backend) API application/service. Our backend service makes requests to its Oracle SQL database, mainframe banking system, and our email system.

A _component diagram_ is a collection of classes behind an interface to implement a functionality. Components are not separately deployable units. Figure 6.3 is an example component diagram of our (backend) API application/service from figure 6.2, illustrating its interfaces and classes, and their requests with other services.

Our browser and mobile apps make requests to our backend, which are routed to the appropriate interfaces:


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0447-01.png)




Figure C.2     A container diagram. Adapted from https://c4model.com/,licensedunderhttps://creativecommons.org/licenses/by/4.0/.Oursign-incontrollerreceivessignin requests. Our reset password controller receives password reset requests. Our security component has functions to process these security-related functionalities from the sign-in controller and reset password controller. It persists data to an Oracle SQL database.

 appendix c _**C4 Model**_

Our email component is a client that makes requests to our email system. Our reset password controller uses our email component to send password reset emails to our users.

Our account summary controller provides users with their bank account balance summaries. To obtain this information, it calls functions in our mainframe banking system façade, which in turn makes requests to our mainframe banking system. There may also be other components in our backend service, not illustrated in figure C.3, which use our mainframe banking system façade to make requests to our mainframe banking system.


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0448-04.png)




Figure C.3    A component diagram. Image adapted from https://c4model.com/,licensedunderhttps://creativecommons.org/licenses/by/4.0/.A_codediagram_isa UML class diagram. (Refer to other sources such as https://www.uml.org/ifyouareunfamiliarwith UML.) You may use object-oriented programming (OOP) design patterns in designing an interface.

Figure C.4 is an example code diagram of our mainframe banking system façade from figure C.3. Employing the façade pattern, our `MainframeBankingSystem Facade` interface is implemented in our `MainframeBankingSystemFacadeImpl` class. We employ the factory pattern, where a `MainframeBankingSystemFacadeImpl` object creates a `GetBalanceRequest` object. We may use the template method pattern to define an `AbstractRequest` interface and `GetBalanceRequest` class, define an `Internet BankingSystemException` interface and a `MainframeBankingSystemException` class, and define an `AbstractResponse` interface and `GetBalanceResponse` class. A `MainframeBankingSystemFacadeImpl` object may use a `BankingSystemConnection` connection pool to connect and make requests to our mainframe banking system _and throw_ a `MainframeBankingSystemException` object when it encounters an error. (We didn’t illustrate dependency injection in figure C.4.)


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0449-03.png)




Figure C.4    A code (UML class) diagram. Image adapted from https://c4model.com/,licensedunderhttps://creativecommons.org/licenses/by/4.0/.Diagramsdrawnduringanintervieworin a system’s documentation tend not to contain only components of a specific level, but rather usually mix components of levels 1–3.

The value of the C4 model is not about following this framework to the letter, but rather about recognizing its levels of abstraction and fluently zooming in and out of a system design.


## _Two-phase commit (2PC)_ ~~_D_~~

We discuss two-phase commit (2PC) here as a possible distributed transactions technique, but emphasize that it is unsuitable for distributed services. If we discuss distributed transactions during an interview, we can briefly discuss 2PC as a possibility and also discuss why it should not be used for services. This section will cover this material.

Figure D.1 illustrates a successful 2PC execution. 2PC consists of two phases (hence its name), the prepare phase and the commit phase. The coordinator first sends a prepare request to every database. (We refer to the recipients as databases, but they may also be services or other types of systems.) If every database responds successfully, the coordinator then sends a commit request to every database. If any database does not respond or responds with an error, the coordinator sends an abort request to every database.


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0451-01.png)


Figure D.1    A successful 2PC execution. This figure illustrates two databases, but the same phases apply to any number of databases. Figure adapted from _Designing Data-Intensive Applications_ by Martin Kleppmann, 2017, O’Reilly Media.

2PC achieves consistency with a performance tradeoff from the blocking requirements. A weakness of 2PC is that the coordinator must be available throughout the process, or inconsistency may result. Figure D.2 illustrates that a coordinator crash during the commit phase may cause inconsistency, as certain databases will commit, but the rest will abort. Moreover, coordinator unavailability completely prevents any database writes from occurring.

 appendix d _**Two-phase commit (2PC)**_


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0452-02.png)


Figure D.2    A coordinator crash during the commit phase will cause inconsistency. Figure adapted from _Designing Data-Intensive Applications_ by Martin Kleppmann, O’Reilly Media, 2017.

Inconsistency can be avoided by participating databases neither committing nor aborting transactions until their outcome is explicitly decided. This has the downside that those transactions may hold locks and block other transactions for a long time until the coordinator comes back.

2PC requires all databases to implement a common API to interact with the coordinator. The standard is called X/Open XA (eXtended Architecture), which is a C API that has bindings in other languages too.

2PC is generally unsuitable for services, for reasons including the following:

- The coordinator must log all transactions, so during a crash recovery it can compare its log to the databases to decide on synchronization. This imposes additional storage requirements.

- Moreover, this is unsuitable for stateless services, which may interact via HTTP, which is a stateless protocol.


- All databases must respond for a commit to occur (i.e., the commit does not occur if any database is unavailable). There is no graceful degradation. Overall, there is lower scalability, performance, and fault-tolerance.

- Crash recovery and synchronization must be done manually because the write is committed to certain databases but not others.

- The cost of development and maintenance of 2PC in every service/database involved. The protocol details, development, configuration, and deployment must be coordinated across all the teams involved in this effort.

- Many modern technologies do not support 2PC. Examples include NoSQL databases, like Cassandra and MongoDB, and message brokers, like Kafka and RabbitMQ.

- 2PC reduces availability, as all participating services must be available for commits. Other distributed transaction techniques, such as Saga, do not have this requirement.

Table D.1 briefly compares 2PC with Saga. We should avoid 2PC and prefer other techniques like Saga, Transaction Supervisor, Change Data Capture, or checkpointing for distributed transactions involving services.

Table D.1    2PC vs. Saga


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0453-08.png)




|2PC|Saga|
|---|---|
|||
|XA is an open standard, but an<br>implementation may be tied to<br>a particular platform/vendor,<br>which may cause lock-in.<br>Typically for immediate<br>transactions.<br>Requires a transaction to be<br>committed in a single process.|Universal. Typically implemented<br>by producing and consuming<br>messages to Kafka topics. (Refer<br>to chapter 5.)<br>Typically for long-running<br>transactions.<br>A transaction can be split into<br>multiple steps.|


#### _index_

#### Symbols

2PC (two-phase commit) 110 consistency 419 disadvantages 420 vs. Saga 421 4xx errors 69 5xx errors 35, 36 400 Bad Request 225 409 Conflict 225 422 Unprocessable Entity 225 429 Too Many Requests

#### A absolute timeout 404 A/B testing 12, 167 access token CDN authentication and authorization 292 OAuth 2.0 407 accuracy as data quality dimension 223 autocomplete 250 batch auditing service 233 defined 70 eventually consistent systems and 71 rate limiting 176 ACID consistency 66 additional complexity, disadvantages of using CDN 289 aggregating events 88 form of 379 aggregation by combination of product ID and timestamp 386 large key space 91 multi-tier 89, 385 on sales events, optimizing Lambda architecture 378 overview 88 partitioning 90 replication and fault-tolerance 92 single-tier 89 aggregation host 380 aggregation operations desired accuracy and consistency 375 determining requirements 375 EDA (Event Driven Architecture) 378 high accuracy 375 large-scale 374– 394 low latency 375 multi-tier horizontal scaling and approximate large-scale 385 trading off accuracy for higher scalability and lower cost 375 aggregation service aggregating by product ID 379 aggregation process on hosts 380 Lambda architecture 378 matching host IDs and product IDs

 index storing timestamps 380 Airbnb, example of system design 329–353 and high-level architecture 335 and nature of system to be designed 330 approval service 339 as reservation and marketplace app 330 availability service 349 booking service 345 customer support and operations 330 design decisions 333 functional partitioning 337 listing creating or updating 337 requirements functional 331 guest’s use cases 331 host’s use cases 330 non-functional 333 operations’ use cases 331 payments solution 331 possible functional 332 system design interview and additional discussion points on 351 alerting service. _See_ notification service alerts defined 35 failed audits and 235 responding to 36 Allowed countries or regions, field 292 Allowed IPs field 292 all-to-all, synchronizing counts 185 _Amazon Web Services in Action_ (Wittig and Wittig) 11 analytics and Top K Problem 375 as topic in system design interviews 374 as typical requirement 27 Craigslist design 166 notification service 200 Angular, browser web framework 130 anomaly detection 39, 163 data quality validation 224 _Apache Hive Essentials_ (Du) 238 API endpoints common 28 reservation system design 333 API gateway additional latency 15, 125 and CDN 294 centralization of cross-cutting concerns 14, 123 disadvantages of architecture with error-checking 124 examples of cloud-provided 123 functionalities 123 large cluster of hosts 125 logging and analytics 124 overview 14 performance and availability 124 security 123 API paradigms, common GraphQL 141 OSI (open systems interconnection) model 137 overview 137 REST 138 caching 139 disadvantages 140 hypermedia 138 RPC (Remote Procedure Call) described 140 main advantages 140 main disadvantages 141 WebSocket 142 API specification common API endpoints 28 drafting 28 application-controlled cookies 58 application-level logging tools 37–39 app manifests 133 approval service 339–344 approximation count-min sketch 388 lower latency and 386 trading off accuracy for faster updates and lower cost 386 A record 8 auditing arguments against 225 database tables 39 importance of 224 authentication 123 defined 403 simple login 404 authentication protocol 28 authentication service, CDN authentication and authorization 292 authorization 123 defined 403 OAuth 2.0 and initial client setup 407 autocomplete and search history consideration index as conceptually simpler than search 247 content moderation and fairness 250 data source for suggestions 249 differences between search and 247 example of initial high-level architecture 251 general search 246 handling phrases instead of single words 263 handling storage requirements 261 implementation database technologies for search log 254 fetching relevant logs from Elasticsearch to HDFS 255 filtering for appropriate words 259 filtering out inappropriate words 256 fuzzy matching and spelling correction 258 generating and delivering weighted trie 259 managing new popular unknown words 259 splitting search strings into words 255 steps as independent tasks 255 weighted trie generator 253 word count 259 word count pipeline 253, 254 limiting suggestions 249 maximum length of suggestions 263 possible uses of 246 preventing inappropriate suggestions 263 retrieving autocomplete suggestions 252 sampling approach 260 scope of autocomplete service 248 shared logging service 252 similarities with search 246 spelling suggestion service 264 user experience details 248 weighted trie and generating autocomplete suggestions 252 described 252 example of 253 availability and designing text messaging app 309 asynchronous communication techniques 59 autocomplete and high 250 batch auditing service 233 caching and 99 caching service 60 CDN and high 291 common benchmarks 59 defined 59 high 59 advantages of using CDN 288 and image sharing service 268 notification service 200 new functional requirements 47 rate limiting 176 synchronous communication protocols 59 availability monitoring 295 availability service 349 AWS App Mesh 126 AWS Lambda 22 Azure Functions

#### B back-channel communication 409 backend service 7, 133 scaling 23 bandwidth 55 basic authentication 404 batch and streaming ETL 29, 39 batch vs. streaming 93 common batch tools 93 common streaming tools 93 differences between Kafka and RabbitMQ 96 Kappa architecture 98 Lambda architecture 98 messaging terminology 95 overview 93–98 simple batch ETL pipeline 93 batch auditing and duplicate or missing data 226 auditing data pipeline 241 audit service 230 Python file template for 231 common practical use 226 example of simple audit script 229 high-level architecture handling alerts 235 logging and monitoring 235, 236 with manually defined validation 224 batch auditing job periodically run 234 running 234 steps after submitted request, example 234 storing results of each 235 the simplest form of 229 batch auditing service audit jobs 232 constraints on database queries 237 checking query strings before submission 238 instructions provided to users

 index limiting query execution time 238 example of initial high-level architecture 233 functional requirements 232 logging, monitoring, and alerting 242 non-functional requirements 233 preventing too many simultaneous queries 239 batch ETL job 234, 303 batch jobs disadvantages 391 failures 391 batch pipelines 377, 378 batch_table 377 illustration of ETL DAG for one rollup job 382 overview 381 Beego, full-stack framework 134 BitTorrent, full mesh used by 67 blocking/unblocking, connection service and allowing immediate 313 block storage 78 booking service 345–348 broadcast hash join 257 broadcasting 185 Brotli 6 Brown, Simon 413 brute force attack 172 bulkheads

C

C4 model 29, 413–417 four levels of abstraction 413 cache busting 104 Cache-Control header 139 cache invalidation 104, 108 browser cache invalidation 105 cache replacement policies, common resources 105 fingerprinting 105 in caching services 105 cache staleness, write strategies and minimizing 101 cache warming 106, 108 caching 350, 353 API gateway 124 as separate service 103 benefits of 99 cache-aside advantages 101 described 100 disadvantages 101 Craigslist 159 frontend service 205 lazy load 100 microservices 399 private cache 103 public cache 103 read strategies 100 read-through 101 REST resources and 139 write-around 102 write-back/write-behind 102 write strategies 101 write through 102 callback, OAuth 2.0 407 CAP theorem consistency 66 high availability and 59 Cassandra and leaderless replication 85 gossip protocol and consistency 70 CCPA (California Consumer Privacy Act) 73, 405 CDC (Change Data Capture) 110, 342, 357 and transaction log tailing pattern 113 defined 112 differences between event sourcing and 113 illustration of 112 transaction log miners 113 CD (continuous deployment) 11 complexity and maintainability 72 feedback cycles 12 CDN (Content Distribution Network) 287, 307–308 adding to service 9 advantages of using 288 and file storage service 276 as geographically distributed file storage 287, 307 authentication and authorization key rotation 294 overview 291 sequence diagram of token generation process 293 steps in 292 benefits of using 10 cache invalidation 306 CdnPath value template 271 common operations 297 defined 287 described 9, 307 disadvantages of using 289 downloading image files directly from 269 example of unexpected problem from using 290 generating access token index latency of uploading image files to 269 organizing directories and files on 271 popular CDNs 10 possible high unit costs for low traffic 289 possible security concerns 289 POST request 272 reads (downloads) 295 described 297 download process 297 download process with encryption at rest 299 retention period 270 storage service 295–296 storing dynamic content on SQL rather than on CDN 282 writes (directory creation, file upload, and file deletion) 295, 301 writing directly to 278 CDNService 287 CDN URL 292 checkpointing 110, 380, 394 fault-tolerance 62 CI/CD (continuous integration/continuous deployment) 11 claims, ID token 412 client, OAuth 2.0 407 client-side components 7 clock skew 84 Clojure, web development language 131 _Cloud Native: Using Containers, Functions, and Data to build Next-Generation Applications_ (Scholl et al.) 35 cloud native, defined 75 _Cloud Native DevOps with Kubernetes_ (Arundel and Domingus) 34 _Cloud Native Patterns_ (Davis) 100, 111 cloud providers “auto-scaling” services 20 services provided by 19 Terraform 11 vendor lock-in 21 cloud services 23, 165 and cost advantages 20 and simplicity of setup 19 benefits of using 19 disadvantages 21 support and quality 20 upgrades 21 cluster management 10 code diagram, C4 model 417 CoffeScript, web development language 131 cold start compensable transactions 279, 305 completeness, as data quality dimension 223 complexity continuous deployment (CD) 72 minimizing 71 rate limiting 175 component diagram, C4 model example of 416 overview 415 concurrent updates, preventing 31 configuration locking, preventing concurrent updates 31 illustration of locking mechanism that uses SQL 33 connection draining 155 connection service 311 endpoints that should be provided by 312 inconsistency, possible solutions 314 making connections 312 sender blocking 312 hacking app 313 possible consistency problems 313 public keys 315 consensus 110 consistency 55, 76. _See also_ linearizability; data consistency 2PC (two-phase commit) 419 and designing text messaging app 309 as data quality dimension 223 autocomplete 250 coordination service 68 different meanings of 66 distributed cache 69 full mesh 67 gossip protocol 70 linearizability 67 random leader selection 70 rate limiting 176 read-after-write consistency 84 storage services and strong 78 techniques for eventual 66 constraints, introduced near the end of the interview 46 container diagram, C4 model 414 content moderation 284, 291 context diagram, C4 model 413 control plane 126 cookie-based authentication 291, 404 Cordova, cross-platform framework 133 cost 47, index advantages of using CDN 288 in system design discussions 72 of system decommission 73 trading off other non-functional requirements for lower 72 count-min sketch 71, 394 as approximation algorithm 388 CQRS (Command Query Responsibility Segregation) 43 data processing 251 described 17 Redis as example of 357 Craigslist design and initial high-level architecture 150, 151 and monolith architecture 151 and typical web application that may have over billion users 147 API 149 caching 159 CDN 160 complexity 164 Craigslist architecture 163 Craigslist as read-heavy application 160 distinguishing primary user types 148 email service 161 functional partitioning 158 homepage 152 migrations 153–156 monitoring and alerting 163 removing old posts 162 scaling reads with SQL cluster 160 scaling write throughput 160 search 162 SQL database and object store 153 SQL database schema 150 user stories and requirements 148 writing and reading posts 156 cross-cutting concerns, centralization of 14, 123 CSS img tag 268 customization capabilities, insufficient, disadvantages of using CDN 290

#### D

Dart, full-stack framework 134 dashboard as instrument of monitoring and alerting 35 combining data from speed_table and batch_ table 377, 378 defined

Kappa architecture 392 OS metrics that can be included in 35 Top K Problem (Heavy Hitters) as common type of 374 with Lambda architecture 390 data accuracy 70 and Change Data Capture (CDC) 112 and migration from one data store to another 153 and reducing costs of storing old 38 anomaly detection and 39 consistency, common informal understanding of 84 cross data center consistency audits 242 data freshness 240 designing data model 29–34 discussing accessibility of 27 encryption at rest 73 event sourcing 111 examples of caching different kinds of 103 illustrating connections between users and 28 inconsistency 109 transaction log tailing pattern and preventing 113 invalid data and service response 225 Kappa architecture and processing large data streams 390 Lambda architecture and processing large data streams 390 notification service 197 Personally Identifiable Information (PII) 73 preventing data loss 224 rate limiter request 177 removing old posts 162 sampling 88 streaming tools and continuously processing 18 upstream and downstream data comparison 243 writing to multiple services 109 database batch auditing service design 223, 244–245, 266 database constraints 225 database queries and requirements for periodic batch audits 232 constraints on 237 checking query strings before submission 238 instructions provided to users 239 limiting query execution time 238 running several and comparing results 229 databases aggregated events 88 batch and streaming ETL 93 choosing between filesystems and 79, index column-oriented 78 consistency 84 denormalization 98 eventually consistent 66 example of disadvantages of multiple services sharing 30 key-value 78 manually entered strings 83 MapReduce database 98 NoSQL 78 scaling 77, 108–109, 122 replication 79 storage services 77 useful resources on 107 schemaless 43 sharded, and scaling storage capacity 87 shared, common problems that may occur with 29 SQL 78 that favor availability vs. linearizability 66 various database solutions 98 when to use and when to avoid 79 database schema metadata 240 database services as shared services 237 provided by third-party providers 237 Databus, CDC platform 113 data centers Airbnb and design decisions 333 and listings grouped by geography 337 and minimizing read latency 334 data consistency 109 data ingestion 251 DataNodes, HDFS replication 85 data plane 126 data privacy laws 352 data processing 251 data quality described 223 different dimensions of 223 many definitions of 223 streaming and batch audit of 39 two approaches in validating 224 DDoS (distributed denial-of-service) 172 dead letter queue 62, 110 Debezium, CDC platform 113 declarative data fetching 141 delegated authorization 404 Deno 131 denormalization 98 dependencies, minimizing deployments blue/green 72 rolling back manually or automatically 11 design decisions, in reservation system example and handling overlapping bookings 335 and randomizing search results 335 data models for room availability 334 locking rooms during booking flow 335 replication 334 _Designing Data-Intensive Applications_ (Kleppmann) 68, 341 _Distributed Systems: Concepts and Design_ (Coulouris, Dollimore, Kindberg, and Blair) 341 distributed transaction 109, 121–122 algorithms for maintaining consistency 110 described 110 useful resources on 120 DML (Data Manipulation Language) queries 84 DNS lookup, additional, disadvantages of using CDN and 289 Docker 11 document 78 documentation, external-facing vs. internal-facing 20 DoS (denial-of-service) 172 Dropwizard, backend development framework 134 DSL (domain-specific language) 11 durability, CDN and 291 duration-based cookies 58 dynamic content, downloading images and data 282 DynamoDB, and handling requests 179 DynamoDB Streams, CDC platform

#### E

ECC (error connection code) 61 EDA (Event Driven Architecture) 378 alternative to 110 defined 110 non-blocking philosophy of 111 rate limiting 111 edge cases, as topic in system design interview 46 Elasticsearch 13 and common techniques of search implementation 41 and fetching relevant logs 255 and search bar implementation 41 booking service 347 described 37 useful resources on 44 using in place of SQL 43 Elasticsearch index, creating on photo metadata index

Elasticsearch SQL 43 Elastic Stack 14 Electron, cross-platform framework 133 ELK service 37 Elm, web development language 131 encoding formats 140 encryption at rest 299 end-to-end encryption 320 message service and 320 engineers and considering cost of engineering labor vs. cloud tools 19 and system design interviews 4 challenging work preferred by 19 good verbal communication 5 SRE (Site Reliability Engineering) team 37 EQL (Elasticsearch query language) 43 errors auditing and silent 40 monitoring and 35 ETag value 139 ETL (Extract, Transform, Load) 17, 93 event sourcing and adding complexity to system design 112 and changing business logic 112 defined 111 differences between Change Data Capture (CDC) and 113 illustration of 111 Eventuate CDC Service, CDC platform 113 exactly-once delivery 308 excessive clients, rate limiting and 171 experimentation 27 and delivering personalized user experience 12 common approaches 12 purpose of 12 vs. gradual rollouts and rollbacks 12 Expires HTTP header 139 expiry, CDN authentication and authorization 292 Express, Node.js server framework 131 external services 20 external storage/coordination service

#### F

FaaS (Function as a Service) described 22 platform 234 portability 22 fault-tolerance and caching responses of other services 62 and illustrating connections between users and data 29 as system characteristic 60 bulkhead described 63 examples of 63 checkpointing 62 circuit breaker 61 implementation on server side 61 dead letter queue 62 defined 60 error correction code (ECC) 61 exponential backoff and retry 62 failure design 60 fallback pattern 64 forward error correction (FEC) 61 logging and periodic auditing 63 microservices 397 new functional requirements 47 notification service 200 rate limiting 176 redundancy 60 replication 60 single host limitations 79 FEC (forward error correction) 61 FIFO (first in first out) 106 files and contents separated into multiple 303 copied to particular data centers 303 multipart upload 302 periodic batch job and distributing files across data centers 303 file storage 78 file storage service 269, 276 fixed window counter 190 sequence diagram of 192 Flask, backend development framework 134 Flickr design 266–286 Flink, streaming tool 18, 93 Flutter, cross-platform framework 132 forms authentication 404 FOSS (free and open-source software) monitoring tools 37 frameworks backend development 133 browser app development 130 client-side 130 cross-platform development index full-stack 133 functional partitioning and various 128 mobile app development 132 server-side 131 web and mobile frameworks 130 fraud detection 19 front-channel communication 409 frontend service 7 full mesh topology 185 functional partitioning 79 Airbnb 337 and centralization of cross-cutting concerns 13 and various frameworks 128 basic sistem design of application 128 purposes of web server app 129 web and mobile frameworks 130 common functionalities of various services 123 common services for 122– 143 Craigslist design 158 example of adding shared services 14 metadata service 126 popular browser app frameworks, client-side 130 popular browser app frameworks, server-side 131, 132 service discovery 127 service mesh 125 fuzzy matching 246 algorithm

#### G

GCP (Google Cloud Platform) Traffic Director 17 GDPR (General Data Protection Regulation) 73, 405 GeoDNS 297 Craigslist design 159 system scaling 7 geolocation routing 158 GET request 276 Gin, full-stack framework 134 Goji, Golang framework 131 gossip protocol 70, 185 graceful degradation 164, 264, 313 Grafana 38 graph 78 Graphite, logging OS metrics 38 GraphQL 141 and functional partitioning 130 gRPC, backend development framework

#### H hard delete 305 HDFS (Hadoop Distributed File System) 61, 86 INSERT command 86 header, ID token 412 health, API endpoints 28 height attribute, displaying thumbnails 268 high-level architecture and designing news feed system 356 serving images 369 and designing text messaging app 310 illustration of 311 approval service 339 autocomplete 251 availability service 349 batch auditing 233 booking service 345 CDN (Content Distribution Network) 294 illustration of 295 Craigslist design 150 for designing reservation system 335 image sharing service 269 large-scale aggregation operations 377 message sending service 317, 322 notification service and example of 202 notification service and initial 200 rate limiting 177 reducing storage requirement 182 Rules service users 178 sender service 316 with Kappa architecture 392 words service 256 HIPAA (Health Insurance Portability and Accountability Act) 405 HiveQL 229 Hive, using with HDFS 254 horizontal scaling 56 host assigner service 324 host logging 36 hosts leader host 186 traffic spike and adding new 172 hotlinking 291 hypermedia 138 Hystrix

#### I

IaC (Infrastructure as Code) 11, index

IDE (integrated development environment), autocomplete and 246 idempotency 10, 338 ID token elements of 412 OpenID Connect authentication 411 image files downloading directly from CDN 269 latency of uploading image files to CDN 269 image sharing service additional discussion topics 284 advertising 284 and non-functional requirements 267 censorship/content moderation 283 downloading images and data 282 Flickr 266 monitoring and alerting 283 organizing directories and files on CDN 271 payments and taxes services 283 personalization 284 photos 267 premium features 283 sharer 267 SQL CREATE statement 270 uploading photos 272 viewer 267 image uploads, backend in 157 inactivity timeout 404 inappropriate content, filtering 264 inappropriate words, filtering out 257 incident metrics 60 increased network traffic to devices, message sending service 321 InfluxDB 38 ingestion service, news feed, highly available 356 ingestion system 251 Integrated Haskell Platform, full-stack framework 134 interservice requests 126 interviewer and key principles of system design interview 24 how interviews begin 3 user stories, discussing with 267 intraservice requests 126 Ionic, cross-platform framework 132 ISP (Internet Service Provider) 8 Istio 16 as popular service mesh implementation 122 item categories/tags

J

Jaeger, distributed tracing system 14 JavaFX, full-stack framework 134 JOIN query

#### K

Kafka as message broker 161 as streaming tool 93 batch jobs 18 checkpointing 62 dead letter queue 63 differences between RabbitMQ and 96 ingestor and 358 Kappa architecture and processing large data streams 390 as alternative to Lambda architecture 374 batch and streaming ETL 98 batch jobs 391 described 390 for Top K dashboard 392 storing large volumes of data in event-streaming platforms 392 vs. Lambda architecture 391–392 Kibana 37 Knative, open-source FaaS solution 22 Kubernetes

#### L

Lambda architecture 264 aggregation service and initial optimization of 378 and handling massive quantities of data 377 and processing large data streams 390 batch and streaming ETL 98 data processing pipelines 377 fast approximate results 377 high-level sketch of 377 slow accurate results 377 vs. Kappa architecture 391–392 Lamport clock 341 large-scale systems, ability to design and review 4 latency API gateway and additional 15 CDN and improved 10 defined 65 design decisions for achieving low 65 geographically closest data centers and lowest index increased, and rolling back deployments manually or automatically 11 lower 80 advantages of using CDN 288 monitoring and 35 new build and possible increase of 12 new functional requirements 46 LDAP (Lightweight Directory Access Protocol) 73 leader host, deliberate loss of data 224 leaky bucket described 189 disadvantages of 190 libraries language specific vs. technology-agnostic 135 predictability of latency 136 rate limiting implemented as library 172 scaling considerations 136 vs. services 135 LIFO (last in first out) 106 linearizability 66, 67, 80 listing creating 337 obtaining appropriate listing regulations 337 load balancers 57 differences between level 4 and level 7 57 level 4 183 level 7 90, 173 limiting number of requests 173 load balancing vs. reverse proxy 58 session replication 58 sticky sessions 58, 78 useful resources on 59 LOAD DATA command 257 localStorage 87, 104 log compaction 392 log entries 53 general considerations in logging 35 logging and asynchronous data processing requests 18 general considerations 35 timestamps 35 logging, monitoring, and alerting Airbnb, example of system design 350 anomaly detection 39 application-level logging tools 37 autocomplete 264 batch auditing 242 CDN (Content Distribution Network) 306 detecting invalid datapoints importance of monitoring 34 key concepts that should be mentioned in system design interviews 34 news feed design 368 observability 34 rate limiting 193 responding to alerts 36 rollup jobs and unusually long run time or failures of tasks 393 shared batch ETL platform 393 silent errors and auditing 40 streaming and batch audit of data quality 39 text messaging app 326 logging service 14 “login with Facebook” button 411 “login with Google” button 411 low storage requirement 149 LRU (least recently used) 78,

M maintainability apps and staying in compliance with user privacy regulations 405 common services for improving 71 continuous deployment (CD) 72 maintenance 45 system design discussions and cost of 72 malicious attacks, rate limiting and 172, 173 manually defined validation auditing service as additional layer of validation 228 batch auditing as common requirement 224 data quality validation 224 defining on conditional statement on multiple queries 228 on individual datapoints of column 226 on multiple columns in single row 227 on multiple datapoints of column 227 on multiple tables 228 with conditional statement on SQL query's result 226 validation condition 224 map join 257 MapReduce programming model 86, 254 match-sorter 41 max-heaps and approximate large-scale aggregation operations 385 in separate hosts 387 with multi-tier, and faster but less accurate aggregation index media queries 133 Memtable 224 Mesos 11 message broker 161, 170 message consumer service 317 message sending service availability improvement 325 delivering message to multiple devices 321 failover procedure 322 high write and low read traffic 321 introduction 321 overview 320 possible questions during system design interview 325 steps in sending messages 324 undeliverable messages 320 metadata service comparison of in-cluster and out-cluster manager 296 described 126 ETL pipelines 126 illustration of 126 real-time syncing 303 tradeoff of using 127 metrics defined 35 usability metrics 45 microservices 402 disadvantages 398– 402 advantages 396 coordinating feature development and deployments that span multiple services 400 described 395 development and maintenance costs of additional components 399 distributed transactions 400 duplicate components 398 failure isolation 397 fault-tolerance 397 interfaces 401 modularity and replaceability 397 ownership and organizational structure 398 referential integrity 400 useful resources on 402 _Microservices for the Enterprise: Designing, Developing, and Deploying_ (Indrasiri and Siriwardena) 63 _Microservices Patterns With Examples in Java_ (Richardson) 113 migration, disadvantages of using CDN 289 mobile data plans moderation service and unifying moderation into single 360 ingestor and 358 monitoring four golden signals of 34 frontend service 205 importance of 34 instruments of 35 streaming and batch audit 36 monolith architecture 151 monoliths 402 advantages over microservices 396 data privacy regulations 396 debugging 396 described 395 disadvantages 395 useful resources on 402 multipart/form-data HTML encoding 302 multipart upload 302 MVP (minimum viable product) 268

N

Nagios, FOSS monitoring tool 38 NameNode, HDFS replication 85 native platforms 132 news feed, designing 354– 373 preparing feed in advance 360–364 additional discussion topics on 372 functional requirements 355 high-level architecture 356 ingestion service 356 logging, monitoring, and alerting 368 news feed service 357 non-functional requirements 356 serving images 368 tools of communication 368 validation and content moderation 364 moderation service 367 tagging posts 365 news feed service high-level architecture of 357 ingestor 357 moderation 360 user’s device and frequency of updating news items 357 news item 354 “noisy neighbor” problem 171 normalization benefits of index disadvantages 99 notebooks service 19 notification/alerting service design 196–221 notification service analytics 200 and handling failed deliveries 216 and possible features it can provide 196 auto-scaling 220 client-side considerations regarding duplicate notifications 218 functional requirements 196 Kafka cluster and scaling memory amount 220 managing recipient groups 199 managing subscribers 199 monitoring and alerting 219 notification addressee groups 212–215 notifications and trigger conditions 199 priority 218 recipient channels 198 scheduled notifications 210 search 219 suitable for wide range of users 196 templates 198 types of users 197 unsubscribe requests 215 uptime monitoring 197 user features 199 notification templates 207–210 access control 209 authoring 209 change management 209 notification template service 207 reusable and extendable template classes and functions 210 NPS (net promoter score) 45

#### O

OAuth 2.0 as common authorization algorithm 403 authentication and 411 back-channel communication 409 client credentials 410 front-channel communication 409 implicit flow 410 initial client setup 407 resource owner password credentials 410 terminology 407 OAuth 2.0 (authorization) vs. OpenID Connect (authentication), use cases of

OAuth 2.0 flow 406–410 overview 406 steps between Yelp and Google 406 object storage 79 observability and addressing possible silent failures 36 errors 36 importance of 165 overview 34–36 useful resources on 40 observability plane 126 opaque token 139 OpenFaaS 22 OpenID Connect authentication 28, 403, 411 OpenTSDB 38

#### P

P99 latency 24 PACELC theorem 75 partitioning 385 performance and designing text messaging app 309 autocomplete 250 caching and 99 CDN and high 291 image sharing service and high 268 notification service 200 rate limiting 175 performance/latency 65 Phoenix, full-stack framework 134 photos availability 268 controlling costs 268 predefined metadata fields 267 privacy settings 268 setting access control on 267 thumbnails, disadvantages of client-side generation 273 uploading 272 software release lifecycle 274 PHP 132 PII (Personally Identifiable Information) 35, 55, 199 privacy and 73 pipeline Directed Acyclic Graph (DAG) 93 fast 98 implementing aggregation 88 simple batch ETL pipeline 93 slow index streaming pipeline 88 pivot transaction 279, 305 point of failure, additional, disadvantages of using CDN and 289 poster, user type 148 POST request 272 posts large number of 169 on users’ devices, changing 365 post expiry 169 reporting 164 power consumption, message sending service 321 _Practical Monitoring_ (Julian) 37 privacy 73 autocomplete 250 CDN 291 frontend service 204 notification service 200 rate limiting 176 text messaging app 309 privacy compliance services 19 Prometheus as FOSS monitoring tool 38 described 39 PromQL (Prometheus query language) 39 protobuf 140 Protocol Buffers, backend development framework 133 PureScript 131 PWA (progressive web app) 133

#### Q

QPS (queries per second) 24 query system 251 quorum consistency, preventing data loss

#### R

Rails, full-stack framework 134 random leader selection 186 random replacement 106 rate limiter requests 175, 177 rate limiting 124, 169 and preventing inadvertent overuse 171 and preventing malicious attacks 172 and required service components 177 and storing all counts in every host 182 and user services 174 as separate service 173 autocomplete system 264 compared to its alternatives 173 comparing different approaches 184 described 171 example of initial high-level architecture of rate limiter 172, 178 frontend service 204 high-level architecture 177 implemented as separate service 172 logging, monitoring, and alerting 193 main input of rate limiter request 177 Rules service 172, 177 security and 73 service mesh and common shared service 126 sidecar pattern 193 stateful approach compared to stateless approach 182 example of backend of stateful solution 180 fault-tolerance 180 level 7 load balancer 180 tradeoff 181 stateless approach 179 subscriptions and 174 synchronizing counts 185 useful resources on 195 user stories 177 when not to do rate limiting 174 rate limiting algorithms 187–193, 195 rate limiting service alternatives to 172, 173 overview 171 providing functionality in client library 194 rate limiting service design 171, 195–196 RBAC (role-based access control) 199 React, browser web framework 130 React Native, cross-platform framework 132 Reason, web development language 131 redirect URI, OAuth 2.0 407 Redis 357, 359 as in-memory cache 69 Redis cache service 8 referential integrity 400 Referrer HTTP header 292 regulations listing and sequence diagram of obtaining appropriate 337 local 169 _Release It!: Design and Deploy Production-Ready Software_ (2nd Edition) (Nygard) 63 replication index defined 79 distributing replicas 80 HDFS replication 85 illustration of multi-level 82 leader-follower 61, 161 leaderless 84, 85 multi-leader approach 84, 303 reservation system design 334 single-leader approach 80, 303 main limitation of 82 with primary-secondary leader failover 81 useful resources on 87 replication factor, HDFS 61 request deduplication 124 request dispatching 124 request-level logging tools 36 requests to search service, duplicate, allowing 168 requests to search service, duplicate, avoiding 168 request validation 124 requirements and logging events 36 clarifying 26 functional analytics 27 and discussing details of some common 26 attention to detail 26 autocomplete 248 batch auditing service 232 brainstorming list of 26 CDN 291 discussing accessibility of data 27 for designing news feed system 355 for designing reservation system 331 for designing text messaging app 309 image sharing service 267 large-scale aggregation operations 375 new, edge cases 46 notification service 196 overall time for discussing 26 rate limiting service and 174 non-functional 54–76 accuracy 70 addressing via cloud native concepts 47 and discussing details of some common 27 autocomplete 250 availability 59 batch auditing service 233 CDN 291 cloud native 75 complexity 71 consistency 66 cost 72 defined 54 failing to clarify 55 fault-tolerance 60 for designing news feed system 356 for designing reservation system 333 for designing text messaging app 309 image sharing service 267 large-scale aggregation operations 375 latency 65 maintainability 71 notification service 200 primary user types 148 privacy 73 rate limiting service and 175 scalability 56 security 73 services 123 throughput 65 typical 54 useful resources on 75 non-technical, customer’s scalability requirements 56 scalability 27 ReScript, web development language 131 reservation system, example of system design and discussing API endpoints 333 and high-level architecture 335 design decisions 333 ResizeObserver 133 resource owner, OAuth 2.0 407 resource server, OAuth 2.0 407 resources, requesting, OAuth 2.0 and initial client setup 409 responsive web design 133 retriable transactions 279, 305 reverse proxy 58. _See also_ load balancers Rocket, Rust framework 131 rollbacks 11 vs. experimentation 12 rollouts, gradual 11 rollups batch pipeline 381 ETL DAG 383 RPC serialization frameworks, reducing complexity 71 Rules service 177 high consistency for users of index runbook, and responding to alerts 37,

#### S saga 110 and comparison between choreography and orchestration 119 choreography saga 276 described 115 illustration of 116 updating metadata service and storage service 304 described 115 important use case of 115 managing failures 115 orchestration saga described 117 illustration of 118 updating metadata service and storage service 305 orchestration saga approach 280 vs. 2PC (two-phase commit) 421 SAML (Security Assertion Markup Language) 404 sampling, autocomplete and 260 saturation, monitoring and 35 saveAsTextFile function, Spark 255 saved searches 167 scalability 76 advantages of using CDN 288 and change of scaling requirements 10 and designing text messaging app 309 and image sharing service 267 autocomplete 250 caching and 99 CDN 291 clarifying scalability requirements 27 defined 6, 56 horizontal 10 large-scale aggregation operations 376 load balancing 57 rate limiting 175 stateless and stateful services 57 scaling. _See also_ vertical scaling; horizontal scaling adding caching service 8 and CDN (Content distribution Network) 9 batch auditing service 233 defined 56 example of consumer-facing app 6 GeoDNS and 7 horizontal scalability 10 notification service 200 scalability 6 system services and 6 schema migration 30 scope OAuth 2.0 407 OAuth and initial client setup 408 search and search bar 40 Craigslist design 162 differences between autocomplete and 247 introduction 40 similarities with autocomplete 246 within specific document collection 246 search bar 19 and common techniques of implementing search 41 creating Elasticsearch index 42 implementation with Elasticsearch 41 overview 40 search service, and autocomplete service as complementing 246 secret key, CDN authentication and authorization 292 secrets management service 294, 299 security 73, 148 and designing text messaging app 309 autocomplete 250 batch auditing service 233 CDN 291 frontend service 204 message sending service 321 notification service 200 rate limiting 176 sender service 311 overview 316 sensitive information, logging and 35 Sensu, FOSS monitoring tool 38 serverless 23 overview 22 server service, sending messages 316 server-side components 7 server-side data encryption 123 service components, discussing required 177 service discovery 127 service mesh and centralization of cross-cutting concerns 14 elements of 126 example illustration of 125 illustration of 16 Istio 16 sidecarless 17 service registry

 index services. _See also_ microservices centralization of cross-cutting concerns 123 common functionalities of various services 123 external vs. internal 21, 74 horizontally scalable 172 idempotent 10, 124 multiple, and disadvantages when sharing databases 30 predictability and reproducibility of behavior 136 predictability of latency 136 rate limiting 171 shared 13 stateless and stateful 57 compared 77 technology-agnostic 136 vs. libraries 134 service workers 133 sharded RDBMS 88 sharding 79, 180 hot shards 180 monitoring 181 reshuffling to prevent 182, 184 sharer 267 sidecar pattern 16, 193. _See also_ service mesh signature, ID token 412 silent errors 40, 225, 244 failed audits as indication of 228 simple login as the most basic type of authentication 404 disadvantages complexity and lack of maintainability 404 no partial authorization 405 sliding window counter 193 sliding window log 192 soft delete 305 software release lifecycle example of 274 example of flowchart of software release process 275 including new code without removing old one 275 Spark 229 HDFS replication 87 using with HDFS 254 SparkContext esRDD method 255 split brain 68 Spring Cloud Function 23 SQL and using Elasticsearch in place of 43 defining validation queries 226 SRE (Site Reliability Engineering) team

SSL termination 123 SSO (single sign-on) 404 standard set of scopes, Open ID Connect authentication 411 stateful sharded approach 180 sticky sessions 58 storage, various types of 78 storage capacity, scaling with sharded databases 87 storage services 18 overview 77 streaming and batch audit 36 streaming ETL 17 streaming pipelines 377, 378 hash table and max-heap with single host 383 horizontal scaling to multiple hosts and multi-tier aggregation 385 overview 383 purpose of 383 speed_table 377 subscriptions 167 system design and making tradeoffs 4 as an art 4 basic, of application 128 usability and feedback 45 system design discussion, as dynamic process 25 system design interview flow of typical 24, 53–54, 77, 109, 122 and concisely expressing system design expertise 5 and discussing additional topics 44 and discussing multiple possible options 4 and factors attesting to importance of 4 and prospective manager’s technical background 52 and some additional topics related to batch auditing service 243 as estimation of breadth and depth of candidate’s expertise 4 auditing as theme for discussion in 244 autocomplete and potential pitfall in 246 as discussion topic 245 some additional discussion points 264 clarifying requirements 24 communication skills 5 covering system discovery in 127 defined 3 designing news feed as common question during 354 designing reservation system 329 discussing alternative architectural decisions index discussing thumbnails in 272 discussion about message sending service 325 discussion on reporting posts 164 distributed transactions as discussion topic during 418 engineers 3 estimation of developing engineering skills 51 evaluating tradeoffs between different architectural styles 142 example of coding discussion 329 extending services to support other user categories, as topic during 45 feedback 50 focusing on certain aspects of 25 interview format 5 interviewing the company 51 key principles to follow during 24 OAuth 2.0 and OpenID Connect as discussion topics during 403 open-ended nature of 4 outlining reflection after 48 post-interview reflection 47 checking resources 49 ommitted details 49 preparation for 4, 23 rate limiting service 171 sharing and interacting with images and video 266 suggesting common notification service 196 suggesting topics for discussion 25 time as important aspect of 25, 53 Top K Problem as common discussion topic in 375 writing assessment 49 system design questions, practicing discussing about 25 system services, scaling various 6 systems, eventually consistent 71,

#### T templates and improving notification service’s scalability 207 notification service 207 search feature 210 Terraform 11 aggregation and 93 test set 39 text messaging app additional discussion points on 327 differences between notification/alerting service and 310 initial high-level design 310 requirements for designing 309 search 326 third-party CDN 288 Thrift, backend development framework 133 throttling. _See_ rate limiting throughput 55, 65–66 higher, advantages of using CDN 288 higher, single host limitations 80 ThumbnailCdnRequest 278 thumbnails choreography saga approach 276, 279 CSS img tag 268 downloading pages of 282 downloading simultaneously multiple lowresolution 268 generating from full-resolution images 268 just after files are stored 269 on backend 276 on clients 272 implementing both server-side and client-side generation 281 orchestration saga approach 280 thumbnail generation service 278 timeliness, as data quality dimension 224 TLS termination 73 token-based authentication 291 token bucket advantages of 188 Cloud Balancer 189 main characteristics 188 token deletion, CDN authentication and authorization 294 Top K Problem (Heavy Hitters) as common type of dashboard 374 examples of 375 useful references 394 Top K products as additional discussion topic during system design interview 393 combining data from speed_table and batch_table to generate lists of 377, 378 logging events to distributed storage solutions 376 preprocessing data prior to computing lists of 376 tradeoffs
 aggregation 89 and key principles of system design interview 24 and using metadata service 127 Craigslist design and monolith architecture 152 rate limiting and stateful approach index sharding 80 system design interview and discussing 4, 26 traffic monitoring and 35 sender blocking and reducing 313 traffic spikes handling write traffic spikes 161 outages and 111 unpredictable 17, 18 training set 39 transaction ACID properties of 110 defined 110 described 110 transaction supervisor 114 batch auditing 224 trigger rules 241 Trino 229 TSDB (time series database) 38 TypeScript

#### U

UML class diagram 417 uniqueness, as data quality dimension 224 User-Agent header 290 user and content management 28 user categories/roles, functional requirements and 26 user experience (UX) and preventing concurrent user update conflicts 31 autocomplete 248 changes in developing new features 12 individual users and different subsets of UX 12 user info endpoint, OpenID Connect authentication 411 user notifications, as common system requirement 196 user requests 175 user services 174 user stories audit service 231 image sharing service 267 rate limiting service

UX changes. _See_ user experience (UX)

#### V validation set 39 validation tasks, ingestor and 357 validity, as data quality dimension 224 Vapor, framework 131 vector clock 341 vendor lock-in 21 vertical scaling 80 described 56 main disadvantages 56 Vert.x 132 viewer 267 user type 148 Vue.js, browser web framework

#### W web development languages 131 webpages, storing as HTML documents 165 Web Scalability for Startup Engineers (Ejsmont) 110, 224, 378 web scraping 172 WebViews 153 weighted trie 245, 252 width attribute, displaying thumbnails 268 word processor, autocomplete suggestions 246 words service

#### X

Xamarin, cross-platform framework

#### Y

Yesod, full-stack framework

#### Z

Zabbix, FOSS monitoring tool 38 Zipkin, distributed tracing system 14 ZooKeeper 68, 296 message sending service and


SYSTEM DESIGN/TECHNICAL INTERVIEW

#### Acing the System Design Interview Zhiyong Tan[●] Forewords by Anthony Asta, Michael Elder he system design interview is daunting even for seasoned software engineers. Fortunately, with a little careful prep T work you can turn those open-ended questions and whiteboard sessions into your competitive advantage! In this powerful book, Zhiyong Tan reveals practical interview techniques and insights about system design that have earned developers job off ers from Amazon, Apple, ByteDance, PayPal, and Uber.

Acing the System Design Interview is a masterclass in how to confi dently nail your next interview. Following these easy-toremember techniques, you’ll learn to quickly assess a question, identify an advantageous approach, and then communicate your ideas clearly to an interviewer. As you work through this book, you’ll gain not only the skills to successfully interview, but also to do the actual work of great system design.

#### What’s Inside

- Insights on scaling, transactions, logging, and more

- Practice questions for core system design concepts

- How to demonstrate your engineering maturity

- Great questions to ask your interviewer

For software engineers, architects, and engineering managers.

Zhiyong Tan is a manager at PayPal. He has worked at Uber, Teradata, and at small startups. Over the years, he has been in many system design interviews, on both sides of the table. Th e technical editor on this book was Mohit Kumar.

“Deconstructs the system design interview and presents each component in an accessible manner for new job seekers as well as seasoned engineers. Th e attention to detail makes this book a must have.”

#### —Mohammad Shafkat Amin Meta

“Comprehensively covers the most common topics, along with helpful tips and advice. It gives you all the tools you need to ace your next system design interview.”

—Rajesh Kumar, Google

“Th e practical advice and real world examples in this book will help you master the art of system design and succeed in your next interview.”

—Kevin Goh, PayPal


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0473-17.png)




For print book owners, all ebook formats are free: https://www.manning.com/freebook![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0473-19.png)


![](../images/Acing_the_System_Design_Interview_--_Zhiyong_Tan_--_1,_2024_--_Manning_Publications_--_9781633439108_--_c73d1a318d63aa7d5e6aeff5a0f76920_--_Anna’s_Archive.pdf-0473-20.png)




**M A N N I N G**


