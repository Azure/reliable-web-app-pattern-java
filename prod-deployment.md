# Steps to deploy the production deployment
This section describes the deployment steps for the reference implementation of a reliable web application pattern with .NET on Microsoft Azure. These steps guide you through using the jump host that is deployed when performing a network isolated deployment because access to resources will be restricted from public network access and must be performed from a machine connected to the vnet.

![Diagram showing the network focused architecture of the reference implementation.](./docs/icons/reliable-web-app-vnet.svg)

## Prerequisites

We recommend that you use a Dev Container to deploy this application.  The requirements are as follows:

- [Azure Subscription](https://azure.microsoft.com/pricing/member-offers/msdn-benefits-details/).
- [Visual Studio Code](https://code.visualstudio.com/).
- [Docker Desktop](https://www.docker.com/get-started/).
- [Permissions to register an application in Microsoft Entra ID](https://learn.microsoft.com/azure/active-directory/develop/quickstart-register-app).
- Visual Studio Code [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

If you do not wish to use a Dev Container, please refer to the [prerequisites](prerequisites.md) for detailed information on how to set up your development system to build, run, and deploy the application.

> **Note**
>
> These steps are used to connect to a Linux jump host where you can deploy the code. The jump host is not designed to be a build server. You should use a devOps pipeline to manage build agents and deploy code into the environment. Also note that for this content the jump host is a Linux VM. This can be swapped with a Windows VM based on your organization's requirements.

## Steps to deploy the reference implementation

The following detailed deployment steps assume you are using a Dev Container inside Visual Studio Code.

### 1. Log in to Azure


1. Start a terminal in the dev container:
    ```sh
    az login --scope https://graph.microsoft.com//.default
    ```

1. Set the subscription to the one you want to use (you can use [az account list]https://learn.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest) to list available subscriptions):


    ```sh
    export AZURE_SUBSCRIPTION_ID="<your-subscription-id>"
    ```

    ```sh
    az account set --subscription $AZURE_SUBSCRIPTION_ID
    ```

1. Azure Developer CLI (azd) has its own authentication context. Run the following command to authenticate to Azure:

To set the active subscription:

    ```sh
    azd auth login
    ```

1. To use Terraform as a provider, you need to enable the feature:

    ```sh
    azd config set alpha.terraform on
    ```

### 2. Provision the app

1. Create a new AZD environment to store your deployment configuration values:

    ```sh
    azd env new <pick_a_name>
    ```

1. Set the default subscription for the azd context:

    ```sh
    azd env set AZURE_SUBSCRIPTION_ID $AZURE_SUBSCRIPTION_ID
    ```

1. To create the prod deployment:

    ```pwsh
    azd env set ENVIRONMENT prod
    ```

1. Production is a multi-region deployment. Choose an Azure region for the primary deployment (Run `(Get-AzLocation).Location` to see a list of locations):

    ```pwsh
    azd env set AZURE_LOCATION <pick_a_region>
    ```

    *You want to make sure the region has availability zones. Azure Database for PostgreSQL - Flexible Server [zone-redundant high availability](https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-high-availability) requires availability zones.*

1. Choose an Azure region for the secondary deployment:

    ```pwsh
    azd env set AZURE_SECONDARY_LOCATION <pick_a_region>
    ```

    *We encourage readers to choose paired regions for multi-regional web apps. Paired regions typically offer low network latency, data residency in the same geography, and sequential updating. Read [Azure paired regions](https://learn.microsoft.com/en-us/azure/reliability/cross-region-replication-azure#azure-paired-regions) to learn more about these regions.*

1. The following are required values that must be set:

    - `JUMPBOX_PASSWORD` - This is the password for the jump box. The password has to fulfill 3 out of these 4 conditions: Has lower characters, Has upper characters, Has a digit, Has a special character other than "_"

    Run the following commands to set these values:

    ```shell
    azd env set JUMPBOX_PASSWORD <password>
    ```

1. Run the following command to create the Azure resources (about 45-minutes to provision):

    ```pwsh
    azd provision
    ```

    When successful the output of the deployment will be displayed in the terminal.

    ```md
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

### 3. Upload the code to the jump host


The output of the deployment will be displayed in the terminal.


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
