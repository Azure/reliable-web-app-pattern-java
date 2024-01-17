# Simulate the Patterns

You can test and configure the three code-level design patterns with this implementation: retry, circuit-breaker, and cache-aside. The following paragraphs detail steps to test the three code-level design patterns.

## Cache-Aside Pattern

Azure Cache for Redis is a fully managed, open-source compatible in-memory data store that powers fast, high-performing applications, with caching and advanced data structures.

The cache-aside pattern enables us to limit read queries to  the Azure PostgreSQL Flexible Server. It also provides a layer of redundancy that can keep parts of our application running in the event of issue with Azure PostgreSQL Database.

For more information, see [cache-aside pattern](https://learn.microsoft.com/azure/architecture/patterns/cache-aside).

Using the Redis Console we can see that we are caching objects and http sessions from Contoso Fiber in Redis.

![image of Azure Cache for Redis Console](docs/assets/redis-console.png)

![image of Azure Cache for Redis Keys](docs/assets/redis-keys.png)

# Logs

Application logging is enabled. To view the logs, navigate to *Diagnose and solve problems*. From there, click on *Application Logs*.

![Diagnose and solve problems](./docs/assets/appservice-diagnose-and-solve-problems.png)

![Application Logs](./docs/assets/appservice-application-logs.png)

## Application Insights

Exceptions in the Contoso Fiber CAMS web application are reported with Application Insights. 

![AppInsightsFailures](./docs/assets/appinsights_failures.png)

Click on an exception to see the end-to-end details:

![AppInsightsEndToEndDetails](./docs/assets/appinsights-end-to-end.png)

Navigate to the Application Map blade:

![AppInsightsApplicationMap](./docs/assets/appinsights_map.png)

Navigate to the Performance blade:

![AppInsightsPerformance](./docs/assets/appinsights_performance.png)

Navigate to the Live Metrics blade to see real-time performance:

![AppInsightsLiveMetrics](./docs/assets/appinsights_live_metrics.png)