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
variable "hub_vnet_cidr" {
  type        = list(string)
  description = "[Optional] The CIDR block(s) for the hub virtual network. Defaults to 10.242.0.0/20"
}

variable "firewall_subnet_cidr" {
  type        = list(string)
  description = "[Optional] The CIDR block(s) for the firewall subnet. Defaults to 10.242.0.0/26"
}

variable "bastion_subnet_cidr" {
  type        = list(string)
  description = "[Optional] The CIDR block(s) for the bastion subnet. Defaults to 10.242.0.64/26"
}

variable "private_link_subnet_cidr" {
  type        = list(string)
  description = "The CIDR block for the private link subnet."
}

#####################################
# Spoke Network Configuration Variables
#####################################

variable "spoke_vnet_cidr" {
  type        = list(string)
  description = "[Optional] The CIDR block(s) for the virtual network for whitelisting on the firewall. Defaults to 10.240.0.0/20"
}

variable "devops_subnet_cidr" {
  type        = list(string)
  description = "[Optional] The CIDR block for the subnet. Defaults to 10.240.10.128/16"
}

variable "jumpbox_username" {
  type        = string
  description = "The username for the jumpbox."
}

variable "jumpbox_password" {
  type        = string
  description = "The password for the jumpbox."
  sensitive   = true
}

variable "jumpbox_vm_size" {
  type        = string
  description = "The size of the jumpbox."
  default     = "Standard_B2ms"
}

variable "deployment_options" {
  type = object({
    deploy_bastion             = bool
    deploy_jumpbox             = bool
  })

  description = "Opt-in settings for the deployment."

  default = {
    deploy_bastion             = true
    deploy_jumpbox             = true
  }
}
