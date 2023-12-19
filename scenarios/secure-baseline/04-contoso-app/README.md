# Java Web App - App Service Secure Baseline Contoso App

In the previous step, we deployed the [services](../03-services/README.md) and now we're ready to deploy the Contoso Fiber Application to Azure App Service. 

## Deploy the Contoso Fiber App

The following commands should be entered in the Visual Studio code terminal if running in the Dev Container.  If running locally, open a terminal and navigate to the `src/contoso-fiber` directory.

```bash
cd src/contoso-fiber
```

### 1. Log in to Azure

Before deploying, you must be authenticated to Azure and have the appropriate subscription selected.  To authenticate, follow the instructions [here](../README.md#1-log-in-to-azure)

### 2. Build Contoso Fiber

Run the following command to build the Contoso Fiber application:

```shell
mvn clean package
```

This will create the `jar` file cams-0.0.1-SNAPSHOT.jar in the `target` directory. This file will be used to deploy the application to Azure App Service.

### 3. Deploy Contoso Fiber to Azure App Service

We can use the Azure CLI to deploy the Contoso Fiber application to Azure App Service. The following command will deploy the application to the `app-contosserv7-eastus-dev` App Service instance in the `rg-contosospoke7-dev` resource group.  The `app-contosserv7-eastus-dev` App Service instance was created in the [spoke](../03-services/README.md#6-record-the-output).

```shell
az webapp deploy --name contoso-fiber --resource-group rg-contosospoke7-dev --name app-contosserv7-eastus-dev --src-path target/cams-0.0.1-SNAPSHOT.jar --type jar
```

### 4. Navigate to the Contoso Fiber App

We deployed `Azure Front Door` in the previous step. The Front Door URL was displayed in the output of the [services deployment](../03-services/README.md#6-record-the-output) .  Navigate to the Front Door URL in a browser to view the Contoso Fiber application.
