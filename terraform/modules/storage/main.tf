terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

resource "azurecaf_name" "app_storage" {
  name          = var.application_name
  resource_type = "azurerm_storage_account"
  suffixes      = [var.environment]
}

resource "azurerm_storage_account" "sa" {
  name                     = azurecaf_name.app_storage.result
  resource_group_name      = var.resource_group
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
