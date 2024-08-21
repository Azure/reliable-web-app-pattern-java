# Generate password if none provided
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  database_administrator_password = coalesce(var.database_administrator_password, random_password.password.result)
}
 
# ----------------------------------------------------------------------------------------------
# Database - Prod - Primary Region
# ----------------------------------------------------------------------------------------------

module "postresql_database" {
  count                       = var.environment == "prod" ? 1 : 0
  source                      = "../shared/terraform/modules/postresql"
  azure_ad_tenant_id          = data.azuread_client_config.current.tenant_id
  resource_group              = azurerm_resource_group.spoke[0].name
  application_name            = var.application_name
  environment                 = var.environment
  location                    = var.location
  virtual_network_id          = module.spoke_vnet[0].vnet_id
  subnet_network_id           = module.spoke_vnet[0].subnets[local.postgresql_subnet_name].id
  administrator_password      = local.database_administrator_password
  log_analytics_workspace_id  = module.hub_app_insights[0].log_analytics_workspace_id
  sku_name                    = local.postgresql_sku_name
}

resource "azurerm_postgresql_flexible_server_database" "postresql_database" {
  count     = var.environment == "prod" ? 1 : 0
  name      = "${var.application_name}db"
  server_id = module.postresql_database[0].database_server_id
}

# Demo purposes only: assign current user as admin for the primary DB
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "contoso-ad-admin" {
  count               = var.environment == "prod" ? 1 : 0
  server_name         = module.postresql_database[0].database_name
  resource_group_name = azurerm_resource_group.spoke[0].name
  tenant_id           = data.azuread_client_config.current.tenant_id
  object_id           = data.azuread_client_config.current.object_id
  principal_name      = data.azuread_client_config.current.object_id
  principal_type      = "User"
}

# ----------------------------------------------------------------------------------------------
# 2nd region
# ----------------------------------------------------------------------------------------------

module "secondary_postresql_database" {
  count                       = var.environment == "prod" ? 1 : 0
  source                      = "../shared/terraform/modules/postresql"
  azure_ad_tenant_id          = data.azuread_client_config.current.tenant_id
  resource_group              = azurerm_resource_group.secondary_spoke[0].name
  application_name            = var.application_name
  environment                 = var.environment
  location                    = var.secondary_location
  virtual_network_id          = module.secondary_spoke_vnet[0].vnet_id
  subnet_network_id           = module.secondary_spoke_vnet[0].subnets[local.postgresql_subnet_name].id
  source_server_id            = module.postresql_database[0].database_server_id
  administrator_password      = local.database_administrator_password
  log_analytics_workspace_id  = module.hub_app_insights[0].log_analytics_workspace_id
  sku_name                    = local.postgresql_sku_name

  depends_on = [
    module.spoke_vnet[0],
    module.secondary_spoke_vnet[0],
    module.peeringSpoke2ToSpoke[0],
    module.peeringSpokeToSpoke2[0]
  ]
}

# Demo purposes only: assign current user as admin for the secondary DB
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "secondary-contoso-ad-admin" {
  count               = var.environment == "prod" ? 1 : 0
  server_name         = module.secondary_postresql_database[0].database_name
  resource_group_name = azurerm_resource_group.secondary_spoke[0].name
  tenant_id           = data.azuread_client_config.current.tenant_id
  object_id           = data.azuread_client_config.current.object_id
  principal_name      = data.azuread_client_config.current.object_id
  principal_type      = "User"
}

# ----------------------------------------------------------------------------------------------
#  Dev - PostgreSQL
# ----------------------------------------------------------------------------------------------

module "dev_postresql_database" {
  count                       = var.environment == "dev" ? 1 : 0
  source                      = "../shared/terraform/modules/postresql"
  azure_ad_tenant_id          = data.azuread_client_config.current.tenant_id
  resource_group              = azurerm_resource_group.dev[0].name
  application_name            = var.application_name
  environment                 = var.environment
  location                    = var.location
  virtual_network_id          = null
  subnet_network_id           = null
  source_server_id            = null
  administrator_password      = local.database_administrator_password
  log_analytics_workspace_id  = module.dev_app_insights[0].log_analytics_workspace_id
  sku_name                    = local.postgresql_sku_name
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "dev_postresql_database_allow_access_rule_local_ip" {
  count            = var.environment == "dev" ? 1 : 0
  name             = "allow-access-from-local-ip"
  server_id        = module.dev_postresql_database[0].dev_database_server_id
  start_ip_address = local.myip
  end_ip_address   = local.myip
}

# Demo purposes only: assign current user as admin for the dev DB
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "dev-contoso-ad-admin" {
  count               = var.environment == "dev" ? 1 : 0
  server_name         = module.dev_postresql_database[0].dev_database_name
  resource_group_name = azurerm_resource_group.dev[0].name
  tenant_id           = data.azuread_client_config.current.tenant_id
  object_id           = data.azuread_client_config.current.object_id
  principal_name      = data.azuread_client_config.current.object_id
  principal_type      = "User"
}

resource "azurerm_postgresql_flexible_server_database" "dev_postresql_database_db" {
  count     = var.environment == "dev" ? 1 : 0
  name      = "${var.application_name}db"
  server_id = module.dev_postresql_database[0].dev_database_server_id
}
