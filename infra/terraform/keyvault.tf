module "key-vault" {
  source           = "../shared/terraform/modules/key-vault"
  resource_group   = azurerm_resource_group.hub.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  virtual_network_id         = module.hub_vnet.vnet_id
  private_endpoint_subnet_id = module.hub_vnet.subnets[local.private_link_subnet_name].id

  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = [local.mynetwork]
    virtual_network_subnet_ids = [
                                  module.spoke_vnet.subnets[local.app_service_subnet_name].id, 
                                  module.secondary_spoke_vnet[0].subnets[local.app_service_subnet_name].id
                                 ]
  }

  log_analytics_workspace_id = module.app_insights.log_analytics_workspace_id
  azure_ad_tenant_id         = data.azuread_client_config.current.tenant_id
}
