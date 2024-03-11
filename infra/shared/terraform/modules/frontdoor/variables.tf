variable "resource_group" {
  type        = string
  description = "The resource group"
}

variable "application_name" {
  type        = string
  description = "The name of your application"
}

variable "environment" {
  type        = string
  description = "The environment (dev, test, prod...)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
}

variable "front_door_sku_name" {
  type    = string
  default = "Standard_AzureFrontDoor"
  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.front_door_sku_name)
    error_message = "The SKU value must be Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "host_name" {
  type        = string
  description = "The IPv4 address, IPv6 address or Domain name of the Origin."
}

variable "web_app_id" {
  type        = string
  description = "The ID of the web app."
}

variable "private_link_target_type" {
  type        = string
  description = "The type of the private link target."
}

# ----------------------------------------------------------------------------------------------
#  Everything below this comment is for provisioning the 2nd region (if AZURE_LOCATION2 was set)
# ----------------------------------------------------------------------------------------------
variable "secondary_location" {
  type        = string
  description = "The Azure region where all resources in this example should be created for the secondary location"
}

variable "host_name2" {
  type        = string
  description = "The IPv4 address, IPv6 address or Domain name of the secondary Origin."
}

variable "secondary_web_app_id" {
  type        = string
  description = "The ID of the web app in the secondary region."
}