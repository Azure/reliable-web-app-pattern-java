#!/usr/bin/env bash

echo "Updating $PROJECT_ROOT/src/airsonic-advanced/airsonic-main/pom.xml"

SED_COMMAND="sed -i"

if [[ $OSTYPE == 'darwin'* ]]; then
  SED_COMMAND="$SED_COMMAND '' -e"
fi

export application_name=$(terraform -chdir=$PROJECT_ROOT/infra show -json | jq .values.outputs.app_service_module_outputs.value.application_name  | tr -d \")
echo "application_name = $application_name"
$SED_COMMAND "s/<\!--application_name-->/$application_name/" $PROJECT_ROOT/src/airsonic-advanced/airsonic-main/pom.xml

export application_resource_group=$(terraform -chdir=$PROJECT_ROOT/infra show -json | jq .values.outputs.app_service_module_outputs.value.application_resource_group  | tr -d \")
echo "application_resource_group = $application_resource_group"
$SED_COMMAND "s/<\!--application_resource_group-->/$application_resource_group/" $PROJECT_ROOT/src/airsonic-advanced/airsonic-main/pom.xml

export application_region=$(terraform -chdir=$PROJECT_ROOT/infra show -json | jq .values.outputs.app_service_module_outputs.value.application_region  | tr -d \")
echo "application_region = $application_region"
$SED_COMMAND "s/<\!--application_region-->/$application_region/" $PROJECT_ROOT/src/airsonic-advanced/airsonic-main/pom.xml

echo "Finished updating $PROJECT_ROOT/src/airsonic-advanced/airsonic-main/pom.xml"