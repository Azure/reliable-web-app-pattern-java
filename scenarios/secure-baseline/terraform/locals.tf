locals {

  #####################################
  # Shared Variables
  #####################################
  environment = "prod"
  telemetryId = "BB720B18-3C24-4D84-8C28-7AC01F4D7F2C-${var.location}"

  base_tags = {
    "terraform"         = true
    "environment"       = local.environment
    "application-name"  = var.application_name
    "contoso-version"   = "1.0"
    "app-pattern-name"  = "java-rwa"
    "azd-env-name"     = var.application_name
  }

  private_link_subnet_name = "privateLink"

  #####################################
  # Hub Network Configuration Variables
  #####################################
  firewall_subnet_name = "AzureFirewallSubnet"
  bastion_subnet_name  = "AzureBastionSubnet"
  devops_subnet_name   = "devops"

  hub_vnet_cidr                = ["10.0.0.0/24"]
  firewall_subnet_cidr         = ["10.0.0.0/26"]
  bastion_subnet_cidr          = ["10.0.0.64/26"]
  devops_subnet_cidr           = ["10.0.0.128/26"]
  hub_private_link_subnet_cidr = ["10.0.0.192/26"]

  #####################################
  # Spoke Network Configuration Variables
  #####################################
  app_service_subnet_name   = "serverFarm"
  ingress_subnet_name       = "ingress"
  postgresql_subnet_name    = "fs"

  spoke_vnet_cidr                 = ["10.240.0.0/20"]
  appsvc_subnet_cidr              = ["10.240.0.0/26"]
  front_door_subnet_cidr          = ["10.240.0.64/26"]
  postgresql_subnet_cidr          = ["10.240.0.128/26"]
  spoke_private_link_subnet_cidr  = ["10.240.11.0/24"]

  #####################################
  # Application Configuration Variables
  #####################################

  front_door_sku_name = "Premium_AzureFrontDoor"
  postgresql_sku_name = "GP_Standard_D4s_v3"
}
