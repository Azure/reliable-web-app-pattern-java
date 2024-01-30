module "ad" {
  source                       = "../../shared/terraform/modules/active-directory"
  application_name             = var.application_name
  environment                  = local.environment
  frontdoor_host_name          = module.frontdoor.host_name
}
