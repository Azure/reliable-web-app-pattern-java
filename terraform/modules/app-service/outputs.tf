output "application_fqdn" {
  value       = azurerm_linux_web_app.application.default_hostname
  description = "The Web application fully qualified domain name (FQDN)."
}

output "application_principal_id" {
  value       = azurerm_linux_web_app.application.identity[0].principal_id
  description = "The id of system assigned managed identity"
}

output "application_name" {
  value       = azurerm_linux_web_app.application.name
  description = "The name for this Linux Web App"
}
