# devOpsScripts Folder
Scripts in this folder are executed by the GitHub pipeline workflow. The support the automated provisioning of Azure resources and deployment of code.

Scripts include:
- delete-resources.sh
- get-aad-settings-from-vault.sh
- reusable-app-registrations.sh

## delete-resources.sh
This script is executed as part of the teardown process to manage costs and clean the Azure environment in preparation for a new (repeatable) deployment
  > Note that since it runs on schedule, it does not have access to the terraform plan file, and cannot run the tf destroy cmd

## reusable-app-registrations.sh
This script is used to provision an Azure AD app registration that can be reused.