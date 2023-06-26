# Proseware Failover playbook

One of Proseware's business objectives was to operate a system that is available 99.9% of the time. To meet that objective the team deploys the web app to two regions with active/passive configuration. In this setup 100% of use traffic is handled by a single region and data is replicated to a secondary region. This enables Proseware to quickly transition from the primary region to the secondary to mitigate the risk of an outage from impacting their availability.

To transition from the primary region Proseware built the following plan that is executed manually. Health checks and automated transition are not part of the plan in this phase.

## Understaning the Proseware system
Before we execute the failover plan we should understand the system and how it is used. Proseware is an Azure web application that provides streaming video training content. The solution architecture includes Azure App Service, Azure Storage (mounted as File Storage on App Service), Application Insights, Key Vault, Azure Cache for Redis, and Azure Database for Postgresql. These components are vnet integrated and secured with private endpoints. Users authenticate with Azure AD and diagnostics for Azure services are stored in Azure Log Analytics Workspace.

<!-- todo: assumes Application Gateway -->
The system is also placed behind an Azure Traffic Manager and Application Gateway with Azure Web Application Firewall enabled. This provides an active/passive load balancing capability between 1 instance of the application and another that provides high availability. The secondary region is a standby region that receives replicated data from the primary region.

<!-- todo: assumes Application Gateway -->
![Diagram showing the architecture of the reference implementation](docs/assets/reliable-web-app-java.png)

In this system we have data stored in different places and each one of those should be handled by the failover.

1. Videos on disk: Proseware training videos are stored in Azure Storage
1. User data: Data for users is handled with RDBMS with PostgreSQL and cached in Redis
1. System settings: Configuration in Key Vault, and other environment settings
1. Monitoring: Diagnostic data stored in Log Analytics and Application Insights

For this plan, Proseware chooses only to address the first two considerations. When traffic is transitioned from primary to secondary region we expect users to continue where they left off with minimal impact to their experience. To support this goal we need to replicae data for Azure Storage and Azure Database for PostgreSQL. Diagnostic data in Log Analytics and Application Insights are not replicated. This approach is also designed to rebuild any information that was stored in Redis as traffic is migrated to the new region.

## Executing the transition
Use the following steps to transition users from primary to secondary region. At this point, the decision to failover has been made. Interruption of services and the risk of potential data-loss has been communicated to users.

> **Note**<br>
> The following content describes failover by region name because the meaning of "primary" is adjusted throughout the context of the plan. *eastus* is primary and *westus* is secondary.

The two flows of traffic we will address are:
* User traffic: dashed blue line
* Data replication: solid green line

![Diagram showing the simplified architecture for failover](docs/assets/failover-part1.png)

<!-- todo: assumes Traffic Manager -->
### Cut-off traffic to the *eastus* region

We want to inform users about the outage and stop traffic flowing to *eastus* while we peform maintenance on the system.

1. Create a new Azure App Service
    1. Deploy an informational maintenance page to the new App Service
1. Update traffic manager endpoint
    1. Change the target resource for the endpoint so that it points to the Azure App Service Maintenance page <br />
    Additional details:
    - [Add Traffic Manager endpoints](https://learn.microsoft.com/azure/traffic-manager/quickstart-create-traffic-manager-profile#add-traffic-manager-endpoints)

With these changes complete, the simplified Proseware multi-region solution is adjusted as shown. Traffic Manager no longer sends data to the *eastus* region.

![Diagram showing the change resulting from part 1](docs/assets/failover-part1-complete.png)

### Stop data replication to *westus*

We want to disconnect the solid green arrow in this step of the failover. In this simplified representation, the line represents two types of data (Azure Files and Database replication).

1. Initiate storage account failover
    <!-- intentially omitting Last Sync Time as data loss is expected to be handled by re-uploading any training videos that were uploaded -->
    
    ```sh
    az storage account show --name <accountName> --expand geoReplicationStats
    az storage account failover --name <accountName>
    ```

    > **Note**<br>
    > This operation will take several minutes to complete. <br>
    > After the failover, your storage account type is automatically converted to locally redundant storage (LRS) in the new primary region.

    Additional details:
    - [Initiate a storage account failover](https://learn.microsoft.com/azure/storage/common/storage-initiate-account-failover)

1. Stop replication for Azure Database for PostgreSQL

    > **Note**<br>
    > After you stop replication to a primary server and a read replica, it can't be undone. The read replica becomes a standalone server that supports both reads and writes. The standalone server can't be made into a replica again.

    ```sh
    az postgres server replica stop --name <mydemoserver-replica> --resource-group <myresourcegroup>
    ```

    Additional details:
    - [Manage read replicas - Azure portal - Azure Database for PostgreSQL - Single Server](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal#stop-replication)
    - [Manage read replicas - Azure CLI, REST API - Azure Database for PostgreSQL - Single Server](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-cli#stop-replication-to-a-replica-server)

With these changes complete, the simplified Proseware multi-region solution is adjusted as shown. The solid green arrow for data replication is removed. Both *eastus* and *westus* are stand-alone copies of the production web app and we have prepared *westus* to become the primary region.

![Diagram showing the change resulting from part 2](docs/assets/failover-part2-complete.png)

<!-- todo -->
### WIP: Update web app configuration
1. Update Key Vault connection string for PostgreSQL database
1. Restart the web app

<!-- todo -->
### WIP: Validate the *westus* traffic
Todo describe the recommendation for the *westus* region to be tested before we send traffic

### WIP: Send traffic to *westus*
<!-- todo: recommending a phased rollout requires feature support -->
Todo describe traffic manager changes. 

### Restore Data Replication to *eastus*

We want to modify the solid green arrow in this step of the failover. In this simplified representation, the line represents two types of data (Azure Files and Database replication).

1. Change the replication type to geo-redundant to replicate data to the secondary region:
    ```sh
    az storage account update --name <storage_account_name> --resource-group <resource_group_name> --sku Standard_GRS
    ```

    Initiating replication will take varying time to complete based on the data being replicated. You can monitor the status of the of the replication type change by running the following:

    ```sh
    az storage account show --name <storage_account_name> --resource-group <resource_group_name> --query "provisioningState"
    ```

    Additional details:
    - [Replication change table](https://learn.microsoft.com/en-us/azure/storage/common/redundancy-migration?tabs=portal#replication-change-table)

1. Create a read replica for Azure Database for PostgreSQL

    > **Note**<br>
    > After you stop replication to a primary server and a read replica, it can't be undone. The read replica becomes a standalone server that supports both reads and writes. The standalone server can't be made into a replica again.

    ```sh
    az postgres server replica create --name <mydemoserver-replica> --source-server <mydemoserver> --resource-group <myresourcegroup> --location <eastus>
    ```

    Additional details:
    - [Manage read replicas - Azure portal - Azure Database for PostgreSQL - Single Server](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal#stop-replication)
    - [Manage read replicas - Azure CLI, REST API - Azure Database for PostgreSQL - Single Server](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-cli#stop-replication-to-a-replica-server)

## Failback
Using the steps described above Proseware plans to migrate their traffic from *westus* back to *eastus* when possible as latency in the web app is a primary concern for thier users.
