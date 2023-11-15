output "hub_resource_group" {
  value       = azurerm_resource_group.hub.name
  description = "The primary resource group."
}
