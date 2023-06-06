variable "resource_group" {
  type        = string
  description = "The resource group"
}

variable "application_name" {
  type        = string
  description = "The name of your application"
}

variable "environment" {
  type        = string
  description = "The environment (dev, test, prod...)"
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
}

variable "vnet_cidr" {
  type        = list(string)
  description = "The address space that is used by the virtual network."
}

variable "app_subnet_cidr" {
  type        = list(string)
  description = "The subnet cidr for the app"
}

variable "postgresql_subnet_cidr" {
  type        = list(string)
  description = "The subnet cidr for PostgreSQL"
}

variable "private_endpoint_subnet_cidr" {
  type        = list(string)
  description = "The subnet cidr for the private endpoints"
}
