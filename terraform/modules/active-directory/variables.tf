variable "application_name" {
  type        = string
  description = "The name of your application"
}

variable "environment" {
  type        = string
  description = "The environment (dev, test, prod...)"
}

variable "frontdoor_host_name" {
  type        = string
  description = "The front door host name"
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
