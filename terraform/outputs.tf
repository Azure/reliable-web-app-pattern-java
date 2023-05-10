output "application_url" {
  value       = module.application.application_url
  description = "The Web application URL."
}

output "frontdoor_url" {
  value       = "https://${module.frontdoor.host_name}"
  description = "The Web application Front Door URL."
}

output "resource_group" {
  value       = azurerm_resource_group.main.name
  description = "The resource group."
}

output "app_service_module_outputs" {
  value = module.application
  sensitive = true
}

output "postresql_database_module_outputs" {
  value = module.postresql_database.database_url
}

output "keyvault_module_outputs" {
  value = module.key-vault
}

output "storage_module_storage_account_name" {
  value = module.storage.storage_account_name
}

output "storage_module_storage_primary_access_key" {
  value = module.storage.storage_primary_access_key
  sensitive = true
}

output "application_playlist_share_name" {
  value       = module.application.application_playlist_share_name
  description = "The storage share name used for playlists"
}

output "application_video_share_name" {
  value       = module.application.application_video_share_name
  description = "The storage share name used for training videos"
}

# ----------------------------------------------------------------------------------------------
#  Everything below this comment is for provisioning the 2nd region (if AZURE_LOCATION2 was set)
# ----------------------------------------------------------------------------------------------

output "resource_group2" {
  value       = azurerm_resource_group.main2.name
  description = "The resource group."
}
