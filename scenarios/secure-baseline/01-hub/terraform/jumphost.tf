module "vm" {
  source            = "../../../shared/terraform/modules/vms"
  vm_name           = "vm-jumpbox"
  location          = var.location
  tags              = var.tags
  admin_username     = var.jumpbox_username
  admin_password     = var.jumpbox_password
  resource_group   = azurerm_resource_group.hub.name
  size              = var.jumpbox_vm_size
  subnet_id          = module.vnet.subnets[local.devops_subnet_name].id
}