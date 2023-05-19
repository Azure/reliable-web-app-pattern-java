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

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'
resource_types=("Microsoft.Web/Sites" "Microsoft.DBforPostgreSQL/flexibleServers" "Microsoft.Cache/redis" "Microsoft.KeyVault/vaults")

for type in "${resource_types[@]}"; do
  echo -e "\nChecking if resource exists for ${GREEN}$type${RESET} in $resourceGroupName in $location"
  resource=$(az resource list --resource-group "$resourceGroupName" --resource-type "$type" --query '[].name' -o tsv)

  if [[ ${#resource} -eq 0 ]]; then
    echo -e "\tNo resource found for ${RED}$type${RESET} in $resourceGroupName in $location"
    continue
  fi
  echo -e "\tFound resource for $type in $resourceGroupName in $location"

  echo -e "\tChecking for diagnostic settings for $type in $resourceGroupName in $location"
  diagnosticSettings=$(az monitor diagnostic-settings list --resource-group "$resourceGroupName" --resource-type "$type" --resource $resource --query '[].name' -o tsv)
  if [[ ${#diagnosticSettings} -gt 0 ]]; then
    echo -e "\tDeleting diagnostic settings for $type in $resourceGroupName in $location"
    az monitor diagnostic-settings delete --resource-group "$resourceGroupName" --resource-type "$type" --name "$diagnosticSettings"
  else
    echo -e "\tCould not find diagnostic-settings for ${YELLOW}$type${RESET} diagnostics"
  fi
done

echo ""

# find key vault from resource group (assumes one vault per resource group)
keyVaultName=$(az keyvault list --resource-group "$resourceGroupName" --query '[0].name' -o tsv)
echo "Found $keyVaultName key vault in $resourceGroupName"

echo "Deleting resources in $resourceGroupName in $location"
# Delete the resource group
#az group delete --name "$resourceGroupName" --yes

echo "Purging $keyVaultName key vault in $resourceGroupName"
# Purge the deleted key vault
#az keyvault purge --name "$keyVaultName" --location $location
