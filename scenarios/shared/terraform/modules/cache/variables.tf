variable "resource_group" {
  type        = string
  description = "The resource group"
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

variable "private_endpoint_vnet_id" {
  type        = string
  description = "The resourceId for a vnet in an Azure vnet that will be used for private endpoints"
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "The resourceId for a subnet in an Azure vnet that will be used for private endpoints"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The id of the log analytics workspace"
}
