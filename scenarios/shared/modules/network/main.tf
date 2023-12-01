terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.26"
    }
  }
}

resource "azurecaf_name" "virtual_network_name" {
  name          = var.application_name
  resource_type = "azurerm_virtual_network"
  suffixes      = ["vnet", var.environment]
}

resource "azurerm_virtual_network" "network" {
  name                = azurecaf_name.virtual_network_name.result
  location            = var.location
  resource_group_name = var.resource_group
  address_space       = var.vnet_cidr
}

# Create the data subnet
resource "azurecaf_name" "app_subnet_name" {
  name          = var.application_name
  resource_type = "azurerm_subnet"
  suffixes      = ["app", var.environment]
}

# https://learn.microsoft.com/azure/app-service/overview-vnet-integration
resource "azurerm_subnet" "app_subnet" {
  name                 = azurecaf_name.app_subnet_name.result
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = var.app_subnet_cidr

  service_endpoints = [ "Microsoft.Storage", "Microsoft.KeyVault"]

  delegation {
    name = "app-service"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Create the private endpoint subnet. Private endpoint cannot be created in a subnet that's delegated
resource "azurecaf_name" "private_endpoint_subnet_name" {
  name          = var.application_name
  resource_type = "azurerm_subnet"
  suffixes      = ["pvtendpoint", var.environment]
}

# https://learn.microsoft.com/azure/app-service/networking/private-endpoint
resource "azurerm_subnet" "private_endpoint_subnet" {
  name                 = azurecaf_name.private_endpoint_subnet_name.result
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = var.private_endpoint_subnet_cidr
}

# Create the data subnet
resource "azurecaf_name" "postgresql_subnet_name" {
  name          = var.application_name
  resource_type = "azurerm_subnet"
  suffixes      = ["postgresql", var.environment]
}

resource "azurerm_subnet" "postgresql_subnet" {
  name                 = azurecaf_name.postgresql_subnet_name.result
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = var.postgresql_subnet_cidr
  
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Create a network security group name to allow database access only from the app subnet
resource "azurerm_network_security_group" "postgresql_nsg" {
  name                = "nsg-postgresql-${var.application_name}"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "allow-postgresql-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = azurerm_subnet.app_subnet.address_prefixes[0]
    destination_address_prefix = azurerm_subnet.postgresql_subnet.address_prefixes[0]
  }
}

resource "azurerm_subnet_network_security_group_association" "postgresql_nsg_association" {
  subnet_id                 = azurerm_subnet.postgresql_subnet.id
  network_security_group_id = azurerm_network_security_group.postgresql_nsg.id
}

# Create a NSG to apply to the subnet for the app to restrict all but https traffic inbound
resource "azurerm_network_security_group" "app_nsg" {
  name                = "nsg-app-${var.application_name}"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "allow-app-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.app_subnet.address_prefixes[0]
  }
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_association" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}
