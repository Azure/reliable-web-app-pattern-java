variable "application_name" {
  type        = string
  description = "The application name"

  validation {
    condition     = length(var.application_name) > 0 && length(var.application_name) < 18
    error_message = "application_name is required and the length must be less than 18 characters."
  }
}

variable "environment" {
  type        = string
  description = "The environment (dev, test, prod...)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
  default     = "eastus"
}

variable "tags" {
  type        = map(string)
  description = "[Optional] Additional tags to assign to your resources"
  default     = {}
}

#####################################
# Hub Network Configuration Variables
#####################################
variable "bastion_subnet_name" {
  type        = string
  description = "[Optional] Name of the subnet to deploy bastion resource to. Defaults to 'AzureBastionSubnet'"
  default     = "AzureBastionSubnet"
}

variable "firewall_subnet_name" {
  type        = string
  description = "[Optional] Name of the subnet for firewall resources. Defaults to 'AzureFirewallSubnet'"
  default     = "AzureFirewallSubnet"
}
variable "hub_vnet_cidr" {
  type        = list(string)
  description = "[Optional] The CIDR block(s) for the hub virtual network. Defaults to 10.242.0.0/20"
  default     = ["10.0.0.0/24"]
}

variable "spoke_vnet_cidr" {
  type        = list(string)
  description = "[Optional] The CIDR block(s) for the virtual network for whitelisting on the firewall. Defaults to 10.240.0.0/20"
  default     = ["10.1.0.0/24"]
}

variable "firewall_subnet_cidr" {
  type        = list(string)
  description = "[Optional] The CIDR block(s) for the firewall subnet. Defaults to 10.242.0.0/26"
  default     = ["10.0.0.0/26"]
}

variable "bastion_subnet_cidr" {
  type        = list(string)
  description = "[Optional] The CIDR block(s) for the bastion subnet. Defaults to 10.242.0.64/26"
  default     = ["10.0.0.64/26"]
}

variable "deployment_options" {
  type = object({
    deploy_bastion             = bool
    deploy_vm                  = bool
  })

  description = "Opt-in settings for the deployment: enable WAF in Front Door, deploy Azure Firewall and UDRs in the spoke network to force outbound traffic to the Azure Firewall, deploy Redis Cache."

  default = {
    deploy_bastion             = true
    deploy_vm                  = true
  }
}
