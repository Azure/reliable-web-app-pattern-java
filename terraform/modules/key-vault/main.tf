terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.26"
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

  enable_rbac_authorization = true

  sku_name = "standard"

  dynamic "network_acls" {
    for_each = var.network_acls != null ? [true] : []
    content {
      bypass                     = var.network_acls.bypass
      default_action             = var.network_acls.default_action
      ip_rules                   = var.network_acls.ip_rules
      virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
    }
  }

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }
}

# Azure Private DNS provides a reliable, secure DNS service to manage and
# resolve domain names in a virtual network without the need to add a custom DNS solution
# https://docs.microsoft.com/azure/dns/private-dns-privatednszone
resource "azurerm_private_dns_zone" "key_vault_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "virtual_network_link_redis" {
  name                  = "privatelink.vaultcore.azure.net"
  private_dns_zone_name = azurerm_private_dns_zone.key_vault_dns_zone.name
  virtual_network_id    = var.virtual_network_id
  resource_group_name   = var.resource_group
}

resource "azurerm_private_endpoint" "keyvault_private_endpoint" {
  name                = format("%s-private-endpoint", azurecaf_name.key_vault.result)
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = var.private_endpoint_subnet_id

  private_dns_zone_group {
    name                 = "privatednsrediszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault_dns_zone.id]
  }
  
  private_service_connection {
    name                           = "keyvault-privatelink"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.application.id
    subresource_names              = ["vault"]
  }
}

# Configure Diagnostic Settings for key vault
resource "azurerm_monitor_diagnostic_setting" "key_vault_diagnostic" {
  name                           = "key-vault-diagnostic-settings"
  target_resource_id             = azurerm_key_vault.application.id
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