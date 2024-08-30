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


# Azure Private DNS provides a reliable, secure DNS service to manage and
# resolve domain names in a virtual network without the need to add a custom DNS solution
# https://docs.microsoft.com/azure/dns/private-dns-privatednszone
#
# After you create a private DNS zone in Azure, you'll need to link a virtual network to it.
# https://docs.microsoft.com/azure/dns/private-dns-virtual-network-links

###############################################
# privatelink.azurewebsites.net
###############################################
resource "azurerm_private_dns_zone" "app_dns_zone" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.hub[0].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_virtual_network_link" {
  count                 = var.environment == "prod" ? 1 : 0
  name                  = "spoke-link"
  private_dns_zone_name = azurerm_private_dns_zone.app_dns_zone[0].name
  virtual_network_id    = module.spoke_vnet[0].vnet_id
  resource_group_name   = azurerm_resource_group.hub[0].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "secondary_spoke_virtual_network_link" {
  count                 = var.environment == "prod" ? 1 : 0
  name                  = "secondary-spoke-link"
  private_dns_zone_name = azurerm_private_dns_zone.app_dns_zone[0].name
  virtual_network_id    = module.secondary_spoke_vnet[0].vnet_id
  resource_group_name   = azurerm_resource_group.hub[0].name

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.spoke_virtual_network_link
  ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_virtual_network_link" {
  count                 = var.environment == "prod" ? 1 : 0
  name                  = "hub-link"
  private_dns_zone_name = azurerm_private_dns_zone.app_dns_zone[0].name
  virtual_network_id    = module.hub_vnet[0].vnet_id
  resource_group_name   = azurerm_resource_group.hub[0].name

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.spoke_virtual_network_link,
    azurerm_private_dns_zone_virtual_network_link.secondary_spoke_virtual_network_link
  ]
}


###############################################
# privatelink.postgres.database.azure.com
###############################################
resource "azurerm_private_dns_zone" "postgres_dns_zone" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.hub[0].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_postgres_virtual_network_link" {
  count                 = var.environment == "prod" ? 1 : 0
  name                  = "spoke-postgres-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns_zone[0].name
  virtual_network_id    = module.spoke_vnet[0].vnet_id
  resource_group_name   = azurerm_resource_group.hub[0].name
}


resource "azurerm_private_dns_zone_virtual_network_link" "secondary_postgres_spoke_virtual_network_link" {
  count                 = var.environment == "prod" ? 1 : 0
  name                  = "secondary-spoke-postgres-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns_zone[0].name
  virtual_network_id    = module.secondary_spoke_vnet[0].vnet_id
  resource_group_name   = azurerm_resource_group.hub[0].name

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.spoke_postgres_virtual_network_link
  ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_postgres_virtual_network_link" {
  count                 = var.environment == "prod" ? 1 : 0
  name                  = "hub-postgres-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns_zone[0].name
  virtual_network_id    = module.hub_vnet[0].vnet_id
  resource_group_name   = azurerm_resource_group.hub[0].name

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.spoke_postgres_virtual_network_link,
    azurerm_private_dns_zone_virtual_network_link.secondary_postgres_spoke_virtual_network_link
  ]
}
