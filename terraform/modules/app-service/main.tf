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
  application_type    = "java"
  workspace_id        = azurerm_log_analytics_workspace.app_workspace.id
}

resource "azurerm_storage_share" "sashare_trainings" {
  name                 = "trainings"
  storage_account_name = var.storage_account_name
  quota                = 50
}

resource "azurerm_storage_share" "sashare_playlist" {
  name                 = "playlist"
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

  sku_name = var.environment == "prod" ? "P2v2" : "P1v2"
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

resource "random_uuid" "airsonic_scope_id" {}
resource "random_uuid" "admin_role_id" {}
resource "random_uuid" "user_role_id" {}
resource "random_uuid" "creator_role_id" {}

resource "azuread_application" "app_registration" {
  display_name     = "${azurecaf_name.app_service.result}-app"
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"  # single tenant

  api {
    oauth2_permission_scope {
        admin_consent_description  = "Allow the application to access ${azurecaf_name.app_service.result} on behalf of the signed-in user."
        admin_consent_display_name = "Access ${azurecaf_name.app_service.result}"
        id                         = random_uuid.airsonic_scope_id.result
        enabled                    = true
        type                       = "User"
        user_consent_description   = "Allow the application to access ${azurecaf_name.app_service.result} on your behalf."
        user_consent_display_name  = "Access ${azurecaf_name.app_service.result}"
        value                      = "user_impersonation"
    }
  }

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
    homepage_url  = "https://${azurecaf_name.app_service.result}.azurewebsites.net/index"
    logout_url    = "https://${azurecaf_name.app_service.result}.azurewebsites.net/logout"
    redirect_uris = ["https://${azurecaf_name.app_service.result}.azurewebsites.net/login/oauth2/code/", "https://${azurecaf_name.app_service.result}.azurewebsites.net/.auth/login/aad/callback", "https://${var.frontdoor_host_name}/.auth/login/aad/callback"]
    implicit_grant {
      id_token_issuance_enabled     = true
    }
  }
}

resource "azuread_service_principal" "application_service_principal" {
  application_id               = azuread_application.app_registration.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_password" "application_password" {
  application_object_id = azuread_application.app_registration.object_id
}

# Retrieve domain information
data "azuread_domains" "domain" {
  only_initial = true
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
    ftps_state              = "Disabled"
    minimum_tls_version     = "1.2"
    always_on               = false

    application_stack {
      java_server = "TOMCAT"
      java_server_version = "9.0"
      java_version = "11"
    }
  }

  storage_account {
    name = "training_content"
    type = "AzureFiles"
    account_name = var.storage_account_name
    access_key = var.storage_account_primary_access_key
    share_name = azurerm_storage_share.sashare_trainings.name 
    mount_path = "/var/proseware"
  }

  storage_account {
    name = "playlist_content"
    type = "AzureFiles"
    account_name = var.storage_account_name
    access_key = var.storage_account_primary_access_key
    share_name = azurerm_storage_share.sashare_playlist.name 
    mount_path = "/var/playlists"
  }

  # https://airsonic.github.io/docs/database/#postgresql
  app_settings = {
    DatabaseConfigType          = "embed"
    DatabaseConfigEmbedDriver   = "org.postgresql.Driver"
    DatabaseConfigEmbedUrl      = "jdbc:postgresql://${var.database_fqdn}:5432/${var.database_name}?stringtype=unspecified"
    DatabaseConfigEmbedUsername = var.database_username
    DatabaseConfigEmbedPassword = var.database_password

    AIRSONIC_RETRY_DEMO = ""

    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.app_insights.connection_string
    APPLICATIONINSIGHTS_SAMPLING_REQUESTS_PER_SECOND = 10
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
    
    SPRING_CLOUD_AZURE_KEYVAULT_SECRET_PROPERTY_SOURCES_0_ENDPOINT=var.key_vault_uri
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
    allowed_external_redirect_urls = ["https://${var.frontdoor_host_name}"]

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

# Configure scaling
resource "azurerm_monitor_autoscale_setting" "airsonicscaling" {
  name                = "airsonicscaling"
  resource_group_name = var.resource_group
  location            = var.location
  target_resource_id  = azurerm_service_plan.application.id
  profile {
    name = "default"
    capacity {
      default = 1
      minimum = 1
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