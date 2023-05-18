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
echo "Found $resourceGroupName in $location"

# find key vault from resource group (assumes one vault per resource group)
keyVaultName=$(az keyvault list --resource-group "$resourceGroupName" --query '[0].name' -o tsv)
echo "Found $keyVaultName key vault in $resourceGroupName"

# find azure app service name
appServiceName=$(az webapp list --resource-group "$resourceGroupName" --query '[0].name' -o tsv)
echo "Found $appServiceName app service in $resourceGroupName"

# find postgres flexible server name
postgresServerName=$(az postgres flexible-server list --resource-group "$resourceGroupName" --query '[0].name' -o tsv)
echo "Found $postgresServerName postgres server in $resourceGroupName"

# find azure monitor diagnostic name
appServiceDiagnosticName=$(az monitor diagnostic-settings list --resource-group "$resourceGroupName" --resource "$appServiceName" --resource-type Microsoft.Web/Sites --query "[0].name" -o tsv)
echo "Found $appServiceDiagnosticName diagnostics in $resourceGroupName in $location"

# find postgres server diagnostic name
postgresSqlDiagnosticName=$(az monitor diagnostic-settings list --resource-group "$resourceGroupName" --resource "$postgresServerName" --resource-type Microsoft.DBforPostgreSQL/flexibleServers --query "[0].name" -o tsv)
echo "Found $postgresSqlDiagnosticName diagnostics in $resourceGroupName in $location"

if [[ ${#appServiceDiagnosticName} -eq 0 ]]; then
  echo "Deleting $appServiceDiagnosticName diagnostics in $resourceGroupName in $location"
  # delete the app service diagnostic so that it does not persist through resource group deletion and conflict with TF plan
  az monitor diagnostic-settings delete --resource-group "$resourceGroupName" --resource "$appServiceName" --name "$appServiceDiagnosticName" --resource-type Microsoft.Web/Sites
else
  echo "Skipping delete for appServiceDiagnosticName diagnostics"
fi

if [[ ${#postgresSqlDiagnosticName} -eq 0 ]]; then
  echo "Deleting $postgresSqlDiagnosticName diagnostics in $resourceGroupName in $location"
  # delete the PostgresSQL server diagnostic so that it does not persist through resource group deletion and conflict with TF plan
  az monitor diagnostic-settings delete --resource-group "$resourceGroupName" --resource "$postgresServerName" --name "$postgresSqlDiagnosticName" --resource-type Microsoft.DBforPostgreSQL/flexibleServers
else
  echo "Skipping delete for postgresSqlDiagnosticName diagnostics"
fi

echo "Deleting resources in $resourceGroupName in $location"
# Delete the resource group
az group delete --name "$resourceGroupName" --yes

echo "Purging $keyVaultName key vault in $resourceGroupName"
# Purge the deleted key vault
az keyvault purge --name "$keyVaultName" --location $location
