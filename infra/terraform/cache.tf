
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


resource "azurerm_redis_cache_access_policy_assignment" "primary_current_user" {
  count              = var.environment == "prod" ? 1 : 0
  name               = "primarycurrentuser"
  redis_cache_id     = module.cache[0].cache_id
  access_policy_name = "Data Owner"
  object_id          = data.azuread_client_config.current.object_id
  object_id_alias    = "currentuser"
}

resource "azurerm_redis_cache_access_policy_assignment" "app_user" {
  count              = var.environment == "prod" ? 1 : 0
  name               = "primaryappuser"
  redis_cache_id     = module.cache[0].cache_id
  access_policy_name = "Data Contributor"
  object_id          = azurerm_user_assigned_identity.primary_app_service_identity[0].principal_id
  object_id_alias    = azurerm_user_assigned_identity.primary_app_service_identity[0].principal_id

  depends_on = [
    azurerm_redis_cache_access_policy_assignment.primary_current_user
  ]
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

resource "azurerm_redis_cache_access_policy_assignment" "secondary_current_user" {
  count              = var.environment == "prod" ? 1 : 0
  name               = "secondarycurrentuser"
  redis_cache_id     = module.secondary_cache[0].cache_id
  access_policy_name = "Data Owner"
  object_id          = data.azuread_client_config.current.object_id
  object_id_alias    = "currentuser"
}

resource "azurerm_redis_cache_access_policy_assignment" "secondary_app_user" {
  count              = var.environment == "prod" ? 1 : 0
  name               = "secondaryappuser"
  redis_cache_id     = module.secondary_cache[0].cache_id
  access_policy_name = "Data Contributor"
  object_id          = azurerm_user_assigned_identity.secondary_app_service_identity[0].principal_id
  object_id_alias    = azurerm_user_assigned_identity.secondary_app_service_identity[0].principal_id

  depends_on = [
    azurerm_redis_cache_access_policy_assignment.secondary_current_user
  ]
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

resource "azurerm_redis_cache_access_policy_assignment" "dev_current_user" {
  count              = var.environment == "dev" ? 1 : 0
  name               = "devcurrentuser"
  redis_cache_id     = module.dev-cache[0].cache_id
  access_policy_name = "Data Owner"
  object_id          = data.azuread_client_config.current.object_id
  object_id_alias    = "currentuser"
}

resource "azurerm_redis_cache_access_policy_assignment" "dev_app_user" {
  count              = var.environment == "dev" ? 1 : 0
  name               = "devappuser"
  redis_cache_id     = module.dev-cache[0].cache_id
  access_policy_name = "Data Contributor"
  object_id          = azurerm_user_assigned_identity.dev_app_service_identity[0].principal_id
  object_id_alias    = azurerm_user_assigned_identity.dev_app_service_identity[0].principal_id

  depends_on = [
    azurerm_redis_cache_access_policy_assignment.dev_current_user
  ]
}
