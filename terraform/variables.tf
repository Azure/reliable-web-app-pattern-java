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

# ----------------------------------------------------------------------------------------------
#  Everything below this comment is for provisioning the 2nd region (if AZURE_LOCATION2 was set)
# ----------------------------------------------------------------------------------------------

variable "location2" {
  type        = string
  description = "The 2nd Azure region where resources in this example should be created"
  default     = "westus"
}
