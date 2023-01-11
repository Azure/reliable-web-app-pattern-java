#!/usr/bin/env bash

echo "Updating $PROJECT_ROOT/src/airsonic/airsonic-main/pom.xml"

SED_COMMAND="sed -i"

if [[ $OSTYPE == 'darwin'* ]]; then
  SED_COMMAND="$SED_COMMAND '' -e"
fi

export application_name=$(terraform -chdir=$PROJECT_ROOT/terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_name  | tr -d \")
echo "application_name = $application_name"
$SED_COMMAND "s/<\!--application_name-->/$application_name/" $PROJECT_ROOT/src/airsonic/airsonic-main/pom.xml

export application_resource_group=$(terraform -chdir=$PROJECT_ROOT/terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_resource_group  | tr -d \")
echo "application_resource_group = $application_resource_group"
$SED_COMMAND "s/<\!--application_resource_group-->/$application_resource_group/" $PROJECT_ROOT/src/airsonic/airsonic-main/pom.xml

export application_region=$(terraform -chdir=$PROJECT_ROOT/terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_region  | tr -d \")
echo "application_region = $application_region"
$SED_COMMAND "s/<\!--application_region-->/$application_region/" $PROJECT_ROOT/src/airsonic/airsonic-main/pom.xml

export application_runtime_webcontainer=$(terraform -chdir=$PROJECT_ROOT/terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_runtime_webcontainer  | tr -d \")
echo "application_runtime_webcontainer = $application_runtime_webcontainer"
$SED_COMMAND "s/<\!--application_runtime_webcontainer-->/$application_runtime_webcontainer/" $PROJECT_ROOT/src/airsonic/airsonic-main/pom.xml

export application_java_version=$(terraform -chdir=$PROJECT_ROOT/terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_java_version  | tr -d \")
echo "application_java_version = $application_java_version"
$SED_COMMAND "s/<\!--application_java_version-->/$application_java_version/" $PROJECT_ROOT/src/airsonic/airsonic-main/pom.xml

echo "Finished updating ../src/airsonic/airsonic-main/pom.xml"