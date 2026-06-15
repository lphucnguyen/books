 84 -->

# Chapter 2  A typical system design interview flow
tools, as reflected in frequent feedback? Which ones were abandoned, and why? 
How do these tools stack up to competitors and to the state of the art? 
¡ What has the company or the relevant teams within the company done to address 
these points? 
¡ What are the experiences of engineers with the company’s CI/CD tools? How 
often do engineers run into problems with CI/CD? Are there incidents where 
CI builds succeed but CD deployments fail? How much time do they spend to 
troubleshoot these problems? How many messages were sent to the relevant help 
desk channels in the last month, divided by the number of engineers? 
¡ What projects are planned, and what needs do they fulfill? What is the engineer-
ing department’s strategic vision? 
¡ What were the organizational-wide migrations in the last two years? Examples of 
migrations: 
–	 Shift services from bare metal to a cloud vendor or between cloud vendors. 
–	 Stop using certain tools (e.g., a database like Cassandra, a particular monitor-
ing solution). 
¡ Have there been sudden U-turns—for example, migrating from bare metal to 
Google Cloud Platform followed by migrating to AWS just a year later? How 
much were these U-turns motivated by unpredictable versus overlooked or polit-
ical factors? 
¡ Have there been any security breaches in the history of the company, how serious 
were they, and what is the risk of future breaches? This is a sensitive question, and 
companies will only reveal what is legally required. 
¡ The overall level of the company’s engineering competence. 
¡ The management track record, both in the current and previous roles.
Be especially critical of your prospective manager’s technical background. As an engi-
neer or engineering manager, never accept a non-technical engineering manager, 
especially a charismatic one. An engineering manager who cannot critically evaluate 
engineering work, cannot make good decisions on sweeping changes in engineering 
processes or lead the execution of such changes (e.g., cloud-native processes like mov-
ing from manual deployments to continuous deployment), and may prioritize fast 
feature development at the cost of technical debt that they cannot recognize. Such a 
manager has typically been in the same company (or an acquired company) for many 
years, has established a political foothold that enabled them to get their position, and 
is unable to get a similar position in other companies that have competent engineering 
organizations. Large companies that breed the growth of such managers have or are 
about to be disrupted by emerging startups. Working at such companies may be more 
lucrative in the short term than alternatives currently available to you, but they may 
set back your long-term growth as an engineer by years. They may also be financially 
worse for you because companies that you rejected for short-term financial gain end 


 85 -->

	
Summary
up performing better in the market, with higher growth in the valuation of your equity. 
Proceed at your own peril. 
Overall, what can I learn and cannot learn from this company in the next four years? 
When you have your offers, you can go over the information you have collected and 
make a thoughtful decision. 
https://blog.pragmaticengineer.com/reverse-interviewing/ is an article on inter-
viewing your prospective manager and team.
Summary
¡ Everything is a tradeoff. Low latency and high availability increase cost and com-
plexity. Every improvement in certain aspects is a regression in others. 
¡ Be mindful of time. Clarify the important points of the discussion and focus on 
them. 
¡ Start the discussion by clarifying the system’s requirements and discuss possible 
tradeoffs in the system’s capabilities to optimize for the requirements.
¡ The next step is to draft the API specification to satisfy the functional 
## requirements.
¡ Draw the connections between users and data. What data do users read and write 
to the system, and how is data modified as it moves between system components?
¡ Discuss other concerns like logging, monitoring, alerting, search, and others 
that come up in the discussion.
¡ After the interview, write your self-assessment to evaluate your performance and 
learn your areas of strength and weakness. It is a useful future reference to track 
your improvement. 
¡ Know what you want to achieve in the next few years and interview the company 
to determine if it is where you wish to invest your career.
¡ Logging, monitoring, and alerting are critical to alert us to unexpected events 
quickly and provide useful information to resolve them.
¡ Use the four golden signals and three instruments to quantify your service’s 
### observability.
¡ Log entries should be easy to parse, small, useful, categorized, have standardized 
time formats, and contain no private information.
¡ Follow the best practices of responding to alerts, such as runbooks that are useful 
and easy to follow, and continuously refine your runbook and approach based on 
the common patterns you identify.


 86 -->

Non-functional 
## requirements
This chapter covers
¡ Discussing non-functional requirements at the 	
	 start of the interview
¡ Using techniques and technologies to fulfill 	
## non-functional requirements
## ¡ Optimizing for non-functional requirements
A system has functional and non-functional requirements. Functional requirements 
describe the inputs and outputs of the system. You can represent them as a rough 
API specification and endpoints.
Non-functional requirements refer to requirements other than the system inputs and 
outputs. Typical non-functional requirements include the following, to be discussed 
in detail later in this chapter.
¡ Scalability—The ability of a system to adjust its hardware resource usage easily 
and with little fuss to cost-efficiently support its load.
¡ Availability—The percentage of time a system can accept requests and return 
the desired response.


 87 -->

	
﻿
¡ Performance/latency/P99 and throughput—Performance or latency is the time taken 
for a user’s request to the system to return a response. The maximum request 
rate that a system can process is its bandwidth. Throughput is the current request 
rate being processed by the system. However, it is common (though incorrect) to 
use the term “throughput” in place of “bandwidth.” Throughput/bandwidth is 
the inverse of latency. A system with low latency has high throughput.
¡ Fault-tolerance—The ability of a system to continue operating if some of its com-
ponents fail and the prevention of permanent harm (such as data loss) should 
downtime occur.
¡ Security—Prevention of unauthorized access to systems. 
¡ Privacy—Access control to Personally Identifiable Information (PII), which can 
be used to uniquely identify a person.
¡ Accuracy—A system’s data may not need to be perfectly accurate, and accuracy 
tradeoffs to improve costs or complexity are often a relevant discussion. 
¡ Consistency—Whether data in all nodes/machines match.
¡ Cost—We can lower costs by making tradeoffs against other non-functional prop-
erties of the system.
¡ Complexity, maintainability, debuggability, and testability—These are related con-
cepts that determine how difficult it is to build a system and then maintain it after 
it is built.
A customer, whether technical or non-technical, may not explicitly request non-func-
tional requirements and may assume that the system will satisfy them. This means that 
the customer’s stated requirements will almost always be incomplete, incorrect, and 
sometimes excessive. Without clarification, there will be misunderstandings on the 
requirements. We may not obtain certain requirements and therefore inadequately 
satisfy them, or we may assume certain requirements, which are actually not required 
and provide an excessive solution. 
A beginner is more likely to fail to clarify non-functional requirements, but a lack of 
clarification can occur for both functional and non-functional requirements. We must 
begin any systems design discussion with discussion and clarification of both the func-
## tional and non-functional requirements.
Non-functional requirements are commonly traded off against each other. In any 
system design interview, we must discuss how various design decisions can be made for 
various tradeoffs. 
It is tricky to separately discuss non-functional requirements and techniques to 
address them because certain techniques have tradeoff gains on multiple non-func-
tional requirements for losses on others. In the rest of this chapter, we briefly discuss 
each non-functional requirement and some techniques to fulfill it, followed by a 
detailed discussion of each technique. 


