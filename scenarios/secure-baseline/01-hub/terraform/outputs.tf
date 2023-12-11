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

output "key_vault_id" {
  description = "The resource ID of the key vault."
  value       = module.key-vault.vault_id
}

output "key_vault_uri" {
  description = "The URI of the key vault."
  value       = module.key-vault.vault_uri
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the log analytics workspace."
  value       = module.app_insights.log_analytics_workspace_id 
}

output "application_insights_id" {
  description = "The resource ID of the application insights."
  value       = module.app_insights.app_insights_id
}
