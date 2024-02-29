# Development Deployment

Login into Azure using the following command:

```shell
az login --scope https://graph.microsoft.com//.default
```

Login into AZD using the following command:

```shell
azd auth login
```

Set the environment variable to the subscription to be used:

```shell
export AZURE_SUBSCRIPTION_ID="<your-subscription-id>"
```

To set the active subscription to be used by Azure CLI, run the following command:

```shell
az account set --subscription $AZURE_SUBSCRIPTION_ID
```

Set the default subscription to be used by the Azure Developer CLI:

```shell
azd config set defaults.subscription $AZURE_SUBSCRIPTION_ID
```

Enable the Terraform Alpha provider:

```shell
azd config set alpha.terraform on
```

Create a new environment with a globally unique name using:

```shell
azd env new <pick_a_name>
```

Set the environment to 'dev' using:

```shell
azd env set ENVIRONMENT dev
```

Set the Azure region to be used:

```shell
azd env set AZURE_LOCATION <pick_a_region>
```

Telemetry collection is on by default.

To opt out, set the environment variable ENABLE_TELEMETRY to false.

```shell
azd env set ENABLE_TELEMETRY false
```

Now provision the infrastructure using:

```shell
azd up
```

You will see an output similar to the following:

```shell
Deploying services (azd deploy)

  (✓) Done: Deploying service application
  - Endpoint: https://fd-nickcams-dev-frcfgefndcctbgdh.z02.azurefd.net
```

Navigate to the Contoso Fiber App

Navigate to the Front Door URL in a browser to view the Contoso Fiber CAMS application. Use the Endpoint URL from the output of the deployment.

## Tear down the environment

When you are done you can cleanup all the resources using:

```shell
azd down --force --purge
```

