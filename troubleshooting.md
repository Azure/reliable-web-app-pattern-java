# Troubleshooting
This document helps with troubleshooting RWA deployment challenges.

## Error: no project exists; to create a new project, run 'azd init'
This error is most often reported when users try to run `azd` commands before running the `cd` command to switch to the directory where the repo was cloned.

### Workaround

Verify that you are in the directory where the `azure.yaml` file is located. You may need to `cd` into the directory to proceed.

## BadRequest: Azure subscription is not registered with CDN Provider.
This error message surfaces from the `azd provision` command when trying to follow the guide to provision an Azure Front Door.

Most [Azure resource providers](https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-register-resource-provider) are registered automatically by the Microsoft Azure portal or the command-line interface, but not all. If you haven't used a particular resource provider before, you might need to register that provider.

**Full error message**
```
ERROR: deployment failed: error deploying infrastructure: failed deploying: deploying to subscription:

Deployment Error Details:
BadRequest: Azure subscription is not registered with CDN Provider.
```

### Workaround

1. Register the provider
    ```ps1
    az provider register --namespace Microsoft.Cdn
    ```

1. Wait for the registration process to complete (waited about 3-min)

1. Run the following to confirm the provider is registered
    ```ps1
    az provider list --query "[? namespace=='Microsoft.Cdn'].id"
    ```

    You should see a notice that the operation succeeded:
    ```
    [
    "/subscriptions/{subscriptionId}/providers/Microsoft.Cdn"
    ]
    ```
