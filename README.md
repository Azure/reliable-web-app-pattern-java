# Reliable web app pattern for Java

This reference implementation provides a production-grade web application that uses best practices from our guidance and gives developers concrete examples to build their own Reliable Web Application in Azure. It simulates the journey from an on-premises Java application to a migration to Azure. It shows you what changes to make to maximize the benefits of the cloud in the initial cloud adoption phase. Here's an outline of the contents in this readme:

- [Architecture guidance](#architecture-guidance)
- [Videos](#videos)
- [Architecture](#architecture)
- [Workflow](#workflow)
- [Steps to deploy the reference implementation](#steps-to-deploy-the-reference-implementation)

## Architecture guidance

This project has [companion architecture guidance](adopt-pattern.md) that describes design patterns and best practices for migrating to the cloud. We suggest you read it as it will give important context to the considerations applied in this implementation.

## Videos

The internally accessible video covers the details of reliable web app pattern for Java. For more information, see [Reliable web app pattern videos (Sharepoint)](https://aka.ms/rwa-java-video).

## Architecture

![Diagram showing the architecture of the reference implementation](docs/assets/java-architecture.png)](docs/assets/java-architecture.png)

- [Production environment estimated cost](https://azure.com/e/c530c133f36c423e9774de286f7dd28a)

- [Non-production environment estimated cost](https://azure.com/e/48201e05118243e089ded6855839594a)

## Workflow

A detailed workflow of the reference implementation is forthcoming.

## Steps to deploy the reference implementation

Deploy this sample using [Visual Studio Code](https://code.visualstudio.com/) with [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.

Note - The following deployment has been tested using devcontainers on **macOS** and **Windows with [Ubuntu on WSL](https://ubuntu.com/wsl)**.

1.  Clone the repo

    If using WSL, start a WSL Ubuntu terminal and clone the repo to a WSL directory.

    ![WSL Ubuntu](docs/assets/wsl-ubuntu.png)

    ```shell
    git clone https://github.com/Azure/reliable-web-app-pattern-java.git
    cd reliable-web-app-pattern-java
    code .
    ```

    Once Visual Studio Code is launched, you should see a popup allowing you to click on the button **Reopen in Container**.

    ![WSL Ubuntu](docs/assets/vscode-reopen-in-container.png)

    If you don't see the popup, open up the Visual Studio Code Command Palette with the keyboard shortcut ⇧⌘P (Windows, Linux Ctrl+Shift+P) or navigating to View -> Command Palette... in the VS Code UI.

    ![WSL Ubuntu](docs/assets/vscode-reopen-in-container-command.png)

1. Prepare for deployment

    Open *./scripts/setup-initial-env.sh* and update the following variables:

    ```shell
    export SUBSCRIPTION=
    export APP_NAME=
    ```

    *The variable APP_NAME needs to be globally unique across all of Azure and less than 16 characters.  This sample uses the APP_NAME as the base for names the Azure Resources. Some Azure Resources have a limit to the length of the name.*

    You may change the `APP_ENVIRONMENT` variable to either *prod* or *dev*. The following table describes the differences in the resources deployed in the 2 environments.

    | Service | Dev SKU | Prod SKU | SKU options |
    | --- | --- | --- | --- |
    | Cache for Redis | Basic | Standard | [Redis Cache SKU options](https://azure.microsoft.com/pricing/details/cache/)
    | App Service | P1v2 | P2v2 | [App Service SKU options](https://azure.microsoft.com/pricing/details/app-service/linux/)
    | PostgreSQL Flexible Server | Burstable B1ms (B_Standard_B1ms) | General Purpose D4s_v3 (GP_Standard_D4s_v3) | [PostgreSQL SKU options](https://learn.microsoft.com/azure/postgresql/flexible-server/concepts-compute-storage)

1. Deploy From a Visual Studio Code Terminal

    The guided [deployment script](./deploy.sh) is used to deploy the solution for this sample.  To deploy, run *[deploy.sh](./deploy.sh)* from the Visual Studio Code Terminal running inside of the devcontainer.  `Hit the Enter key to step through the guided deployment`.

    ![Deploy](docs/assets/proseware-deploy.gif)

1. (Optional) Add Users to Azure Active Directory enterprise applications

    The next step is to add a user to the application and assign them a role. To do this, go to Azure Portal --> Azure Active Directory --> Enterprise Applications and search for the Proseware application. Add a user to the application.

    ![Proseware Azure Active Directory Enterprise Applications](docs/assets/AAD-Enterprise-Application.png)

## Navigate to Proseware

After adding the user, open the browser and navigate to *Proseware*. Use the following command to get the site name.

```shell
echo $(terraform -chdir=$PROJECT_ROOT/terraform output -raw frontdoor_url)
```

![Proseware AAD](docs/assets/proseware.png)

## Teardown

```shell
RESOURCE_GROUP=$(terraform -chdir=$PROJECT_ROOT/terraform output -raw resource_group)
echo $RESOURCE_GROUP
az group delete --name $RESOURCE_GROUP --no-wait

APP_REGISTRATION_ID=$(terraform -chdir=$PROJECT_ROOT/terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_registration_id | tr -d \")
echo $APP_REGISTRATION_ID
az ad app delete --id $APP_REGISTRATION_ID
```

## Data collection

The software in the reference implementation may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You can turn off the telemetry, and the following code shows you how to opt out. There are also some features in the software that enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of [Microsoft Privacy Statement](https://go.microsoft.com/fwlink/?LinkId=521839). You can learn more about data collection and use in the help documentation and our privacy statement. When you use the software, you consent to these practices.

Telemetry collection is on by default.

To opt out, set the environment variable `ENABLE_TELEMETRY` to `false` in *./scripts/setup-initial-env.sh*.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).

Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.

## Additional links

- [Patterns overview](adopt-pattern.md)
- [Applying the patterns](apply-pattern.md)
- [Simulating developer patterns](simulate-patterns.md)
- [Known issues](known-issues.md)
- [Contributing](CONTRIBUTING.md)
