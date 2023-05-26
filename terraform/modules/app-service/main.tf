terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.33.0"
    }
  }
}

data "azuread_client_config" "current" {}

resource "azurecaf_name" "app_service_plan" {
  name          = var.application_name
  resource_type = "azurerm_app_service_plan"
  suffixes      = [var.location, var.environment]
}

# This creates the plan that the service use
resource "azurerm_service_plan" "application" {
  name                         = "ken-app-svc-20230522-${var.principal_type}"#azurecaf_name.app_service_plan.result
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

resource "random_uuid" "admin_role_id" {}
resource "random_uuid" "user_role_id" {}
resource "random_uuid" "creator_role_id" {}

resource "azuread_application" "app_registration" {
  display_name     = "${azurecaf_name.app_service.result}-app"
  count            = var.principal_type == "User" ? 1 : 0
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"  # single tenant

  app_role {
    allowed_member_types = ["User"]
    description          = "ReadOnly roles have limited query access"
    display_name         = "ReadOnly"
    enabled              = true
    id                   = random_uuid.user_role_id.result
    value                = "User"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "Creator roles allows users to create content"
    display_name         = "Creator"
    enabled              = true
    id                   = random_uuid.creator_role_id.result
    value                = "Creator"
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read https://marketplace.visualstudio.com/items?itemName=stephane-eyskens.aadv1appprovisioning
      type = "Scope"
    }
  }

  web {
    homepage_url  = "https://${var.frontdoor_host_name}"
    logout_url    = "https://${var.frontdoor_host_name}/logout"
    redirect_uris = ["https://${var.frontdoor_host_name}/login/oauth2/code/"]
    implicit_grant {
      id_token_issuance_enabled     = true
    }
  }
}

resource "azuread_service_principal" "application_service_principal" {
  application_id               = var.principal_type == "User" ? azuread_application.app_registration[0].application_id : "Ran as ServicePrincipal"
  count                        = var.principal_type == "User" ? 1 : 0
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_password" "application_password" {
  count                 = var.principal_type == "User" ? 1 : 0
  application_object_id = var.principal_type == "User" ? azuread_application.app_registration[0].object_id : "Ran as ServicePrincipal"
}

# This is not guidance and is done for demo purposes. The resource below will add the 
# "Creator" app role assignment for the application of the current user deploying this sample.
resource "azuread_app_role_assignment" "application_role_current_user" {
  app_role_id         = azuread_service_principal.application_service_principal[0].app_role_ids["Creator"]
  count               = var.principal_type == "User" ? 1 : 0
  principal_object_id = data.azuread_client_config.current.object_id
  resource_object_id  = azuread_service_principal.application_service_principal[0].object_id
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
    health_check_path       = "/actuator/health"

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

# Configure scaling
#resource "azurerm_monitor_autoscale_setting" "airsonicscaling" {
#  name                = "airsonicscaling"
#  resource_group_name = var.resource_group
#  location            = var.location
#  target_resource_id  = azurerm_service_plan.application.id
#  profile {
#    name = "default"
#    capacity {
#      default = 2
#      minimum = 2
#      maximum = 10
#    }
#    rule {
#      metric_trigger {
#        metric_name         = "CpuPercentage"
#        metric_resource_id  = azurerm_service_plan.application.id
#        time_grain          = "PT1M"
#        statistic           = "Average"
#        time_window         = "PT5M"
#        time_aggregation    = "Average"
#        operator            = "GreaterThan"
#        threshold           = 85
#      }
#      scale_action {
#        direction = "Increase"
#        type      = "ChangeCount"
#        value     = "1"
#        cooldown  = "PT1M"
#      }
#    }
#    rule {
#      metric_trigger {
#        metric_name         = "CpuPercentage"
#        metric_resource_id  = azurerm_service_plan.application.id
#        time_grain          = "PT1M"
#        statistic           = "Average"
#        time_window         = "PT5M"
#        time_aggregation    = "Average"
#        operator            = "LessThan"
#        threshold           = 65
#      }
#      scale_action {
#        direction = "Decrease"
#        type      = "ChangeCount"
#        value     = "1"
#        cooldown  = "PT1M"
#      }
#    }
#  }
#}