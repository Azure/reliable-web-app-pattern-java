terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.26"
    }
  }
}

resource "azurecaf_name" "app_service_plan" {
  name          = var.application_name
  resource_type = "azurerm_app_service_plan"
  suffixes      = [var.location, var.environment]
}

# This creates the plan that the service use
resource "azurerm_service_plan" "application" {
  name                         = azurecaf_name.app_service_plan.result
  resource_group_name          = var.resource_group
  location                     = var.location
  
  sku_name = var.environment == "prod" ? "P2v3" : "P1v3"
  os_type  = "Linux"

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }
}

resource "azurecaf_name" "app_service" {
  name          = var.application_name
  resource_type = "azurerm_app_service"
  suffixes      = [var.location, var.environment]
}

# This creates the linux web app
resource "azurerm_linux_web_app" "application" {
  name                    = azurecaf_name.app_service.result
  location                = var.location
  resource_group_name     = var.resource_group
  service_plan_id         = azurerm_service_plan.application.id
  client_affinity_enabled = true
  https_only              = true

  virtual_network_subnet_id = var.subnet_id

  identity {
    type = "SystemAssigned"
  }

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
    "azd-service-name" = "application"
  }

  site_config {
    ftps_state              = "Disabled"
    minimum_tls_version     = "1.2"
    always_on               = true
    health_check_path       = "/"

    application_stack {
      java_server = "JAVA"
      java_server_version = "17"
      java_version = "17"
    }

    ip_restriction {
      service_tag               = "AzureFrontDoor.Backend"
      ip_address                = null
      virtual_network_subnet_id = null
      action                    = "Allow"
      priority                  = 100
      headers {
        x_azure_fdid      = [var.frontdoor_profile_uuid]
        x_fd_health_probe = []
        x_forwarded_for   = []
        x_forwarded_host  = []
      }
      name = "Allow traffic from Front Door"
    }
  }

  sticky_settings {
    app_setting_names = [
      "APPLICATIONINSIGHTS_CONNECTION_STRING",
    ]
  }

  logs {
    http_logs {
      file_system {
        retention_in_mb   = 35
        retention_in_days = 30
      }
    }
  }
}

# Configure Diagnostic Settings for App Service
resource "azurerm_monitor_diagnostic_setting" "app_service_diagnostic" {
  name                           = "app-service-diagnostic-settings"
  target_resource_id             = azurerm_linux_web_app.application.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  #log_analytics_destination_type = "AzureDiagnostics"

  enabled_log {
    category_group = "allLogs"

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  enabled_log {
    category_group = "audit"

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
