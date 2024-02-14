output "spoke_resource_group" {
  value = azurerm_resource_group.spoke.name
  description = "The primary spoke resource group"
}

output "secondary_spoke_resource_group" {
  value = length(azurerm_resource_group.secondary_spoke) > 0 ? azurerm_resource_group.secondary_spoke[0].name : null
  description = "The secondaryspoke resource group"
}

output "frontdoor_url" {
  value       = "https://${module.frontdoor.host_name}"
  description = "The Web application Front Door URL."
}

output "app_service_name" {
  value       = module.application.application_name
  description = "The Web application name in the primary region."
}

output "secondary_app_service_name" {
  value       = length(module.secondary_application) > 0 ? module.secondary_application[0].application_name : null
  description = "The Web application name in the secondary region."
}