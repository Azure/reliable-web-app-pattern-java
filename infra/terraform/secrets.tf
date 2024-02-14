locals {
  contoso_client_id     = module.ad.application_registration_id
  contoso_tenant_id     = data.azuread_client_config.current.tenant_id
}

# For demo purposes, allow current user access to the key vault
# Note: when running as a service principal, this is also needed
resource azurerm_role_assignment kv_administrator_user_role_assignement {
  scope                 = module.key-vault.vault_id
  role_definition_name  = "Key Vault Administrator"
  principal_id          = data.azuread_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "contoso_database_url" {
  name         = "contoso-database-url"
  value        = "jdbc:postgresql://${module.postresql_database.database_fqdn}:5432/${azurerm_postgresql_flexible_server_database.postresql_database.name}"
  key_vault_id = module.key-vault.vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_database_admin" {
  name         = "contoso-database-admin"
  value        = module.postresql_database.database_username
  key_vault_id = module.key-vault.vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_database_admin_password" {
  name         = "contoso-database-admin-password"
  value        = local.database_administrator_password
  key_vault_id = module.key-vault.vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_application_tenant_id" {
  name         = "contoso-application-tenant-id"
  value        = local.contoso_tenant_id
  key_vault_id = module.key-vault.vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_application_client_id" {
  name         = "contoso-application-client-id"
  value        = local.contoso_client_id
  key_vault_id = module.key-vault.vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_application_client_secret" {
  name         = "contoso-application-client-secret"
  value        = module.ad.application_client_secret
  key_vault_id = module.key-vault.vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_cache_secret" {
  name         = "contoso-redis-password"
  value        = module.cache.cache_secret
  key_vault_id = module.key-vault.vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_app_insights_connection_string" {
  name         = "contoso-app-insights-connection-string"
  value        = module.app_insights.connection_string
  key_vault_id = module.key-vault.vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

# ----------------------------------------------------------------------------------------------
# 2nd region
# ----------------------------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "secondary_contoso_database_url" {
  count = local.is_multi_region ? 1 : 0
  
  name         = "contoso-secondary-database-url"
  value        = "jdbc:postgresql://${module.secondary_postresql_database[0].database_fqdn}:5432/${azurerm_postgresql_flexible_server_database.postresql_database.name}"
  key_vault_id = module.key-vault.vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

# Give the app access to the key vault secrets - https://learn.microsoft.com/azure/key-vault/general/rbac-guide?tabs=azure-cli#secret-scope-role-assignment
resource azurerm_role_assignment app_keyvault_role_assignment {
  scope                 = module.key-vault.vault_id
  role_definition_name  = "Key Vault Secrets User"
  principal_id          = module.application.application_principal_id
}

resource azurerm_role_assignment app_keyvault_role_assignments {
  scope                 = module.key-vault.vault_id
  role_definition_name  = "Key Vault Secrets User"
  principal_id          = module.secondary_application[0].application_principal_id
}