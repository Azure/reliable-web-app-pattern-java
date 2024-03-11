terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.26"
    }
  }
}

#https://learn.microsoft.com/en-us/azure/app-service/overview-private-endpoint#dns
resource "azurecaf_name" "webapp_private_endpoint" {
  name          = var.app_service_name
  resource_type = "azurerm_private_endpoint"
}

resource "azurerm_private_endpoint" "app_private_endpoint" {
  name                = azurecaf_name.webapp_private_endpoint.result
  resource_group_name = var.resource_group
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = azurecaf_name.webapp_private_endpoint.result
    private_connection_resource_id = var.appsvc_webapp_id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

locals {
  private_dns_records = [
    lower("${var.app_service_name}"),
    lower("${var.app_service_name}.scm")
  ]
}

resource "azurerm_private_dns_a_record" "this" {
  count = length(local.private_dns_records)

  name                = local.private_dns_records[count.index]
  zone_name           = "privatelink.azurewebsites.net"
  resource_group_name = var.private_dns_resource_group
  ttl                 = 300
  records             = [azurerm_private_endpoint.app_private_endpoint.private_service_connection[0].private_ip_address]
}