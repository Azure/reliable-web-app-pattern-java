#!/usr/bin/env bash

# Invoked by AZD from the azure.yaml as a postprovision hook
# executed by azd postprovision event we use the output of provision (which sets the azd env variable primary_resource_group)
# to set the variable AZURE_RESOURCE_GROUP so that the `azd deploy` command knows which group to target when deploying

green='\033[0;32m'
yellow='\e[0;33m'
red='\e[1;31m'
clear='\033[0m'

PRIMARY_RESOURCE_GROUP=$(azd env get-values --output json | jq -r .primary_resource_group)

if [[ $PRIMARY_RESOURCE_GROUP == 'null' ]]; then
   printf "${red}ERROR:${clear} primary_resource_group was not set by azd provision\n\n"
   exit 1
fi

azd env set AZURE_RESOURCE_GROUP $PRIMARY_RESOURCE_GROUP

printf "${green}Success:${clear} done setting default resource group"
