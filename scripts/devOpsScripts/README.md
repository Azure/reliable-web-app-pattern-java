# devOpsScripts Folder
Scripts in this folder are executed by the GitHub pipeline workflow. The support the automated provisioning of Azure resources and deployment of code.

Scripts include:
- cleanup.ps1
- reusable-app-registrations.sh

## cleanup.ps1
This script is not executed as part of the teardown or the reader's flow. It is included as part of a recovery process to assist with recovering from failed deployments.

## reusable-app-registrations.sh
This script is used to provision an Azure AD app registration that can be reused.