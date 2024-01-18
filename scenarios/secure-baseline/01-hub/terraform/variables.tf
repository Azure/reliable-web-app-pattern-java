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

variable "deploy_bastion" {
  type        = bool
  description = "Deploy a bastion host in the hub network."
  default     = true
}

variable "deploy_jumpbox" {
  type        = bool
  description = "Deploy a jumpbox in the hub network."
  default     = true
}