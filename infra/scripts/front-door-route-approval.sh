#!/usr/bin/env 

# This script approves pending private endpoint connections for Azure Web Apps.
# https://github.com/Azure/appservice-landing-zone-accelerator/blob/main/scenarios/secure-baseline-multitenant/azure-resource-manager/README.md

rg_name=$1
webapp_ids=$(az webapp list -g $rg_name --query "[].id" -o tsv)

# you might have more than one web apps, check for all of them if there are pending approvals
for webapp_id in $webapp_ids; do
    # there might be more than one pending connection per web app
    fd_conn_ids=$(az network private-endpoint-connection list --id $webapp_id --query "[?properties.provisioningState == 'Pending'].id" -o tsv)
    
    for fd_conn_id in $fd_conn_ids; do
        az network private-endpoint-connection approve --id "$fd_conn_id" --description "Approved"
    done
done