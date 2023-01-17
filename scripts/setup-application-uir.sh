#!/usr/bin/env bash

export application_registration_id=$(terraform -chdir=$PROJECT_ROOT/terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_registration_id  | tr -d \")
echo "application_registration_id = $application_registration_id"
az ad app update --id ${application_registration_id} --identifier-uris api://${application_registration_id}
