# Generate password if none provided
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  database_administrator_password = coalesce(var.database_administrator_password, random_password.password.result)
}

data "azurerm_subnet" "postgresql_subnet" {
  name                 = local.postgresql_subnet_name
  resource_group_name  = local.spoke_vnet_resource_group
  virtual_network_name = local.spoke_vnet_name
}

module "postresql_database" {
  source                      = "../../../shared/terraform/modules/postresql"
  azure_ad_tenant_id          = data.azuread_client_config.current.tenant_id
  resource_group              = local.spoke_vnet_resource_group
  application_name            = var.application_name
  environment                 = local.environment
  location                    = var.location
  virtual_network_id          = var.spoke_vnet_id

  subnet_network_id           = data.azurerm_subnet.postgresql_subnet.id

  administrator_password      = local.database_administrator_password
  log_analytics_workspace_id  = var.log_analytics_workspace_id
  sku_name                    = local.postgresql_sku_name
}

resource "azurerm_postgresql_flexible_server_database" "postresql_database" {
  name                = "${var.application_name}db"
  server_id           = module.postresql_database.database_server_id
}

# Demo purposes only: assign current user as admin to the created DB
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "contoso-ad-admin" {
  server_name         = module.postresql_database.database_name
  resource_group_name = local.spoke_vnet_resource_group
  tenant_id           = data.azuread_client_config.current.tenant_id
  object_id           = data.azuread_client_config.current.object_id
  principal_name      = data.azuread_client_config.current.object_id
  principal_type      = "User"
}