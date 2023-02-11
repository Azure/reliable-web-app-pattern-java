terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.43.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  // If an environment is set up (dev, test, prod...), it is used in the application name
  environment = var.environment == "" ? "dev" : var.environment
}

data "azurerm_client_config" "current" {}

resource "azurecaf_name" "resource_group" {
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = [local.environment]
}

resource "azurerm_resource_group" "main" {
  name     = azurecaf_name.resource_group.result
  location = var.location

  tags = {
    "terraform"        = "true"
    "environment"      = local.environment
    "application-name" = var.application_name
    "nubesgen-version" = "0.13.0"
    "airsonic-version" = "1.0"
  }
}

module "network" {
  source             = "./modules/network"
  resource_group     = azurerm_resource_group.main.name
  application_name   = var.application_name
  environment        = local.environment
  location           = var.location
}

module "storage" {
  source             = "./modules/storage"
  resource_group     = azurerm_resource_group.main.name
  application_name   = var.application_name
  environment        = local.environment
  location           = var.location
  virtual_network_id = module.network.vnet_id
  subnet_network_id  = module.network.app_subnet_id
}

module "postresql_database" {
  source             = "./modules/postresql"
  azure_ad_tenant_id = data.azurerm_client_config.current.tenant_id
  resource_group     = azurerm_resource_group.main.name
  application_name   = var.application_name
  environment        = local.environment
  location           = var.location
  virtual_network_id = module.network.vnet_id
  subnet_network_id  = module.network.postgresql_subnet_id
}

module "application" {
  source           = "./modules/app-service"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
  subnet_id        = module.network.app_subnet_id

  database_id       = module.postresql_database.database_id
  database_fqdn     = module.postresql_database.database_fqdn
  database_name     = module.postresql_database.database_name

  key_vault_uri     = module.key-vault.vault_uri

  database_username = "@Microsoft.KeyVault(SecretUri=${module.key-vault.vault_uri}secrets/${module.key-vault.airsonic_database_admin_secret_name})"
  database_password = "@Microsoft.KeyVault(SecretUri=${module.key-vault.vault_uri}secrets/${module.key-vault.airsonic_database_admin_password_secret_name})"

  storage_account_name = module.storage.storage_account_name
  storage_account_primary_access_key = module.storage.storage_primary_access_key

  frontdoor_host_name     = module.frontdoor.host_name
}

module "key-vault" {
  source           = "./modules/key-vault"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
  
  azure_ad_tenant_id = data.azurerm_client_config.current.tenant_id
  azure_ad_object_id = data.azurerm_client_config.current.object_id

  airsonic_database_admin            = module.postresql_database.database_username
  airsonic_database_admin_password   = module.postresql_database.database_password
  airsonic_application_client_id     = module.application.application_registration_id
  airsonic_application_client_secret = module.application.application_client_secret
}

data "azuread_user" "current_user" {
  object_id = data.azurerm_client_config.current.object_id
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "airsonic-ad-admin" {
  server_name         = module.postresql_database.database_server_name
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azuread_user.current_user.object_id
  principal_name      = data.azuread_user.current_user.user_principal_name
  principal_type      = "User"
}

module "frontdoor" {
  source           = "./modules/frontdoor"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
  host_name        = module.application.application_fqdn
}

data "http" "myip" {
  url = "http://whatismyip.akamai.com"
}

locals {
  myip = chomp(data.http.myip.body)
}

resource "azurerm_storage_account_network_rules" "airsonic-storage-network-rules" {
  storage_account_id = module.storage.storage_account_id

  default_action             = "Deny"
  virtual_network_subnet_ids = [module.network.app_subnet_id]
  ip_rules                   = [local.myip]

  depends_on = [
    module.storage
  ]
}

resource "azurerm_key_vault_access_policy" "application_access_policy" {
  key_vault_id = module.key-vault.vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.application.application_principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Set Azure AD Application ID URI.
resource "null_resource" "setup-application-uri" {
  depends_on = [
    module.application
  ]

  provisioner "local-exec" {
    command = "az ad app update --id ${module.application.application_registration_id} --identifier-uris api://${module.application.application_registration_id}"
  }
}

#Due to the following [issue](https://github.com/hashicorp/terraform-provider-azurerm/issues/12928), We have to manually upgrade the auth settings to version 2.
resource "null_resource" "upgrade_auth_v2" {
  depends_on = [
    module.application
  ]

  provisioner "local-exec" {
    command = "az webapp auth config-version upgrade --name ${module.application.application_name} --resource-group ${azurerm_resource_group.main.name}"
  }
}

resource "null_resource" "app_service_startup_script" {
  depends_on = [
    module.application
  ]

  provisioner "local-exec" {
    command = "az webapp deploy --name ${module.application.application_name} --resource-group ${azurerm_resource_group.main.name} --src-path scripts/startup.sh --type=startup"
  }
}

resource "null_resource" "app_service_startup_command" {
  depends_on = [
    module.application
  ]

  provisioner "local-exec" {
    command = "az webapp config set --name ${module.application.application_name} --resource-group ${azurerm_resource_group.main.name} --startup-file /home/site/scripts/startup.sh"
  }
}