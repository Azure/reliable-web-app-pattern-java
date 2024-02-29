 
locals {
  contoso_client_id     = var.environment == "prod" ? module.ad[0].application_registration_id : null
  contoso_tenant_id     = data.azuread_client_config.current.tenant_id
  dev_contoso_client_id = var.environment == "dev" ? module.dev_ad[0].application_registration_id : null
}

# For demo purposes, allow current user access to the key vault
# Note: when running as a service principal, this is also needed
resource azurerm_role_assignment kv_administrator_user_role_assignement {
  count                 = var.environment == "prod" ? 1 : 0
  scope                 = module.hub_key_vault[0].vault_id
  role_definition_name  = "Key Vault Administrator"
  principal_id          = data.azuread_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "contoso_database_url" {
  count        = var.environment == "prod" ? 1 : 0
  name         = "contoso-database-url"
  value        = "jdbc:postgresql://${module.postresql_database[0].database_fqdn}:5432/${azurerm_postgresql_flexible_server_database.postresql_database[0].name}"
  key_vault_id = module.hub_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_database_admin" {
  count        = var.environment == "prod" ? 1 : 0
  name         = "contoso-database-admin"
  value        = module.postresql_database[0].database_username
  key_vault_id = module.hub_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_database_admin_password" {
  count        = var.environment == "prod" ? 1 : 0
  name         = "contoso-database-admin-password"
  value        = local.database_administrator_password
  key_vault_id = module.hub_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_application_tenant_id" {
  count        = var.environment == "prod" ? 1 : 0
  name         = "contoso-application-tenant-id"
  value        = local.contoso_tenant_id
  key_vault_id = module.hub_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_application_client_id" {
  count        = var.environment == "prod" ? 1 : 0
  name         = "contoso-application-client-id"
  value        = local.contoso_client_id
  key_vault_id = module.hub_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_application_client_secret" {
  count        = var.environment == "prod" ? 1 : 0
  name         = "contoso-application-client-secret"
  value        = module.ad[0].application_client_secret
  key_vault_id = module.hub_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_cache_secret" {
  count        = var.environment == "prod" ? 1 : 0
  name         = "contoso-redis-password"
  value        = module.cache[0].cache_secret
  key_vault_id = module.hub_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "contoso_app_insights_connection_string" {
  count        = var.environment == "prod" ? 1 : 0
  name         = "contoso-app-insights-connection-string"
  value        = module.hub_app_insights[0].connection_string
  key_vault_id = module.hub_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

# ----------------------------------------------------------------------------------------------
# 2nd region
# ----------------------------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "secondary_contoso_database_url" {
  count        = var.environment == "prod" ? 1 : 0 
  name         = "contoso-secondary-database-url"
  value        = "jdbc:postgresql://${module.secondary_postresql_database[0].database_fqdn}:5432/${azurerm_postgresql_flexible_server_database.postresql_database[0].name}"
  key_vault_id = module.hub_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.kv_administrator_user_role_assignement
  ]
}

# Give the app access to the key vault secrets - https://learn.microsoft.com/azure/key-vault/general/rbac-guide?tabs=azure-cli#secret-scope-role-assignment
resource azurerm_role_assignment app_keyvault_role_assignment {
  count                 = var.environment == "prod" ? 1 : 0
  scope                 = module.hub_key_vault[0].vault_id
  role_definition_name  = "Key Vault Secrets User"
  principal_id          = module.application[0].application_principal_id
}

resource azurerm_role_assignment app_keyvault_role_assignments {
  count                 = var.environment == "prod" ? 1 : 0
  scope                 = module.hub_key_vault[0].vault_id
  role_definition_name  = "Key Vault Secrets User"
  principal_id          = module.secondary_application[0].application_principal_id
}

# ------
#  Dev
# ------

# For demo purposes, allow current user access to the key vault
# Note: when running as a service principal, this is also needed
resource azurerm_role_assignment dev_kv_administrator_user_role_assignement {
  count                 = var.environment == "dev" ? 1 : 0
  scope                 = module.dev_key_vault[0].vault_id
  role_definition_name  = "Key Vault Administrator"
  principal_id          = data.azuread_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "dev_contoso_database_url" {
  count        = var.environment == "dev" ? 1 : 0
  name         = "contoso-database-url"
  value        = "jdbc:postgresql://${module.dev_postresql_database[0].dev_database_fqdn}:5432/${azurerm_postgresql_flexible_server_database.dev_postresql_database_db[0].name}"
  key_vault_id = module.dev_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.dev_kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "dev_contoso_database_admin" {
  count        = var.environment == "dev" ? 1 : 0
  name         = "contoso-database-admin"
  value        = module.dev_postresql_database[0].database_username
  key_vault_id = module.dev_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.dev_kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "dev_contoso_database_admin_password" {
  count        = var.environment == "dev" ? 1 : 0
  name         = "contoso-database-admin-password"
  value        = local.database_administrator_password
  key_vault_id = module.dev_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.dev_kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "dev_contoso_application_tenant_id" {
  count        = var.environment == "dev" ? 1 : 0
  name         = "contoso-application-tenant-id"
  value        = local.contoso_tenant_id
  key_vault_id = module.dev_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.dev_kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "dev_contoso_application_client_id" {
  count        = var.environment == "dev" ? 1 : 0
  name         = "contoso-application-client-id"
  value        = local.dev_contoso_client_id
  key_vault_id = module.dev_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.dev_kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "dev_contoso_application_client_secret" {
  count        = var.environment == "dev" ? 1 : 0
  name         = "contoso-application-client-secret"
  value        = module.dev_ad[0].application_client_secret
  key_vault_id = module.dev_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.dev_kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "dev_contoso_cache_secret" {
  count        = var.environment == "dev" ? 1 : 0
  name         = "contoso-redis-password"
  value        = module.dev-cache[0].cache_secret
  key_vault_id = module.dev_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.dev_kv_administrator_user_role_assignement
  ]
}

resource "azurerm_key_vault_secret" "dev_contoso_app_insights_connection_string" {
  count        = var.environment == "dev" ? 1 : 0
  name         = "contoso-app-insights-connection-string"
  value        = module.dev_app_insights[0].connection_string
  key_vault_id = module.dev_key_vault[0].vault_id
  depends_on = [
    azurerm_role_assignment.dev_kv_administrator_user_role_assignement
  ]
}

# Give the app access to the key vault secrets - https://learn.microsoft.com/azure/key-vault/general/rbac-guide?tabs=azure-cli#secret-scope-role-assignment
resource azurerm_role_assignment dev_app_keyvault_role_assignment {
  count                 = var.environment == "dev" ? 1 : 0
  scope                 = module.dev_key_vault[0].vault_id
  role_definition_name  = "Key Vault Secrets User"
  principal_id          = module.dev_application[0].application_principal_id
}
