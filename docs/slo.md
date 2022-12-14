# Resulting service level and cost

Acme's solution has a 99.78% availability SLO.

## Service Level Objective

Acme uses multiple Azure Services to achieve a composite availability SLO of 99.78%.

To calculate this, they reviewed their business scenario and defined that the system is considered *available* when internal customers can view the training material. This means that we can determine the solution's availability by finding the availability of the Azure services that must be functioning to view the training material.

> This also means that the team *does not* consider Azure Monitor a part of their scope
> for an available web app. This means the team accepts that the web app might miss an alert
> or scaling event if there is an issue with Azure Monitor. If this were unacceptable
> then the team would have to add that as an additional Azure service for their availability
> calculations.

The next step to calculate the availability was to identify the SLA of the services that must each be available to view the training material.

| Azure Service | SLA |
| --- | --- |
| [Azure App Service](https://azure.microsoft.com/support/legal/sla/app-service/) | 99.95% |
| [Azure Active Directory](https://azure.microsoft.com/support/legal/sla/active-directory/v1_1/) | 99.99% |
| [Azure Private Link](https://azure.microsoft.com/support/legal/sla/private-link/v1_0/) | 99.99%|
| [Azure Storage Accounts](https://azure.microsoft.com/support/legal/sla/storage/v1_5/) |  99.9% |
| [Azure Database for PostgreSQL](https://azure.microsoft.com/en-us/support/legal/sla/postgresql/v1_4/) |  99.95% |

To find the impact that one of these services has to our availability [we multiply each of these SLAs](https://learn.microsoft.com/en-us/azure/architecture/framework/resiliency/business-metrics#composite-slas).
By combining the numbers we reach the percentage of time that all services are available.

When combined the SLAs assert that training material can be viewed 99.78% of the time. This availability meant there could be as much as 20 hours of downtime in a year.
