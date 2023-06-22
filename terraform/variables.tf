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

variable "location_fd" {
  type        = string
  description = "The Azure region for Azure Front Door"
  default     = "eastus2"
}

variable "location_db" {
  type        = string
  description = "The Azure region for Storage resource group"
  default     = "eastus2"
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
    error_message = "The principal_type value must be User or ServicePrincipal."
  }
}

variable "proseware_client_id" {
  type = string
  description = "Azure AD App Registration: clientId"
}

variable "proseware_client_secret" {
  type = string
  description = "Azure AD App Registration: clientSecret"
}

variable "proseware_tenant_id" {
  type = string
  description = "Azure AD App Registration: tenantId"
}

# ----------------------------------------------------------------------------------------------
#  Everything below this comment is for provisioning the 2nd region (if AZURE_LOCATION2 was set)
# ----------------------------------------------------------------------------------------------

variable "location2" {
  type        = string
  description = "The 2nd Azure region where resources in this example should be created"
  default     = "westus"
}
