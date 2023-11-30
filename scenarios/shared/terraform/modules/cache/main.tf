terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.26"
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
  minimum_tls_version = "1.2"
  # public network access will be allowed for non-prod so devs can do integration testing while debugging locally
  public_network_access_enabled = var.environment == "prod" ? false : true

  # https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-configure#default-redis-server-configuration
  redis_configuration {
  }
}

# Azure Private DNS provides a reliable, secure DNS service to manage and
# resolve domain names in a virtual network without the need to add a custom DNS solution
# https://docs.microsoft.com/azure/dns/private-dns-privatednszone
resource "azurerm_private_dns_zone" "dns_for_cache" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = var.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "virtual_network_link_redis" {
  name                  = "privatelink.redis.cache.windows.net"
  private_dns_zone_name = azurerm_private_dns_zone.dns_for_cache.name
  virtual_network_id    = var.private_endpoint_vnet_id
  resource_group_name   = var.resource_group
}

resource "azurerm_private_endpoint" "redis_pe_redis" {
  name                = "private-endpoint-redis"
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = var.private_endpoint_subnet_id

   private_dns_zone_group {
    name                 = "privatednsrediszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_for_cache.id]
  }

  private_service_connection {
    name                           = "peconnection-redis"
    private_connection_resource_id = azurerm_redis_cache.cache.id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }
}

# Configure Diagnostic Settings for redis
resource "azurerm_monitor_diagnostic_setting" "redis_diagnostic" {
  name                           = "redis-diagnostic-settings"
  target_resource_id             = azurerm_redis_cache.cache.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  #log_analytics_destination_type = "AzureDiagnostics"

  enabled_log {
    category_group = "audit"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category_group = "allLogs"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = false
      days    = 0
    }
  }
}
