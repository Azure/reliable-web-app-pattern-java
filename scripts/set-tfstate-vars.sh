#!/usr/bin/env bash

# Invoked by AZD from the azure.yaml as a preprovision hook
# provides unique values that will facilitate external management for the terraform state file
# https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/use-terraform-for-azd#enable-remote-state


environment_name=$(azd env get-values --output json | jq -r .AZURE_ENV_NAME)
primary_region=$(azd env get-values --output json | jq -r .AZURE_LOCATION)
existing_container_name=$(azd env get-values --output json | jq -r .RS_CONTAINER_NAME)
app_environment=$(azd env get-values --output json | jq -r .APP_ENVIRONMENT)
subscription_id=$(azd env get-values --output json | jq -r .AZURE_SUBSCRIPTION_ID)

if [[ $app_environment == "null" ]]; then
    # default to dev
    app_environment="dev"
fi

if [[ $existing_container_name != 'null' ]]; then
    echo 'Terraform values are already set'
    exit 0
fi

if [[ $subscription_id == 'null' ]]; then
    echo 'Subscription ID is not set. Please set the subscription ID using azd env set AZURE_SUBSCRIPTION_ID <subscription_id> before running this script.'
    exit 1
fi

if [[ $environment_name == 'null' ]]; then
    echo 'Environment name is not set. Please set the environment name using azd env new <environment_name> before running this script.'
    exit 1
fi

if [[ $primary_region == 'null' ]]; then
    echo 'Primary region is not set. Please set the primary region using azd env set AZURE_LOCATION <region> before running this script.'
    exit 1
fi

random_string=$RANDOM

# values must be set by GitHub pipeline as vars that are consistent across workflows because we have one that deploys and another that does teardown
rs_storage_account=stprosedevops${random_string}
rs_container_name=terraform
rs_resource_group=rg-${environment_name}-terraform

az group create --name $rs_resource_group --location $primary_region --tags app-pattern-name=java-rwa environment=$app_environment
az storage account create --name $rs_storage_account --resource-group $rs_resource_group --location $primary_region --allow-blob-public-access false --allow-shared-key-access false

# Assign the current user as a Storage Blob Data Contributor to the storage account
userId=$(az ad signed-in-user show --query id --output tsv)
az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id $userId --assignee-principal-type "User" --scope "/subscriptions/$subscription_id/resourceGroups/$rs_resource_group/providers/Microsoft.Storage/storageAccounts/$rs_storage_account"

az storage container create --account-name $rs_storage_account --name $rs_container_name --auth-mode login

azd env set RS_STORAGE_ACCOUNT $rs_storage_account
azd env set RS_CONTAINER_NAME $rs_container_name
azd env set RS_RESOURCE_GROUP $rs_resource_group
