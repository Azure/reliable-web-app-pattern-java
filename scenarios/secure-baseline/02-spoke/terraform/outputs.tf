output "spoke_resource_group" {
  value       = azurerm_resource_group.spoke.name
  description = "The primary resource group."
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics workspace."
  value       = module.app_insights.log_analytics_workspace_id
}