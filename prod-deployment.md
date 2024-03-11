# Production Deployment

After starting the Dev Container, open a terminal in Visual Studio Code.

You must first be authenticated to Azure and have the appropriate subscription selected.  To authenticate:

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
export AZURE_SUBSCRIPTION_ID="<your-subscription-id>"

az account set --subscription $AZURE_SUBSCRIPTION_ID

azd config set defaults.subscription $AZURE_SUBSCRIPTION_ID
```

Enable the Terraform Alpha provider:

```shell
azd config set alpha.terraform on
```

## Create a new environment

The environment name should be less than 18 characters and must be comprised of lower-case, numeric, and dash characters (for example, `contosocams`).  The environment name is used for resource group naming and specific resource naming. 

**Choose a unique name for the environment**

Run the following commands to set these values and create a new environment:

```shell
azd env new <pick_a_name>
```

>By default, Azure resources are sized for a "development" mode. If doing a Production deployment, see the [prod Deployment](./README-prod.md) instructions for more detail.

## Set the AZD Environment Values

Set the environment to 'prod' using:

```shell
azd env set ENVIRONMENT prod
```

The following are required values that must be set:

- `JUMPBOX_PASSWORD` - This is the password for the jump box. The password has to fulfill 3 out of these 4 conditions: Has lower characters, Has upper characters, Has a digit, Has a special character other than "_"

Run the following commands to set these values:

```shell
azd env set JUMPBOX_PASSWORD <password>
```

The following are optional values that can be set:

- `JUMPBOX_USERNAME` - This is the username for the jump box.  The default is `azureuser`.
- `JUMPBOX_VM_SIZE` - This is the size of the jump box VM.  The default is `Standard_B2s`.

These values can be set by running the following commands:

```shell
azd env set <variable> <value>
```

## Select a region for deployment

The application can be deployed in either a single region or multi-region manner. PROD deployments are multi-region. You can find a list of available Azure regions by running the following Azure CLI command.

> ```shell
> az account list-locations --query "[].name" -o tsv
> ```

Set the `AZURE_LOCATION` to the primary region:

```shell
azd env set AZURE_LOCATION <pick_a_region>
```

You want to make sure the region has availability zones. Azure Database for PostgreSQL - Flexible Server [zone-redundant high availability](https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-high-availability) requires availability zones.

Make sure the secondary region is a paired region with the primary region (`AZURE_LOCATION`). For a full list of region pairs, see [Azure region pairs](https://learn.microsoft.com/azure/reliability/cross-region-replication-azure#azure-cross-region-replication-pairings-for-all-geographies). We have validated the following paired regions.

 Set the `AZURE_SECONDARY_LOCATION` to the secondary region:

```shell
azd env set AZURE_SECONDARY_LOCATION <pick_a_region>
```

## Telemetry

Telemetry collection is on by default.

To opt out, set the environment variable ENABLE_TELEMETRY to false.

```shell
azd env set ENABLE_TELEMETRY false
```

## Provision infrastructure

Run the following command to create the infrastructure and deploy the app:

```shell
azd provision
```

The output of the deployment will be displayed in the terminal.

```
Outputs:

bastion_host_name = "vnet-bast-nickcontosocams-prod"
frontdoor_url = "https://fd-nickcontosocams-prod-facscqd0a2gqf2eh.z02.azurefd.net"
hub_resource_group = "rg-nickcontosocams-hub-prod"
jumpbox_resource_id = "/subscriptions/1234/resourceGroups/rg-nickcontosocams-hub-prod/providers/Microsoft.Compute/virtualMachines/vm-jumpbox"
primary_app_service_name = "app-nickcontosocams-eastus-prod"
primary_spoke_resource_group = "rg-nickcontosocams-spoke-prod"
secondary_app_service_name = "app-nickcontosocams-centralus-prod"
secondary_spoke_resource_group = "rg-nickcontosocams-spoke2-prod"
```

> **Record the output. The values are required in order to run the next steps of the deployment.**

## Build Contoso Fiber CAMS

Run the following command to build the Contoso Fiber application:

```shell
./mvnw clean package
```

This will create the `jar` file cams-0.0.1-SNAPSHOT.jar in the `target` directory. This file will be used to deploy the application to Azure App Service.

## Deploy the Contoso Fiber App

Create the SSH tunnel to the jumpbox using a SEPARATE terminal:

```shell
az network bastion tunnel --name <bastion_name> --resource-group <hub_resource_group> --target-resource-id <jumpbox_resource_id> --resource-port 22 --port 50022
```

Copy the JAR file to the jumpbox using:

```shell
scp -P 50022 -r src/contoso-fiber/target/*.jar azureuser@localhost:/home/azureuser
```

Login into the jumpbox with the jumpbox password using:

```shell
ssh -p 50022 azureuser@localhost
```

Login into Azure using:

```shell
az login --use-device-code
```
Set the subscription id:

```shell
az account set --subscription <subscription_id>
```

Deploy the application to the primary region using:

```shell
az webapp deploy --resource-group <primary_spoke_resource_group> --name <primary_app_service_name> --src-path cams.jar --type jar
```

Deploy the application to the secondary region using:

```shell
az webapp deploy --resource-group <secondary_spoke_resource_group> --name <secondary_app_service_name> --src-path cams.jar --type jar
```

Exit the jumpbox using:

```shell
  exit
```

Close the tunnel in the SEPARATE terminal using:

```shell
  CTRL+C
```

## Navigate to the Contoso Fiber App

Navigate to the Front Door URL in a browser to view the Contoso Fiber CAMS application.

## Tear down the environment

When you are done you can cleanup all the resources using:

```shell
azd down --force --purge
```
