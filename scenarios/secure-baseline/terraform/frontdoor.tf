module "frontdoor" {
  source                       = "../../shared/terraform/modules/frontdoor"
  resource_group               = azurerm_resource_group.spoke.name
  application_name             = var.application_name
  environment                  = local.environment
  location                     = var.location
  host_name                    = module.application.application_fqdn
  front_door_sku_name          = local.front_door_sku_name
  web_app_id                   = module.application.web_app_id
  private_link_target_type     = "sites"
  host_name2                   = "" #TODO: multi-region
}
