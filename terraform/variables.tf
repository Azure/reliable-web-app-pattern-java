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
