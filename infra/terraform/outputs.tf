// ---------------------------------------------------------------------------
//  Production
// ---------------------------------------------------------------------------

# ---------------------------
#  Hub - Resource Group Name
# ---------------------------

output "hub_resource_group" {
  value = length(azurerm_resource_group.hub) > 0 ? azurerm_resource_group.hub[0].name : null
  description = "The Hub resource group"
}

# --------------------------------
#  Primary - Spoke Resource Group
# --------------------------------

output "primary_spoke_resource_group" {
  value = length(azurerm_resource_group.spoke) > 0 ? azurerm_resource_group.spoke[0].name : null
  description = "The Primary Spoke resource group"
}

# ----------------------------------
#  Secondary - Spoke Resource Group
# ----------------------------------

output "secondary_spoke_resource_group" {
  value = length(azurerm_resource_group.secondary_spoke) > 0 ? azurerm_resource_group.secondary_spoke[0].name : null
  description = "The Secondary Spoke resource group"
}

# ------------------------------
#  Primary - App Service Name
# ------------------------------

output "primary_app_service_name" {
  value       = length(module.application) > 0 ? module.application[0].application_name : null
  description = "The Web application name in the primary region."
}

# ------------------------------
#  Secondary - App Service Name
# ------------------------------

output "secondary_app_service_name" {
  value       = length(module.secondary_application) > 0 ? module.secondary_application[0].application_name : null
  description = "The Web application name in the secondary region."
}

output "bastion_host_name" {
  value       = length(module.bastion) > 0 ? module.bastion[0].name : null
  description = "The name of the Bastion Host."
}

output "jumpbox_resource_id" {
  value       = length(module.hub_jumpbox) > 0 ? module.hub_jumpbox[0].vm_id : null
  description = "The resource ID of the Jumpbox."
}

# -----------------------
#  Prod - Front Door URL
# -----------------------

output "frontdoor_url" {
  value       = length(module.frontdoor) > 0 ? "https://${module.frontdoor[0].host_name}" : null
  description = "The Web application Front Door URL."
}

// ---------------------------------------------------------------------------
//  Development
// ---------------------------------------------------------------------------

# ---------------------------
#  Dev - Resource Group Name 
# ---------------------------

output "dev_resource_group" {
  value = length(azurerm_resource_group.dev) > 0 ? azurerm_resource_group.dev[0].name : null
  description = "The Dev Resource Group Name."
}

# ------------------------
#  Dev - App Service Name
# ------------------------

output "dev_app_service_name" {
  value       = length(module.dev_application) > 0 ? module.dev_application[0].application_name : null
  description = "The Dev App Service Name."
}

# ----------------------
#  Dev - Front Door URL
# ----------------------

output "dev_frontdoor_url" {
  value       = length(module.dev_frontdoor) > 0 ? "https://${module.dev_frontdoor[0].host_name}" : null
  description = "The Dev Front Door URL."
}

output "SERVICE_APPLICATION_ENDPOINTS" {
  value       = length(module.dev_frontdoor) > 0 ? ["https://${module.dev_frontdoor[0].host_name}"] : null
  description = "The Dev Web application Front Door URL."
}