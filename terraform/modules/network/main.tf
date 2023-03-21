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

# https://learn.microsoft.com/en-us/azure/app-service/overview-vnet-integration
resource "azurerm_subnet" "app_subnet" {
  name                 = azurecaf_name.app_subnet_name.result
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.1.0/24"]

  private_endpoint_network_policies_enabled = true

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

# https://learn.microsoft.com/en-us/azure/app-service/networking/private-endpoint
resource "azurerm_subnet" "private_endpoint_subnet" {
  name                 = azurecaf_name.private_endpoint_subnet_name.result
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.3.0/24"]
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
  address_prefixes     = ["10.0.2.0/24"]
  
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
