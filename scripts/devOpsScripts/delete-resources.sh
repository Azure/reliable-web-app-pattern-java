#!/bin/bash

# Usage: ./delete-resources.sh -g <resource-group-name>
# Example: ./delete-resources.sh -g my-resource-group

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --resource-group|-g)
      resourceGroupName="$2"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

# check if resource group exists
if [[ $(az group exists --name "$resourceGroupName") == false ]]; then
  echo "Resource group $resourceGroupName does not exist."
  exit 1
fi

# get location of resource group
location=$(az group show --name "$resourceGroupName" --query location -o tsv)

# find key vault from resource group (assumes one vault per resource group)
keyVaultName=$(az keyvault list --resource-group "$resourceGroupName" --query '[0].name' -o tsv)

# find azure app service name
appServiceName=$(az webapp list --resource-group "$resourceGroupName" --query '[0].name' -o tsv)

# find postgres flexible server name
postgresServerName=$(az postgres flexible-server list --resource-group "$resourceGroupName" --query '[0].name' -o tsv)

# find azure monitor diagnostic name
appServiceDiagnosticName=$(az monitor diagnostic-settings list --resource-group "$resourceGroupName" --resource "$appServiceName" --resource-type Microsoft.Web/Sites --query "[0].name" -o tsv)

# find postgres server diagnostic name
postgresSqlDiagnosticName=$(az monitor diagnostic-settings list --resource-group "$resourceGroupName" --resource "$postgresServerName" --resource-type Microsoft.DBforPostgreSQL/flexibleServers --query "[0].name" -o tsv)

# delete the app service diagnostic so that it does not persist through resource group deletion and conflict with TF plan
az monitor diagnostic-settings delete --resource-group "$resourceGroupName" --resource "$appServiceName" --name "$appServiceDiagnosticName"

# delete the PostgresSQL server diagnostic so that it does not persist through resource group deletion and conflict with TF plan
az monitor diagnostic-settings list --resource-group "$resourceGroupName" --resource "$postgresServerName" --name "$postgresSqlDiagnosticName"

# Delete the resource group
az group delete --name "$resourceGroupName" --yes

# Purge the deleted key vault
az keyvault purge --name "$keyVaultName" --location $location
