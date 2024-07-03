variable "environment" {
  type        = string
  description = "The environment (dev / prod)"
  default     = "dev"
}

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

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
}

variable "secondary_location" {
  type        = string
  description = "The second Azure region where all resources in this example should be created"
}

variable "jumpbox_username" {
  type        = string
  description = "The username for the jumpbox."
}

variable "jumpbox_vm_size" {
  type        = string
  description = "The size of the jumpbox."
  default     = "Standard_B2ms"
}

#####################################
# Application Configuration Variables
#####################################
variable "database_administrator_password" {
  type        = string
  description = "The database administrator password"
  default     = null
}

variable "service_management_reference" {
  type = string
  description = "value for the service management reference"
  default = null
}
