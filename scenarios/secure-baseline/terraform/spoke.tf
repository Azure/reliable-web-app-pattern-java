resource "azurecaf_name" "spoke_resource_group" {
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = ["spoke", local.environment]
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

module "spoke_vnet" {
  source = "../../shared/terraform/modules/networking/vnet"

  name            = azurecaf_name.spoke_vnet_name.result
  resource_group  = azurerm_resource_group.spoke.name
  location        = azurerm_resource_group.spoke.location
  vnet_cidr       = local.spoke_vnet_cidr

  subnets = [
    {
      name              = local.app_service_subnet_name
      subnet_cidr       = local.appsvc_subnet_cidr
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
      subnet_cidr       = local.front_door_subnet_cidr
      service_endpoints = null
      delegation        = null
    },
    {
      name              = local.private_link_subnet_name
      subnet_cidr       = local.spoke_private_link_subnet_cidr
      service_endpoints = null
      delegation        = null
    },
    {
      name = local.postgresql_subnet_name
      subnet_cidr = local.postgresql_subnet_cidr

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
  source         = "../../shared/terraform/modules/networking/peering"

  local_vnet_name  = module.spoke_vnet.vnet_name
  remote_vnet_id   = module.hub_vnet.vnet_id
  remote_vnet_name = module.hub_vnet.vnet_name
  remote_resource_group_name = azurerm_resource_group.spoke.name
}

module "peeringHubToSpoke" {
  source         = "../../shared/terraform/modules/networking/peering"

  local_vnet_name  = module.hub_vnet.vnet_name
  remote_vnet_id   = module.spoke_vnet.vnet_id
  remote_vnet_name = module.spoke_vnet.vnet_name
  remote_resource_group_name = azurerm_resource_group.hub.name
}
