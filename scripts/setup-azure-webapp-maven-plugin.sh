#!/usr/bin/env bash

# This script updates the azure-webapp-maven-plugin section in airsonic-main/pom.xml.
# The Maven plugin for Azure App Service is used to deploy the app to Azure,

echo "Updating $PROJECT_ROOT/src/airsonic-advanced/airsonic-main/pom.xml"

SED_COMMAND="sed -i"

if [[ $OSTYPE == 'darwin'* ]]; then
  SED_COMMAND="$SED_COMMAND '' -e"
fi

application_name=$(terraform -chdir=$PROJECT_ROOT/terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_name  | tr -d \")
echo "application_name = $application_name"
$SED_COMMAND "s/<\!--application_name-->/$application_name/" $PROJECT_ROOT/src/airsonic-advanced/airsonic-main/pom.xml

application_resource_group=$(terraform -chdir=$PROJECT_ROOT/terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_resource_group  | tr -d \")
echo "application_resource_group = $application_resource_group"
$SED_COMMAND "s/<\!--application_resource_group-->/$application_resource_group/" $PROJECT_ROOT/src/airsonic-advanced/airsonic-main/pom.xml

application_region=$(terraform -chdir=$PROJECT_ROOT/terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_region  | tr -d \")
echo "application_region = $application_region"
$SED_COMMAND "s/<\!--application_region-->/$application_region/" $PROJECT_ROOT/src/airsonic-advanced/airsonic-main/pom.xml

echo "Finished updating $PROJECT_ROOT/src/airsonic-advanced/airsonic-main/pom.xml"