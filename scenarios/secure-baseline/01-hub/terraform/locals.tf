locals {
  // If an environment is set up (dev, test, prod...), it is used in the application name
  environment = var.environment == "" ? "dev" : var.environment
  telemetryId = "BB720B18-3C24-4D84-8C28-7AC01F4D7F2C-hub-${var.location}"

  base_tags = {
    "terraform"         = true
    "environment"       = local.environment
    "application-name"  = var.application_name
    "contoso-version"   = "1.0"
    "app-pattern-name"  = "java-rwa"
    "azd-env-name"     = var.application_name
  }

  firewall_subnet_name = "AzureFirewallSubnet"
  bastion_subnet_name  = "AzureBastionSubnet"
  devops_subnet_name   = "devops"
  private_link_subnet_name = "privateLink"

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
}
