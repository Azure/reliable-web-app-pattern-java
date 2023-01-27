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

variable "virtual_network_id" {
  type        = string
  description = "The id of the vnet with the address space of 10.0.0.0/16"
}

variable "subnet_network_id" {
  type        = string
  description = "The id of the subnet for the database"
}

variable "administrator_login" {
  type        = string
  description = "The MySQL administrator login"
  default     = "myadmin"
}
