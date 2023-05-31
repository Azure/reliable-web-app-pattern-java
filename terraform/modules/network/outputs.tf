output "vnet_name" {
  value = azurerm_virtual_network.network.name
  description = "The name of the vnet"
}

output "vnet_id" {
  value       = azurerm_virtual_network.network.id
  description = "The id of the vnet"
}

output "subnets" {
  value = azurerm_subnet.network[*]
}
