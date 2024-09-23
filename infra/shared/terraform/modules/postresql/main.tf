terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.26"
    }
  }
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
  private_dns_zone_id          = var.private_dns_zone_id #azurerm_private_dns_zone.postgresql_database[0].id

  geo_redundant_backup_enabled = false

  # High Availability is only available in prod and is not available for the Read replica.
  dynamic high_availability {
    for_each = var.environment == "prod" && var.source_server_id == null ? ["this"] : []

    content {
      mode = "ZoneRedundant"
    }
  }

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

  lifecycle {
    ignore_changes = [
      zone,
      high_availability.0.standby_availability_zone
    ]
  }
}

# Configure Diagnostic Settings for PostgreSQL
resource "azurerm_monitor_diagnostic_setting" "postgresql_diagnostic" {
  count                          = var.environment == "prod" ? 1 : 0
  name                           = "postgresql-diagnostic-settings"
  target_resource_id             = azurerm_postgresql_flexible_server.postgresql_database[0].id
  log_analytics_workspace_id     = var.log_analytics_workspace_id

  enabled_log {
    category_group = "audit"
  }

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
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
