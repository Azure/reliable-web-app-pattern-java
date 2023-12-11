data "azurerm_subnet" "private_link_subnet" {
  name                 = local.private_link_subnet_name
  resource_group_name  = local.spoke_vnet_resource_group
  virtual_network_name = local.spoke_vnet_name
}

module "cache" {
  source                      = "../../../shared/terraform/modules/cache"
  resource_group              = local.spoke_vnet_resource_group
  environment                 = local.environment
  location                    = var.location
  private_endpoint_vnet_id    = var.spoke_vnet_id
  private_endpoint_subnet_id  = data.azurerm_subnet.private_link_subnet.id
  log_analytics_workspace_id  = var.log_analytics_workspace_id
}