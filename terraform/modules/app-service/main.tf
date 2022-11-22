terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
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

# This creates the linux web app
resource "azurerm_linux_web_app" "application" {
  name                = azurecaf_name.app_service.result
  location            = var.location
  resource_group_name = var.resource_group
  service_plan_id     = azurerm_service_plan.application.id
  https_only          = true

  virtual_network_subnet_id = var.subnet_id

  #identity {
  #  type = "SystemAssigned"
  #}

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
  }
}
