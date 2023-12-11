//The name of the environment (e.g. "dev", "test", "prod")
environment             = "dev"
tags                    = {}

#####################################
# Hub Network Configuration Variables
#####################################
hub_vnet_cidr            = ["10.0.0.0/24"]
firewall_subnet_cidr     = ["10.0.0.0/26"]
bastion_subnet_cidr      = ["10.0.0.64/26"]
devops_subnet_cidr       = ["10.0.0.128/26"]
private_link_subnet_cidr = ["10.0.0.192/26"]


#####################################
# Spoke Network Configuration Variables
#####################################
spoke_vnet_cidr         = ["10.1.0.0/24"]

#######################################
# Jumpbox Configuration Variables
#######################################
jumpbox_vm_size         = "Standard_B2s"
jumpbox_username        = "azureuser"
jumpbox_password        = ""

deployment_options = {
  deploy_bastion             = true
  deploy_jumpbox             = true
}