# How to apply the reliable web app pattern (Java)

The reliable web app pattern is a set of best practices built on the the [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/architecture/framework/) that helps developers successfully migrate web applications to the cloud. The goal is to improve the cost, performance, security, operations, and reliability of your web application with minimal changes. The reliable web app pattern is an essential first step for web applications converging on the cloud and sets a foundation for future modernizations in Azure.

This article shows you how to apply the reliable web app pattern. There's a companion article that provides an [overview of the pattern](pattern-overview.yml) and a [reference implementation](README.md#steps-to-deploy-the-reference-implementation) that you can deploy. The guidance refers to the code and architecture of the reference implementation throughout, and the following diagram illustrates its architecture.

## Architecture and code

Architecture and code are symbiotic. A well-architected web application needs quality code, and quality code needs a well-architected solution. Flaws in one limit the benefits of the other. The guidance here situates code changes within the pillars of the [Azure Well-Architected Framework](https:/learn.microsoft.com/en-us/azure/architecture/framework/) to reinforce the interdependence of code and architecture. The following diagram shows the architecture of the reference implementation that applies the reliable web app pattern.

[![Diagram showing the architecture of the reference implementation](docs/assets/java-architecture.png)]((docs/assets/java-architecture.png))

## Reliability

A reliable web application is one that is both resilient and available. Resiliency is the ability of the system to recover from failures and continue to function. The goal of resiliency is to return the application to a fully functioning state after a failure occurs. Availability is whether your users can access your web application when they need to. We recommend using the retry and circuit-breaker patterns as a critical first step toward improving application reliability. These design patterns introduce self-healing qualities and help your application maximize the reliability features of the cloud. Here are our reliability recommendations.

### Use the retry pattern

The retry pattern is a technique for handling temporary service interruptions. These temporary service interruptions are known as transient faults. They're transient because they typically resolve themselves in a few seconds. In the cloud, the leading causes of transient faults are service throttling, dynamic load distribution, and network connectivity. The retry pattern handles transient faults by resending failed requests to the service. You can configure the amount of time between retries and how many retries to attempt before throwing an exception. For more information, see [transient fault handling](https://review.learn.microsoft.com/en-us/azure/architecture/best-practices/transient-faults).

If your code already uses the retry pattern, you should update your code to use the retry mechanisms available in Azure services and client SDKs. If your application doesn't have a retry pattern, then you should use [Resilience4j](https://github.com/resilience4j/resilience4j).

Resilience4j is a lightweight fault tolerance library inspired by Netflix Hystrix and designed for functional programming. It provides higher-order functions (decorators) to enhance any functional interface, lambda expression or method reference with a Circuit Breaker, Rate Limiter, Retry or Bulkhead.

*Reference implementation.* The reference implementation decorates a lambda expression with a Circuit Breaker and Retry in order to retry the call to get the media file from disk. The folowing code demonstrates how to use Resilience4j to retry a filesystem call to Azure Files to get the last modified time.

```java
private MediaFile checkLastModified(MediaFile mediaFile, MusicFolder folder, boolean minimizeDiskAccess) {
        Retry retry = retryRegistry.retry("media");
        CheckedFunction0<MediaFile> supplier = () -> doCheckLastModified(mediaFile, folder, minimizeDiskAccess);
        CheckedFunction0<MediaFile> retryableSupplier = Retry.decorateCheckedSupplier(retry, supplier);
        Try<MediaFile> result = Try.of(retryableSupplier).recover((IOException) -> mediaFile);
        return result.get();
    }
```

The retry registry gets a Retry object. It uses a functional approach with the `vavr` library to recover from an exception and invoke another lambda expression as a fallback. In this case, the original MediaFile is returned if the maximum amount of retries has occurred. You can configure your Retry properties in the `application.yml` file.

```java
resilience4j.retry:
    instances:
        media:
            maxRetryAttempts: 8
            waitDuration: 10s
            enableExponentialBackoff: true
            exponentialBackoffMultiplier: 2
            retryExceptions:
                - java.nio.file.FileSystemException
                - java.io.IOException
```

For more ways to configure Resiliency4J, see [Resilliency4J documentation](https://resilience4j.readme.io/v1.7.0/docs/getting-started-3).

*Simulate the retry pattern:* The reference implementation uses the `Spring Boot Actuator` to monitor retries in our application. After deploying the application, navigate to your site’s `/actuator` endpoint to see a list of Spring Boot Actuator endpoints. Navigate to `/actuator/retries` to see retried calls.
  
### Use the circuit-breaker pattern

You should pair the retry pattern with the circuit breaker pattern. The circuit breaker pattern handles faults that aren't transient. The goal is to prevent an application from repeatedly invoking a service that is clearly faulted. It releases the application and avoids wasting CPU cycles so the application retains its performance integrity for end users. For more information, see the [circuit breaker pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker).

## Security

Cloud applications benefit from using multiple Azure services, and communication between those services across compute nodes needs to be secure, and enforcing secure authentication, authorization, and accounting practices in your application is essential to health security posture. At this phase in the cloud journey, we recommend using managed identities, secrets management, and private endpoints. Here are the security recommendations for the reliable web app pattern.

### Use managed identities

You should use managed identities for all supported Azure services. They make identity management easier and more secure, providing benefits for authentication, authorization, and accounting.

**Authentication:** Managed identities provide an automatically managed identity in Azure AD for applications to use when connecting to resources that support Azure AD authentication. Applications can use managed identities to obtain Azure AD tokens without having to manage any credentials.

Managed identities are similar to connection strings in on-premises applications. On-premises apps use connection strings to secure communication to a database. Trusted connection and Integrated security features hide the database username and password from the config file. The application connects to the database with an Active Directory account. These are often referred to as service accounts because only the service could authenticate.

**Authorization:** Governing these actions is a key tenet of security. When granting access to a resource, we recommend that you always grant the least permissions needed. Using extra permissions when not needed gives attackers more opportunity to compromise the confidentiality, integrity, or the availability of your solution.

**Accounting:** Accounting in cybersecurity refers to the process of tracking and logging actions within an environment. With managed identities in Azure, you can gain better visibility into which supported Azure resources are accessing other resources and set appropriate permissions for each resource or service. While connection strings with secrets stored in Azure Key Vault can provide secure access to a resource, they do not offer the same level of accounting visibility. As a result, it can be more challenging to govern and control access using only connection strings.

Managed identities provide a secure and traceable way to control access to Azure resources. For more information, see:

- [Developer introduction and guidelines for credentials](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview-for-developers)
- [Managed identities for Azure resources](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)
- [Azure services supporting managed identities](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/managed-identities-status)
- [Web app managed identity](https://learn.microsoft.com/en-us/azure/active-directory/develop/multi-service-web-app-access-storage)

### Use a central secrets store

Not every service supports managed identities, so sometimes you have to use secrets. In these situations, you must externalize the application configurations and put the secrets in a central secret store. In Azure, the central secret store is Azure Key Vault.

Many on-premises environments don't have a central secrets store. The absence makes key rotation uncommon and auditing to see who has access to a secret difficult. However, with Key Vault you can store secrets, rotate keys, and audit key access. You can also enable monitor in Key Vault. For more information, see Monitoring Azure Key Vault.

*Reference implementation:* The reference implementation uses an Azure AD client secret stored in Key Vault. The secret verifies the identity of the web app. To rotate the secret, generate a new client secret and then save the new value to Key Vault. In the reference implementation, the web app must restart so the code will start using the new secret. After the web app has been restarted, the team can delete the previous client secret.

### Secure communication with private endpoints

You should use private endpoints to provide more secure communication between your web app and Azure services. By default, service communication to most Azure services traverses the public internet. These services include Azure Database for PostgreSQL and Azure App Service in the reference implementation. Azure Private Link allows you to secure communication with private endpoints in a virtual network and avoid the public internet.

This network security is transparent from the code perspective. It doesn't involve any app configuration, connection string, or code changes.

- [How to create a private endpoint](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/private-web-app/private-web-app#deploy-this-scenario)
- [Best practices for endpoint security](https://learn.microsoft.com/en-us/azure/architecture/framework/security/design-network-endpoints)

### Use a web application firewall

You should protect web applications with a web application firewall. The web application firewall provides a level protection against common security attacks and botnets. To take advantage of the value of the web application firewall, you have to prevent traffic from bypassing the web application firewall. In Azure, you should restrict access on the application platform (App Service) to only accept inbound communication from Azure Front Door.

*Reference implementation:* The reference implementation uses Front Door as the host name URL. In production, you should use your own host name and follow the guidance in [Preserve the original HTTP host name](https://learn.microsoft.com/en-us/azure/architecture/best-practices/host-name-preservation).

## Cost optimization

Cost optimization principles balance business goals with budget justification to create a cost-effective web application. Cost optimization is about reducing unnecessary expenses and improving operational efficiencies. For a web app converging on the cloud, here are our recommendations for cost optimization.

**Reference architecture:** Our app uses Azure Files integrated with App Service to save training videos that users upload. Refactoring this to use Azure Storage Blobs would reduce hosting costs and should be evaluated as part of future modernizations.

### Rightsize resources for each environment

Production environments need SKUs that meet the service level agreements (SLA), features, and scale needed for production. But non-production environments don't normally need the same capabilities. You can optimize costs in non-production environments by using cheaper SKUs that have lower capacity and SLAs. You should consider Azure Dev/Test pricing and Azure reservations. How or whether you use these cost-saving methods depends on your environment.

**Consider Azure Dev/Test pricing.** Azure Dev/Test pricing gives you access to select Azure services for non-production environments at discounted pricing under the Microsoft Customer Agreement. The plan reduces the costs of running and managing applications in development and testing environments, across a range of Microsoft products. For more information, see [Dev/Test pricing options](https://azure.microsoft.com/pricing/dev-test/#overview).

**Consider Azure reservations or an Azure savings plan.** You can combine an Azure savings plan with Azure reservations to optimize compute cost and flexibility. Azure reservations help you save by committing to one-year or three-year plans for multiple products. The Azure savings plan for compute is the most flexible savings plan. It generates savings on pay-as-you-go prices. Pick a one-year or three-year commitment for compute services, regardless of region, instance size, or operating system. Eligible compute services include virtual machines, dedicated hosts, container instances, Azure Functions Premium, and Azure app services. For more information, see:

- [Azure Reservations](https://learn.microsoft.com/azure/cost-management-billing/reservations/save-compute-costs-reservations)
- [Azure savings plans for compute](https://learn.microsoft.com/azure/cost-management-billing/savings-plan/savings-plan-compute-overview)

*Reference implementation:* The reference implementation has an optional parameter to deploy different SKUs. It uses cheaper SKUs for Azure Cache for Redis, App Service, and Azure PostgreSQL Flexible Server when deploying to the development environment. You can choose any SKUs that meet your needs, but the reference implementation uses the following SKUs:

| Service | Dev SKU | Prod SKU | SKU options |
| --- | --- | --- | --- |
| Cache for Redis | Basic | Standard | [Redis Cache SKU options](https://azure.microsoft.com/en-in/pricing/details/cache/)
| App Service | P1v2 | P2v2 | [App Service SKU options](https://azure.microsoft.com/en-us/pricing/details/app-service/linux/)
| PostgreSQL Flexible Server | Burstable B1ms (B_Standard_B1ms) | General Purpose D4s_v3 (GP_Standard_D4s_v3) | [PostgreSQL SKU options](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-compute-storage)

The following parameter tells the Terraform template the SKUs to select development SKUs. In `scripts/setup-initial-env.sh`, you can set `APP_ENVIRONMENT` to either be prod or dev.

```bash
# APP_ENVIRONMENT can either be prod or dev
export APP_ENVIRONMENT=dev
```

[See code in context](https://github.com/Azure/reliable-web-app-pattern-java/blob/main/scripts/setup-initial-env.sh)

The Terraform uses the `APP_ENVIRONMENT` as the `environment` value when deploying.

```shell
terraform -chdir=./terraform plan -var application_name=${APP_NAME} -var environment=${APP_ENVIRONMENT} -out airsonic.tfplan
```

### Automate scaling the environment

You should use autoscale to automate horizontal scaling for production environments. Autoscaling adapts to user demand to save you money. Horizontal scaling automatically increases compute capacity to meet user demand and decreases compute capacity when demand drops. Don't increase the size of your application platform (vertical scaling) to meet frequent changes in demand. It's less cost efficient. For more information, see:

- [Scaling in Azure App Service](https://learn.microsoft.com/azure/app-service/manage-scale-up)
- [Autoscale in Microsoft Azure](https://learn.microsoft.com/azure/azure-monitor/autoscale/autoscale-overview)

### Delete non-production environments

IaC is often considered an operational best practice, but it's also a way to manage costs. IaC can create and delete entire environments. You should delete non-production environments after hours or during holidays to optimize cost.

## Operational excellence

Organizations that move to cloud and apply a DevOps methodology see greater returns on investment. Infrastructure-as-code (IaC) is a key tenant of DevOps, and the reliable web app pattern uses IaC (Terraform) to deploy application infrastructure, configure services, and setup application telemetry. Monitoring operational health requires telemetry to measure security, cost, reliability, and performance gains. The cloud offers built-in features to capture telemetry, and when fed into a DevOps framework, they help rapidly improve your application. Here are the recommendations for operational excellence with the reliable web app pattern.

### Logging and application telemetry

You should enable logging to diagnose when any request fails for tracing and debugging. The telemetry you gather on your application should cater to the operational needs of the web application. At a minimum, you must collect telemetry on baseline metrics. Gather information on user behavior that can help you apply targeted improvements. Here are our recommendations for collecting application telemetry:

**Monitor baseline metrics.** The workload should monitor baseline metrics. Important metrics to measure include request throughput, average request duration, errors, and monitoring dependencies. We recommend using application Insights to gather this telemetry.

*Reference implementation:* The reference implementation uses the following code to enable Application Insights Java programmatically.

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

To enable the Java application to capture telemetry, see [Java in process agent](https://learn.microsoft.com/azure/azure-monitor/app/java-in-process-agent). For more information on configuring Application Insights in apps like our sample, see [Using Azure Monitor Application Insights with Spring Boot](https://learn.microsoft.com/azure/azure-monitor/app/java-spring-boot).

**Create custom telemetry as needed.** You should augment baseline metrics with information that helps you understand your users. You can use Application Insights to gather custom telemetry.

**Gather log-based metrics.** You should track log-based metrics to gain more visibility into essential application health and metrics. You can use [Kusto Query Language (KQL)](https://learn.microsoft.com/azure/data-explorer/kusto/query/) queries in Application Insights to find and organize data. You can run these queries in the portal. Under **Monitoring**, select **Logs** to run your queries. For more information, see:

- [Azure Application Insights log-based metrics](https://learn.microsoft.com/azure/azure-monitor/essentials/app-insights-metrics)
- [Log-based and pre-aggregated metrics in Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/pre-aggregated-metrics-log-metrics)

## Performance efficiency

Performance efficiency is the ability of a workload to scale and meet the demands placed on it by users in an efficient manner. In cloud environments, a workload should anticipate increases in demand to meet business requirements. You should use the cache-aside pattern to manage application data while improving performance and optimizing costs.

### Use the cache-aside pattern

The cache-aside pattern is a technique that's used to manage in-memory data caching. The cache-aside pattern makes the application responsible for managing data requests and data consistency between the cache and a persistent data store, like a database. When a data request reaches the application, the application first checks the cache to see if the cache has the data in memory. If it doesn't, the application queries the database, replies to the requester, and stores that data in the cache. For more information, see [Cache-aside pattern overview](https://learn.microsoft.com/azure/architecture/patterns/cache-aside).

The cache-aside pattern introduces a few benefits to the web application. It reduces the request response time and can lead to increased response throughput. This efficiency reduces the number of horizontal scaling events, making the app more capable of handling traffic bursts. It also improves service availability by reducing the load on the primary data store and decreasing the likelihood of service outages.

**Cache high-need data.** Most applications have pages that get more viewers than other pages. You should cache data that supports the most-viewed pages of your application to improve responsiveness for the end user and reduce demand on the database. You should use Azure Monitor and Azure SQL Analytics to track the CPU, memory, and storage of the database. You can use these metrics to determine whether you can use a smaller database SKU.

**Keep cache data fresh.** You should periodically refresh the data in the cache to keep it relevant. The process involves getting the latest version of the data from the database to ensure that the cache has the most requested data and the most current information. The goal is to ensure that users get current data fast. The frequency of the refreshes depends on the application.

**Ensure data consistency.** You need to change cached data whenever a user makes an update. An event-driven system can make these updates. Another option is to ensure that cached data is only accessed directly from the repository class that's responsible for handling the create and edit events.

### Deploy the reference implementation

You can deploy the reference implementation by following the instructions in the [reliable web app pattern for Java repository](README.md#steps-to-deploy-the-reference-implementation). Follow the deployment guide to set up a local development environment and deploy the solution to Azure.

## Next Steps

The following resources can help you learn cloud best practices and discover migration tools

### Cloud best practices

For Azure best practices, see:

- [Cloud Adoption Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/overview). Can help your organization prepare and execute a strategy to build solutions on Azure.
- [Well Architected Framework](https://learn.microsoft.com/azure/architecture/framework/). Describes the best practices and design principles that you should apply when you design Azure solutions that align with Microsoft-recommended best practices.
- [Azure architectures](https://learn.microsoft.com/azure/architecture/browse/). Provides architecture diagrams and technology descriptions for reference architectures, real-world examples of cloud architectures, and solution ideas for common workloads on Azure.
- [Azure Architecture Center fundamentals](https://learn.microsoft.com/azure/architecture/guide/). Provides a library of content that presents a structured approach for designing applications on Azure that are scalable, highly secure, resilient, and highly available.

### Migration guidance

The following tools and resources can help you migrate on-premises resources to Azure.

- [Azure Migrate](https://learn.microsoft.com/azure/migrate/migrate-services-overview) provides a simplified migration, modernization, and optimization service for Azure that handles assessment and migration of web apps, SQL Server, and virtual machines.
- [Azure Database Migration Guides](https://learn.microsoft.com/data-migration/) provides resources for different database types, and different tools designed for your migration scenario.
- [Azure App Service landing zone accelerator](https://learn.microsoft.com/azure/cloud-adoption-framework/scenarios/app-platform/app-services/landing-zone-accelerator) provides guidance for hardening and scaling App Service deployments.
