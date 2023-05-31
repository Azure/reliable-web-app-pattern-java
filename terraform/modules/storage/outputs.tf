output "storage_account_name" {
  value       = azurerm_storage_account.sa.name
  description = "The name of the storage account"
}

output "storage_primary_access_key" {
  value       = azurerm_storage_account.sa.primary_access_key
  sensitive   = true
  description = "The primary key of the storage account"
}

output "storage_account_id" {
    value = azurerm_storage_account.sa.id
}

output "trainings_share_name" {
  value = azurerm_storage_share.sashare_trainings.name
}

output "playlist_share_name" {
  value = azurerm_storage_share.sashare_playlist.name
}