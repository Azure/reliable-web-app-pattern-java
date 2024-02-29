// ---------------------------------------------------------------------------
//  Production
// ---------------------------------------------------------------------------

# -------------------------
#  Hub Resource Group Name
# -------------------------

resource "azurecaf_name" "hub_resource_group" {
  count         = var.environment == "prod" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = ["hub", var.environment]
}

# --------------------
#  Hub Resource Group
# --------------------

resource "azurerm_resource_group" "hub" {
  count    = var.environment == "prod" ? 1 : 0
  name     = azurecaf_name.hub_resource_group[0].result
  location = var.location
  tags     = local.base_tags
}

# ---------------
#  Hub VNET name
# ---------------

resource "azurecaf_name" "hub_virtual_network_name" {
  count         = var.environment == "prod" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_virtual_network"
  suffixes      = [var.environment]
  prefixes      = [ "hub" ]
}

# ----------
#  Hub VNET
# ----------

module "hub_vnet" {
  count           = var.environment == "prod" ? 1 : 0
  source          = "../shared/terraform/modules/networking/vnet"
  name            = azurecaf_name.hub_virtual_network_name[0].result
  resource_group  = azurerm_resource_group.hub[0].name
  location        = azurerm_resource_group.hub[0].location
  vnet_cidr       = local.hub_vnet_cidr
  tags            = local.base_tags

  subnets = [
    {
      name              = local.firewall_subnet_name
      subnet_cidr       = local.firewall_subnet_cidr
      service_endpoints = null
      delegation        = null
    },
    {
      name              = local.bastion_subnet_name
      subnet_cidr       = local.bastion_subnet_cidr
      service_endpoints = null
      delegation        = null
    },
    {
      name              = local.devops_subnet_name
      subnet_cidr       = local.devops_subnet_cidr
      service_endpoints = null
      delegation        = null
    },
    {
      name              = local.private_link_subnet_name
      subnet_cidr       = local.hub_private_link_subnet_cidr
      service_endpoints = null
      delegation        = null
    }
  ]
}
 
resource "azurecaf_name" "firewall_name" {
  count         = var.environment == "prod" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_firewall"
  suffixes      = [var.environment]
}

module "firewall" {
  count          = var.environment == "prod" ? 1 : 0
  source         = "../shared/terraform/modules/firewall"
  name           = azurecaf_name.firewall_name[0].result

  # Retrieve the subnet id by a lookup on subnet name from the list of subnets in the module output
  subnet_id      = module.hub_vnet[0].subnets[local.firewall_subnet_name].id
  resource_group = azurerm_resource_group.hub[0].name
  location       = azurerm_resource_group.hub[0].location

  firewall_rules_source_addresses = concat(local.hub_vnet_cidr, local.spoke_vnet_cidr)
  devops_subnet_cidr              = local.devops_subnet_cidr
  tags                            = local.base_tags
}
