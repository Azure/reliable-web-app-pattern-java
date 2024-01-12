data "azurerm_subnet" "app_service_subnet" {
  name                 = local.app_service_subnet_name
  resource_group_name  = local.spoke_vnet_resource_group
  virtual_network_name = local.spoke_vnet_name
}

module "application" {
  source             = "../../../shared/terraform/modules/app-service"
  resource_group     = local.spoke_vnet_resource_group
  application_name   = var.application_name
  environment        = local.environment
  location           = var.location

  subnet_id          = data.azurerm_subnet.app_service_subnet.id

  app_insights_connection_string = data.azurerm_application_insights.app_insights.connection_string
  log_analytics_workspace_id     = var.log_analytics_workspace_id

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
