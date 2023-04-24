#!/usr/bin/env bash

RESOURCE_GROUP=$(terraform -chdir=$PROJECT_ROOT/terraform output -raw resource_group)
echo "Deleting $RESOURCE_GROUP"
az group delete --name $RESOURCE_GROUP --no-wait

APP_REGISTRATION_ID=$(terraform -chdir=$PROJECT_ROOT/terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_registration_id | tr -d \")
echo " Deleting $APP_REGISTRATION_ID"
az ad app delete --id $APP_REGISTRATION_ID

echo "Removing Terraform files"
rm -rf $PROJECT_ROOT/terraform/.terraform*
rm -rf $PROJECT_ROOT/terraform/terraform.tfstate*
rm $PROJECT_ROOT/terraform/proseware.tfplan
