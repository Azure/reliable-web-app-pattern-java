#!/bin/bash
#
# This script creates an Azure AD App Registration for the Reliable Web App Pattern which assumes a web app configured for id_tokens issued to users of "My Org" only.
# When the arguments are present it will save the information to Key Vault.
# When using the console-out option the configuration will print the to console so that you can save them to Key Vault, or GitHub pipeline variables.
#
# Options:
# --app-name       -n  [Required] : The name used in Azure AD to uniquely identify this App Registration.
# --key-vault      -kv            : Name of a key vault where the settings should be saved. When not provided, settings will be written to console output to be saved by the user.
# --resource-group -g             : Name of the resource group where a key vault is located.
# --location       -l             : Location (deaults to eastus). Values from: `az account list-locations`. You can configure the default location using `az configure --defaults location=<location>`.
# --console-out    -c             : When provided, the script will print the settings to console output instead of saving them to Key Vault.

POSITIONAL_ARGS=()

debug=''
consoleOutput=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --app-name|-n)
      appName="$2"
      shift # past argument
      shift # past value
      ;;
    --key-vault|-kv)
      keyVaultName="$2"
      shift # past argument
      shift # past value
      ;;
    --resource-group|-g)
      resourceGroupName="$2"
      shift # past argument
      shift # past value
      ;;
    --location|-l)
      location="$2"
      shift # past argument
      shift # past value
      ;;
    --console-out|-c)
      consoleOutput=true
      shift # past argument
      ;;
    --debug)
      debug=1
      shift # past argument
      ;;
    --help*)
      echo ''
      echo 'Use this command to create an Azure AD App Registration for the Reliable Web App Pattern which assumes a web app configured for id_tokens issued to users of "My Org" only.'
      echo ''
      echo 'Command'
      echo '    createAppRegistrations.sh : Uses the user'\''s `az account` context to create an App Registration. When the arguments are present it will save the information to Key Vault. And when they are unavailable it will print the required settings to console so that you can save them to Key Vault, or GitHub pipeline variables.'
      echo ''
      echo 'Arguments'
      echo '    --app-name       -n  [Required] : The name used in Azure AD to uniquely identify this App Registration.'
      echo '    --key-vault      -kv            : Name of a key vault where the settings should be saved. When not provided, settings will be written to console output to be saved by the user.'
      echo '    --resource-group -g             : Name of the resource group where a key vault is located.'
      echo '    --location       -l             : Location (deaults to eastus). Values from: `az account list-locations`. You can configure the default location using `az configure --defaults location=<location>`.'      echo ''
      echo '    --console-out    -c             : When provided, the script will print the settings to console output instead of saving them to Key Vault.'
      echo 'Global Arguments'
      echo '    --debug             : Increase logging verbosity to show all debug logs.'
      exit 1
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

green='\033[0;32m'
yellow='\e[0;33m'
red='\e[1;31m'
clear='\033[0m'

# Note that redirectUri will not be known until after Azure Front Door origin is created
# So the only URI we set here is the one that supports local debugging
# The final configuration of the redirectUri will be handled during TF deployment (see "setup-application-uri" ./terraform/main.tf)
# when a user runs the `azd` commands
redirectUri='https://localhost:8080/login/oauth2/code/'

if [[ ${#appName} -eq 0 ]]; then
  printf "${red}FATAL ERROR:${clear} Missing required parameter --app-name"
  echo ""
  exit 6
fi

if [[ ! $consoleOutput && ${#resourceGroupName} -eq 0 && ${#keyVaultName} -gt 0 ]]; then
  printf "${red}FATAL ERROR:${clear} When, --key-vault is provided, --resource-group is required."
  echo ""
  exit 6
fi

if [[ ! $consoleOutput && ${#keyVaultName} -eq 0 && ${#resourceGroupName} -gt 0 ]]; then
  printf "${red}FATAL ERROR:${clear} When, --resource-group is provided, --key-vault is required."
  echo ""
  exit 6
fi

if [[ ${#location} -eq 0 ]]; then
  # default region for new resources
  location='eastus'
fi

echo "Inputs"
echo "----------------------------------------------"
echo "appName='$appName'"
echo "resourceGroupName='$resourceGroupName'"
echo "keyVaultName='$keyVaultName'"
echo "redirectUri='$redirectUri'"
echo "debug='$debug'"
echo "location='$location'"
echo "consoleOutput='$consoleOutput'"
echo ""

if [[ $debug ]]; then
    read -n 1 -r -s -p "Press any key to continue and create an App Registration..."
    echo ''
    echo "..."
fi

# if key vault and resource group are provided, then ensure that we can save the settings as intended before trying to create them
if [[ ! $consoleOutput && ${#resourceGroupName} -gt 0 ]]; then
  echo "Checking for existing resource group..."
  resourceGroupExists=$(az group list --query "[?contains(name, '$resourceGroupName')].name" -o tsv)
  if [[ ${#resourceGroupExists} -eq 0 ]]; then
    echo "Creating resource group..."
    az group create --name $resourceGroupName --location $location
  elif [[ $debug ]]; then
    echo "Resource group '$resourceGroupName' already exists."
  fi

  if [[ ${#keyVaultName} -gt 0 ]]; then
    echo "Checking for existing key vault '$keyVaultName'..."
    keyVaultExists=$(az keyvault show --name $keyVaultName --query "name" -o tsv)
    if [[ ${#keyVaultExists} -eq 0 ]]; then
      echo "Creating key vault '$keyVaultName'..."
      az keyvault create --name $keyVaultName --resource-group $resourceGroupName --location $location
    elif [[ $debug ]]; then
      echo "keyvault with name '$resourceGroupName' already exists."
    fi
  fi
fi

prosewareClientId=''

echo "Checking for existing app registration..."
existingClientIdObject=$(az ad app list --filter "displayName eq '$appName'" --query "[].appId" -o tsv)
if [[ ${#existingClientIdObject} -gt 0 ]]; then
    echo "Found existing app registration..."
    prosewareClientId="$existingClientIdObject"
else
    echo "Creating app registration..."
    prosewareClientId=$(az ad app create \
        --display-name $appName \
        --sign-in-audience AzureADMyOrg \
        --app-roles '[{ "allowedMemberTypes": [ "User" ], "description": "Creator roles allows users to create content", "displayName": "Creator", "isEnabled": "true", "value": "Creator" },{ "allowedMemberTypes": [ "User" ], "description": "ReadOnly roles have limited query access", "displayName": "ReadOnly", "isEnabled": "true", "value": "ReadOnly" }]' \
        --web-redirect-uris $redirectUri \
        --enable-id-token-issuance \
        --query appId --output tsv)
fi

if [[ $debug ]]; then
    echo "App Registration Id: $prosewareClientId"
fi

tenantId=$(az account show --query "tenantId" -o tsv)

# passwords for client secrets can never be accessed so we reset it every time we need it
echo ''
# added echo cmds to ensure that the warning printed by this cmd is visible
prosewareClientSecret=$(az ad app credential reset --id $prosewareClientId --append --query "password" -o tsv)
echo ''

# Print the settings we created or found
echo "App Registration Settings"
echo "----------------------------------------------"
echo "prosewareClientId='$prosewareClientId'"
echo "tenantId='$tenantId'"
echo ''

if [[ $debug ]]; then
    read -n 1 -r -s -p "Press any key to continue persisting these settings..."
    echo ''
    echo "..."
fi

if [[ $consoleOutput ]]; then
  echo "Persisting settings to console..."
  echo "clientSecret='$prosewareClientSecret'"
else
  echo "Persisting settings to key vault..."
  az keyvault secret set --name 'AzureAd--ClientId' --vault-name $keyVaultName --value $prosewareClientId
  az keyvault secret set --name 'AzureAd--TenantId' --vault-name $keyVaultName --value $tenantId
  az keyvault secret set --name 'AzureAd--ClientSecret' --vault-name $keyVaultName --value $prosewareClientSecret
fi
