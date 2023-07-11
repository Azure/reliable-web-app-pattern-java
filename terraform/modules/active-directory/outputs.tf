output "application_registration_id" {
  value       = var.principal_type == "User" ?  azuread_application.app_registration[0].application_id : var.proseware_client_id
  description = "The id of application registration  (also called Client ID)."
}

output "application_client_secret" {
  value       = var.principal_type == "User" ?  azuread_application_password.application_password[0].value : "Not set by terraform, provided by input param"
  sensitive   = true
  description = "The client secret of the application"
}
