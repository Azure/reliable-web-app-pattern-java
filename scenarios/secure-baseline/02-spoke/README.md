# Java Web App - App Service Secure Baseline Spoke

In the previous step, we deployed the [hub](../01-hub/README.md).  Now we're going to deploy the spoke.  The spoke will be connected to the hub via a VNet peering.  The spoke will be configured with private endpoints and private DNS zones for things like databases.

## Deploy the Spoke

The following commands should be entered in the Visual Studio code terminal if running in the Dev Container.  If running locally, open a terminal and navigate to the `scenarios/secure-baseline/02-spoke` directory.

```bash
cd $PROJECT_ROOT/scenarios/secure-baseline/02-spoke
```

### 1. Log in to Azure

Before deploying, you must be authenticated to Azure and have the appropriate subscription selected.  To authenticate, follow the instructions [here](../README.md#1-log-in-to-azure)

### 2. Create a new environment

The environment name should be less than 18 characters and must be comprised of lower-case, numeric, and dash characters (for example, `contosospoke`).  The environment name is used for resource group naming and specific resource naming. 

**Choose a unique name for the environment**

Run the following commands to set these values and create a new environment:

```shell
azd env new contosospoke
```

### 3. Set the AZD Environment Values

The following are required values that must be set:

- `HUB_VNET_ID` - This is the resource ID of the hub VNet.

Run the following commands to set these values:

```shell
azd env set HUB_VNET_ID $hub_vnet_id
```

Optionally, you can update the following values:

- `APP_ENVIRONMENT` - The name of the environment.  This value is used for resource group naming and choosing service SKUs.  The default value is `dev`. Valid values are `dev` and `prod`.

```shell
azd env set APP_ENVIRONMENT prod
```

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

### 6. Set the environment variables for the next step

The output of the deployment will be displayed in the terminal.

```
Outputs:

spoke_subnet_ids = [
  "/subscriptions/<id>/resourceGroups/rg-contosospoke7-dev/providers/Microsoft.Network/virtualNetworks/spoke-vnet-contosospoke7-dev/subnets/serverFarm",
  "/subscriptions/<id>/resourceGroups/rg-contosospoke7-dev/providers/Microsoft.Network/virtualNetworks/spoke-vnet-contosospoke7-dev/subnets/ingress",
  "/subscriptions/<id>/resourceGroups/rg-contosospoke7-dev/providers/Microsoft.Network/virtualNetworks/spoke-vnet-contosospoke7-dev/subnets/privateLink",
  "/subscriptions/<id>/resourceGroups/rg-contosospoke7-dev/providers/Microsoft.Network/virtualNetworks/spoke-vnet-contosospoke7-dev/subnets/fs",
]
```

To bring the environment variables into the current shell, run the following command:

```shell
source $(azd env list --output json | jq -r '.[] | select(.IsDefault == true) | .DotEnvPath')
```

**This step is required in order to run the next steps of the deployment.**

Verify the environment is set by testing one of the variables:

```shell
echo $spoke_vnet_id
```

### 7. Deploy the services

Change to the services directory and follow the instructions in the [README](../03-services/README.md).

```shell
cd ../03-services
```

