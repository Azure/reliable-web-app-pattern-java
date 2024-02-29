// ---------------------------------------------------------------------------
//  Production
// ---------------------------------------------------------------------------

# -----------------------------------
#  Hub - Application Insights
# -----------------------------------

module "hub_app_insights" {
  count              = var.environment == "prod" ? 1 : 0
  source             = "../shared/terraform/modules/app-insights"
  resource_group     = azurerm_resource_group.hub[0].name
  application_name   = var.application_name
  environment        = var.environment
  location           = var.location
}

// ---------------------------------------------------------------------------
//  Development
// ---------------------------------------------------------------------------

# ----------------------------
#  Dev - Application Insights
# ----------------------------

module "dev_app_insights" {
  count              = var.environment == "dev" ? 1 : 0
  source             = "../shared/terraform/modules/app-insights"
  resource_group     = azurerm_resource_group.dev[0].name
  application_name   = var.application_name
  environment        = var.environment
  location           = var.location
}
