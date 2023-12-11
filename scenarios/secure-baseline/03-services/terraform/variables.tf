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

variable "log_analytics_workspace_id" {
  type = string
  description = "The id of the log analytics workspace"
  
}

variable "app_insights_id" {
  type = string
  description = "The id of the app insights"
}

variable "key_vault_id" {
  type = string
  description = "The id of the key vault"
  
}

########################################
# Spoke Resource Configuration Variables
########################################
variable "spoke_vnet_id" {
  type = string
  description = "The spoke virtual network id"
}

variable "database_administrator_password" {
  type        = string
  description = "The database administrator password"
  default     = null
}

variable "deployment_options" {
  type = object({
  })

  description = "Opt-in settings for the deployment"

  default = {
  }
}

