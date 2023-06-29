#!/usr/bin/env bash

# Invoked by AZD from the azure.yaml as a postdown hook
# This script deletes the resource group that was created by set-tf-state-vars.sh to support clean teardown

existing_resource_group=$(azd env get-values --output json | jq -r .RS_RESOURCE_GROUP)

if [[ $(az group exists --name $existing_resource_group) == 'true' ]]; then
    az group delete --name $existing_resource_group --yes
fi