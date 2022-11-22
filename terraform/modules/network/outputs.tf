output "vnet_id" {
  value       = azurerm_virtual_network.network.id
  description = "The id of the vnet"
}

output "data_subnet_id" {
  value       = azurerm_subnet.data_subnet.id
  description = "The id of the data subnet"
}

output "postgresql_subnet_id" {
  value       = azurerm_subnet.postgresql_subnet.id
  description = "The id of the postgresql subnet"
}

output "app_subnet_id" {
  value       = azurerm_subnet.app_subnet.id
  description = "The id of the application subnet"
}

#output "storage_subnet_id" {
#  value       = azurerm_subnet.storage_subnet.id
#  description = "The id of the storage subnet"
#}