## Virtual Network

resource "azurerm_virtual_network" "vnet" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group
  address_space       = var.vnet_cidr

  tags = var.tags
}

resource "azurerm_subnet" "this" {
  count = length(var.subnets)

  name                 = var.subnets[count.index].name
  address_prefixes     = var.subnets[count.index].subnet_cidr
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name

  service_endpoints = var.subnets[count.index].service_endpoints == null ? [] : var.subnets[count.index].service_endpoints

  dynamic "delegation" {
    for_each = var.subnets[count.index].delegation == null ? [] : [var.subnets[count.index].delegation]

    content {
      name = var.subnets[count.index].delegation.name

      service_delegation {
        name    = var.subnets[count.index].delegation.service_delegation.name
        actions = var.subnets[count.index].delegation.service_delegation.actions
      }
    }
  }
}