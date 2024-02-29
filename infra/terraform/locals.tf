locals {

  #####################################
  # Shared Variables
  #####################################
  telemetryId = "92141f6a-c03e-4141-bc1c-2113e4772c8d-${var.location}"

  base_tags = {
    "terraform"         = true
    "environment"       = var.environment
    "application-name"  = var.application_name
    "contoso-version"   = "1.0"
    "app-pattern-name"  = "java-rwa"
    "azd-env-name"     = var.application_name
  }

  #####################################
  # Common
  #####################################
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

  // Network cidrs for secondary region
  secondary_spoke_vnet_cidr                 = ["10.241.0.0/20"]
  secondary_appsvc_subnet_cidr              = ["10.241.0.0/26"]
  secondary_front_door_subnet_cidr          = ["10.241.0.64/26"]
  secondary_postgresql_subnet_cidr          = ["10.241.0.128/26"]
  secondary_spoke_private_link_subnet_cidr  = ["10.241.11.0/24"]

  #####################################
  # Application Configuration Variables
  #####################################
  front_door_sku_name = var.environment == "prod" ? "Premium_AzureFrontDoor" : "Standard_AzureFrontDoor"
  postgresql_sku_name = var.environment == "prod" ? "GP_Standard_D4s_v3" : "B_Standard_B1ms"
}
