# Deploy Azure Infrastructure

## Open the project using the Dev Container

1. Start VS Code and run Dev Containers: Clone Repository in Container Volume... from the Command Palette (F1).

1. Select the repository *Azure/web-app-pattern-java* to clone and press Enter.

## Deploy the Azure Infrastructure

The following commands should be entered in the Visual Studio code terminal if running in the Dev Container.  If running locally, open a terminal and navigate to the root of the project.

### 1. Log in to Azure

Before deploying, you must be authenticated to Azure and have the appropriate subscription selected.  To authenticate:

```shell
az login --scope https://graph.microsoft.com//.default
azd auth login
```

Each command will open a browser allowing you to authenticate.  To list the subscriptions you have access to:

```shell
az account list
```

To set the active subscription:

```shell
export AZURE_SUBSCRIPTION="<your-subscription-id>"
az account set --subscription $AZURE_SUBSCRIPTION
azd config set defaults.subscription $AZURE_SUBSCRIPTION
```

### 2. Create a new environment

The environment name should be less than 18 characters and must be comprised of lower-case, numeric, and dash characters (for example, `eap-javarwa`).  The environment name is used for resource group naming and specific resource naming. Also, select a password for the admin user of the database.

Run the following commands to set these values and create a new environment:

```shell
azd config set alpha.terraform on
azd env new eap-javarwa
azd env set DATABASE_PASSWORD "AV@lidPa33word"
```

Substitute the environment name and database password for your own values.

By default, Azure resources are sized for a "development" mode. Set the `APP_ENVIRONMENT` to `prod` using the following code to deploy production SKUs:

```shell
azd env set APP_ENVIRONMENT prod
```

The following table lists the the development and production SKU differences.

| Service | Dev SKU | Prod SKU | SKU options |
| --- | --- | --- | --- |
| Cache for Redis | Basic | Standard | [Redis Cache SKU options](https://azure.microsoft.com/pricing/details/cache/) |
| App Service | P1v3 | P2v3 | [App Service SKU options](https://azure.microsoft.com/pricing/details/app-service/linux/) |
| PostgreSQL Flexible Server | Burstable B1ms (B_Standard_B1ms) | General Purpose D4s_v3 (GP_Standard_D4s_v3) | [PostgreSQL SKU options](https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-compute-storage) |

### 3. Select a region for deployment

The application can be deployed in either a single region or multi-region manner. You can find a list of available Azure regions by running the following Azure CLI command.

> ```shell
> az account list-locations --query "[].name" -o tsv
> ```

Set the `AZURE_LOCATION` to the primary region:

```shell
azd env set AZURE_LOCATION westus3
```

You want to make sure the region has availability zones. Azure Database for PostgreSQL - Flexible Server [zone-redundant high availability](https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-high-availability) requires availability zones.

If doing a multi-region deployment, set the `AZURE_LOCATION2` to the secondary region:

```shell
azd env set AZURE_LOCATION2 eastus
```

### 6. Provision infrastructure

Run the following command to create the infrastructure:

```shell
azd provision --no-prompt
```

### 7. Tear down infrastructure

Run the following command to tear down the infrastructure:

```shell
azd down
