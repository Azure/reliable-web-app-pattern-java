output "application_registration_id" {
  value       = azuread_application.app_registration.application_id
  description = "The id of application registration  (also called Client ID)."
}

output "application_client_secret" {
  value       = azuread_application_password.application_password.value
  sensitive   = true
  description = "The client secret of the application"
}
