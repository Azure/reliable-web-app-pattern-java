provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
  // If an environment is set up (dev, test, prod...), it is used in the application name
  environment = var.environment == "" ? "dev" : var.environment
  telemetryId = "92141f6a-c03e-4141-bc1c-2113e4772c8d-${var.location}"
}

data "azurerm_client_config" "current" {}

data "azuread_user" "current_user" {
  object_id = data.azurerm_client_config.current.object_id
}

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

module "key-vault" {
  source           = "./modules/key-vault"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  virtual_network_id         = module.network.vnet_id
  private_endpoint_subnet_id = module.network.private_endpoint_subnet_id

  network_acls = {
    bypass                     = "None"
    default_action             = "Deny"
    ip_rules                   = [local.myip]
    virtual_network_subnet_ids = [module.network.app_subnet_id]
  }

  azure_ad_tenant_id = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_key_vault_access_policy" "user_access_policy" {
  key_vault_id = module.key-vault.vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Set", "Get", "List"]
}

resource "azurerm_key_vault_secret" "airsonic_database_admin" {
  name         = "airsonic-database-admin"
  value        = module.postresql_database.database_username
  key_vault_id = module.key-vault.vault_id

  depends_on = [
    azurerm_key_vault_access_policy.user_access_policy
  ]
}

resource "azurerm_key_vault_secret" "airsonic_database_admin_password" {
  name         = "airsonic-database-admin-password"
  value        = module.postresql_database.database_password
  key_vault_id = module.key-vault.vault_id

  depends_on = [
    azurerm_key_vault_access_policy.user_access_policy
  ]
}

resource "azurerm_key_vault_secret" "airsonic_application_client_secret" {
  name         = "airsonic-application-client-secret"
  value        = module.application.application_client_secret
  key_vault_id = module.key-vault.vault_id

  depends_on = [
    azurerm_key_vault_access_policy.user_access_policy
  ]
}

resource "azurerm_key_vault_secret" "airsonic_cache_secret" {
  name         = "airsonic-redis-password"
  value        = module.cache.cache_secret
  key_vault_id = module.key-vault.vault_id
}

module "cache" {
  source                      = "./modules/cache"
  resource_group              = azurerm_resource_group.main.name
  environment                 = local.environment
  location                    = var.location
  private_endpoint_vnet_id    = module.network.vnet_id
  private_endpoint_subnet_id  = module.network.private_endpoint_subnet_id
}

module "application" {
  source           = "./modules/app-service"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
  subnet_id        = module.network.app_subnet_id

  database_id      = module.postresql_database.database_id
  database_fqdn    = module.postresql_database.database_fqdn
  database_name    = module.postresql_database.database_name

  redis_host       = module.cache.cache_hostname
  redis_port       = module.cache.cache_ssl_port

  key_vault_uri    = module.key-vault.vault_uri

  storage_account_name               = module.storage.storage_account_name
  storage_account_primary_access_key = module.storage.storage_primary_access_key

  frontdoor_host_name = module.frontdoor.host_name
}

resource "azurerm_key_vault_access_policy" "application_access_policy" {
  key_vault_id = module.key-vault.vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.application.application_principal_id

  secret_permissions = ["Get", "List"]
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
resource "azurerm_resource_group_template_deployment" "deploymenttelemetry" {
  count               = var.enable_telemetry ? 1 : 0
  name                = local.telemetryId
  resource_group_name = azurerm_resource_group.main.name
  deployment_mode     = "Incremental"
  
  template_content = <<TEMPLATE
  {
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "variables": {},
    "resources": []
  }
  TEMPLATE
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