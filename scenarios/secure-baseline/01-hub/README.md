# Java Web App - App Service Secure Baseline Hub

This is the first step to deploy a network isolated Azure environment for the [Contoso Fiber Java Web App](../README.md).  This hub will be the egress point for all traffic in connected spokes.

## Deploy the Hub

The following commands should be entered in the Visual Studio code terminal if running in the Dev Container.  If running locally, open a terminal and navigate to the `scenarios/secure-baseline/01-hub` directory.

```bash
cd $PROJECT_ROOT/scenarios/secure-baseline/01-hub
```

### 1. Log in to Azure

Before deploying, you must be authenticated to Azure and have the appropriate subscription selected.  To authenticate, follow the instructions [here](../README.md#1-log-in-to-azure)

### 2. Create a new environment

The environment name should be less than 18 characters and must be comprised of lower-case, numeric, and dash characters (for example, `contosohub`).  The environment name is used for resource group naming and specific resource naming. 

**Choose a unique name for the environment**

Run the following commands to set these values and create a new environment:

```shell
azd env new contosohub
```

### 3. Set the AZD Environment Values

The following are required values that must be set:

- `JUMPBOX_PASSWORD` - This is the password for the jump box. The password has to fulfill 3 out of these 4 conditions: Has lower characters, Has upper characters, Has a digit, Has a special character other than "_"

Run the following commands to set these values:

```shell
azd env set JUMPBOX_PASSWORD <password>
```

The following are optional values that can be set:

- `JUMPBOX_USERNAME` - This is the username for the jump box.  The default is `azureuser`.
- `JUMPBOX_VM_SIZE` - This is the size of the jump box VM.  The default is `Standard_B2s`.
- `DEPLOY_BASTION` - This will deploy a bastion host in the hub.  The default is `true`.
- `DEPLOY_JUMPBOX` - This will deploy a jump box in the hub.  The default is `true`.

These values can be set by running the following commands:

```shell
azd env set <variable> <value>
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

hub_resource_group = "rg-contosohub-dev"

hub_vnet_id = "/subscriptions/<id>/resourceGroups/rg-contosohub-dev/providers/Microsoft.Network/virtualNetworks/hub-vnet-contosohub-dev"

hub_vnet_name = "hub-vnet-contosohub-dev"
```

To bring the environment variables into the current shell, run the following command:

```shell
source $(azd env list --output json | jq -r '.[] | select(.IsDefault == true) | .DotEnvPath')
```

**This step is required in order to run the next steps of the deployment.**

Verify the environment is set by testing one of the variables:

```shell
echo $hub_vnet_id
```

### 7. Deploy the spoke

Change to the spoke directory and follow the instructions in the [README](../02-spoke/README.md).

```shell
cd ../02-spoke
```
