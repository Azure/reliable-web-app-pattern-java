terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

resource "azurecaf_name" "key_vault" {
  random_length = "15"
  resource_type = "azurerm_key_vault"
  suffixes      = [var.environment]
}

resource "azurerm_key_vault" "application" {
  name                = azurecaf_name.key_vault.result
  resource_group_name = var.resource_group
  location            = var.location

  tenant_id                  = var.azure_ad_tenant_id
  soft_delete_retention_days = 7

  sku_name = "standard"

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }
}

resource "azurerm_key_vault_secret" "airsonic_database_admin" {
  name         = "airsonic-database-admin"
  value        = var.airsonic_database_admin
  key_vault_id = azurerm_key_vault.application.id
}

resource "azurerm_key_vault_secret" "airsonic_database_admin_password" {
  name         = "airsonic-database-admin-password"
  value        = var.airsonic_database_admin_password
  key_vault_id = azurerm_key_vault.application.id
}

resource "azurerm_key_vault_secret" "airsonic_application_client_id" {
  name         = "airsonic-application-client-id"
  value        = var.airsonic_application_client_id
  key_vault_id = azurerm_key_vault.application.id
}

resource "azurerm_key_vault_secret" "airsonic_application_client_secret" {
  name         = "airsonic-application-client-secret"
  value        = var.airsonic_application_client_secret
  key_vault_id = azurerm_key_vault.application.id
}

resource "azurerm_key_vault_secret" "airsonic_application_tenant_id" {
  name         = "airsonic-application-tenant-id"
  value        = var.azure_ad_tenant_id
  key_vault_id = azurerm_key_vault.application.id
}