# Java Web App - App Service Secure Baseline Spoke

In the previous step, we deployed the [hub](../01-hub/README.md).  Now we're going to deploy the spoke.  The spoke will be connected to the hub via a VNet peering.  The spoke will be configured with private endpoints and private DNS zones for things like databases.

## Deploy the Spoke

The following commands should be entered in the Visual Studio code terminal if running in the Dev Container.  If running locally, open a terminal and navigate to the `scenarios/secure-baseline/02-spoke` directory.

```bash
cd scenarios/secure-baseline/02-spoke
```

### 1. Log in to Azure

Before deploying, you must be authenticated to Azure and have the appropriate subscription selected.  To authenticate, follow the instructions [here](../README.md#1-log-in-to-azure)

### 2. Create a new environment

The environment name should be less than 18 characters and must be comprised of lower-case, numeric, and dash characters (for example, `contosospoke`).  The environment name is used for resource group naming and specific resource naming. Also, select a password for the admin user of the database.

Run the following commands to set these values and create a new environment:

```shell
azd env new contosospoke
```

### 3. Update Terraform Values

Update the `terraform.tfvars` file with the following values:

- `hub_vnet_id` - This is the id of the hub vnet created in the previous step (for example, `"/subscriptions/1234/resourceGroups/rg-contosohub-dev/providers/Microsoft.Network/virtualNetworks/hub-vnet-contosohub-dev"`).

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
### 6. Record the output

The output of the deployment will be displayed in the terminal.  Record the following values for use in the next step:

```
Outputs:

spoke_subnet_ids = [
  "/subscriptions/<id>/resourceGroups/rg-contosospoke7-dev/providers/Microsoft.Network/virtualNetworks/spoke-vnet-contosospoke7-dev/subnets/serverFarm",
  "/subscriptions/<id>/resourceGroups/rg-contosospoke7-dev/providers/Microsoft.Network/virtualNetworks/spoke-vnet-contosospoke7-dev/subnets/ingress",
  "/subscriptions/<id>/resourceGroups/rg-contosospoke7-dev/providers/Microsoft.Network/virtualNetworks/spoke-vnet-contosospoke7-dev/subnets/privateLink",
  "/subscriptions/<id>/resourceGroups/rg-contosospoke7-dev/providers/Microsoft.Network/virtualNetworks/spoke-vnet-contosospoke7-dev/subnets/fs",
]
```
