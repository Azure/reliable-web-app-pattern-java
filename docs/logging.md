# Logging

Contoso Fiber CAMS makes use of App Insights for logging. Take a look at the [App Insights documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview) for more information. Follow this [guide](https://learn.microsoft.com/en-us/azure/azure-monitor/app/azure-web-apps-java) to get started with Application Monitoring for Azure App Service and Java.

## Pom.xml changes

Add the following dependency to your pom.xml file:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```
The Spring Boot Actuator provides production-ready features to help you monitor your application.

## Application Insights Configuration

Add the following properties to your application.properties file:

```properties
management.endpoints.web.exposure.include=metrics,health,info
management.endpoint.health.show-details=when-authorized
management.endpoint.health.show-components=when-authorized
```

For more information, refer to the [Spring Boot Actuator documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/production-ready-features.html#production-ready-enabling).

## Application Insights

Check out [Simulate Patterns - Logs](../demo.md#logs) to see how to monitor the app with Application Insights.