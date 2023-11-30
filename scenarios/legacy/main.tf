terraform {
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
  // If an environment is set up (dev, test, prod...), it is used in the application name
  environment = var.environment == "" ? "dev" : var.environment
  telemetryId = "92141f6a-c03e-4141-bc1c-2113e4772c8d-${var.location}"

  // If a location2 is set up, then the deployment is multi region
  is_multi_region          = length(var.location2) > 0

  // Network cidrs for primary region
  primary_network_cidr = ["10.0.0.0/16"]
  primary_app_subnet_cidr = ["10.0.1.0/27"]
  primary_postgresql_subnet_cidr = ["10.0.2.0/27"]
  primary_private_endpoint_subnet_cidr = ["10.0.3.0/27"]

  // Network cidrs for secondary region
  secondary_network_cidr = ["10.1.0.0/16"]
  secondary_app_subnet_cidr = ["10.1.1.0/27"]
  secondary_postgresql_subnet_cidr = ["10.1.2.0/27"]
  secondary_private_endpoint_subnet_cidr = ["10.1.3.0/27"]

  // Read Replicas are currently supported for the General Purpose and Memory Optimized server compute tiers,
  // Burstable server compute tier is not supported. (https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-read-replicas)
  // The SKU therefore needs to be General Purpose for multi region deployments
  postgresql_sku_name = var.environment == "prod" || length(var.location2) > 0 ? "GP_Standard_D4s_v3" : "B_Standard_B1ms"

  contoso_client_id     = var.principal_type == "User" ?  module.ad[0].application_registration_id : var.contoso_client_id
  contoso_tenant_id     = var.principal_type == "User" ?  data.azuread_client_config.current.tenant_id : var.contoso_tenant_id
}

data "azuread_client_config" "current" {}

resource "azurecaf_name" "resource_group" {
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = ["app1", local.environment]
}

resource "azurerm_resource_group" "main" {
  name     = azurecaf_name.resource_group.result
  location = var.location

  tags = {
    "terraform"        = "true"
    "environment"      = local.environment
    "application-name" = var.application_name
    "nubesgen-version" = "0.13.0"
    "contoso-version" = "1.0"
    "app-pattern-name" = "java-rwa"
    "azd-env-name"     = var.application_name
  }
}

module "ad" {
  source                       = "../shared/terraform/modules/active-directory"
  count                        = var.principal_type == "User" ? 1 : 0
  application_name             = var.application_name
  environment                  = local.environment
  frontdoor_host_name          = module.frontdoor.host_name
}

module "network" {
  source                       = "../shared/terraform/modules/network"
  resource_group               = azurerm_resource_group.main.name
  application_name             = var.application_name
  location                     = var.location
  environment                  = local.environment
  vnet_cidr                    = local.primary_network_cidr
  app_subnet_cidr              = local.primary_app_subnet_cidr
  postgresql_subnet_cidr       = local.primary_postgresql_subnet_cidr
  private_endpoint_subnet_cidr = local.primary_private_endpoint_subnet_cidr
}

module "app_insights" {
  source = "../shared/terraform/modules/app-insights"
  resource_group     = azurerm_resource_group.main.name
  application_name   = var.application_name
  environment        = local.environment
  location           = var.location
}

resource "azurerm_postgresql_flexible_server_database" "postresql_database" {
  name                = "${var.application_name}db"
  server_id           = module.postresql_database.database_server_id
}

module "key-vault" {
  source           = "../shared/terraform/modules/key-vault"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  log_analytics_workspace_id     = module.app_insights.log_analytics_workspace_id

  virtual_network_id         = module.network.vnet_id
  private_endpoint_subnet_id = module.network.private_endpoint_subnet_id

  network_acls = {
    bypass                     = "None"
    default_action             = "Deny"
    ip_rules                   = [local.mynetwork]
    virtual_network_subnet_ids = [module.network.app_subnet_id]
  }

  azure_ad_tenant_id = data.azuread_client_config.current.tenant_id
}

module "cache" {
  source                      = "../shared/terraform/modules/cache"
  resource_group              = azurerm_resource_group.main.name
  environment                 = local.environment
  location                    = var.location
  private_endpoint_vnet_id    = module.network.vnet_id
  private_endpoint_subnet_id  = module.network.private_endpoint_subnet_id
  log_analytics_workspace_id  = module.app_insights.log_analytics_workspace_id
}

module "application" {
  source             = "../shared/terraform/modules/app-service"
  resource_group     = azurerm_resource_group.main.name
  application_name   = var.application_name
  environment        = local.environment
  location           = var.location
  subnet_id          = module.network.app_subnet_id

  app_insights_connection_string = module.app_insights.connection_string
  log_analytics_workspace_id     = module.app_insights.log_analytics_workspace_id

  contoso_webapp_options = {
    contoso_active_directory_tenant_id = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_application_tenant_id.id})"
    contoso_active_directory_client_id = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_application_client_id.id})"
    contoso_active_directory_client_secret = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_application_client_secret.id})"

    postgresql_database_url = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_database_url.id})"
    postgresql_database_user = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_database_admin.id})"
    postgresql_database_password = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_database_admin_password.id})"
  }

  frontdoor_host_name     = module.frontdoor.host_name
  frontdoor_profile_uuid  = module.frontdoor.resource_guid
}

# Demo purposes only: assign current user as admin to the created DB
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "contoso-ad-admin" {
  count               = var.principal_type == "User" ? 1 : 0
  server_name         = module.postresql_database.database_name
  resource_group_name = azurerm_resource_group.main_db.name
  tenant_id           = data.azuread_client_config.current.tenant_id
  object_id           = data.azuread_client_config.current.object_id
  principal_name      = data.azuread_client_config.current.object_id
  principal_type      = "User"
}

resource "azurerm_resource_group_template_deployment" "deploymenttelemetry" {
  count               = var.enable_telemetry ? 1 : 0
  name                = local.telemetryId
  resource_group_name = azurerm_resource_group.main.name
  deployment_mode     = "Incremental"

  template_content = <<TEMPLATE
  {
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "variables": {},
    "resources": []
  }
  TEMPLATE
}

data "http" "myip" {
  url = "https://api.ipify.org"
}

locals {
  myip = chomp(data.http.myip.response_body)
  mynetwork = "${cidrhost("${local.myip}/16", 0)}/16"
  virtual_network_app_subnet_ids = local.is_multi_region ? [module.network.app_subnet_id, module.network2[0].app_subnet_id] : [module.network.app_subnet_id]
}


# Set Azure AD Application redirectURI.
resource "null_resource" "setup-application-uri" {
  count   = var.principal_type == "User" ? 1 : 0
  depends_on = [
    module.ad
  ]

  provisioner "local-exec" {
    command = "az ad app update --id ${local.contoso_client_id} --identifier-uris api://${local.contoso_client_id}"
  }
}


# ----------------------------------------------------------------------------------------------
#  PostgreSQL database
# ----------------------------------------------------------------------------------------------

resource "azurecaf_name" "resource_group_db" {
  name          = "${var.application_name}"
  resource_type = "azurerm_resource_group"
  suffixes      = ["db", local.environment]
}

resource "azurerm_resource_group" "main_db" {
  name     = azurecaf_name.resource_group_db.result
  location = length(var.location_db) > 0 ? var.location_db : var.location
  tags = {
    "terraform"        = "true"
    "environment"      = local.environment
    "application-name" = var.application_name
    "nubesgen-version" = "0.13.0"
    "contoso-version" = "1.0"
    "app-pattern-name" = "java-rwa"
    "azd-env-name"     = var.application_name
  }
}

module "postresql_database" {
  source                      = "../shared/terraform/modules/postresql"
  azure_ad_tenant_id          = data.azuread_client_config.current.tenant_id
  resource_group              = azurerm_resource_group.main_db.name
  application_name            = var.application_name
  environment                 = local.environment
  location                    = var.location
  virtual_network_id          = module.network.vnet_id
  subnet_network_id           = module.network.postgresql_subnet_id
  administrator_password      = var.database_administrator_password
  log_analytics_workspace_id  = module.app_insights.log_analytics_workspace_id
  sku_name                    = local.postgresql_sku_name
}

module "postresql_database2" {
  count                       = local.is_multi_region ? 1 : 0
  source                      = "../shared/terraform/modules/postresql"
  azure_ad_tenant_id          = data.azuread_client_config.current.tenant_id
  resource_group              = azurerm_resource_group.main_db.name
  application_name            = var.application_name
  environment                 = local.environment
  location                    = var.location2
  virtual_network_id          = module.network2[0].vnet_id
  subnet_network_id           = module.network2[0].postgresql_subnet_id
  administrator_password      = var.database_administrator_password
  source_server_id            = module.postresql_database.database_server_id
  log_analytics_workspace_id  = module.app_insights.log_analytics_workspace_id
  sku_name                    = local.postgresql_sku_name

  depends_on = [
    module.network,
    module.network2[0],
    azurerm_virtual_network_peering.primary_to_secondary,
    azurerm_virtual_network_peering.secondary_to_primary
  ]
}


# ----------------------------------------------------------------------------------------------
#  Azure Front Door and WAF policy
# ----------------------------------------------------------------------------------------------

resource "azurecaf_name" "resource_group_fd" {
  name          = "${var.application_name}"
  resource_type = "azurerm_resource_group"
  suffixes      = ["fd", local.environment]
}

resource "azurerm_resource_group" "main_fd" {
  name     = azurecaf_name.resource_group_fd.result
  location = length(var.location_fd) > 0 ? var.location_fd : var.location
  tags = {
    "terraform"        = "true"
    "environment"      = local.environment
    "application-name" = var.application_name
    "nubesgen-version" = "0.13.0"
    "contoso-version" = "1.0"
    "app-pattern-name" = "java-rwa"
    "azd-env-name"     = var.application_name
  }
}

module "frontdoor" {
  source           = "../shared/terraform/modules/frontdoor"
  resource_group   = azurerm_resource_group.main_fd.name
  application_name = var.application_name
  environment      = local.environment
  location         = length(var.location_fd) > 0 ? var.location_fd : var.location
  host_name        = module.application.application_fqdn
  host_name2       = local.is_multi_region ? module.application2[0].application_fqdn : ""
}

# ----------------------------------------------------------------------------------------------
#  Everything below this comment is for provisioning the 2nd region (if AZURE_LOCATION2 was set)
# ----------------------------------------------------------------------------------------------

#
# Create 2nd region resource group name by appending "s".
#
resource "azurecaf_name" "resource_group2" {
  count         = local.is_multi_region ? 1 : 0
  name          = "${var.application_name}"
  resource_type = "azurerm_resource_group"
  suffixes      = ["app2", local.environment]
}

#
# Create 2nd resource group.
#
resource "azurerm_resource_group" "main2" {
  count    = local.is_multi_region ? 1 : 0
  name     = azurecaf_name.resource_group2[0].result
  location = var.location2

  tags = {
    "terraform"        = "true"
    "environment"      = local.environment
    "application-name" = var.application_name
    "nubesgen-version" = "0.13.0"
    "contoso-version" = "1.0"
    "app-pattern-name" = "java-rwa"
    "azd-env-name"     = var.application_name
  }
}

module "network2" {
  count                        = local.is_multi_region ? 1 : 0
  source                       = "../shared/terraform/modules/network"
  resource_group               = azurerm_resource_group.main2[0].name
  application_name             = var.application_name
  location                     = var.location2
  environment                  = local.environment
  vnet_cidr                    = local.secondary_network_cidr
  app_subnet_cidr              = local.secondary_app_subnet_cidr
  postgresql_subnet_cidr       = local.secondary_postgresql_subnet_cidr
  private_endpoint_subnet_cidr = local.secondary_private_endpoint_subnet_cidr
}

resource "azurerm_virtual_network_peering" "primary_to_secondary" {
  count                        = local.is_multi_region ? 1 : 0
  name                         = "primary-to-secondary-${var.application_name}"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = module.network.vnet_name
  remote_virtual_network_id    = module.network2[0].vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false

  depends_on = [
    module.network,
    module.network2[0]
  ]
}

resource "azurerm_virtual_network_peering" "secondary_to_primary" {
  count                        = local.is_multi_region ? 1 : 0
  name                         = "secondary-to-primary-${var.application_name}"
  resource_group_name          = azurerm_resource_group.main2[0].name
  virtual_network_name         = module.network2[0].vnet_name
  remote_virtual_network_id    = module.network.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false

  depends_on = [
    module.network,
    module.network2[0]
  ]
}

module "key-vault2" {
  count            = local.is_multi_region ? 1 : 0
  source           = "../shared/terraform/modules/key-vault"
  resource_group   = azurerm_resource_group.main2[0].name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location2

  log_analytics_workspace_id     = module.app_insights.log_analytics_workspace_id

  virtual_network_id         = module.network2[0].vnet_id
  private_endpoint_subnet_id = module.network2[0].private_endpoint_subnet_id

  network_acls = {
    bypass                     = "None"
    default_action             = "Deny"
    ip_rules                   = [local.mynetwork]
    virtual_network_subnet_ids = [module.network2[0].app_subnet_id]
  }

  azure_ad_tenant_id = data.azuread_client_config.current.tenant_id
}

module "cache2" {
  count                       = local.is_multi_region ? 1 : 0
  source                      = "../shared/terraform/modules/cache"
  resource_group              = azurerm_resource_group.main2[0].name
  environment                 = local.environment
  location                    = var.location2
  private_endpoint_vnet_id    = module.network2[0].vnet_id
  private_endpoint_subnet_id  = module.network2[0].private_endpoint_subnet_id
  log_analytics_workspace_id  = module.app_insights.log_analytics_workspace_id
}

module "application2" {
  count               = local.is_multi_region ? 1 : 0
  source              = "../shared/terraform/modules/app-service"
  resource_group      = azurerm_resource_group.main2[0].name
  application_name    = "${var.application_name}"
  environment         = local.environment
  location            = var.location2
  subnet_id           = module.network2[0].app_subnet_id

  app_insights_connection_string = module.app_insights.connection_string
  log_analytics_workspace_id     = module.app_insights.log_analytics_workspace_id

  contoso_webapp_options = {
    contoso_active_directory_tenant_id = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_application_tenant_id.id})"
    contoso_active_directory_client_id = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_application_client_id2[0].id})"
    contoso_active_directory_client_secret = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_application_client_secret2[0].id})"

    postgresql_database_url = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_database_url2[0].id})"
    postgresql_database_user = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_database_admin2[0].id})"
    postgresql_database_password = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.contoso_database_admin_password2[0].id})"
  }

  frontdoor_host_name = module.frontdoor.host_name
  frontdoor_profile_uuid  = module.frontdoor.resource_guid
}
