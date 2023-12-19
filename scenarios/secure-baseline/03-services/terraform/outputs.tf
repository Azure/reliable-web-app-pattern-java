output "frontdoor_url" {
  value       = "https://${module.frontdoor.host_name}"
  description = "The Web application Front Door URL."
}

output "app_service_name" {
  value       = module.application.application_name
  description = "The Web application name."
}