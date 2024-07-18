terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.26"
    }
  }
}

# Quickstart: Use Terraform to create an Azure Database for MySQL - Flexible Server
# https://docs.microsoft.com/azure/mysql/flexible-server/quickstart-create-terraform?tabs=azure-cli


# Azure Private DNS provides a reliable, secure DNS service to manage and
# resolve domain names in a virtual network without the need to add a custom DNS solution
# https://docs.microsoft.com/azure/dns/private-dns-privatednszone
resource "azurerm_private_dns_zone" "postgresql_database" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "privatelink.${var.location}.postgres.database.azure.com"
  resource_group_name = var.resource_group
}

# After you create a private DNS zone in Azure, you'll need to link a virtual network to it.
# https://docs.microsoft.com/azure/dns/private-dns-virtual-network-links
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql_database" {
  count                 = var.environment == "prod" ? 1 : 0
  name                  = azurerm_private_dns_zone.postgresql_database[0].name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql_database[0].name
  virtual_network_id    = var.virtual_network_id
  resource_group_name   = var.resource_group
}

resource "azurecaf_name" "postgresql_server" {
  count         = var.environment == "prod" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_postgresql_flexible_server"
  suffixes      = [var.location, var.environment]
}

# It's recommended to use fine-grained access control in PostgreSQL when connecting to the database.
# https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-create-users
# https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-azure-ad-authentication
resource "azurerm_postgresql_flexible_server" "postgresql_database" {
  count               = var.environment == "prod" ? 1 : 0
  name                = azurecaf_name.postgresql_server[0].result
  resource_group_name = var.resource_group
  location            = var.location

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password

  sku_name                     = var.sku_name
  version                      = "16"

  public_network_access_enabled = false
  delegated_subnet_id          = var.subnet_network_id
  private_dns_zone_id          = azurerm_private_dns_zone.postgresql_database[0].id

  geo_redundant_backup_enabled = false

  # High Availability is only available in prod and is not available for the Read replica.
  dynamic high_availability {
    for_each = var.environment == "prod" && var.source_server_id == null ? ["this"] : []

    content {
      mode = "ZoneRedundant"
      standby_availability_zone = 2
    }
  }

  zone = 1
  storage_mb = 32768

  create_mode = var.source_server_id != null ? "Replica" : null
  source_server_id = var.source_server_id

  authentication {
    active_directory_auth_enabled  = true
    password_auth_enabled          = true

    tenant_id = var.azure_ad_tenant_id
  }

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql_database]
}

# Configure Diagnostic Settings for PostgreSQL
resource "azurerm_monitor_diagnostic_setting" "postgresql_diagnostic" {
  count                          = var.environment == "prod" ? 1 : 0
  name                           = "postgresql-diagnostic-settings"
  target_resource_id             = azurerm_postgresql_flexible_server.postgresql_database[0].id
  log_analytics_workspace_id     = var.log_analytics_workspace_id

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

# ------------------
#  Dev - PostgreSQL
# ------------------

resource "azurecaf_name" "dev_postgresql_server" {
  count         = var.environment == "dev" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_postgresql_flexible_server"
  suffixes      = [var.location, var.environment]
}

resource "azurerm_postgresql_flexible_server" "dev_postresql_database" {
  count                         = var.environment == "dev" ? 1 : 0
  name                          = azurecaf_name.dev_postgresql_server[0].result
  resource_group_name           = var.resource_group
  location                      = var.location
  administrator_login           = var.administrator_login
  administrator_password        = var.administrator_password
  sku_name                      = var.sku_name
  version                       = "16"
  geo_redundant_backup_enabled  = false
  storage_mb                    = 32768
  zone                          = 1

  authentication {
      active_directory_auth_enabled  = true
      password_auth_enabled          = true
      tenant_id                      = var.azure_ad_tenant_id
  }

  tags = {
      "environment"      = var.environment
      "application-name" = var.application_name
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "dev_postresql_database_allow_access_rule" {
  count            = var.environment == "dev" ? 1 : 0
  name             = "allow-access-from-azure-services"
  server_id        = azurerm_postgresql_flexible_server.dev_postresql_database[0].id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
