output "host_name" {
  value       = azurerm_cdn_frontdoor_endpoint.endpoint.host_name
  description = "The Web application URL."
}
