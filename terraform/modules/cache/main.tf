terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

resource "azurecaf_name" "cache" {
  random_length = "15"
  resource_type = "azurerm_redis_cache"
  suffixes      = [var.environment]
}

resource "azurerm_redis_cache" "cache" {
  name                = azurecaf_name.cache.result
  location            = var.location
  resource_group_name = var.resource_group
  capacity            = var.environment == "prod" ? 1 : 0
  family              = "C"
  sku_name            = var.environment == "prod" ? "Standard" : "Basic"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }
}