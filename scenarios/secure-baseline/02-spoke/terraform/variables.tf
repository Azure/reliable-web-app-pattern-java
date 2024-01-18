variable "application_name" {
  type        = string
  description = "The application name"

  validation {
    condition     = length(var.application_name) > 0 && length(var.application_name) < 18
    error_message = "application_name is required and the length must be less than 18 characters."
  }
}

variable "enable_telemetry" {
  type        = bool
  description = "Telemetry collection is on by default"
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

#####################################
# Hub Network Configuration Variables
#####################################

variable "hub_vnet_id" {
  type = string
  description = "The hub virtual network id"
}
