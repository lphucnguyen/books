## **Chapter 33** 

## **Manageability** 

Operators use observability tools to understand the behavior of their application, but they also need a way to modify the behavior without code changes. One example of this is releasing a new version of an application to production, which we discussed earlier. Another example is changing the way an application behaves by modifying its configuration. 

An application generally depends on a variety of configuration settings. Some affect its behavior, like the maximum size of an internal cache, while others contain secrets, like credentials to access external data stores. Because settings vary by environment and can contain sensitive information, they should not be hardcoded. 

To decouple the application from its configuration, the configuration can be persisted in a dedicated store[1] like AWS AppConfig[2] or Azure App Configuration[3] . 

At deployment time, the CD pipeline can read the configuration from the store and pass it to the application through environment 

> 1“Continuous Configuration at the Speed of Sound,” https://www.allthingsd istributed.com/2021/08/continuous-configuration-on-aws.html 

> 2“AWS AppConfig Documentation,” https://docs.aws.amazon.com/appconfi g/ 

> 3“Azure App Configuration,” https://azure.microsoft.com/en-us/services/ app-configuration/ 


324 variables. The drawback of this approach is that the configuration cannot be changed without redeploying the application. 

For the application to be able to react to configuration changes, it needs to periodically re-read the configuration during run time and apply the changes. For example, if the constructor of an HTTP handler depends on a specific configuration setting, the handler needs to be re-created when that setting changes. 

Once it’s possible to change configuration settings dynamically, new features can be released with settings to toggle (enable/disable) them. This allows a build to be released with a new feature disabled at first. Later, the feature can be enabled for a fraction of application instances (or users) to build up confidence that it’s working as intended before it’s fully rolled out. Similarly, the same mechanism can be used to perform A/B tests[4] . 

4“A/B testing,” https://en.wikipedia.org/wiki/A/B_testing 


## **Summary** 

If you have spent even a few months in a team that operates a production service, you should be very familiar with the topics discussed in this part. Although we would all love to design new large-scale systems and move on, the reality is that the majority of the time is spent in maintenance activities, such as fixing bugs, adding new features to existing services, and operating production services. 

In my opinion, the only way to become a better system designer is to embrace these maintenance activities and aspire to make your systems easy to modify, extend and operate so that they are easy to maintain. By doing so, you will pick up a “sixth sense” that will allow you to critique the design of third-party systems and ultimately make you a better systems designer/builder. 

So my advice to you is to use every chance you get to learn from production services. Be on call for your services. Participate in as many post-mortems as you can and relentlessly ask yourself how an incident could have been avoided. These activities will pay off in the long term a lot more than reading about the latest architectural patterns and trends. 


