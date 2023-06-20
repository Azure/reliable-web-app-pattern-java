output "vnet_name" {
  value = azurerm_virtual_network.network.name
  description = "The name of the vnet"
}

output "vnet_id" {
  value       = azurerm_virtual_network.network.id
  description = "The id of the vnet"
}

output "postgresql_subnet_id" {
  value       = azurerm_subnet.postgresql_subnet.id
  description = "The id of the postgresql subnet"
}

output "app_subnet_id" {
  value       = azurerm_subnet.app_subnet.id
  description = "The id of the application subnet"
}

output "private_endpoint_subnet_id" {
  value       = azurerm_subnet.private_endpoint_subnet.id
  description = "The id of the subnet used for private endpoints"
}