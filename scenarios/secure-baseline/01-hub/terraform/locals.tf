locals {
  // If an environment is set up (dev, test, prod...), it is used in the application name
  environment = var.environment == "" ? "dev" : var.environment
  telemetryId = "92141f6a-c03e-4141-bc1c-2113e4772c8d-${var.location}"

  base_tags = merge({
    "terraform"         = true
    "environment"       = local.environment
    "application-name"  = var.application_name
    "contoso-version"   = "1.0"
    "app-pattern-name"  = "java-rwa"
    "azd-env-name"     = var.application_name
  }, var.tags)

  firewall_subnet_name = "AzureFirewallSubnet"
  bastion_subnet_name  = "AzureBastionSubnet"
  devops_subnet_name   = "devops"
}