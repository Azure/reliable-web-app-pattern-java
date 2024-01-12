output "spoke_vnet_id" {
  value       = module.vnet.vnet_id
  description = "The primary spoke virtual network id."
}

output "spoke_vnet_name" {
  value       = module.vnet.vnet_name
  description = "The primary spoke virtual network name."
}

output "spoke_subnet_ids" {
  value       = module.vnet.subnet_ids
  description = "The primary spoke subnet ids."
}

output "spoke_resource_group" {
  value = azurerm_resource_group.spoke.name
  description = "value of the spoke resource group name"
}