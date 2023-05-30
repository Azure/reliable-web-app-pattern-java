# GitHub Workflow Setup
This folder contains workflows that support the process of building the reliable web app pattern.

## Workflow Installation
There are several steps required to install the workflow. One of the challenges this approach
works around is the creation, and reuse, of an existing Azure AD app registration.

1. Create an Azure AD App Registration

    > ./scripts/devOpsScripts/reuseable-app-registrations.sh --console-out --app-name rwa-java-pipeline-test1

    **Outcome**

    You should now be able to browse to Azure AD and see an App Registration that was created
    for use when testing the Proseware web app. Save this data for later to be configured
    in GitHub settings.

1. Create a service principal for the workflow

    <!-- TODO: Explore GH Federated Credentials to replace client-secret -->
    > The following command produces a warning:
    >     https://github.com/Azure/azure-cli/issues/20743
    > 
    > Currently, this is still the recommended approach:
    >     https://github.com/azure/login#configure-a-service-principal-with-a-secret

    ```bash
    az ad sp create-for-rbac --name rwa-gh-java-spn --sdk-auth --role contributor \
    --scopes /subscriptions/{subscription_id}
    ```

    **Outcome**

    You have now created a service principal that GitHub can use to connect, and deploy, to an Azure subscription.
    Save this data for later to be configured in GitHub settings.

1. Give the ServicePrincipal access to assign Azure RBAC

    Start by finding the objectId (not the clientId) for the service principal

    Replace `clientId` with the value from the previous command:
    ```bash
    az ad sp show --id <clientId>
    ```

    Use the *id* property from the previous command to replace `service_principal_object_id`
    Set the *subscription_id* to the subscription where this Service Principal was granted **Contributor** access.

    > By default, this should be the subscription shown by `az account show`

    ```bash
    az role assignment create --assignee <service_principal_object_id> --role "User Access Administrator" --scope /subscriptions/<subscription_id>
    ```

    **Outcome**

    The GitHub Service Principal now has access to perform Azure role assignments on RBAC provisioned services. This means that we can encode Key Vault Access Permissions (RBAC permissions) from infrastructure-as-code to give the managed identities (the web app's identity) access to read data from Key Vault.


  1. Set workflow variables & secrets in GitHub:

        *Secrets*

        |Name                       |Value                |
        |---------------------------|---------------------|
        |AZURE_CLIENT_SECRET        | (TEXT FROM CONSOLE) |
        |AZURE_CREDENTIALS          | (TEXT FROM CONSOLE) |
        |AZURE_CLIENT_SECRET        | (TEXT FROM CONSOLE) |

        > Paste all of the json from the previous command into the textarea as
         the value for the AZURE_CREDENTIALS secret.

        *Variables*

        |Name                       |Value                |
        |---------------------------|---------------------|
        |AZURE_APP_NAME             | rwajavaghpipeline   |
        |AZURE_CLIENT_ID            | (GUID FROM CONSOLE) |
        |AZURE_LOCATION             | australiaeast       |
        |AZURE_TENANT_ID            | (GUID FROM CONSOLE) |
        |POSTGRES_DATABASE_PASSWORD | SUPER-sonic4114!    |

        **Outcome**

        The workflow is now ready to run.

## Workflow Overview
There are three workflows:
- build-and-deploy.yml: a terraform based workflow that builds a war file artifact
- scheduled-azure-build-and-deploy.yml: a terraform flow executed through AZD as a reader would execute this guide
- scheduled-azure-teardown.yml: a clean up workflow to manage costs and remove failed deployments

### build-and-deploy.yml

This TerraForm workflow deployment is meant as a starter template to help readers with devOps
deployments of this content.

The starter template is not currently complete and includes some remaining tasks that must
be addressed before it can be applied in a dev environment:

1. The tfplan file must be persisted so that infrastructure can be managed by Terraform
1. The database should not be managed by the code, it should be managed by a database lifecylce process that manages schema changes as scripts that are under source control and reviewed by your database administrator to prevent any data loss as columns change.
1. The war file packaged, and created by the pipeline, should support web app startup.
