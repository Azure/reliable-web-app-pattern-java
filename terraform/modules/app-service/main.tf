terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

data "azuread_client_config" "current" {}

resource "azurecaf_name" "app_workspace" {
  name          = var.application_name
  resource_type = "azurerm_log_analytics_workspace"
  suffixes      = [var.environment]
}

# Log Analiytics Workspace
resource "azurerm_log_analytics_workspace" "app_workspace" {
  name                = azurecaf_name.app_workspace.result
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurecaf_name" "app_insights" {
  name          = var.application_name
  resource_type = "azurerm_application_insights"
  suffixes      = [var.environment]
}

# Application Insight
resource "azurerm_application_insights" "app_insights" {
  name                = azurecaf_name.app_insights.result
  location            = var.location
  resource_group_name = var.resource_group
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.app_workspace.id
}

resource "azurerm_storage_share" "sashare" {
  name                 = "music"
  storage_account_name = var.storage_account_name
  quota                = 50
}

resource "azurecaf_name" "app_service_plan" {
  name          = var.application_name
  resource_type = "azurerm_app_service_plan"
  suffixes      = [var.environment]
}

# This creates the plan that the service use
resource "azurerm_service_plan" "application" {
  name                = azurecaf_name.app_service_plan.result
  resource_group_name = var.resource_group
  location            = var.location

  sku_name = "P1v2"
  os_type  = "Linux"

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }
}

resource "azurecaf_name" "app_service" {
  name          = var.application_name
  resource_type = "azurerm_app_service"
  suffixes      = [var.environment]
}

resource "random_uuid" "widgets_scope_id" {}

resource "azuread_application" "app_registration" {
  display_name     = "${azurecaf_name.app_service.result}-app"
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"


  api {
    oauth2_permission_scope {
        admin_consent_description  = "Allow the application to access ${azurecaf_name.app_service.result} on behalf of the signed-in user."
        admin_consent_display_name = "Access ${azurecaf_name.app_service.result}"
        id                         = random_uuid.widgets_scope_id.result
        enabled                    = true
        type                       = "User"
        user_consent_description   = "Allow the application to access ${azurecaf_name.app_service.result} on your behalf."
        user_consent_display_name  = "Access ${azurecaf_name.app_service.result}"
        value                      = "user_impersonation"
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read https://marketplace.visualstudio.com/items?itemName=stephane-eyskens.aadv1appprovisioning
      type = "Scope"
    }
  }

  web {
    homepage_url  = "https://${azurecaf_name.app_service.result}.azurewebsites.net"
    redirect_uris = ["https://${azurecaf_name.app_service.result}.azurewebsites.net/.auth/login/aad/callback"]
    implicit_grant {
      id_token_issuance_enabled     = true
    }
  }
}

# This creates the linux web app
resource "azurerm_linux_web_app" "application" {
  name                = azurecaf_name.app_service.result
  location            = var.location
  resource_group_name = var.resource_group
  service_plan_id     = azurerm_service_plan.application.id
  https_only          = true

  virtual_network_subnet_id = var.subnet_id

  identity {
    type = "SystemAssigned"
  }

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }

  site_config {
    always_on        = false
    vnet_route_all_enabled = true
    application_stack {
      java_server = "TOMCAT"
      java_server_version = "9.0"
      java_version = "jre8"
    }
  }

  storage_account {
    name = "music_content"
    type = "AzureFiles"
    account_name = var.storage_account_name
    access_key = var.storage_account_primary_access_key
    share_name = azurerm_storage_share.sashare.name 
    mount_path = "/var/music"
  }

  # https://airsonic.github.io/docs/database/#postgresql
  app_settings = {
    DatabaseConfigType          = "embed"
    DatabaseConfigEmbedDriver   = "org.postgresql.Driver"
    DatabaseConfigEmbedUrl      = "jdbc:postgresql://${var.database_fqdn}:5432/${var.database_name}?stringtype=unspecified"
    DatabaseConfigEmbedUsername = var.database_username
    DatabaseConfigEmbedPassword = var.database_password
    DatabaseUsertableQuote      = "\""
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.app_insights.connection_string
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

  auth_settings {
    enabled = true
    runtime_version = "~2"
    active_directory {
      client_id = azuread_application.app_registration.application_id
    }
  }
}

resource "azurecaf_name" "app_service_diagnostic" {
  name          = var.application_name
  resource_type = "azurerm_monitor_diagnostic_setting"
  suffixes      = [var.environment]
}

# Configure Diagnostic Settings for App Service
resource "azurerm_monitor_diagnostic_setting" "app_service_diagnostic" {
  name                       = azurecaf_name.app_service_diagnostic.result
  target_resource_id         = azurerm_linux_web_app.application.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.app_workspace.id

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = false
      days    = 0
    }
  }
}
