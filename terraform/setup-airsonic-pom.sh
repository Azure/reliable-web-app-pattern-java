#!/usr/bin/env bash

echo "Updating ../src/airsonic/airsonic-main/pom.xml"

SED_COMMAND="sed -i"

if [[ $OSTYPE == 'darwin'* ]]; then
  SED_COMMAND="$SED_COMMAND '' -e"
fi

application_name=$(terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_name  | tr -d \")
echo "application_name = $application_name"
$SED_COMMAND "s/<\!--application_name-->/$application_name/" ../src/airsonic/airsonic-main/pom.xml

application_resource_group=$(terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_resource_group  | tr -d \")
echo "application_resource_group = $application_resource_group"
$SED_COMMAND "s/<\!--application_resource_group-->/$application_resource_group/" ../src/airsonic/airsonic-main/pom.xml

application_region=$(terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_region  | tr -d \")
echo "application_region = $application_region"
$SED_COMMAND "s/<\!--application_region-->/$application_region/" ../src/airsonic/airsonic-main/pom.xml

application_runtime_webcontainer=$(terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_runtime_webcontainer  | tr -d \")
echo "application_runtime_webcontainer = $application_runtime_webcontainer"
$SED_COMMAND "s/<\!--application_runtime_webcontainer-->/$application_runtime_webcontainer/" ../src/airsonic/airsonic-main/pom.xml

application_java_version=$(terraform show -json | jq .values.outputs.app_service_module_outputs.value.application_java_version  | tr -d \")
echo "application_java_version = $application_java_version"
$SED_COMMAND "s/<\!--application_java_version-->/$application_java_version/" ../src/airsonic/airsonic-main/pom.xml

echo "Finished updating ../src/airsonic/airsonic-main/pom.xml"