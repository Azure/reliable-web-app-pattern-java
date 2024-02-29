
# ----------------------------------------------------------------------------------------------
#  Cache - Prod - Primary Region
# ----------------------------------------------------------------------------------------------

module "cache" {
  count                       = var.environment == "prod" ? 1 : 0
  source                      = "../shared/terraform/modules/cache"
  resource_group              = azurerm_resource_group.spoke[0].name
  environment                 = var.environment
  location                    = var.location
  private_endpoint_vnet_id    = module.spoke_vnet[0].vnet_id
  private_endpoint_subnet_id  = module.spoke_vnet[0].subnets[local.private_link_subnet_name].id
  log_analytics_workspace_id  = module.hub_app_insights[0].log_analytics_workspace_id
}

# ----------------------------------------------------------------------------------------------
#  Cache - Prod - Secondary Region
# ----------------------------------------------------------------------------------------------

module "secondary_cache" {
  count                       = var.environment == "prod" ? 1 : 0
  source                      = "../shared/terraform/modules/cache"
  resource_group              = azurerm_resource_group.secondary_spoke[0].name
  environment                 = var.environment
  location                    = var.secondary_location
  private_endpoint_vnet_id    = module.secondary_spoke_vnet[0].vnet_id
  private_endpoint_subnet_id  = module.secondary_spoke_vnet[0].subnets[local.private_link_subnet_name].id
  log_analytics_workspace_id  = module.hub_app_insights[0].log_analytics_workspace_id
}

# ----------------------------------------------------------------------------------------------
# Cache - Dev
# ----------------------------------------------------------------------------------------------

module "dev-cache" {
  count                       = var.environment == "dev" ? 1 : 0
  source                      = "../shared/terraform/modules/cache"
  resource_group              = azurerm_resource_group.dev[0].name
  environment                 = var.environment
  location                    = var.location
  private_endpoint_vnet_id    = null
  private_endpoint_subnet_id  = null
  log_analytics_workspace_id  = module.dev_app_insights[0].log_analytics_workspace_id
}
