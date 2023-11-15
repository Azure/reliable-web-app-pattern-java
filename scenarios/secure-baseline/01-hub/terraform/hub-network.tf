module "vnet" {
  source = "../../../shared/terraform/modules/networking/vnet"

  name            = var.application_name
  resource_group  = azurerm_resource_group.hub.name
  location        = azurerm_resource_group.hub.location
  vnet_cidr       = var.hub_vnet_cidr

  subnets = [
    {
      name        = var.firewall_subnet_name
      subnet_cidr = var.firewall_subnet_cidr
      delegation  = null
    },
    {
      name        = var.bastion_subnet_name
      subnet_cidr = var.bastion_subnet_cidr
      delegation  = null
  }]

  tags = local.base_tags
}

module "firewall" {
  source = "../../../shared/terraform/modules/firewall"

  name            = var.application_name

  # Retrieve the subnet id by a lookup on subnet name from the list of subnets in the module output
  subnet_id      = module.vnet.subnets[var.firewall_subnet_name].id
  resource_group = azurerm_resource_group.hub.name
  location       = azurerm_resource_group.hub.location

  firewall_rules_source_addresses = concat(var.hub_vnet_cidr, var.spoke_vnet_cidr)

  tags = local.base_tags
}

module "bastion" {
  count = var.deployment_options.deploy_bastion ? 1 : 0

  source = "../../../shared/terraform/modules/bastion"

  name            = var.application_name
  subnet_id       = module.vnet.subnets[var.bastion_subnet_name].id
  resource_group  = azurerm_resource_group.hub.name
  location        = azurerm_resource_group.hub.location

  tags = local.base_tags
  
}