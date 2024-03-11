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
  client_affinity_enabled = false
  https_only              = true

  public_network_access_enabled = var.public_network_access_enabled

  virtual_network_subnet_id = var.appsvc_subnet_id

  identity {
    type = "SystemAssigned"
  }

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
    "azd-service-name" = "application"
  }

  site_config {
    vnet_route_all_enabled = true
    use_32_bit_worker      = false

    ftps_state              = "Disabled"
    minimum_tls_version     = "1.2"
    always_on               = true
    health_check_path       = "/actuator/health"

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
      "ApplicationInsightsAgent_EXTENSION_VERSION"
    ]
  }

  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"

    SPRING_DATASOURCE_URL      = var.contoso_webapp_options.postgresql_database_url
    SPRING_DATASOURCE_USERNAME = var.contoso_webapp_options.postgresql_database_user
    SPRING_DATASOURCE_PASSWORD = var.contoso_webapp_options.postgresql_database_password

    SPRING_CLOUD_AZURE_ACTIVE_DIRECTORY_CREDENTIAL_CLIENT_ID     = var.contoso_webapp_options.contoso_active_directory_client_id
    SPRING_CLOUD_AZURE_ACTIVE_DIRECTORY_CREDENTIAL_CLIENT_SECRET = var.contoso_webapp_options.contoso_active_directory_client_secret
    SPRING_CLOUD_AZURE_ACTIVE_DIRECTORY_PROFILE_TENANT_ID        = var.contoso_webapp_options.contoso_active_directory_tenant_id

    SPRING_DATA_REDIS_HOST = var.contoso_webapp_options.redis_host_name
    SPRING_DATA_REDIS_PORT = var.contoso_webapp_options.redis_port
    SPRING_DATA_REDIS_PASSWORD = var.contoso_webapp_options.redis_password

    CONTOSO_RETRY_DEMO = "0"
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

module "private_endpoint" {
  count                       = var.environment == "prod" ? 1 : 0
  source                      = "./private-endpoint"
  resource_group              = var.resource_group
  location                    = var.location
  app_service_name            = azurerm_linux_web_app.application.name
  appsvc_webapp_id            = azurerm_linux_web_app.application.id 
  private_endpoint_subnet_id  = var.private_endpoint_subnet_id
  private_dns_resource_group  = var.private_dns_resource_group
}

# Configure Diagnostic Settings for App Service
resource "azurerm_monitor_diagnostic_setting" "app_service_diagnostic" {
  name                           = "app-service-diagnostic-settings"
  target_resource_id             = azurerm_linux_web_app.application.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  #log_analytics_destination_type = "AzureDiagnostics"

  enabled_log {
    category_group = "allLogs"

    ## `retention_policy` has been deprecated in favor of `azurerm_storage_management_policy` resource - to learn more https://aka.ms/diagnostic_settings_log_retention
    # retention_policy {
    #   days    = 0
    #   enabled = false
    # }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    ## `retention_policy` has been deprecated in favor of `azurerm_storage_management_policy` resource - to learn more https://aka.ms/diagnostic_settings_log_retention
    # retention_policy {
    #   days    = 0
    #   enabled = false
    # }
  }
}


# Configure scaling
resource "azurerm_monitor_autoscale_setting" "app_service_scaling" {
  name                = "contosocamsscaling"
  resource_group_name = var.resource_group
  location            = var.location
  target_resource_id  = azurerm_service_plan.application.id
  profile {
    name = "default"
    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }
    rule {
      metric_trigger {
        metric_name         = "CpuPercentage"
        metric_resource_id  = azurerm_service_plan.application.id
        time_grain          = "PT1M"
        statistic           = "Average"
        time_window         = "PT5M"
        time_aggregation    = "Average"
        operator            = "GreaterThan"
        threshold           = 85
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name         = "CpuPercentage"
        metric_resource_id  = azurerm_service_plan.application.id
        time_grain          = "PT1M"
        statistic           = "Average"
        time_window         = "PT5M"
        time_aggregation    = "Average"
        operator            = "LessThan"
        threshold           = 65
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}