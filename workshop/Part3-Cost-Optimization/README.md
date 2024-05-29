
# Cost Optimization

## Introduction

Optimizing costs in environments is a continuous process that requires regular review and adjustment of resources. By analyzing costs, identifying cost reduction opportunities, implementing cost reduction measures, and reviewing their impact, you can ensure that you're not overspending on your environments.

In Part 0, we introduced the cache-aside pattern with the Caffeine library to enhance performance. In this section on Cost Optimization, we explore how adjusting cache settings and choosing cost-effective resources can significantly reduce operational costs while maintaining performance. This practical application of caching not only optimizes response times but also efficiently manages resource costs by reducing the need for more expensive compute resources.

However, its non-production environments do not need the same capabilities. Here, we explore how to optimize costs in non-production environments by using cheaper SKUs with lower capacity and SLAs.

The reference example uses the same infrastructure-as-code (IaC) templates for both the development and production deployments. The only difference is a few SKU variations to optimize costs in the development environment. The option exists to use cheaper SKUs in the development environment for Azure Cache for Redis, App Service, and Azure Database for PostgreSQL Flexible Server. The following table shows the services and the SKUs selected for each environment.

*Table 1. Reference implementation SKU differences between the development and production environments.*

| Service                                         | Development Environment SKU               | Production Environment SKU                   | Additional Configuration in Production             |
| ---------------------------------------------   | ----------------------------------------- | ------------------------------------------   | ------------------------------------------------- |
| Azure Cache for Redis                           | Basic                                     | Standard                                    | -                                                 |
| App Service                                     | P1v3                                      | P2v3                                        | -                                                 |
| Azure Database for PostgreSQL - Flexible Server | B_Standard_B1ms (Burstable)                | Not explicitly specified                     | High Availability (ZoneRedundant, Standby Zone 2) |

> ## Note: Deploying Production SKUs
> 
> As this workshop uses a single region, the instructions do not cover deploying production SKUs. However, you can deploy production SKUs by following the instructions in the Reference example by setting the environment `ENVIRONMENT` to `prod`.
> 
> ```shell
> azd env set ENVIRONMENT prod
> ```
> 
> Also, the default deployment is single region. For multi-region, set `AZURE_SECONDARY_LOCATION` as per instructions.
> 
> ```shell
> azd env set AZURE_SECONDARY_LOCATION eastus
> ```

## Autoscaling

Autoscaling is configured for both development and production environments in the Azure App Service, ensuring efficient resource management based on workload. This dynamic scaling helps maintain optimal performance and manage costs effectively by adjusting the number of instances according to CPU usage.

### Autoscaling Settings

| Setting                | Development       | Production        |
| ---------------------- | ----------------- | ----------------- |
| **Default Instances**  | 1                 | 2                 |
| **Minimum Instances**  | 1                 | 2                 |
| **Maximum Instances**  | 10                | 10                |
| **Scale Up Trigger**   | CPU > 85%         | CPU > 85%         |
| **Scale Down Trigger** | CPU < 65%         | CPU < 65%         |

This configuration allows the service to scale up by adding an instance when the CPU usage exceeds 85% and scale down by removing an instance when the CPU usage drops below 65%. This ensures that resources are available during high demand and conserved during lower usage, optimizing both performance and cost.

## Next Up

Next, we will explore the concept of reliability in cloud applications. Please proceed to [Part 4 - Reliability](../Part4-Reliability/README.md) for more information.

## Resources
[Well-Architected Framework cost optimization portal](https://learn.microsoft.com/azure/well-architected/cost-optimization)

[Azure Cost Calculator](https://azure.microsoft.com/pricing/calculator)

