output "vault_id" {
  value       = azurerm_key_vault.application.id
  description = "The Azure Key Vault ID"
}

output "vault_uri" {
  value       = azurerm_key_vault.application.vault_uri
  description = "The Azure Key Vault URI"
}

output "vault_name" {
  value       = azurerm_key_vault.application.name
  description = "The Azure Key Vault Name"
}
