module "app_insights" {
  source = "../../shared/terraform/modules/app-insights"
  resource_group     = azurerm_resource_group.hub.name
  application_name   = var.application_name
  environment        = local.environment
  location           = var.location
}
