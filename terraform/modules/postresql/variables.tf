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
  description = "The PostgreSQL administrator login"
  default     = "myadmin"
}

variable "administrator_password" {
  type        = string
  description = "The password for the PostgreSQL administrator login"
}

variable "replication_enabled" {
  type       = bool
  description = "Is replication enabled"
  default     = false
}

variable "source_server_id" {
  type       = string
  description = "The resource ID of the source PostgreSQL Flexible Server for replication"
  default     = null
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The id of the log analytics workspace"
}

variable "sku_name" {
  type    = string
  default = "B_Standard_B1ms"
}