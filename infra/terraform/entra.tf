// ---------------------------------------------------------------------------
//  Production
// ---------------------------------------------------------------------------

# ---------------------
#  Production Entra ID
# ---------------------

module "ad" {
  count                        = var.environment == "prod" ? 1 : 0
  source                       = "../shared/terraform/modules/active-directory"
  application_name             = var.application_name
  environment                  = var.environment
  frontdoor_host_name          = module.frontdoor[0].host_name
}

// ---------------------------------------------------------------------------
//  Development
// ---------------------------------------------------------------------------

# --------------
#  Dev Entra ID
# --------------

module "dev_ad" {
  count                        = var.environment == "dev" ? 1 : 0
  source                       = "../shared/terraform/modules/active-directory"
  application_name             = var.application_name
  environment                  = var.environment
  frontdoor_host_name          = module.dev_frontdoor[0].host_name
}
