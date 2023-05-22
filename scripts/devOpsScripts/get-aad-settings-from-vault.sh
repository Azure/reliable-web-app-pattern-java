#!/bin/bash

# Usage: ./get-aad-settings-from-vault.sh -g <resource-group-name>
# Example: ./get-aad-settings-from-vault.sh -g my-resource-group

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