# Reliable web app pattern for Java

This reference implementation provides a production-grade web application that uses best practices from our guidance and gives developers concrete examples to build their own Reliable Web Application in Azure. It simulates the journey from an on-premises Java application to a migration to Azure. It shows you what changes to make to maximize the benefits of the cloud in the initial cloud adoption phase. Here's an outline of the contents in this readme:

- [Architecture guidance](#architecture-guidance)
- [Videos](#videos)
- [Architecture](#architecture)
- [Workflow](#workflow)
- [Steps to deploy the reference implementation](#steps-to-deploy-the-reference-implementation)

## Architecture guidance

This project has [companion architecture guidance](pattern-overview.md) that describes design patterns and best practices for migrating to the cloud. We suggest you read it as it will give important context to the considerations applied in this implementation.

## Videos

Forthcoming is a video series that details the reliable web app pattern for Java.

## Architecture

[![Diagram showing the architecture of the reference implementation](docs/assets/java-architecture.png)](docs/assets/java-architecture.png)

## Workflow

A detailed workflow of the reference implementation is forthcoming.

## Steps to deploy the reference implementation

There are two ways to deploy the solution. The recommended way is to use [Visual Studio Code](https://code.visualstudio.com/) with [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.

To deploy the solution without [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers), install the following.

- [Java 8](https://openjdk.org/install/)
- [Maven](https://maven.apache.org/install.html)
- [Terraform](https://www.terraform.io/)
- [Azure CLI](https://aka.ms/nubesgen-install-az-cli)
- [jq](https://stedolan.github.io/jq/download/)
- [Git](https://git-scm.com/)

Note - The following deployment has been tested on **macOS** and [Ubuntu on WSL](https://ubuntu.com/wsl).

### Clone the repo

```shell
git clone https://github.com/Azure/reliable-web-app-pattern-java.git
cd reliable-web-app-pattern-java
```

### Prepare for deployment

Open *./scripts/setup-initial-env.sh* and update the following variables:

```shell
export SUBSCRIPTION=
export APP_NAME=
```

*The variable APP_NAME needs to be globally unique across all of Azure* 

Run the following to set up the environment:

```shell
source ./scripts/setup-initial-env.sh
```

### Login using Azure CLI

Login to Azure using the Azure CLI and choose your active subscription. 

```shell
az login --scope https://graph.microsoft.com//.default
az account set --subscription ${SUBSCRIPTION}
```

### Allow AZ CLI extensions to install without prompt

```shell
az config set extension.use_dynamic_install=yes_without_prompt
```

### Deploy Azure Infrastructure

Create the Azure resources by running the following commands:

```shell
terraform -chdir=./terraform init
terraform -chdir=./terraform plan -var application_name=${APP_NAME} -out airsonic.tfplan
terraform -chdir=./terraform apply airsonic.tfplan
```

### Download training videos

If you plan on seeding the Proseware with videos and playlists, you may want to run the following scripts while the Azure resources defined in Terraform are being provisioned.  In a separate terminal, run the following.

```shell
source ./scripts/setup-initial-env.sh
./scripts/download-trainings.sh
```

After the completion of this step, you should see a videos directory that contains training videos.

### Upload training videos and playlists

The following command uploads the training videos and playlists to the `Azure Storage` account.  Run the following after Terraform has successfully completed deploying the Azure resources.

```shell
./scripts/upload-trainings.sh
```

## Set up local build environment

```shell
source ./scripts/setup-local-build-env.sh
```

## Package and deploy Airsonic

It's now time to compile and package Airsonic, skipping the unit tests.

```shell
cd src/airsonic-advanced
mvn -Dmaven.test.skip=true -DskipTests clean package
```

Now that we have a war file, we can deploy it to our Azure App Service.

```shell
mvn com.microsoft.azure:azure-webapp-maven-plugin:2.6.1:deploy -pl airsonic-main
```

### Add Users to Azure Active Directory enterprise applications

The next step is to add a user to the application and assign them a role. To do this, go to Azure Portal --> Azure Active Directory --> Enterprise Applications and search for the Airsonic application. Add a user to the application.

![Aisonic Azure Active Directory Enterprise Applications](docs/assets/AAD-Enterprise-Application.png)

After adding the user, open the browser and navigate to https://{AIRSONIC_SITE}/index. Use the following command to get the site name.

```shell
terraform -chdir=$PROJECT_ROOT/terraform output -raw frontdoor_url
```

![Aisonic AAD](docs/assets/proseware.png)

### Teardown

```shell
RESOURCE_GROUP=$(terraform -chdir=$PROJECT_ROOT/terraform output -raw resource_group)
echo $RESOURCE_GROUP
az group delete --name $RESOURCE_GROUP --no-wait

APP_REGISTRATION_ID=$(terraform -chdir=$PROJECT_ROOT/terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_registration_id | tr -d \")
echo $APP_REGISTRATION_ID
az ad app delete --id $APP_REGISTRATION_ID
```

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).

Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.

## Additional links

- [Known issues](known-issues.md)
- [Developer patterns](simulate-patterns.md)
- [Contributing](CONTRIBUTING.md)
