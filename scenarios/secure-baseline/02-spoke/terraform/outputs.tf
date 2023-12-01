output "spoke_resource_group" {
  value       = azurerm_resource_group.spoke.name
  description = "The primary resource group."
}
