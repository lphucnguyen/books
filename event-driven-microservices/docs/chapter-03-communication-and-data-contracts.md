## **CHAPTER 3** 

## **Communication and Data Contracts** 

_The fundamental problem of communication is that of reproducing at one point either exactly or approximately a message selected at another point._ 

—Claude Shannon 

Shannon, known as the Father of Information Theory, identified the largest hurdle of communication: ensuring that a consumer of a message can accurately reproduce the producer’s message, such that both the content and meaning are correctly conveyed. The producer and consumer must have a common understanding of the message; otherwise, it may be misinterpreted, and the communication will be incomplete. In the event-driven ecosystem, the event is the message and the fundamental unit of communication. An event must describe as accurately as possible _what_ happened and _why_ . It is a statement of fact and, when combined with all the other events in a system, provides a complete history of what has happened. 

## **Event-Driven Data Contracts** 

The format of the data to be communicated and the logic under which it is created form the _data contract_ . This contract is followed by both the producer and the consumer of the event data. It gives the event meaning and form beyond the context in which it is produced and extends the usability of the data to consumer applications. 

There are two components of a well-defined data contract. First is the _data definition_ , or what will be produced (i.e., the fields, types, and various data structures). The second component is the _triggering logic_ , or why it is produced (i.e., the specific business logic that triggered the event’s creation). Changes can be made to both the data definition and the triggering logic as the business requirements evolve. 


You must take care when changing the data definition, so as not to delete or alter fields that are being used by downstream consumers. Similarly, you must also be careful when modifying the triggering logic. It is far more common to change the data definition than the triggering mechanism, as altering the latter often breaks the meaning of the original event definition. 

## **Using Explicit Schemas as Contracts** 

The best way to enforce data contracts and provide consistency is to define a schema for each event. The producer defines an explicit schema detailing the data definition and the triggering logic, with all events of the same type adhering to this format. In doing so, the producer provides a mechanism for communicating its event format to all prospective consumers. The consumers, in turn, can confidently build their microservice business logic against the schematized data. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0058-03.png)


Any implementation of event-based communication between a producer and consumer that lacks an _explicit_ predefined schema will inevitably end up relying on an _implicit_ schema. Implicit data contracts are brittle and susceptible to uncontrolled change, which can cause much undue hardship to downstream consumers. 

A consumer must be able to extract the data necessary for its business processes, and it cannot do that without having a set of expectations about what data should be available. Consumers must often rely on tribal knowledge and interteam communication to resolve data issues, a process that is not scalable as the number of event streams and teams increases. There is also substantial risk in requiring each consumer to independently interpret the data, as a consumer may interpret it differently than its peers, which leads to inconsistent views of the single source of truth. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0058-06.png)


It may be tempting to build a common library that interprets any given event for all services, but this creates problems with multiple language formats, event evolutions, and independent release cycles. Duplicating efforts across services to ensure a consistent view of implicitly defined data is nontrivial and best avoided completely. 

Producers are also at a disadvantage with implicit schemas. Even with the best of intentions, a producer may not notice (or perhaps their unit tests don’t reveal) that they have altered their event data definition. Without an explicit check of their service’s event format, this situation may go unnoticed until it causes downstream consumers to fail. Explicit schemas give security and stability to both consumers and producers. 


## **Schema Definition Comments** 

Support for integrated comments and arbitrary metadata in the schema definition is essential for communicating the meaning of an event. The knowledge surrounding the production and consumption of events should be kept as close as possible to the event definition. Schema comments help remove ambiguity about the data’s meaning and reduce the chance of misinterpretation by consumers. There are two main areas where comments are particularly valuable: 

- Specifying the triggering logic of the event. This is typically done in a block header at the top of the schema definition and should clearly state _why_ an event has been generated. 

- Giving context and clarity about a particular field within the structured schema. For example, a datetime field’s comments could specify if the format is UTC, ISO, or Unix time. 

## **Full-Featured Schema Evolution** 

The schema format must support a full range of schema evolution rules. Schema evolution enables producers to update their service’s output format while allowing consumers to continue consuming the events uninterrupted. Business changes may require that new fields be added, old fields be deprecated, or the scope of a field be expanded. A schema evolution framework ensures that these changes can occur safely and that producers and consumers can be updated independently of one another. 

Updates to services become prohibitively expensive without schema evolution support. Producers and consumers are forced to coordinate closely, and old, previously compatible data may no longer be compatible with current systems. It is unreasonable to expect consumers to update their services whenever a producer changes the data schema. In fact, a core value proposition of microservices is that they should be independent of the release cycles of other services except in exceptional cases. 

An explicit set of schema evolution rules goes a long way in enabling both consumers and producers to update their applications in their own time. These rules are known as _compatibility types_ . 

## _Forward compatibility_ 

Allows for data produced with a newer schema to be read as though it were produced with an older schema. This is a particularly useful evolutionary requirement in an event-driven architecture, as the most common pattern of system change begins with the producer updating its data definition and producing data with the newer schema. The consumer is required only to update its copy of the schema and code should it need access to the new fields. 

**Event-Driven Data Contracts | 41** 


## _Backward compatibility_ 

Allows for data produced with an older schema to be read as though it were produced with a newer schema. This enables a consumer of data to use a newer schema to read older data. There are several scenarios where this is particularly useful: 

- The consumer is expecting a new feature to be delivered by the upstream team. If the new schema is already defined, the consumer can release its own update prior to the producer release. 

- Schema-encoded data is sent by a product deployed on customer hardware, such as a cell phone application that reports on user metrics. Updates can be made to the schema format for new producer releases, while maintaining the compatibility with previous releases. 

- The consumer application may need to reprocess data in the event stream that was produced with an older schema version. Schema evolution ensures that the consumer can translate it to a familiar version. If backward compatibility is not followed, the consumer will only be able to read messages with the latest format. 

## _Full compatibility_ 

The union of forward compatibility and backward compatibility, this is the strongest guarantee and the one you should use whenever possible. You can always loosen the compatibility requirements at a later date, but it is often far more difficult to tighten them. 

## **Code Generator Support** 

A _code generator_ is used to turn an event schema into a class definition or equivalent structure for a given programming language. This class definition is used by the producer to create and populate new event objects. The producer is required by the compiler or serializer (depending on the implementation) to respect data types and populate all non-nullable fields that are specified in the original schema. The objects created by the producer are then converted into their serialized format and sent to the event broker, as shown in Figure 3-1. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0060-09.png)


_Figure 3-1. Producer event production workflow using a code generator_ 


The consumer of the event data maintains its own version of the schema, which is often the same version as the producer’s but could be an older or newer schema, depending on the usage of schema evolution. If full compatibility is being observed, the service can use any version of the schema to generate its definitions. The consumer reads the event and deserializes it using the schema version that it was encoded with. The event format is stored either alongside the message, which can be prohibitively expensive at scale, or in a schema registry and accessed on-demand (see “Schema Registry” on page 241). Once deserialized into its original format, the event can be converted to the version of the schema supported by the consumer. Evolution rules come into play at this point, with defaults being applied to missing fields, and unused fields dropped completely. Finally, the data is converted into an object based on the schema-generated class. At this point, the consumer’s business logic may begin its operations. This process is shown in Figure 3-2. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0061-01.png)


_Figure 3-2. Consumer event consumption and conversion workflow using a code generator; note that the consumer converts events from schema v2, as created by the producer, to v1, the schema format used by the consumer_ 

The biggest benefit of code generator support is being able to write your application against a class definition in the language of your choice. If you are using a compiled language, the code generator provides compiler checks to ensure that you aren’t mishandling event types or missing the population of any given non- `null` data field. Your code will not compile unless it adheres to the schema, and therefore your application will not be shipped without adhering to the schema data definition. Both compiled and noncompiled languages benefit from having a class implementation to code against. A modern IDE will notify you when you’re trying to pass the wrong types into a constructor or setter, whereas you would receive no notification if you’re instead using a generic format such as an object key/value map. Reducing the risk of mishandling data provides for much more consistent data quality across the ecosystem. 

## **Breaking Schema Changes** 

There are times when the schema definition must change in a way that results in a breaking evolutionary change. This can happen for a number of reasons, including evolving business requirements that alter the model of the original domain, improper scoping of the original domain, and human error while defining the schema. While the producing service can be fairly easily changed to accommodate the new schema, the impacts to downstream consumers vary and need to be taken into account. 

**Event-Driven Data Contracts | 43** 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0062-00.png)


The most important thing when dealing with breaking schema changes is to communicate early and clearly with downstream consumers. Ensure that any migration plans have the understanding and approval of everyone involved and that no one is caught unprepared. 

While it may seem heavy-handed to require intense coordination between producers and consumers, the renegotiation of the data contract and the alteration of the domain model require buy-in from everyone. Aside from renegotiating the schema, you need to take some additional steps to accommodate the new schema and new event streams that are created from it. Breaking schema changes tend to be quite impactful for entities that exist indefinitely, but less so for events that expire after a given period of time. 

## **Accommodating breaking schema changes for entities** 

Breaking changes to an entity schema are fairly rare, as this circumstance typically requires a redefinition of the original domain model such that the current model cannot simply be extended. New entities will be created under the new schema, while previous entities were generated under the old schema. This divergence of data definition leaves you with two choices: 

- Contend with both the old and new schemas. 

- Re-create all entities in the new schema format (via migration, or by re-creating them from source). 

The first option is the easiest for the producer, but it simply pushes off the resolution of the different entity definitions onto the consumer. This contradicts the goal of _reducing_ the need for consumers to interpret the data individually and increases the risk of misinterpretation, inconsistent processing between services, and significantly higher complexity in maintaining systems. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0062-08.png)


The reality is that the consumer will never be in a better position than the producer for resolving divergent schema definitions. It is bad practice to defer this responsibility to the consumer. 

The second option is more difficult for the producer, but ensures that the business entities, both old and new, are redefined consistently. In practice, the producer must reprocess the source data that led to the generation of the old entities and apply the new business logic to re-create the entities under the new format. This approach forces the organization as a whole to resolve what these entities mean and how they should be understood and used by producer and consumer alike. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0063-00.png)


Leave the old entities under the old schema in their original event stream, because you may need them for reprocessing validation and forensic investigations. Produce the new and updated entities using the new schema to a new stream. 

## **Accommodating breaking schema changes for events** 

Nonentity events tend to be simpler to deal with when you are incorporating breaking changes. The simplest option is to create a new event stream and begin producing the new events to that stream. The consumers of the old stream must be notified so that they can register themselves as consumers of the new event stream. Each consuming service must also account for the divergence in business logic between the two event definitions. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0063-04.png)


Don’t mix different event types in an event stream, especially event types that are evolutionarily incompatible. Event stream overhead is cheap, and the logical separation is important in ensuring that consumers have full information and explicit definitions when dealing with the events they need to process. 

Given that the old event stream no longer has new events being produced to it, the consumers of each consuming service will eventually catch up to the latest record. As time goes on, the stream’s retention period will eventually result in a full purging of the stream, at which point all consumers can unregister themselves and the event stream can be deleted. 

## **Selecting an Event Format** 

While there are many options available for formatting and serializing event data, data contracts are best fulfilled with strongly defined formats such as Avro, Thrift, or Protobuf. Some of the most popular event broker frameworks have support for serializing and deserializing events encoded with these formats. For example, both Apache Kafka and Apache Pulsar support JSON, Protobuf, and Avro schema formats. The mechanism of support for both of the technologies is the schema registry, which is covered in more detail in “Schema Registry” on page 241. Though a detailed evaluation and comparison of these serialization options is beyond the scope of this book, there are a number of online resources available that can help you decide among these particular options. 

You may be tempted to choose a more flexible option in the form of plain-text events using simple key/value pairs, which still offers some structure but provides no explicit schema or schema evolution frameworks. Proceed cautiously with this approach, 


however, as it can compromise microservices’ ability to remain isolated from one another via a strong data contract, requiring far more interteam communication. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0064-01.png)


Unstructured plain-text events usually become a burden to both the producer and the consumer, particularly as use cases and data changes over time. As mentioned, I recommend instead choosing a strongly defined, explicit schema format that supports controlled schema evolution, such as Apache Avro or Protobuf. I do not recommend JSON, as it does not provide full-compatibility schema evolution. 

## **Designing Events** 

There are a number of best practices to follow when you are creating event definitions, as well as several anti-patterns to avoid. Keep in mind that as the number of architectures powered by event-driven microservices expands, so does the number of event definitions. Well-designed events will minimize the otherwise repetitive pain points for both consumers and producers. With that being said, none of the following are hard-and-fast rules. You can break them as you see fit, though I recommend that you think very carefully about the full scope of implications and the tradeoffs for your problem space before proceeding. 

## **Tell the Truth, the Whole Truth, and Nothing but the Truth** 

A good event definition is not simply a message indicating that _something_ happened, but rather the complete description of _everything_ that happened during that event. In business terms, this is the resultant data that is produced when input data is ingested and the business logic is applied. This output event must be treated as the single source of truth and must be recorded as an immutable fact for consumption by downstream consumers. It is the full and total authority on what actually occurred, and consumers should not need to consult any other source of data to know that such an event took place. 

## **Use a Singular Event Definition per Stream** 

An event stream should contain events representing a single logical event. It is not advisable to mix different types of events within an event stream, because doing so can muddle the definitions of what the event is and what the stream represents. It is difficult to validate the schemas being produced, as new schemas may be added dynamically in such a scenario. Though there are special circumstances where you may wish to ignore this principle, the vast majority of event streams produced and consumed within your architectural workflow should each have a strict, single definition. 


## **Use the Narrowest Data Types** 

Use the narrowest types for your event data. This lets you rely on the code generators, language type checking (if supported), and serialization unit tests to check the boundaries of your data. It sounds simple, but there are many cases where ambiguity can creep in when you don’t use the proper types. Here are a few easily avoidable realworld examples: 

## _Using_ `string` _to store a numeric value_ 

This requires the consumer to parse and convert the string to a numeric value and often comes up with GPS coordinates. This is error prone and subject to failures, especially when a `null` value or an empty string is sent. 

## _Using_ `integer` _as a boolean_ 

While `0` and `1` can be used to denote false and true, respectively, what does `2` mean? How about `-1` ? 

## _Using_ `string` _as an enum_ 

This is problematic for producers, as they must ensure that their published values match an accepted pseudo-enum list. Typos and incorrect values will inevitably be introduced. A consumer interested in this field will need to know the range of possible values, and this will require talking to the producing team, unless it’s specified in the comments of the schema. In either case, this is an _implicit_ definition, since the producers are not guarded against any changes to the range of values in the string. This whole approach is simply bad practice. 

Enums are often avoided because producers fear creating a new enum token that isn’t present in the consumer’s schema. However, the consumer has a responsibility to consider enum tokens that it does not recognize, and determine if it should process them using a default value or simply throw a fatal exception and halt processing until someone can work out what needs to be done. Both Protobuf and Avro have elegant ways of handling unknown enum tokens and should be used if either is selected for your event format. 

## **Keep Events Single-Purpose** 

One common anti-pattern is adding a `type` field to an event definition, where different `type` values indicate specific subfeatures of the event. This is generally done for data that is “similar yet different” and is often a result of the implementer incorrectly identifying the events as single-purpose. Though it may seem like a time-saving measure or a simplification of a data access pattern, overloading events with `type` parameters is rarely a good idea. 

There are several problems with this approach. Each `type` parameter value usually has a fundamentally different business meaning, even if its technical representation is 


nearly identical to the others. It is also possible for these meanings to change over time and for the scope that an event covers to creep. Some of these types may require the addition of new parameters to track type-specific information, whereas other types require separate parameters. Eventually you could have a situation where there are several very distinct events all inhabiting the same event schema, making it difficult to reason about what the event truly represents. 

This complexity affects not only the developers who must maintain and populate these events, but also the data’s consumers, who need to have a consistent understanding about what data is published and why. If the data contract changes, they expect to be able to isolate themselves from those changes. Adding extra field types requires them to filter for only data that they care about. There is a risk that the consumer will fail to fully understand the various meanings of the types, leading to incorrect consumption and logically wrong code. For each consumer, additional processing must also be done to discard events that aren’t relevant to that consumer. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0066-02.png)


It is very important to note that adding `type` fields does not reduce or eliminate the underlying complexity inherent in the data being produced. In fact, this complexity is merely shifted from multiple distinct event streams with distinct schemas to a union of all the schemas merged into one event stream. It could be argued that this actually _increases_ the complexity. Future evolution of the schema becomes more difficult, as does maintaining the code that produces the events. 

Remember the principles of the data contract definition. Events should be related to a single business action, not a generic event that records large assortments of data. If it seems like you need a generic event with various `type` parameters, that’s usually a telltale sign that your problem space and bounded context is not well defined. 

## **Example: Overloading event definitions** 

Imagine a simple website where a user can read a book or watch a movie. When the user first engages the website, say by opening the book or starting the movie, a backend service publishes an event of this engagement, named `ProductEngagement` , into an event stream. The data structure of this cautionary tale event may look something like this: 

```
TypeEnum: Book, Movie
ActionEnum: Click
ProductEngagement {
  productId: Long,
  productType: TypeEnum,
  actionType: ActionEnum
}
```


Now imagine a new business requirement comes in: you need to track who watched the movie trailer before watching the movie. There are no previews for books, and though a boolean would suit the movie-watching case, it must be nullable to allow for book engagements. 

```
ProductEngagement {
  productId: Long,
  productType: TypeEnum,
  actionType: ActionEnum,
  //Only applies to type=Movie
  watchedPreview: {null, Boolean}
}
```

At this point, `watchedPreview` has nothing to do with `Books` , but it’s added into the event definition anyway since we’re already capturing product engagements this way. If you’re feeling particularly helpful to your downstream consumers, you can add a comment in the schema to tell them that this field is only related to `type=Movie` . 

Another new business requirement comes in: you need to track users who place a bookmark in their book, and log what page it is on. Again, because there is only a single defined structure of events for product engagements, your course of action is constrained to adding a new action entity ( `Bookmark` ) and adding a nullable `PageId` field. 

```
TypeEnum: Book, Movie
ActionEnum: Click, Bookmark
ProductEngagement {
  productId: Long,
  productType: TypeEnum,
  actionType: ActionEnum,
  //Only applies to productType=Movie
  watchedPreview: {null, Boolean},
  //Only applies to productType=Book,actionType=Bookmark
  pageId: {null, Int}
}
```

As you can see by now, just a few changes in business requirements can greatly complicate a schema that is trying to serve multiple business purposes. This adds complexity for the producer and the consumer of the data, as they both must check for the validity of the data logic. The data to be collected and represented will always be complex, but by following single responsibility principles you can decompose the schema into something more manageable. Let’s see what this example would look like if you split up each schema according to single responsibilities: 

```
MovieClick {
  movieId: Long,
  watchedPreview: Boolean
}
```


```
BookClick {
  bookId: Long
}
BookBookmark {
  bookId: Long,
  pageId: Int
}
```

The `productType` and `actionType` enumerations are now gone, and the schemas have been flattened out accordingly. There are now three event definitions instead of just a single one, and while the schema definition count has increased, the internal complexity of each schema is greatly reduced. Following the recommendation of one event definition per stream would see the creation of a new stream for each event type. Event definitions would not drift over time, the triggering logic would not change, and consumers could be secure in the stability of the single-purpose event definition. 

The takeaway from this example is not that the original creator of the event definition made a mistake. In fact, at the time, the business cared about _any_ product engagements but no _specific_ product engagement, so the original definition is quite reasonable. As soon as the business requirements changed to include tracking moviespecific events, the owner of the service needed to re-evaluate whether the event definition was still serving a single purpose, or if it was instead now covering multiple purposes. Due to the business requiring lower-level details of an event, it became clear that, while the event could serve multiple purposes, it soon would become complex and unwieldy to do so. 


![](event-driven-microservices-github-pages/images/Event-Driven_Microservices.pdf-0068-03.png)


Avoid adding `type` fields in your events that overload the meaning of the event. This can cause significant difficulty in evolving and maintaining the event format. 

Take some time to consider how your schemas may evolve. Identify the main business purpose of the data being produced, the scope, the domain, and whether you’re building it as single-purpose. Validate that the schemas accurately reflect business concerns, especially for systems that cover a broad scope of business function responsibility. It could be that the business scope and the technical implementation are misaligned. Finally, evolving business requirements may require you to revisit the event definitions and potentially change them beyond just incremental definitions of a single schema. Events may need to be split up and redefined completely should sufficient business changes occur. 


## **Minimize the Size of Events** 

Events work well when they’re small, well defined, and easily processed. Large events can and do happen, though. Generally these larger events represent a lot of contextual information. Perhaps they comprise many data points that are related to the given event, and are simply a very large measurement of something that occurred. 

There are several considerations when you’re looking at a design that produces a very large event. Make sure that the data is directly related and relevant to the event. Additional data may have been added to an event “just in case,” but it may not be of any real use to the downstream consumers. If you find that all the event data is indeed directly related, take a step back and look at your problem space. Does your microservice require access to the data? You may want to evaluate the bounded context to see if the service is performing a reasonable amount of work. Perhaps the service could be reduced in scope with additional functionality split off into its own service. 

This scenario is not always avoidable, though—some event processors produce very large output files (perhaps a large image) that are much too big to fit into a single message of an event stream. In these scenarios you can use a pointer to the actual data, but do this sparingly. This approach adds risk in the form of multiple sources of truth and payload mutability, as an immutable ledger cannot ensure the preservation of data outside of its system. 

## **Involve Prospective Consumers in the Event Design** 

When designing a new event, it is important to involve any anticipated consumers of this data. Consumers will understand their own needs and anticipated business functions better than the producers and may help in clarifying requirements. Consumers will also get a better understanding of the data coming their way. A joint meeting or discussion can shake out any issues around the data contract between the two systems. 

## **Avoid Events as Semaphores or Signals** 

Avoid using events as a semaphore or a signal. These events simply indicate that something has occurred without being the single source of truth for the results. 

Consider a very simple example where a system outputs an event indicating that work has been completed for an arbitrary job. Although the event itself indicates the work is done, the actual result of the work is not included in the event. This means that to consume this event properly, you must find where the completed work actually resides. Once there are two sources of truth for a piece of data, consistency problems arise. 


## **Summary** 

Asynchronous event-driven architectures rely heavily upon event quality. Highquality events are explicitly defined with an evolvable schema, have well-defined triggering logic, and include full schema definitions with comments and documentation. Implicit schemas, while easier to implement and maintain for the producer, offload much of the interpretation work onto the consumer. They are also more prone to unexpected failures due to missing event data and unintentional changes. Explicit schemas are an essential component for widespread adoption of event-driven architectures, particularly as an organization grows and it becomes impossible to communicate tribal knowledge organization-wide. 

Event definitions should be narrow and closely focused on the domain of the event. An event should represent a specific _business_ occurrence and contain the appropriate data fields to record what has happened. These events form the official narrative about business operations and can be consumed by other microservices for their own needs. 

Schema evolution is a very important aspect of explicit schemas, as it allows for a controlled mechanism of change for the event domain model. It is common for a domain model to evolve, particularly as new business requirements emerge and the organization expands. Schema evolution allows producers and consumers to isolate themselves from changes that aren’t essential to their operations, while permitting those services that _do_ care about the changes to update themselves accordingly. 

In some cases schema evolution is not possible, and a breaking change must occur. The producer and consumer stakeholders must communicate the reasons behind the breaking changes and come together to redefine the domain model going forward. Migration of old events may or may not be necessary. 


