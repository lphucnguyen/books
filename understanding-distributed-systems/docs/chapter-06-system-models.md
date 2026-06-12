## **Chapter 6** 

## **System models** 

To reason about distributed systems, we need to define precisely what can and can’t happen. A _system model_ encodes expectations about the behavior of processes, communication links, and timing; think of it as a set of assumptions that allow us to reason about distributed systems by ignoring the complexity of the actual technologies used to implement them. 

For example, these are some common models for communication links: 

- The _fair-loss link_ model assumes that messages may be lost and duplicated, but if the sender keeps retransmitting a message, eventually it will be delivered to the destination. 

- The _reliable link_ model assumes that a message is delivered exactly once, without loss or duplication. A reliable link can be implemented on top of a fair-loss one by de-duplicating messages at the receiving side. 

- The _authenticated reliable link_ model makes the same assumptions as the reliable link but additionally assumes that the receiver can authenticate the sender. 

Even though these models are just abstractions of real communication links, they are useful to verify the correctness of algorithms. And, as we have seen in the previous chapters, it’s possible to build 


58 a reliable and authenticated communication link on top of a fairloss one. For example, TCP implements reliable transmission (and more), while TLS implements authentication (and more). 

Similarly, we can model the behavior of processes based on the type of failures we expect to happen: 

- The _arbitrary-fault_ model assumes that a process can deviate from its algorithm in arbitrary ways, leading to crashes or unexpected behaviors caused by bugs or malicious activity. For historical reasons, this model is also referred to as the “Byzantine” model. More interestingly, it can be theoretically proven that a system using this model can tolerate up to[1] 3[of] faulty processes[1] and still operate correctly. 

- The _crash-recovery_ model assumes that a process doesn’t deviate from its algorithm but can crash and restart at any time, losing its in-memory state. 

- The _crash-stop_ model assumes that a process doesn’t deviate from its algorithm but doesn’t come back online if it crashes. Although this seems unrealistic for software crashes, it models unrecoverable hardware faults and generally makes the algorithms simpler. 

The arbitrary-fault model is typically used to model safety-critical systems like airplane engines, nuclear power plants, and systems where a single entity doesn’t fully control all the processes (e.g., digital cryptocurrencies such as Bitcoin). These use cases are outside the book’s scope, and the algorithms presented here will generally assume a crash-recovery model. 

Finally, we can also model timing assumptions: 

- The _synchronous_ model assumes that sending a message or executing an operation never takes more than a certain amount of time. This is not very realistic for the type of systems we care about, where we know that sending messages over the network can potentially take a very long 

> 1“The Byzantine Generals Problem,” https://lamport.azurewebsites.net/pubs /byz.pdf 


59 time, and processes can be slowed down by, e.g., garbage collection cycles or page faults. 

- The _asynchronous_ model assumes that sending a message or executing an operation on a process can take an unbounded amount of time. Unfortunately, many problems can’t be solved under this assumption; if sending messages can take an infinite amount of time, algorithms can get stuck and not make any progress at all. Nevertheless, this model is useful because it’s simpler than models that make timing assumptions, and therefore algorithms based on it are also easier to implement[2] . 

- The _partially synchronous_ model assumes that the system behaves synchronously most of the time. This model is typically representative enough of real-world systems. 

In the rest of the book, we will generally assume a system model with fair-loss links, crash-recovery processes, and partial synchrony. If you are curious and want to learn more about other system models, “Introduction to Reliable and Secure Distributed Programming”[3] is an excellent theoretical book that explores distributed algorithms for a variety of models not considered in this text. 

But remember, models are just an abstraction of reality[4] since they don’t represent the real world with all its nuances. So, as you read along, question the models’ assumptions and try to imagine how algorithms that rely on them could break in practice. 

> 2“Unreliable Failure Detectors for Reliable Distributed Systems,” https://ww w.cs.utexas.edu/~lorenzo/corsi/cs380d/papers/p225-chandra.pdf 

> 3“Introduction to Reliable and Secure Distributed Programming,” https://ww w.distributedprogramming.net/ 

> 4“All models are wrong,” https://en.wikipedia.org/wiki/All_models_are_w rong 


