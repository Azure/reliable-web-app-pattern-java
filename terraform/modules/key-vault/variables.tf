variable "resource_group" {
  type        = string
  description = "The resource group"
}

variable "azure_ad_tenant_id" {
  type        = string
  description = "The AD tenant id"
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

variable "network_acls" {
  description = "Network rules to apply to key vault."
  type = object({
    bypass                     = string
    default_action             = string
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = null
}

variable "virtual_network_id" {
  type        = string
  description = "The id of the vnet with the address space of 10.0.0.0/16"
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "The id of the subnet to use for private endpoint"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The id of the log analytics workspace"
}