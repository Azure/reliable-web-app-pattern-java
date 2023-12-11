# Java Web App - App Service Secure Baseline Serivces

In the previous step, we deployed the [spoke](../02-spoke/README.md) and now we're ready to deploy the Contoso Fiber. However, before we deploy the application, we're going to first deploy the following resources.

- Azure PostgreSQL Flexible Database
- Azure Redis Cache
- Private Link for each, including related DNS Private Zone configuration
- User managed identities for the workload

## Deploy the Services

The following commands should be entered in the Visual Studio code terminal if running in the Dev Container.  If running locally, open a terminal and navigate to the `scenarios/secure-baseline/03-services` directory.

```bash
cd scenarios/secure-baseline/03-services
```

### 1. Log in to Azure

Before deploying, you must be authenticated to Azure and have the appropriate subscription selected.  To authenticate, follow the instructions [here](../README.md#1-log-in-to-azure)

### 2. Create a new environment

The environment name should be less than 18 characters and must be comprised of lower-case, numeric, and dash characters (for example, `contososervices`).  The environment name is used for resource group naming and specific resource naming. Also, select a password for the admin user of the database.

Run the following commands to set these values and create a new environment:

```shell
azd env new contososervices
```

### 3. Update Terraform Values

Update the `terraform.tfvars` file with the following values:

- `app_insights_id` - The resource ID of the Application Insights instance created in the hub.
- `log_analytics_workspace_id` - The resource ID of the Log Analytics workspace created in the hub.
- `key_vault_id` - The resource ID of the Key Vault created in the hub.
- `spoke_vnet_id` - The resource ID of the spoke VNet created in the spoke.

Optionally, you can update the `terraform.tfvars` file with the following values:

- `environment` - The name of the environment.  This value is used for resource group naming and choosing service SKUs.  The default value is `dev`.

### 4. Select a region for deployment

You can find a list of available Azure regions by running the following Azure CLI command.

> ```shell
> az account list-locations --query "[].name" -o tsv
> ```

Set the `AZURE_LOCATION` to the primary region:

```shell
azd env set AZURE_LOCATION eastus
```

### 5. Provision infrastructure

Run the following command to create the infrastructure and deploy the app:

```shell
azd up
```
