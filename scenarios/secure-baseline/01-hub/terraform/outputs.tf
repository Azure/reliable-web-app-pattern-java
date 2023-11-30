output "hub_resource_group" {
  description = "The name of the Hub resource group."
  value       = azurerm_resource_group.hub.name
}

output "hub_vnet_id" {
  description = "The resource ID of hub virtual network."
  value       = module.vnet.vnet_id
}

output "hub_vnet_name" {
  value = module.vnet.vnet_name
}
