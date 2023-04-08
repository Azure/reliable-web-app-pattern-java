#!/usr/bin/env bash

########################
# include the magic
########################
. demo-magic.sh

########################
# Configure the options
########################

#
# speed at which to simulate typing. bigger num = faster
#
TYPE_SPEED=30

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${BLACK}➜ ${GREEN}\W "

# hide the evidence
clear

p ">>> Setup initial environment <<<"
pe "source ./scripts/setup-initial-env.sh"

p ">>> Login to Azure using the Azure CLI <<<"
pe "az login --scope https://graph.microsoft.com//.default"

p ">>> Set the active subscription <<<"
pe "az account set --subscription ${SUBSCRIPTION_ID}"

p ">>> Allow installing AZ CLI extensions without prompt <<<"
pe "az config set extension.use_dynamic_install=yes_without_prompt"

p ">>> Deploying Azure infrastructure <<"
pe "terraform -chdir=./terraform init"
pe "terraform -chdir=./terraform plan -var application_name=${APP_NAME} -var environment=${APP_ENVIRONMENT} -var enable_telemetry=${ENABLE_TELEMETRY} -var database_administrator_password=${DATABASE_PASSWORD} -out proseware.tfplan"
pe "terraform -chdir=./terraform apply proseware.tfplan"

p ">>> Set Up Your Local Build Environment <<<"
pe "source ./scripts/setup-local-build-env.sh"

p ">>> Download Training Videos <<<"
pe "./scripts/download-trainings.sh"

p ">>> Upload Training Videos and Playlists <<<"
pe "./scripts/upload-trainings.sh"

p ">>> Build and package <<<"
pe "cd src/airsonic-advanced"
pe "mvn -Dmaven.test.skip=true -DskipTests package"

p ">>> Deploy Airsonic to Azure App Service <<<"
pe "mvn com.microsoft.azure:azure-webapp-maven-plugin:2.6.1:deploy -pl airsonic-main"

p ">>> Get the Frontdoor URL <<<"
pe "echo $(terraform -chdir=$PROJECT_ROOT/terraform output -raw frontdoor_url)"
