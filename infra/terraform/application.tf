module "application" {
  source             = "../shared/terraform/modules/app-service"
  resource_group     = azurerm_resource_group.spoke.name
  application_name   = var.application_name
  environment        = local.environment
  location           = var.location

  subnet_id          = module.spoke_vnet.subnets[local.app_service_subnet_name].id

  app_insights_connection_string = module.app_insights.connection_string
  log_analytics_workspace_id     = module.app_insights.log_analytics_workspace_id

  contoso_webapp_options = {
    contoso_active_directory_tenant_id = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_application_tenant_id.id})"
    contoso_active_directory_client_id = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_application_client_id.id})"
    contoso_active_directory_client_secret = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_application_client_secret.id})"

    postgresql_database_url = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_database_url.id})"
    postgresql_database_user = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_database_admin.id})"
    postgresql_database_password = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_database_admin_password.id})"

    redis_host_name = module.cache.cache_hostname
    redis_port = module.cache.cache_ssl_port
    redis_password = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_cache_secret.id})"
  }

  frontdoor_host_name     = module.frontdoor.host_name
  frontdoor_profile_uuid  = module.frontdoor.resource_guid
}

# ----------------------------------------------------------------------------------------------
# 2nd region
# ----------------------------------------------------------------------------------------------

module "secondary_application" {
  count = local.is_multi_region ? 1 : 0

  source             = "../shared/terraform/modules/app-service"
  resource_group     = azurerm_resource_group.secondary_spoke[0].name
  application_name   = var.application_name
  environment        = local.environment
  location           = var.secondary_location

  subnet_id          = module.secondary_spoke_vnet[0].subnets[local.app_service_subnet_name].id

  app_insights_connection_string = module.app_insights.connection_string
  log_analytics_workspace_id     = module.app_insights.log_analytics_workspace_id

  contoso_webapp_options = {
    contoso_active_directory_tenant_id = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_application_tenant_id.id})"
    contoso_active_directory_client_id = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_application_client_id.id})"
    contoso_active_directory_client_secret = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_application_client_secret.id})"

    postgresql_database_url = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.secondary_contoso_database_url[0].id})"
    postgresql_database_user = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_database_admin.id})"
    postgresql_database_password = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_database_admin_password.id})"

    redis_host_name = module.secondary_cache[0].cache_hostname
    redis_port = module.secondary_cache[0].cache_ssl_port
    redis_password = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_cache_secret.id})"
  }

  frontdoor_host_name     = module.frontdoor.host_name
  frontdoor_profile_uuid  = module.frontdoor.resource_guid
}