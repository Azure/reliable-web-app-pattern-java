//The name of the environment (e.g. "dev", "test", "prod". Up to 8 characters long.
environment             = "dev"
tags                    = {}

#####################################
# Hub Network Configuration Variables
#####################################
hub_vnet_cidr           = ["10.0.0.0/24"]
firewall_subnet_cidr    = ["10.0.0.0/26"]
bastion_subnet_cidr     = ["10.0.0.64/26"]

#####################################
# Spoke Network Configuration Variables
#####################################
spoke_vnet_cidr         = ["10.1.0.0/24"]
devops_subnet_cidr      = ["10.1.0.0/26"]

deployment_options = {
  deploy_bastion             = true
}