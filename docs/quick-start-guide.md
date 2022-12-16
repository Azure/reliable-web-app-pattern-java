# Quick Start

##  What you will need

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

## Login using Azure CLI

Login to Azure using the Azure CLI and choose your active subscription. 

```shell
az login --use-device-code
az account list -o table
az account set --subscription ${SUBSCRIPTION}
```

## Deploy Azure Infrastructure

Customize the application by editing `terraform/variables.tf`.  The `application_name` variable needs to be globally unique.

Open `terraform/variables.tf` and change the default variable for `application_name`:

```
variable "application_name" {
  type        = string
  description = "The application name"
  default     = "airsonic"
}
```

Create the Azure resources by running the following commands:

```shell
cd terraform
terraform init
terraform plan -out airsonic.tfplan
terraform apply airsonic.tfplan
./setup-airsonic-pom.sh
cd ..
```

## Package and Deploy Airsonic

It's now time to compile and package Airsonic, skipping the unit tests. 

```shell
cd src/airsonic
mvn -Dmaven.test.skip=true -DskipTests package
```

Now that we have a war file, we can deploy it to our Azure App Service.

```shell
mvn com.microsoft.azure:azure-webapp-maven-plugin:2.6.1:deploy -pl airsonic-main
```
