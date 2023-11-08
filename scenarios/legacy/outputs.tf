output "frontdoor_url" {
  value       = "https://${module.frontdoor.host_name}"
  description = "The Web application Front Door URL."
}

output "primary_resource_group" {
  value       = azurerm_resource_group.main.name
  description = "The primary resource group."
}

output "secondary_resource_group" {
  value       = length(azurerm_resource_group.main2) > 0 ? azurerm_resource_group.main2[0].name : null
  description = "The secondary resource group."
}

output "SERVICE_APPLICATION_ENDPOINTS" {
  value       = ["https://${module.frontdoor.host_name}"]
  description = "The Web application Front Door URL."
}