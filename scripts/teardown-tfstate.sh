#!/usr/bin/env bash

# Invoked by AZD from the azure.yaml as a postdown hook
# This script deletes the resource group that was created by set-tfstate-vars.sh to support clean teardown

existing_resource_group=$(azd env get-values --output json | jq -r .RS_RESOURCE_GROUP)

if [[ $(az group exists --name $existing_resource_group) == 'true' ]]; then
    echo "deleting group: $existing_resource_group"   
    az group delete --name $existing_resource_group --yes
else
    echo "no resource group to delete"
fi