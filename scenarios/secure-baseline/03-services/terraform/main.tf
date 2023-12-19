terraform {
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = true
    }
  }
}

data "azuread_client_config" "current" {}

data "azurerm_application_insights" "app_insights" {
  name                = local.app_insights_name
  resource_group_name = local.app_insights_resource_group
}

data "azurerm_virtual_network" "spoke" {
  name                = local.spoke_vnet_name
  resource_group_name = local.spoke_vnet_resource_group
}

module "frontdoor" {
  source                       = "../../../shared/terraform/modules/frontdoor"
  resource_group               = local.spoke_vnet_resource_group
  application_name             = var.application_name
  environment                  = local.environment
  location                     = var.location
  host_name                    = module.application.application_fqdn
  front_door_sku_name          = local.front_door_sku_name
  web_app_id                   = module.application.web_app_id
  private_link_target_type     = "sites"
  host_name2                   = "" #TODO: multi-region
}

module "ad" {
  source                       = "../../../shared/terraform/modules/active-directory"
  application_name             = var.application_name
  environment                  = local.environment
  frontdoor_host_name          = module.frontdoor.host_name
}

