# Quick Start

##  What you will need

There are two ways to deploy the solution. The recommended way is to use [Visual Studio Code](https://code.visualstudio.com/) with [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension.

To deploy the solution without [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers), install the following.

- [Java 8](https://openjdk.org/install/)
- [Maven](https://maven.apache.org/install.html)
- [Terraform](https://www.terraform.io/)
- [Azure CLI](https://aka.ms/nubesgen-install-az-cli)
- [jq](https://stedolan.github.io/jq/download/)
- [Git](https://git-scm.com/)

Note - The following deployment has been tested on **macOS** and [Ubuntu on WSL](https://ubuntu.com/wsl).

## Clone the repo

```shell
git clone https://github.com/Azure/reliable-web-app-pattern-java.git
cd reliable-web-app-pattern-java
```

## Preparing for deployment

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

## Login using Azure CLI

Login to Azure using the Azure CLI and choose your active subscription. 

```shell
az login --scope https://graph.microsoft.com//.default
az account set --subscription ${SUBSCRIPTION}
```

## Deploy Azure Infrastructure

Create the Azure resources by running the following commands:

```shell
cd terraform
terraform init
terraform plan -var application_name=${APP_NAME} -out airsonic.tfplan
terraform apply airsonic.tfplan
./setup-airsonic-pom.sh
cd ..
```

Due to the following [issue](https://github.com/hashicorp/terraform-provider-azurerm/issues/12928), We have to manually upgrade the auth settings to version 2.

```shell

export application_resource_group=$(terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_resource_group  | tr -d \")

export application_name=$(terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_name  | tr -d \")
echo "application_name = $application_name"

echo "application_resource_group = ${application_name}"
echo "application_resource_group = $application_resource_group"

az webapp auth config-version upgrade --name ${application_name} --resource-group ${application_resource_group}
```

## Package and Deploy Airsonic

It's now time to compile and package Airsonic, skipping the unit tests. 

```shell
cd src/airsonic
mvn -Dmaven.test.skip=true -DskipTests package
```

Now that we have a war file, we can deploy it to our Azure App Service.

```shell
mvn com.microsoft.azure:azure-webapp-maven-plugin:2.8.0:deploy -pl airsonic-main
```
