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
      java_server = "TOMCAT"
      java_server_version = "9.0"
      java_version = "11"
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

  storage_account {
    name = "training_content"
    type = "AzureFiles"
    account_name = var.storage_account_name
    access_key = var.storage_account_primary_access_key
    share_name = var.trainings_share_name
    mount_path = "/var/proseware"
  }

  storage_account {
    name = "playlist_content"
    type = "AzureFiles"
    account_name = var.storage_account_name
    access_key = var.storage_account_primary_access_key
    share_name = var.playlist_share_name
    mount_path = "/var/playlists"
  }

  sticky_settings {
    app_setting_names = [
      "APPLICATIONINSIGHTS_CONNECTION_STRING",
    ]
  }

  app_settings = {
    SPRING_DATASOURCE_URL = "jdbc:postgresql://${var.database_fqdn}:5432/${var.database_name}?stringtype=unspecified"
    
    SPRING_REDIS_HOST = var.redis_host
    SPRING_REDIS_PORT = var.redis_port

    SPRING_CLOUD_AZURE_ACTIVE_DIRECTORY_CREDENTIAL_CLIENT_ID = var.proseware_client_id
    SPRING_CLOUD_AZURE_ACTIVE_DIRECTORY_PROFILE_TENANT_ID    = var.proseware_tenant_id

    SPRING_CLOUD_AZURE_KEYVAULT_SECRET_PROPERTY_SOURCES_0_ENDPOINT=var.key_vault_uri

    AIRSONIC_RETRY_DEMO = ""

    APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection_string
    APPLICATIONINSIGHTS_SAMPLING_REQUESTS_PER_SECOND = 10
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
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
