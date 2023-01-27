terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

resource "azurecaf_name" "cdn_frontdoor_profile_name" {
  name          = var.application_name
  resource_type = "azurerm_frontdoor"
  suffixes      = ["profile", var.environment]
}

resource "azurerm_cdn_frontdoor_profile" "my_front_door" {
  name                = azurecaf_name.cdn_frontdoor_profile_name.result
  resource_group_name = var.resource_group
  sku_name            = var.front_door_sku_name
}

resource "azurecaf_name" "cdn_frontdoor_endpoint_name" {
  name          = var.application_name
  resource_type = "azurerm_frontdoor"
  suffixes      = ["endpoint", var.environment]
}

resource "azurerm_cdn_frontdoor_endpoint" "my_endpoint" {
  name                     = azurecaf_name.cdn_frontdoor_endpoint_name.result
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.my_front_door.id
}

resource "azurecaf_name" "front_door_origin_group_name" {
  name          = var.application_name
  resource_type = "azurerm_frontdoor"
  suffixes      = ["origin", "group", var.environment]
}

resource "azurerm_cdn_frontdoor_origin_group" "my_origin_group" {
  name                     = azurecaf_name.front_door_origin_group_name.result
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.my_front_door.id
  session_affinity_enabled = true

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

resource "azurecaf_name" "front_door_origin_name" {
  name          = var.application_name
  resource_type = "azurerm_frontdoor"
  suffixes      = ["origin", "group", var.environment]
}

resource "azurerm_cdn_frontdoor_origin" "my_app_service_origin" {
  name                          = azurecaf_name.front_door_origin_name.result
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.my_origin_group.id

  enabled                        = true
  host_name                      = var.host_name
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.host_name
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = false
}

resource "azurecaf_name" "front_door_route_name" {
  name          = var.application_name
  resource_type = "azurerm_frontdoor"
  suffixes      = ["route", var.environment]
}

resource "azurerm_cdn_frontdoor_route" "my_route" {
  name                          = azurecaf_name.front_door_route_name.result
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.my_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.my_origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.my_app_service_origin.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true
}

