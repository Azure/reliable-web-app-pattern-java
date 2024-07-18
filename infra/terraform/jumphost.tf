# ---------------
#  Hub - Jumpbox
# ---------------

resource "random_password" "jumpbox_password" {
  length           = 16
  numeric          = true
  lower            = true
  upper            = true
  special          = true
  override_special = "!#$%&*()-=+[]{}<>:?"
}

module "hub_jumpbox" {
  count                 = var.environment == "prod" ? 1 : 0
  source                = "../shared/terraform/modules/vms"
  vm_name               = "vm-jumpbox"
  location              = var.location
  tags                  = local.base_tags
  admin_username        = var.jumpbox_username
  admin_password        = random_password.jumpbox_password.result
  admin_principal_id    = data.azuread_client_config.current.object_id
  resource_group        = azurerm_resource_group.hub[0].name
  size                  = var.jumpbox_vm_size
  subnet_id             = module.hub_vnet[0].subnets[local.devops_subnet_name].id
}

# --------------------
#  Hub - Bastion Name
# --------------------

resource "azurecaf_name" "hub_bastion_name" {
  count         = var.environment == "prod" ? 1 : 0
  name          = var.application_name
  resource_type = "azurerm_bastion_host"
  suffixes      = [var.environment]
}

# ---------------
#  Hub - Bastion
# ---------------

module "bastion" {
  count           = var.environment == "prod" ? 1 : 0
  source          = "../shared/terraform/modules/bastion"
  name            = azurecaf_name.hub_bastion_name[0].result
  subnet_id       = module.hub_vnet[0].subnets[local.bastion_subnet_name].id
  resource_group  = azurerm_resource_group.hub[0].name
  location        = azurerm_resource_group.hub[0].location
  tags            = local.base_tags
}
