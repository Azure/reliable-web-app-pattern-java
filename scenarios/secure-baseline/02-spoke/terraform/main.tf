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

resource "azurecaf_name" "spoke_resource_group" {
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = [local.environment]
}

resource "azurerm_resource_group" "spoke" {
  name     = azurecaf_name.spoke_resource_group.result
  location = var.location

  tags = local.base_tags
}

resource "azurecaf_name" "spoke_vnet_name" {
  name          = var.application_name
  resource_type = "azurerm_virtual_network"
  prefixes      = ["spoke"]
  suffixes      = [local.environment]
}

module "vnet" {
  source = "../../../shared/terraform/modules/networking/vnet"

  name            = azurecaf_name.spoke_vnet_name.result
  resource_group  = azurerm_resource_group.spoke.name
  location        = azurerm_resource_group.spoke.location
  vnet_cidr       = var.spoke_vnet_cidr

  subnets = [
    {
      name              = local.app_service_subnet_name
      subnet_cidr       = var.appsvc_subnet_cidr
      service_endpoints = [ "Microsoft.Storage", "Microsoft.KeyVault"]
      delegation = {
        name = "Microsoft.Web/serverFarms"
        service_delegation = {
          name    = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    },
    {
      name              = local.ingress_subnet_name
      subnet_cidr       = var.front_door_subnet_cidr
      service_endpoints = null
      delegation        = null
    },
    {
      name              = local.private_link_subnet_name
      subnet_cidr       = var.private_link_subnet_cidr
      service_endpoints = null
      delegation        = null
    },
    {
      name = local.postgresql_subnet_name
      subnet_cidr = var.postgresql_subnet_cidr

      service_endpoints = ["Microsoft.Storage"]

      delegation = {
        name = "Microsoft.DBforPostgreSQL/flexibleServers"
        service_delegation = {
          name    = "Microsoft.DBforPostgreSQL/flexibleServers"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    }
  ]

  tags = local.base_tags
}

module "peeringSpokeToHub" {
  source         = "../../../shared/terraform/modules/networking/peering"
  
  local_vnet_name  = module.vnet.vnet_name
  remote_vnet_id   = var.hub_vnet_id
  remote_vnet_name = local.hub_vnet_name
  remote_resource_group_name = azurerm_resource_group.spoke.name
}

module "peeringHubToSpoke" {
  source         = "../../../shared/terraform/modules/networking/peering"

  local_vnet_name  = local.hub_vnet_name
  remote_vnet_id   = module.vnet.vnet_id
  remote_vnet_name = local.hub_vnet_name
  remote_resource_group_name = local.hub_vnet_resource_group
}
