// ---------------------------------------------------------------------------
//  Production
// ---------------------------------------------------------------------------

# ----------------------
#  Production FrontDoor
# ----------------------

module "frontdoor" {
  count                        = var.environment == "prod" ? 1 : 0
  source                       = "../shared/terraform/modules/frontdoor"
  resource_group               = azurerm_resource_group.spoke[0].name
  application_name             = var.application_name
  environment                  = var.environment
  location                     = var.location
  host_name                    = module.application[0].application_fqdn
  front_door_sku_name          = local.front_door_sku_name
  web_app_id                   = module.application[0].web_app_id
  private_link_target_type     = "sites"
  host_name2                   = module.secondary_application[0].application_fqdn
}

// ---------------------------------------------------------------------------
//  Development
// ---------------------------------------------------------------------------

# ---------------
#  Dev FrontDoor
# ---------------

module "dev_frontdoor" {
  count                        = var.environment == "dev" ? 1 : 0
  source                       = "../shared/terraform/modules/frontdoor"
  resource_group               = azurerm_resource_group.dev[0].name
  application_name             = var.application_name
  environment                  = var.environment
  location                     = var.location
  host_name                    = module.dev_application[0].application_fqdn
  front_door_sku_name          = local.front_door_sku_name
  web_app_id                   = module.dev_application[0].web_app_id
  private_link_target_type     = "sites"
  host_name2                   = ""
}
