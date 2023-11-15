# Java Web App - App Service Secure Baseline Hub

This is the first step to deploy a network isolated Azure environment for the [Contoso Fiber Java Web App](../README.md).  This hub will be the egress point for all traffic in connected spokes.

## Deploy the Hub

The following commands should be entered in the Visual Studio code terminal if running in the Dev Container.  If running locally, open a terminal and navigate to the `scenarios/secure-baseline/01-hub` directory.

```bash
cd scenarios/secure-baseline/01-hub
```

### 1. Log in to Azure

Before deploying, you must be authenticated to Azure and have the appropriate subscription selected.  To authenticate, follow the instructions [here](../README.md#1-log-in-to-azure)

### 2. Create a new environment

The environment name should be less than 18 characters and must be comprised of lower-case, numeric, and dash characters (for example, `contoso-hub`).  The environment name is used for resource group naming and specific resource naming. Also, select a password for the admin user of the database.

Run the following commands to set these values and create a new environment:

```shell
azd env new contoso-hub
```

### 3. Select a region for deployment

You can find a list of available Azure regions by running the following Azure CLI command.

> ```shell
> az account list-locations --query "[].name" -o tsv
> ```

Set the `AZURE_LOCATION` to the primary region:

```shell
azd env set AZURE_LOCATION westus3
```

### 4. Provision infrastructure

Run the following command to create the infrastructure and deploy the app:

```shell
azd up
```
