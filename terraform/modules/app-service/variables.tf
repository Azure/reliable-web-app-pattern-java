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
  default     = "dev"
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
}

variable "database_id" {
  type        = string
  description = "The id of the database"
}

variable "database_name" {
  type        = string
  description = "The name of the database"
}

variable "database_fqdn" {
  type        = string
  description = "The FQDN of the database"
}

variable "database_username" {
  type        = string
  description = "The database username"
}

variable "database_password" {
  type        = string
  description = "The database password"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
}

variable "storage_account_primary_access_key" {
  type        = string
  description = "The storage account access key"
}

variable "subnet_id" {
  type        = string
  description = "The id of the subnet for the application"
}

variable "key_vault_uri" {
  type        = string
  description = "The uri of the key vault"
}
