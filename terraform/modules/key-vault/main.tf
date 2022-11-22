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

  access_policy {
    tenant_id = var.azure_ad_tenant_id
    object_id = var.azure_ad_object_id

    secret_permissions = [
      "Set",
      "Get",
      "List",
      "Delete",
      "Purge"
    ]

    key_permissions = [
      "Create",
      "Get",
      "List",
      "Delete",
      "Update",
      "Purge"
    ]

    storage_permissions = [
      "Set",
      "Get",
      "List",
      "Delete",
      "Purge"
    ]
  }

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


resource "azurerm_key_vault_secret" "airsonic_database_username" {
  name         = "airsonic-database-username"
  value        = var.airsonic_database_username
  key_vault_id = azurerm_key_vault.application.id
}

resource "azurerm_key_vault_secret" "airsonic_database_password" {
  name         = "airsonic-database-password"
  value        = var.airsonic_database_password
  key_vault_id = azurerm_key_vault.application.id
}