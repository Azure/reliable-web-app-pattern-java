output "application_registration_id" {
  value       = azuread_application.app_registration.client_id
  description = "The Client Id for the application."
}

output "application_client_secret" {
  value       = azuread_application_password.application_password.value
  sensitive   = true
  description = "The client secret of the application"
}
