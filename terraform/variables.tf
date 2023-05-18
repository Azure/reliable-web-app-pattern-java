variable "application_name" {
  type        = string
  description = "The application name"

  validation {
    condition     = length(var.application_name) < 18
    error_message = "The length of the application_name must be less than 18 characters."
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

variable "database_administrator_password" {
  type        = string
  description = "The password for the PostgreSQL administrator login"
}

variable "enable_telemetry" {
  type        = bool
  description = "Telemetry collection is on by default"
  default     = true
}

variable "principal_type" {
  type = string
  description = "Describes the type of user running the deployment. Valid options are 'User' or 'ServicePrincipal'"
  default = "User"
  validation {
    condition     = contains(["User", "ServicePrincipal"], var.principal_type)
    error_message = "The principal_type value must be user or service_principal."
  }
}