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

resource "azurecaf_name" "hub_resource_group" {
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = [local.environment]
}

resource "azurerm_resource_group" "hub" {
  name     = azurecaf_name.hub_resource_group.result
  location = var.location

  tags = local.base_tags
}

resource "azurecaf_name" "hub_virtual_network_name" {
  name          = var.application_name
  resource_type = "azurerm_virtual_network"
  suffixes      = [local.environment]
  prefixes      = [ "hub" ]
}

module "vnet" {
  source = "../../../shared/terraform/modules/networking/vnet"

  name            = azurecaf_name.hub_virtual_network_name.result
  resource_group  = azurerm_resource_group.hub.name
  location        = azurerm_resource_group.hub.location
  vnet_cidr       = local.hub_vnet_cidr

  subnets = [
    {
      name        = local.firewall_subnet_name
      subnet_cidr = local.firewall_subnet_cidr
      service_endpoints = null
      delegation  = null
    },
    {
      name        = local.bastion_subnet_name
      subnet_cidr = local.bastion_subnet_cidr
      service_endpoints = null
      delegation  = null
    },
    {
      name        = local.devops_subnet_name
      subnet_cidr = local.devops_subnet_cidr
      service_endpoints = null
      delegation  = null
    },
    {
      name        = local.private_link_subnet_name
      subnet_cidr = local.private_link_subnet_cidr
      service_endpoints = null
      delegation  = null
    }
  ]

  tags = local.base_tags
}

resource "azurecaf_name" "firewall_name" {
  name          = var.application_name
  resource_type = "azurerm_firewall"
  suffixes      = [local.environment]
}

module "firewall" {
  source = "../../../shared/terraform/modules/firewall"

  name            = azurecaf_name.firewall_name.result

  # Retrieve the subnet id by a lookup on subnet name from the list of subnets in the module output
  subnet_id      = module.vnet.subnets[local.firewall_subnet_name].id
  resource_group = azurerm_resource_group.hub.name
  location       = azurerm_resource_group.hub.location

  firewall_rules_source_addresses = concat(local.hub_vnet_cidr, local.spoke_vnet_cidr)

  devops_subnet_cidr = local.devops_subnet_cidr

  tags = local.base_tags
}

resource "azurecaf_name" "bastion_name" {
  name          = var.application_name
  resource_type = "azurerm_bastion_host"
  suffixes      = [local.environment]
}

module "bastion" {
  count = var.deploy_bastion ? 1 : 0

  source = "../../../shared/terraform/modules/bastion"

  name            = azurecaf_name.bastion_name.result
  subnet_id       = module.vnet.subnets[local.bastion_subnet_name].id
  resource_group  = azurerm_resource_group.hub.name
  location        = azurerm_resource_group.hub.location

  tags = local.base_tags
}

module "app_insights" {
  source = "../../../shared/terraform/modules/app-insights"
  resource_group     = azurerm_resource_group.hub.name
  application_name   = var.application_name
  environment        = local.environment
  location           = var.location
}