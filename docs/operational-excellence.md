# Operational Excellence

## Monitoring

To see how our application is behaving we're integrating with Application Insights. To enable the Java application to capture telemetry, follow the instructions [here](https://learn.microsoft.com/en-us/azure/azure-monitor/app/java-in-process-agent).

To enable Application Insights Java programmatically, we added the following.

1. Maven dependency

   ```xml
   <dependency>
      <groupId>com.microsoft.azure</groupId>
      <artifactId>applicationinsights-runtime-attach</artifactId>
      <version>3.4.7</version>
   </dependency>
   ```
1. Invoke the ApplicationInsights.attach() method in Application.java.

   ```java
   public static void main(String[] args) {
       ApplicationInsights.attach();
       SpringApplicationBuilder builder = new SpringApplicationBuilder();
       doConfigure(builder).run(args);
   }
   ```

## Logs

Application logging is enabled. To view the logs, navigate to *Diagnose and solve problems*. From there, click on *Application Logs*.

![Diagnose and solve problems](assets/appservice-diagnose-and-solve-problems.png)

![Application Logs](assets/appservice-diagnose-and-solve-problems-application-logs.png)