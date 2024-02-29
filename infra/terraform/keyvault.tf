# -----------------
#  Hub - Key Vault
# -----------------

module "hub_key_vault" {
  count                      = var.environment == "prod" ? 1 : 0
  source                     = "../shared/terraform/modules/key-vault"
  resource_group             = azurerm_resource_group.hub[0].name
  application_name           = var.application_name
  environment                = var.environment
  location                   = var.location
  virtual_network_id         = module.hub_vnet[0].vnet_id
  private_endpoint_subnet_id = module.hub_vnet[0].subnets[local.private_link_subnet_name].id
  log_analytics_workspace_id = module.hub_app_insights[0].log_analytics_workspace_id
  azure_ad_tenant_id         = data.azuread_client_config.current.tenant_id

  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = [local.mynetwork]
    virtual_network_subnet_ids = [
                                  module.spoke_vnet[0].subnets[local.app_service_subnet_name].id, 
                                  module.secondary_spoke_vnet[0].subnets[local.app_service_subnet_name].id
                                 ]
  }
}

# -----------------
#  Dev - Key Vault
# -----------------

module "dev_key_vault" {
  count                      = var.environment == "dev" ? 1 : 0
  source                     = "../shared/terraform/modules/key-vault"
  resource_group             = azurerm_resource_group.dev[0].name
  application_name           = var.application_name
  environment                = var.environment
  location                   = var.location
  log_analytics_workspace_id = module.dev_app_insights[0].log_analytics_workspace_id
  azure_ad_tenant_id         = data.azuread_client_config.current.tenant_id
  virtual_network_id         = null
  private_endpoint_subnet_id = null
}
