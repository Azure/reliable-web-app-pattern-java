//The name of the environment (e.g. "dev", "test", "prod". Up to 8 characters long.
environment             = "dev"
tags                    = {}

#####################################
# Hub Network Configuration Variables
#####################################
hub_vnet_cidr           = ["10.0.0.0/24"]
hub_vnet_id             = "<Hub VNET ID>"

#######################################
# Spoke Network Configuration Variables
#######################################
spoke_vnet_cidr           = ["10.240.0.0/20"]
appsvc_subnet_cidr        = ["10.240.0.0/26"]
front_door_subnet_cidr    = ["10.240.0.64/26"]
private_link_subnet_cidr  = ["10.240.11.0/24"]

deployment_options = {
}