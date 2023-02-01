output "vault_id" {
  value       = azurerm_key_vault.application.id
  description = "The Azure Key Vault ID"
}

output "vault_uri" {
  value       = azurerm_key_vault.application.vault_uri
  description = "The Azure Key Vault URI"
}

output "airsonic_database_admin_secret_name" {
  value = azurerm_key_vault_secret.airsonic_database_admin.name
  description = "The name of the key vault secret that stores the admin name"
}

output "airsonic_database_admin_password_secret_name" {
  value = azurerm_key_vault_secret.airsonic_database_admin_password.name
  description = "The name of the key vault secret that stores the admin password"
}