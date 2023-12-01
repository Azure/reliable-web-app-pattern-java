terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.26"
    }
  }
}

resource "azurecaf_name" "cdn_frontdoor_profile_name" {
  name          = var.application_name
  resource_type = "azurerm_frontdoor"
  suffixes      = ["profile", var.environment]
}

resource "azurerm_cdn_frontdoor_profile" "front_door" {
  name                = azurecaf_name.cdn_frontdoor_profile_name.result
  resource_group_name = var.resource_group
  sku_name            = var.front_door_sku_name
}

resource "azurecaf_name" "cdn_frontdoor_endpoint_name" {
  name          = var.application_name
  resource_type = "azurerm_frontdoor"
  suffixes      = [var.environment]
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = azurecaf_name.cdn_frontdoor_endpoint_name.result
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.front_door.id
}

resource "azurecaf_name" "front_door_origin_group_name" {
  name          = var.application_name
  resource_type = "azurerm_frontdoor"
  suffixes      = ["origin", "group", var.environment]
}

resource "azurerm_cdn_frontdoor_origin_group" "origin_group" {
  name                     = azurecaf_name.front_door_origin_group_name.result
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.front_door.id
  session_affinity_enabled = false

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 16
    successful_samples_required        = 3
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

resource "azurerm_cdn_frontdoor_origin" "app_service_origin" {
  name                          = azurecaf_name.front_door_origin_name.result
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id

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

resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = azurecaf_name.front_door_route_name.result
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.app_service_origin.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true
}

resource "azurecaf_name" "front_door_firewall_policy_name" {
  name          = var.application_name
  resource_type = "azurerm_frontdoor_firewall_policy"
  suffixes      = [var.environment]
}

resource "azurerm_cdn_frontdoor_firewall_policy" "firewall_policy" {
  name                              = azurecaf_name.front_door_firewall_policy_name.result
  resource_group_name               = var.resource_group
  sku_name                          = azurerm_cdn_frontdoor_profile.front_door.sku_name
  enabled                           = true
  mode                              = "Prevention"
}

resource "azurecaf_name" "front_door_security_policy_name" {
  name          = var.application_name
  resource_type = "azurerm_frontdoor"
  suffixes      = ["security", "policy", var.environment]
}

resource "azurerm_cdn_frontdoor_security_policy" "web_app_waf" {
  name                     = azurecaf_name.front_door_security_policy_name.result
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.front_door.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.firewall_policy.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.endpoint.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

# ----------------------------------------------------------------------------------------------
#  Everything below this comment is for provisioning the 2nd region (if AZURE_LOCATION2 was set)
# ----------------------------------------------------------------------------------------------

resource "azurecaf_name" "front_door_origin_name2" {
  name          = "${var.application_name}s"
  resource_type = "azurerm_frontdoor"
  suffixes      = ["origin", "group", var.environment]
}

resource "azurerm_cdn_frontdoor_origin" "app_service_origin2" {
  name                          = azurecaf_name.front_door_origin_name2.result
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id

  enabled                        = false
  host_name                      = length(var.host_name2) > 0 ? var.host_name2 : var.host_name
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = length(var.host_name2) > 0 ? var.host_name2 : var.host_name
  priority                       = 2
  weight                         = 1000
  certificate_name_check_enabled = false
}
