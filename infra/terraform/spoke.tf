resource "azurecaf_name" "spoke_resource_group" {
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = ["spoke", local.environment]
}

resource "azurerm_resource_group" "spoke" {
  name     = azurecaf_name.spoke_resource_group.result
  location = var.location
  tags     = local.base_tags
}

resource "azurecaf_name" "spoke_vnet_name" {
  name          = var.application_name
  resource_type = "azurerm_virtual_network"
  prefixes      = ["spoke"]
  suffixes      = [local.environment]
}

module "spoke_vnet" {
  source = "../shared/terraform/modules/networking/vnet"

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
  source = "../shared/terraform/modules/networking/peering"

  local_vnet_name     = module.spoke_vnet.vnet_name
  resource_group_name = azurerm_resource_group.spoke.name
  remote_vnet_id      = module.hub_vnet.vnet_id
}

module "peeringHubToSpoke" {
  source = "../shared/terraform/modules/networking/peering"

  local_vnet_name     = module.hub_vnet.vnet_name
  resource_group_name = azurerm_resource_group.hub.name
  remote_vnet_id      = module.spoke_vnet.vnet_id
}

# ----------------------------------------------------------------------------------------------
# 2nd region
# ----------------------------------------------------------------------------------------------

resource "azurecaf_name" "secondary_spoke_resource_group" {
  count         = local.is_multi_region ? 1 : 0

  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = ["spoke2", local.environment]
}

resource "azurerm_resource_group" "secondary_spoke" {
  count    = local.is_multi_region ? 1 : 0

  name     = azurecaf_name.secondary_spoke_resource_group[0].result
  location = var.secondary_location
  tags     = local.base_tags
}

resource "azurecaf_name" "secondary_spoke_vnet_name" {
  count         = local.is_multi_region ? 1 : 0

  name          = var.application_name
  resource_type = "azurerm_virtual_network"
  prefixes      = ["spoke2"]
  suffixes      = [local.environment]
}

module "secondary_spoke_vnet" {
  count         = local.is_multi_region ? 1 : 0

  source = "../shared/terraform/modules/networking/vnet"

  name            = azurecaf_name.secondary_spoke_vnet_name[0].result
  resource_group  = azurerm_resource_group.secondary_spoke[0].name
  location        = azurerm_resource_group.secondary_spoke[0].location
  vnet_cidr       = local.secondary_spoke_vnet_cidr

  subnets = [
    {
      name              = local.app_service_subnet_name
      subnet_cidr       = local.secondary_appsvc_subnet_cidr
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
      subnet_cidr       = local.secondary_front_door_subnet_cidr
      service_endpoints = null
      delegation        = null
    },
    {
      name              = local.private_link_subnet_name
      subnet_cidr       = local.secondary_spoke_private_link_subnet_cidr
      service_endpoints = null
      delegation        = null
    },
    {
      name = local.postgresql_subnet_name
      subnet_cidr = local.secondary_postgresql_subnet_cidr

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

module "peeringSpoke2ToHub" {
  count = local.is_multi_region ? 1 : 0

  source = "../shared/terraform/modules/networking/peering"

  local_vnet_name     = module.secondary_spoke_vnet[0].vnet_name
  resource_group_name = azurerm_resource_group.secondary_spoke[0].name
  remote_vnet_id      = module.hub_vnet.vnet_id
}

module "peeringHubToSpoke2" {
  count = local.is_multi_region ? 1 : 0

  source = "../shared/terraform/modules/networking/peering"

  local_vnet_name     = module.hub_vnet.vnet_name
  resource_group_name = azurerm_resource_group.hub.name
  remote_vnet_id      = module.secondary_spoke_vnet[0].vnet_id
}

module "peeringSpokeToSpoke2" {
  count = local.is_multi_region ? 1 : 0

  source = "../shared/terraform/modules/networking/peering"

  local_vnet_name     = module.spoke_vnet.vnet_name
  resource_group_name = azurerm_resource_group.spoke.name
  remote_vnet_id      = module.secondary_spoke_vnet[0].vnet_id
}

module "peeringSpoke2ToSpoke" {
  count = local.is_multi_region ? 1 : 0

  source = "../shared/terraform/modules/networking/peering"

  local_vnet_name     = module.secondary_spoke_vnet[0].vnet_name
  resource_group_name = azurerm_resource_group.secondary_spoke[0].name
  remote_vnet_id      = module.spoke_vnet.vnet_id
}
