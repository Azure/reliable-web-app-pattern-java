#!/usr/bin/env bash

# Invoked by AZD from the azure.yaml as a preprovision hook
# provides unique values that will facilitate external management for the terraform state file
# https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/use-terraform-for-azd#enable-remote-state


existing_container_name=$(azd env get-values --output json | jq -r .rs_container_name)

if [[ ${#existing_container_name} -gt 0 ]]; then
    echo 'Terraform values are already set'
    exit 0
fi

random_string=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 11 | head -n 1)

# values must be set by GitHub pipeline as vars that are consistent across workflows because we have one that deploys and another that does teardown
RS_STORAGE_ACCOUNT=stprosedevops$(random_string)
RS_CONTAINER_NAME=terraform
RS_RESOURCE_GROUP=rg-stprosedevops

azd env set RS_STORAGE_ACCOUNT $RS_STORAGE_ACCOUNT
azd env set RS_CONTAINER_NAME $RS_CONTAINER_NAME
azd env set RS_RESOURCE_GROUP $RS_RESOURCE_GROUP