module "cache" {
  source                      = "../../shared/terraform/modules/cache"
  resource_group              = azurerm_resource_group.spoke.name
  environment                 = local.environment
  location                    = var.location
  private_endpoint_vnet_id    = module.spoke_vnet.vnet_id
  private_endpoint_subnet_id  = module.spoke_vnet.subnets[local.private_link_subnet_name].id
  log_analytics_workspace_id  = module.app_insights.log_analytics_workspace_id
}
