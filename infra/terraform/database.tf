# Generate password if none provided
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  database_administrator_password = coalesce(var.database_administrator_password, random_password.password.result)
}

module "postresql_database" {
  source                      = "../shared/terraform/modules/postresql"
  azure_ad_tenant_id          = data.azuread_client_config.current.tenant_id
  resource_group              = azurerm_resource_group.spoke.name
  application_name            = var.application_name
  environment                 = local.environment
  location                    = var.location
  virtual_network_id          = module.spoke_vnet.vnet_id

  subnet_network_id           = module.spoke_vnet.subnets[local.postgresql_subnet_name].id

  administrator_password      = local.database_administrator_password
  log_analytics_workspace_id  = module.app_insights.log_analytics_workspace_id
  sku_name                    = local.postgresql_sku_name
}

resource "azurerm_postgresql_flexible_server_database" "postresql_database" {
  name                = "${var.application_name}db"
  server_id           = module.postresql_database.database_server_id
}

# Demo purposes only: assign current user as admin to the created DB
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "contoso-ad-admin" {
  server_name         = module.postresql_database.database_name
  resource_group_name = azurerm_resource_group.spoke.name
  tenant_id           = data.azuread_client_config.current.tenant_id
  object_id           = data.azuread_client_config.current.object_id
  principal_name      = data.azuread_client_config.current.object_id
  principal_type      = "User"
}

# ----------------------------------------------------------------------------------------------
# 2nd region
# ----------------------------------------------------------------------------------------------

module "secondary_postresql_database" {
  count = local.is_multi_region ? 1 : 0

  source                      = "../shared/terraform/modules/postresql"
  azure_ad_tenant_id          = data.azuread_client_config.current.tenant_id
  resource_group              = azurerm_resource_group.secondary_spoke[0].name
  application_name            = var.application_name
  environment                 = local.environment
  location                    = var.secondary_location
  virtual_network_id          = module.secondary_spoke_vnet[0].vnet_id
  subnet_network_id           = module.secondary_spoke_vnet[0].subnets[local.postgresql_subnet_name].id
  source_server_id            = module.postresql_database.database_server_id
  administrator_password      = local.database_administrator_password
  log_analytics_workspace_id  = module.app_insights.log_analytics_workspace_id
  sku_name                    = local.postgresql_sku_name

  depends_on = [
    module.spoke_vnet,
    module.secondary_spoke_vnet[0],
    module.peeringSpoke2ToSpoke,
    module.peeringSpokeToSpoke2
  ]
}
