module "vm" {
  source            = "../shared/terraform/modules/vms"
  vm_name           = "vm-jumpbox"
  location          = var.location
  tags              = local.base_tags
  admin_username    = var.jumpbox_username
  admin_password    = var.jumpbox_password
  resource_group    = azurerm_resource_group.hub.name
  size              = var.jumpbox_vm_size
  subnet_id         = module.hub_vnet.subnets[local.devops_subnet_name].id
}

resource "azurecaf_name" "bastion_name" {
  name          = var.application_name
  resource_type = "azurerm_bastion_host"
  suffixes      = [local.environment]
}

module "bastion" {
  source = "../shared/terraform/modules/bastion"

  name            = azurecaf_name.bastion_name.result
  subnet_id       = module.hub_vnet.subnets[local.bastion_subnet_name].id
  resource_group  = azurerm_resource_group.hub.name
  location        = azurerm_resource_group.hub.location

  tags = local.base_tags
}
