#!/usr/bin/env bash

# Invoked by AZD from the azure.yaml as a preprovision hook
# provides unique values that will facilitate external management for the terraform state file
# https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/use-terraform-for-azd#enable-remote-state


environment_name=$(azd env get-values --output json | jq -r .AZURE_ENV_NAME)
primary_region=$(azd env get-values --output json | jq -r .AZURE_LOCATION)
existing_container_name=$(azd env get-values --output json | jq -r .RS_CONTAINER_NAME)
app_environment=$(azd env get-values --output json | jq -r .APP_ENVIRONMENT)


if [[ $app_environment == "null" ]]; then
    # default to dev
    app_environment="dev"
fi

if [[ $existing_container_name != 'null' ]]; then
    echo 'Terraform values are already set'
    exit 0
fi

random_string=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 11 | head -n 1)

# values must be set by GitHub pipeline as vars that are consistent across workflows because we have one that deploys and another that does teardown
rs_storage_account=stprosedevops${random_string}
rs_container_name=terraform
rs_resource_group=rg-${environment_name}-terraform

az group create --name $rs_resource_group --location $primary_region --tags app-pattern-name=java-rwa environment=$app_environment
az storage account create --name $rs_storage_account --resource-group $rs_resource_group --location $primary_region --allow-blob-public-access false

connection_string=$(az storage account show-connection-string --resource-group $rs_resource_group --name $rs_storage_account --query "connectionString" -o tsv)

az storage container create --account-name $rs_storage_account --name $rs_container_name --connection-string $connection_string

azd env set RS_STORAGE_ACCOUNT $rs_storage_account
azd env set RS_CONTAINER_NAME $rs_container_name
azd env set RS_RESOURCE_GROUP $rs_resource_group
