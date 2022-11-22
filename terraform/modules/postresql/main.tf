terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

# Quickstart: Use Terraform to create an Azure Database for MySQL - Flexible Server
# https://docs.microsoft.com/en-us/azure/mysql/flexible-server/quickstart-create-terraform?tabs=azure-cli


# Azure Private DNS provides a reliable, secure DNS service to manage and
# resolve domain names in a virtual network without the need to add a custom DNS solution
# https://docs.microsoft.com/en-us/azure/dns/private-dns-privatednszone
resource "azurerm_private_dns_zone" "postresql_database" {
  name                = "${var.application_name}.postgres.database.azure.com"
  resource_group_name = var.resource_group
}

# After you create a private DNS zone in Azure, you'll need to link a virtual network to it.
# https://docs.microsoft.com/en-us/azure/dns/private-dns-virtual-network-links
resource "azurerm_private_dns_zone_virtual_network_link" "postresql_database" {
  name                  = "${var.application_name}PSQLVnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.postresql_database.name
  virtual_network_id    = var.virtual_network_id
  resource_group_name   = var.resource_group
}

resource "random_password" "password" {
  length           = 32
  special          = true
  override_special = "_%@"
}

resource "azurecaf_name" "postgresql_server" {
  name          = var.application_name
  resource_type = "azurerm_postgresql_flexible_server"
  suffixes      = [var.environment]
}

resource "azurerm_postgresql_flexible_server" "postresql_database" {
  name                = azurecaf_name.postgresql_server.result
  resource_group_name = var.resource_group
  location            = var.location

  administrator_login    = var.administrator_login
  administrator_password = random_password.password.result

  sku_name                     = "GP_Standard_D4s_v3"
  version                      = "12"

  delegated_subnet_id          = var.subnet_network_id
  private_dns_zone_id          = azurerm_private_dns_zone.postresql_database.id

  geo_redundant_backup_enabled = false

  zone = 1

  storage_mb = 32768

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postresql_database]
}

resource "azurerm_postgresql_flexible_server_database" "postresql_database" {
  name                = "${var.application_name}db"
  server_id           = azurerm_postgresql_flexible_server.postresql_database.id
}

#resource "azurecaf_name" "mysql_firewall_rule" {
#  name          = var.application_name
#  resource_type = "azurerm_mysql_firewall_rule"
#  suffixes      = [var.environment]
#}

# This rule is to enable the 'Allow access to Azure services' checkbox
#resource "azurerm_mysql_flexible_server_firewall_rule" "database" {
#  name                = azurecaf_name.mysql_firewall_rule.result
#  resource_group_name = var.resource_group
#  server_name         = azurerm_mysql_flexible_server.database.name
#  start_ip_address    = "0.0.0.0"
#  end_ip_address      = "0.0.0.0"
#}
