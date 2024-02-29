// ---------------------------------------------------------------------------
//  Production
// ---------------------------------------------------------------------------

# -----------------------------------
#  Primary Spoke Resource Group Name
# -----------------------------------

resource "azurecaf_name" "spoke_resource_group" {
  count         = var.environment == "prod" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = ["spoke", var.environment]
}

# ------------------------------
#  Primary Spoke Resource Group 
# ------------------------------

resource "azurerm_resource_group" "spoke" {
  count    = var.environment == "prod" ? 1 : 0
  name     = azurecaf_name.spoke_resource_group[0].result
  location = var.location
  tags     = local.base_tags
}

# -------------------------
#  Primary Spoke VNET Name
# -------------------------

resource "azurecaf_name" "spoke_vnet_name" {
  count         = var.environment == "prod" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_virtual_network"
  prefixes      = ["spoke"]
  suffixes      = [var.environment]
}

# --------------------
#  Primary Spoke VNET 
# --------------------

module "spoke_vnet" {
  count           = var.environment == "prod" ? 1 : 0
  source          = "../shared/terraform/modules/networking/vnet"
  name            = azurecaf_name.spoke_vnet_name[0].result
  resource_group  = azurerm_resource_group.spoke[0].name
  location        = azurerm_resource_group.spoke[0].location
  vnet_cidr       = local.spoke_vnet_cidr
  tags            = local.base_tags

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
}
 
module "peeringSpokeToHub" {
  count               = var.environment == "prod" ? 1 : 0
  source              = "../shared/terraform/modules/networking/peering"
  local_vnet_name     = module.spoke_vnet[0].vnet_name
  resource_group_name = azurerm_resource_group.spoke[0].name
  remote_vnet_id      = module.hub_vnet[0].vnet_id
}

module "peeringHubToSpoke" {
  count               = var.environment == "prod" ? 1 : 0
  source              = "../shared/terraform/modules/networking/peering"
  local_vnet_name     = module.hub_vnet[0].vnet_name
  resource_group_name = azurerm_resource_group.hub[0].name
  remote_vnet_id      = module.spoke_vnet[0].vnet_id
}

# -------------------------------------
#  Secondary Spoke Resource Group Name
# -------------------------------------

resource "azurecaf_name" "secondary_spoke_resource_group" {
  count         = var.environment == "prod" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = ["spoke2", var.environment]
}

# --------------------------------
#  Secondary Spoke Resource Group 
# --------------------------------

resource "azurerm_resource_group" "secondary_spoke" {
  count    = var.environment == "prod" ? 1 : 0
  name     = azurecaf_name.secondary_spoke_resource_group[0].result
  location = var.secondary_location
  tags     = local.base_tags
}

# ---------------------------
#  Secondary Spoke VNET Name
# ---------------------------

resource "azurecaf_name" "secondary_spoke_vnet_name" {
  count         = var.environment == "prod" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_virtual_network"
  prefixes      = ["spoke2"]
  suffixes      = [var.environment]
}

# ----------------------
#  Secondary Spoke VNET 
# ----------------------

module "secondary_spoke_vnet" {
  count           = var.environment == "prod" ? 1 : 0
  source          = "../shared/terraform/modules/networking/vnet"
  name            = azurecaf_name.secondary_spoke_vnet_name[0].result
  resource_group  = azurerm_resource_group.secondary_spoke[0].name
  location        = azurerm_resource_group.secondary_spoke[0].location
  vnet_cidr       = local.secondary_spoke_vnet_cidr
  tags            = local.base_tags

  subnets = [
    {
      name              = local.app_service_subnet_name
      subnet_cidr       = local.secondary_appsvc_subnet_cidr
      service_endpoints = [ "Microsoft.Storage", "Microsoft.KeyVault"]
      delegation        = {
        name               = "Microsoft.Web/serverFarms"
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
      name              = local.postgresql_subnet_name
      subnet_cidr       = local.secondary_postgresql_subnet_cidr
      service_endpoints = ["Microsoft.Storage"]
      delegation        = {
        name               = "Microsoft.DBforPostgreSQL/flexibleServers"
        service_delegation = {
            name    = "Microsoft.DBforPostgreSQL/flexibleServers"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }
    }
  ]
}
 
module "peeringSpoke2ToHub" {
  count               = var.environment == "prod" ? 1 : 0
  source              = "../shared/terraform/modules/networking/peering"
  local_vnet_name     = module.secondary_spoke_vnet[0].vnet_name
  resource_group_name = azurerm_resource_group.secondary_spoke[0].name
  remote_vnet_id      = module.hub_vnet[0].vnet_id
}

module "peeringHubToSpoke2" {
  count               = var.environment == "prod" ? 1 : 0
  source              = "../shared/terraform/modules/networking/peering"
  local_vnet_name     = module.hub_vnet[0].vnet_name
  resource_group_name = azurerm_resource_group.hub[0].name
  remote_vnet_id      = module.secondary_spoke_vnet[0].vnet_id
}

module "peeringSpokeToSpoke2" {
  count               = var.environment == "prod" ? 1 : 0
  source              = "../shared/terraform/modules/networking/peering"
  local_vnet_name     = module.spoke_vnet[0].vnet_name
  resource_group_name = azurerm_resource_group.spoke[0].name
  remote_vnet_id      = module.secondary_spoke_vnet[0].vnet_id
}

module "peeringSpoke2ToSpoke" {
  count               = var.environment == "prod" ? 1 : 0
  source              = "../shared/terraform/modules/networking/peering"
  local_vnet_name     = module.secondary_spoke_vnet[0].vnet_name
  resource_group_name = azurerm_resource_group.secondary_spoke[0].name
  remote_vnet_id      = module.spoke_vnet[0].vnet_id
}
