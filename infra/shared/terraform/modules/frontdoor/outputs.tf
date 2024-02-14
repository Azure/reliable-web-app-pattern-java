output "host_name" {
  value       = azurerm_cdn_frontdoor_endpoint.endpoint.host_name
  description = "The Web application URL."
}

output "resource_guid" {
  value = azurerm_cdn_frontdoor_profile.front_door.resource_guid
  description = "The UUID of this Front Door Profile which will be sent in the HTTP Header as the X-Azure-FDID attribute"
}