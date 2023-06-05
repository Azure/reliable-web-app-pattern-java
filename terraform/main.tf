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

  // Use GZRS storage if deploying in multi-region
  is_multi_region          = length(var.location2) > 0
  account_replication_type = length(var.location2) > 0 ? "GZRS" : "ZRS"

  // Network cidrs for primary region
  primary_network_cidr = ["10.0.0.0/16"]
  primary_app_subnet_cidr = ["10.0.1.0/27"]
  primary_postgresql_subnet_cidr = ["10.0.2.0/27"]
  primary_private_endpoint_subnet_cidr = ["10.0.3.0/27"]

  // Network cidrs for secondary region
  secondary_network_cidr = ["10.1.0.0/16"]
  secondary_app_subnet_cidr = ["10.1.1.0/27"]
  secondary_postgresql_subnet_cidr = ["10.1.2.0/27"]
  secondary_private_endpoint_subnet_cidr = ["10.1.3.0/27"]
}

data "azurerm_client_config" "current" {}

resource "azurecaf_name" "resource_group" {
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = [var.location, local.environment]
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
    "azd-env-name"     = var.application_name
  }
}

module "network" {
  source                       = "./modules/network"
  resource_group               = azurerm_resource_group.main.name
  application_name             = var.application_name
  location                     = var.location
  environment                  = local.environment
  vnet_cidr                    = local.primary_network_cidr
  app_subnet_cidr              = local.primary_app_subnet_cidr
  postgresql_subnet_cidr       = local.primary_postgresql_subnet_cidr
  private_endpoint_subnet_cidr = local.primary_private_endpoint_subnet_cidr
}

module "app_insights" {
  source = "./modules/app-insights"
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
  account_replication_type = local.account_replication_type
}

module "postresql_database" {
  source                      = "./modules/postresql"
  azure_ad_tenant_id          = data.azurerm_client_config.current.tenant_id
  resource_group              = azurerm_resource_group.main.name
  application_name            = var.application_name
  environment                 = local.environment
  location                    = var.location
  virtual_network_id          = module.network.vnet_id
  subnet_network_id           = module.network.postgresql_subnet_id
  replication_enabled         = true
  administrator_password      = var.database_administrator_password
  log_analytics_workspace_id  = module.app_insights.log_analytics_workspace_id
}

resource "azurerm_postgresql_flexible_server_database" "postresql_database" {
  name                = "${var.application_name}db"
  server_id           = module.postresql_database.database_server_id
}

module "key-vault" {
  source           = "./modules/key-vault"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  log_analytics_workspace_id     = module.app_insights.log_analytics_workspace_id

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

# For demo purposes, allow current user access to the key vault
resource azurerm_role_assignment kv_contributor_user_role_assignement {
  scope                 = module.key-vault.vault_id
  role_definition_name  = "Key Vault Contributor"
  principal_id          = data.azurerm_client_config.current.object_id
}
resource azurerm_role_assignment kv_administrator_user_role_assignement {
  scope                 = module.key-vault.vault_id
  role_definition_name  = "Key Vault Administrator"
  principal_id          = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "airsonic_database_admin" {
  name         = "airsonic-database-admin"
  value        = module.postresql_database.database_username
  key_vault_id = module.key-vault.vault_id

  depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement,
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "airsonic_database_admin_password" {
  name         = "airsonic-database-admin-password"
  value        = var.database_administrator_password
  key_vault_id = module.key-vault.vault_id

  depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement,
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "airsonic_application_client_secret" {
  name         = "airsonic-application-client-secret"
  value        = module.application.application_client_secret
  key_vault_id = module.key-vault.vault_id

  depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement,
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "airsonic_cache_secret" {
  name         = "airsonic-redis-password"
  value        = module.cache.cache_secret
  key_vault_id = module.key-vault.vault_id

  depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement,
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

# Give the app access to the key vault secrets - https://learn.microsoft.com/azure/key-vault/general/rbac-guide?tabs=azure-cli#secret-scope-role-assignment
resource azurerm_role_assignment app_database_admin_rbac_assignment {
  scope                 = "${module.key-vault.vault_id}/secrets/${azurerm_key_vault_secret.airsonic_database_admin.name}"
  role_definition_name  = "Key Vault Secrets User"
  principal_id          = module.application.application_principal_id

   depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement,
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource azurerm_role_assignment app_database_admin_password_rbac_assignment {
  scope                 = "${module.key-vault.vault_id}/secrets/${azurerm_key_vault_secret.airsonic_database_admin_password.name}"
  role_definition_name  = "Key Vault Secrets User"
  principal_id          = module.application.application_principal_id

   depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement,
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource azurerm_role_assignment app_client_secret_rbac_assignment {
  scope                 = "${module.key-vault.vault_id}/secrets/${azurerm_key_vault_secret.airsonic_application_client_secret.name}"
  role_definition_name  = "Key Vault Secrets User"
  principal_id          = module.application.application_principal_id

   depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement,
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource azurerm_role_assignment app_redis_password_rbac_assignment {
  scope                 = "${module.key-vault.vault_id}/secrets/${azurerm_key_vault_secret.airsonic_cache_secret.name}"
  role_definition_name  = "Key Vault Secrets User"
  principal_id          = module.application.application_principal_id

   depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement,
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

# The application needs Key Vault Reader role in order to read the key vault meta data
resource azurerm_role_assignment app_key_vault_reader_rbac_assignment {
  scope                 = module.key-vault.vault_id
  role_definition_name  = "Key Vault Reader"
  principal_id          = module.application.application_principal_id

  depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement,
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

module "cache" {
  source                      = "./modules/cache"
  resource_group              = azurerm_resource_group.main.name
  environment                 = local.environment
  location                    = var.location
  private_endpoint_vnet_id    = module.network.vnet_id
  private_endpoint_subnet_id  = module.network.private_endpoint_subnet_id
  log_analytics_workspace_id  = module.app_insights.log_analytics_workspace_id
}

module "application" {
  source             = "./modules/app-service"
  resource_group     = azurerm_resource_group.main.name
  application_name   = var.application_name
  environment        = local.environment
  location           = var.location
  subnet_id          = module.network.app_subnet_id

  app_insights_connection_string = module.app_insights.connection_string
  log_analytics_workspace_id     = module.app_insights.log_analytics_workspace_id

  database_fqdn    = module.postresql_database.database_fqdn
  database_name    = azurerm_postgresql_flexible_server_database.postresql_database.name

  redis_host       = module.cache.cache_hostname
  redis_port       = module.cache.cache_ssl_port

  key_vault_uri    = module.key-vault.vault_uri

  storage_account_name               = module.storage.storage_account_name
  storage_account_primary_access_key = module.storage.storage_primary_access_key
  trainings_share_name               = module.storage.trainings_share_name
  playlist_share_name                = module.storage.playlist_share_name

  frontdoor_host_name     = module.frontdoor.host_name
  frontdoor_profile_uuid  = module.frontdoor.resource_guid
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "airsonic-ad-admin" {
  server_name         = module.postresql_database.database_server_name
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  principal_name      = data.azurerm_client_config.current.object_id
  principal_type      = "User"
}

module "frontdoor" {
  source           = "./modules/frontdoor"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
  host_name        = module.application.application_fqdn
  host_name2       = local.is_multi_region ? module.application2[0].application_fqdn : ""
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
  myip = chomp(data.http.myip.response_body)
  virtual_network_app_subnet_ids = local.is_multi_region ? [module.network.app_subnet_id, module.network2[0].app_subnet_id] : [module.network.app_subnet_id]
}

resource "azurerm_storage_account_network_rules" "airsonic-storage-network-rules" {
  storage_account_id = module.storage.storage_account_id

  default_action             = "Deny"
  virtual_network_subnet_ids = local.virtual_network_app_subnet_ids
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

resource "null_resource" "app_service_startup_script" {
  depends_on = [
    module.application
  ]

  provisioner "local-exec" {
    command = "az webapp deploy --name ${module.application.application_name} --resource-group ${azurerm_resource_group.main.name} --src-path scripts/startup.sh --type=startup"
  }
}

# ----------------------------------------------------------------------------------------------
#  Everything below this comment is for provisioning the 2nd region (if AZURE_LOCATION2 was set)
# ----------------------------------------------------------------------------------------------

#
# Create 2nd region resource group name by appending "s".
#
resource "azurecaf_name" "resource_group2" {
  count         = local.is_multi_region ? 1 : 0
  name          = "${var.application_name}"
  resource_type = "azurerm_resource_group"
  suffixes      = [var.location2, local.environment]
}

#
# Create 2nd resource group.
#
resource "azurerm_resource_group" "main2" {
  count    = local.is_multi_region ? 1 : 0
  name     = azurecaf_name.resource_group2[0].result
  location = var.location2

  tags = {
    "terraform"        = "true"
    "environment"      = local.environment
    "application-name" = var.application_name
    "nubesgen-version" = "0.13.0"
    "airsonic-version" = "1.0"
    "azd-env-name"     = var.application_name
  }
}

module "network2" {
  count                        = local.is_multi_region ? 1 : 0
  source                       = "./modules/network"
  resource_group               = azurerm_resource_group.main2[0].name
  application_name             = var.application_name
  location                     = var.location2
  environment                  = local.environment
  vnet_cidr                    = local.secondary_network_cidr
  app_subnet_cidr              = local.secondary_app_subnet_cidr
  postgresql_subnet_cidr       = local.secondary_postgresql_subnet_cidr
  private_endpoint_subnet_cidr = local.secondary_private_endpoint_subnet_cidr
}

resource "azurerm_virtual_network_peering" "primary_to_secondary" {
  count                        = local.is_multi_region ? 1 : 0
  name                         = "primary-to-secondary-${var.application_name}"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = module.network.vnet_name
  remote_virtual_network_id    = module.network2[0].vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false

  depends_on = [
    module.network,
    module.network2[0]
  ]
}

resource "azurerm_virtual_network_peering" "secondary_to_primary" {
  count                        = local.is_multi_region ? 1 : 0
  name                         = "secondary-to-primary-${var.application_name}"
  resource_group_name          = azurerm_resource_group.main2[0].name
  virtual_network_name         = module.network2[0].vnet_name
  remote_virtual_network_id    = module.network.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false

  depends_on = [
    module.network,
    module.network2[0]
  ]
}

module "postresql_database2" {
  count                       = local.is_multi_region ? 1 : 0
  source                      = "./modules/postresql"
  azure_ad_tenant_id          = data.azurerm_client_config.current.tenant_id
  resource_group              = azurerm_resource_group.main.name
  application_name            = "${var.application_name}"
  environment                 = local.environment
  location                    = var.location2
  virtual_network_id          = module.network2[0].vnet_id
  subnet_network_id           = module.network2[0].postgresql_subnet_id
  administrator_password      = var.database_administrator_password
  replication_enabled         = true
  source_server_id            = module.postresql_database.database_server_id
  log_analytics_workspace_id  = module.app_insights.log_analytics_workspace_id

  depends_on = [
    module.network,
    module.network2[0],
    azurerm_virtual_network_peering.primary_to_secondary,
    azurerm_virtual_network_peering.secondary_to_primary
  ]
}

module "key-vault2" {
  count            = local.is_multi_region ? 1 : 0
  source           = "./modules/key-vault"
  resource_group   = azurerm_resource_group.main2[0].name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location2

  log_analytics_workspace_id     = module.app_insights.log_analytics_workspace_id

  virtual_network_id         = module.network2[0].vnet_id
  private_endpoint_subnet_id = module.network2[0].private_endpoint_subnet_id

  network_acls = {
    bypass                     = "None"
    default_action             = "Deny"
    ip_rules                   = [local.myip]
    virtual_network_subnet_ids = [module.network2[0].app_subnet_id]
  }

  azure_ad_tenant_id = data.azurerm_client_config.current.tenant_id
}

module "cache2" {
  count                       = local.is_multi_region ? 1 : 0
  source                      = "./modules/cache"
  resource_group              = azurerm_resource_group.main2[0].name
  environment                 = local.environment
  location                    = var.location2
  private_endpoint_vnet_id    = module.network2[0].vnet_id
  private_endpoint_subnet_id  = module.network2[0].private_endpoint_subnet_id
  log_analytics_workspace_id  = module.app_insights.log_analytics_workspace_id
}

module "application2" {
  count               = local.is_multi_region ? 1 : 0
  source              = "./modules/app-service"
  resource_group      = azurerm_resource_group.main2[0].name
  application_name    = "${var.application_name}"
  environment         = local.environment
  location            = var.location2
  subnet_id           = module.network2[0].app_subnet_id

  app_insights_connection_string = module.app_insights.connection_string
  log_analytics_workspace_id     = module.app_insights.log_analytics_workspace_id

  database_fqdn    = module.postresql_database2[0].database_fqdn
  database_name    = azurerm_postgresql_flexible_server_database.postresql_database.name

  redis_host       = module.cache2[0].cache_hostname
  redis_port       = module.cache2[0].cache_ssl_port

  key_vault_uri    = module.key-vault2[0].vault_uri

  storage_account_name               = module.storage.storage_account_name
  storage_account_primary_access_key = module.storage.storage_primary_access_key
  trainings_share_name               = module.storage.trainings_share_name
  playlist_share_name                = module.storage.playlist_share_name

  frontdoor_host_name = module.frontdoor.host_name
  frontdoor_profile_uuid  = module.frontdoor.resource_guid
}

# For demo purposes, allow current user access to the key vault
resource azurerm_role_assignment kv_contributor_user_role_assignement2 {
  count                 = local.is_multi_region ? 1 : 0
  scope                 = module.key-vault2[0].vault_id
  role_definition_name  = "Key Vault Contributor"
  principal_id          = data.azurerm_client_config.current.object_id
}
resource azurerm_role_assignment kv_administrator_user_role_assignement2 {
  count                 = local.is_multi_region ? 1 : 0
  scope                 = module.key-vault2[0].vault_id
  role_definition_name  = "Key Vault Administrator"
  principal_id          = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "airsonic_database_admin2" {
  count        = local.is_multi_region ? 1 : 0
  name         = "airsonic-database-admin"
  value        = module.postresql_database2[0].database_username
  key_vault_id = module.key-vault2[0].vault_id

  depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement2,
    azurerm_role_assignment.kv_administrator_user_role_assignement2
  ]
}

resource "azurerm_key_vault_secret" "airsonic_database_admin_password2" {
  count        = local.is_multi_region ? 1 : 0
  name         = "airsonic-database-admin-password"
  value        = var.database_administrator_password
  key_vault_id = module.key-vault2[0].vault_id

  depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement2,
    azurerm_role_assignment.kv_administrator_user_role_assignement2
  ]
}

resource "azurerm_key_vault_secret" "airsonic_application_client_secret2" {
  count        = local.is_multi_region ? 1 : 0
  name         = "airsonic-application-client-secret"
  value        = module.application2[0].application_client_secret
  key_vault_id = module.key-vault2[0].vault_id

  depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement2,
    azurerm_role_assignment.kv_administrator_user_role_assignement2
  ]
}

resource "azurerm_key_vault_secret" "airsonic_cache_secret2" {
  count        = local.is_multi_region ? 1 : 0
  name         = "airsonic-redis-password"
  value        = module.cache2[0].cache_secret
  key_vault_id = module.key-vault2[0].vault_id

  depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement2,
    azurerm_role_assignment.kv_administrator_user_role_assignement2
  ]
}

# Give the app access to the key vault secrets - https://learn.microsoft.com/azure/key-vault/general/rbac-guide?tabs=azure-cli#secret-scope-role-assignment
resource azurerm_role_assignment app_database_admin_rbac_assignment2 {
  count                 = local.is_multi_region ? 1 : 0
  scope                 = "${module.key-vault2[0].vault_id}/secrets/${azurerm_key_vault_secret.airsonic_database_admin.name}"
  role_definition_name  = "Key Vault Secrets User"
  principal_id          = module.application2[0].application_principal_id

   depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement2,
    azurerm_role_assignment.kv_administrator_user_role_assignement2
  ]
}

resource azurerm_role_assignment app_database_admin_password_rbac_assignment2 {
  count                 = local.is_multi_region ? 1 : 0
  scope                 = "${module.key-vault2[0].vault_id}/secrets/${azurerm_key_vault_secret.airsonic_database_admin_password.name}"
  role_definition_name  = "Key Vault Secrets User"
  principal_id          = module.application2[0].application_principal_id

   depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement2,
    azurerm_role_assignment.kv_administrator_user_role_assignement2
  ]
}

resource azurerm_role_assignment app_client_secret_rbac_assignment2 {
  count                 = local.is_multi_region ? 1 : 0
  scope                 = "${module.key-vault2[0].vault_id}/secrets/${azurerm_key_vault_secret.airsonic_application_client_secret.name}"
  role_definition_name  = "Key Vault Secrets User"
  principal_id          = module.application2[0].application_principal_id

   depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement2,
    azurerm_role_assignment.kv_administrator_user_role_assignement2
  ]
}

resource azurerm_role_assignment app_redis_password_rbac_assignment2 {
  count                 = local.is_multi_region ? 1 : 0
  scope                 = "${module.key-vault2[0].vault_id}/secrets/${azurerm_key_vault_secret.airsonic_cache_secret.name}"
  role_definition_name  = "Key Vault Secrets User"
  principal_id          = module.application2[0].application_principal_id

   depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement2,
    azurerm_role_assignment.kv_administrator_user_role_assignement2
  ]
}

# The application needs Key Vault Reader role in order to read the key vault meta data
resource azurerm_role_assignment app_key_vault_reader_rbac_assignment2 {
  count                 = local.is_multi_region ? 1 : 0
  scope                 = module.key-vault2[0].vault_id
  role_definition_name  = "Key Vault Reader"
  principal_id          = module.application2[0].application_principal_id

  depends_on = [
    azurerm_role_assignment.kv_contributor_user_role_assignement2,
    azurerm_role_assignment.kv_administrator_user_role_assignement2
  ]
}
