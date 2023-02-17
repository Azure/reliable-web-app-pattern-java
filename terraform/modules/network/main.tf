terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
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
  address_space       = ["10.0.0.0/16"]
}

# Create the data subnet
resource "azurecaf_name" "app_subnet_name" {
  name          = var.application_name
  resource_type = "azurerm_subnet"
  suffixes      = ["app", var.environment]
}

resource "azurerm_subnet" "app_subnet" {
  name                 = azurecaf_name.app_subnet_name.result
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = [ "Microsoft.Storage", "Microsoft.KeyVault"]

  delegation {
    name = "app-service"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Create the data subnet
resource "azurecaf_name" "data_subnet_name" {
  name          = var.application_name
  resource_type = "azurerm_subnet"
  suffixes      = ["data", var.environment]
}

resource "azurerm_subnet" "data_subnet" {
  name                 = azurecaf_name.data_subnet_name.result
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.2.0/24"]
  
  delegation {
    name = "mysql"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
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
  address_prefixes     = ["10.0.6.0/24"]
  
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

